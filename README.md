# EKS Module

This module provides an EKS cluster, configurable with managed node groups with/without custom launch template.

## Core concepts

This module covers the following use cases:

* Create quickly a working EKS cluster
* Cluster with long-term maintainability in mind by reducing dependencies to official providers only
* Cluster with default configuration
  * Addons (vpc-cni, kube-proxy, coredns)
  * Support for managed node groups with custom launch templates
  * OpenIDConnect provider to support [IAM Roles for Service Accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
  * [Default security groups](https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html) and extensible IAM permissions

## How do you use this module?

Create the following new module block with the desired parameters in one of your `.tf` file

```tf
module "eks" {
  source = "github.com/tx-pts-dai/terraform-aws-eks.git?ref=eks-v1.0.0"

  cluster_name    = "sample-eks-cluster"
  cluster_version = "1.25"

  subnet_ids  = module.vpc.private_subnets
  node_groups = {
    node-group-01 = {}
  }

  admin_roles = {
    "administrator_sso" = local.admin_sso_role_arn
  }
  admin_users = {
    "cicd" = data.aws_iam_user.github_runner.arn
  }
}

output "eks_cluster_name" {
  value = "${module.eks.cluster_name}"
}
```

Use it in combination with `aws-eks-blueprints` to have workloads, minimally configured, that use minimal permissions to achieve exactly what they need. An example here that deploys cluster-autoscaler, metrics-server and aws-load-balancer controller.

```tf
# Every addon comes with service account and IAM Role for it.
module "eks_blueprints_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons"

  eks_cluster_id       = module.eks.cluster_id
  eks_cluster_version  = module.eks.cluster_version
  eks_cluster_endpoint = module.eks.cluster_endpoint
  eks_oidc_provider    = module.eks.cluster_oidc_provider

  #K8s Add-ons
  enable_cluster_autoscaler = true
  enable_metrics_server     = true

  enable_aws_load_balancer_controller = true
}
```

Further workloads supported by this: <https://aws-ia.github.io/terraform-aws-eks-blueprints/add-ons/>

## Contributing

### Pre-Commit

Installation: [install pre-commit](https://pre-commit.com/) and execute `pre-commit install`. This will generate pre-commit hooks according to the config in `.pre-commit-config.yaml`

Before submitting a PR be sure to have used the pre-commit hooks or run: `pre-commit run -a`

The `pre-commit` command will run:

* Terraform fmt
* Terraform validate
* Terraform docs
* Terraform validate with tflint
* check for merge conflicts
* fix end of files

as described in the `.pre-commit-config.yaml` file

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.2 |
| aws | >= 4.0 |
| kubernetes | >= 2.0 |
| tls | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 4.0 |
| kubernetes | >= 2.0 |
| tls | >= 4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| node\_groups | ./modules/node_groups | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_eks_addon.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_iam_openid_connect_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [kubernetes_config_map_v1_data.aws_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1_data) | resource |
| [aws_eks_addon_version.latest](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_addon_version) | data source |
| [tls_certificate.this](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| addons | Map of objects 'addon\_name => object' of the EKS addons to deploy. By default 'vpc-cni', 'coredns', 'kube-proxy' latest version are installed. | ```map(object({ version = optional(string) resolve_conflicts_on_create = optional(string, "OVERWRITE") configuration_values = optional(any, {}) }))``` | `{}` | no |
| admin\_roles | Map of 'username => ARN' of the IAM roles who will be granted admin permissions. (e.g. admin\_sso) | `map(string)` | `{}` | no |
| admin\_users | Map of 'username => ARN' of the IAM users who will be granted admin permissions. (e.g. cicd) | `map(string)` | `{}` | no |
| cluster\_additional\_iam\_policies | Additional IAM policies to be assigned to the cluster IAM role | `list(string)` | `[]` | no |
| cluster\_log\_types | Types of cluster logging to enable | `set(string)` | ```[ "api", "authenticator", "controllerManager", "scheduler" ]``` | no |
| cluster\_name | Name of the cluster | `string` | n/a | yes |
| cluster\_version | Kubernetes version of the cluster | `string` | n/a | yes |
| node\_bootstrap\_roles | List of 'ARNs' for the IAM roles who will be granted node bootstrap permissions. | `list(string)` | `[]` | no |
| node\_extra\_iam\_policies | List of policy ARNs to assign to the all the nodes IAM role | `list(string)` | `[]` | no |
| node\_groups | Node group map for all the different Managed Node Groups that we need to manage. | ```map(object({ k8s_version = optional(string) min_size = optional(number, 1) desired_size = optional(number, 1) max_size = optional(number, 10) max_unavailable = optional(number, 1) instance_types = optional(list(string), ["t3.large"]) ami_type = optional(string, "AL2_x86_64") capacity_type = optional(string, "ON_DEMAND") disk_size = optional(number, 50) subnet_ids = optional(list(string), []) labels = optional(map(string), {}) tags = optional(map(string), {}) self_managed = optional(bool, false) self_managed_configuration = optional(object({ extra_bootstrap_flags = optional(string, "") # Extra flags to pass to the bootstrap.sh userdata script spot_instances_percentage = optional(number, 0) warm_instances = optional(number, 0) }), {}) }))``` | n/a | yes |
| subnet\_ids | Subnet IDs to associate to the cluster | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| autoscaling\_group\_names | n/a |
| cluster\_arn | n/a |
| cluster\_certificate\_authority\_data | Base64 encoded certificate data required to communicate with the cluster |
| cluster\_endpoint | n/a |
| cluster\_iam\_role\_arn | n/a |
| cluster\_id | n/a |
| cluster\_name | n/a |
| cluster\_oidc\_issuer\_url | The URL on the EKS cluster for the OpenID Connect identity provider |
| cluster\_oidc\_provider | The OpenID Connect identity provider (issuer URL without leading `https://`) |
| cluster\_oidc\_provider\_arn | The ARN of the OIDC Provider if `enable_irsa = true` |
| cluster\_tls\_certificate\_sha1\_fingerprint | The SHA1 fingerprint of the public key of the cluster's certificate |
| cluster\_version | n/a |
| node\_group\_role\_arns | n/a |
| node\_groups | n/a |
<!-- END_TF_DOCS -->
