resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 90
  skip_destroy      = false
}

# AWS EKS creates by default a security group that is shared among control plane and nodes. (https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html)
# The default rules allow all traffic to flow freely between your cluster and nodes, and allows all outbound traffic to any destination.
# IMPORTANT: Mind that this is true for Managed Node Groups only.
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.this.arn

  enabled_cluster_log_types = var.cluster_log_types

  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true
    subnet_ids              = var.subnet_ids
  }
}

resource "aws_iam_role" "this" {
  name_prefix = var.cluster_name
  path        = "/"
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "eks.amazonaws.com"
          }
          Sid = "EKSClusterAssumeRole"
        },
      ]
      Version = "2012-10-17"
    }
  )
  force_detach_policies = true
  managed_policy_arns = concat([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSServicePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
  ], var.cluster_additional_iam_policies)

  inline_policy {
    name = var.cluster_name
    policy = jsonencode(
      {
        Statement = [
          {
            Action = [
              "logs:CreateLogGroup",
            ]
            Effect   = "Deny"
            Resource = "*"
          },
        ]
        Version = "2012-10-17"
      }
    )
  }
}

module "node_groups" {
  for_each = var.node_groups
  source   = "./modules/node_groups"

  cluster_name = aws_eks_cluster.this.name
  subnet_ids   = length(each.value.subnet_ids) != 0 ? each.value.subnet_ids : var.subnet_ids
  name_prefix  = each.key
  k8s_version  = each.value.k8s_version

  capacity_type  = each.value.capacity_type
  min_size       = each.value.min_size
  desired_size   = each.value.desired_size
  max_size       = each.value.max_size
  instance_types = each.value.instance_types
  disk_size      = each.value.disk_size

  max_unavailable = each.value.max_unavailable

  node_extra_iam_policies = var.node_extra_iam_policies

  # Support for self-managed nodes
  self_managed = each.value.self_managed
  self_managed_configuration = each.value.self_managed == false ? null : merge(each.value.self_managed_configuration, {
    cluster_certificate_authority_data = aws_eks_cluster.this.certificate_authority[0].data
    cluster_security_group_id          = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
    cluster_endpoint                   = aws_eks_cluster.this.endpoint
  })

  labels = each.value.labels
  tags   = each.value.tags
}

# OpenIDConnect configuration. Used by IAM Roles for Service Account
data "tls_certificate" "this" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = data.tls_certificate.this.certificates[*].sha1_fingerprint
  url             = data.tls_certificate.this.url
}

# AWS Authentication through aws-auth ConfigMap
locals {
  combined_roles = concat(
    [for node in module.node_groups : {
      groups   = ["system:bootstrappers", "system:nodes"]
      rolearn  = node.node_iam_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
    }],
    [for username, arn in var.admin_roles : {
      groups   = ["system:masters"]
      rolearn  = arn
      username = username
    }],
    [for arn in var.additional_node_role_arns : {
      groups   = ["system:bootstrappers", "system:nodes"]
      rolearn  = arn
      username = "system:node:{{EC2PrivateDNSName}}"
    }],
    [for arn in var.fargate_role_arns : {
      groups   = ["system:bootstrappers", "system:nodes", "system:node-proxier"]
      rolearn  = arn
      username = "system:node:{{SessionName}}"
    }],
  )

  aws_auth_configmap_data = {
    mapRoles = yamlencode(local.combined_roles)
    mapUsers = yamlencode([for username, arn in var.admin_users : {
      groups   = ["system:masters"]
      userarn  = arn
      username = username
    }])
    mapAccounts = yamlencode([])
  }
}

resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = local.aws_auth_configmap_data

  field_manager = "Terraform"
  force         = true
}
