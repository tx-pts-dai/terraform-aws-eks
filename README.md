# EKS cluster module

This module provides an EKS cluster, configurable with managed node groups with/without custom launch template.

## Usage

Create the following new module block with the desired parameters in one of your `.tf` file

```tf
module "eks" {
  source = "github.com/DND-IT/infra-terraform-module.git//eks?ref=eks-v1.0.0"

  cluster_name    = "sample-eks-cluster"
  cluster_version = "1.23"

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

## Core concepts

This module covers the following use cases:

- Create quickly a working EKS cluster
- Cluster with long-term maintainability in mind by reducing dependencies to official providers only
- Cluster with default configuration
  - Addons (vpc-cni, kube-proxy, coredns)
  - Support for managed node groups with custom launch templates
  - OpenIDConnect provider to support [IAM Roles for Service Accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
  - [Default security groups](https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html) and extensible IAM permissions

### Pre-Commit

Installation: [install pre-commit](https://pre-commit.com/) and execute `pre-commit install`. This will generate pre-commit hooks according to the config in `.pre-commit-config.yaml`

Before submitting a PR be sure to have used the pre-commit hooks or run: `pre-commit run -a`

The `pre-commit` command will run:

- Terraform fmt
- Terraform validate
- Terraform docs
- Terraform validate with tflint
- check for merge conflicts
- fix end of files

as described in the `.pre-commit-config.yaml` file

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

| Name                                                                        | Version |
| --------------------------------------------------------------------------- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform)    | >= 1.2  |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                      | >= 4.0  |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement_kubernetes) | >= 2.0  |
| <a name="requirement_tls"></a> [tls](#requirement_tls)                      | >= 4.0  |

## Providers

| Name                                                                  | Version |
| --------------------------------------------------------------------- | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws)                      | >= 4.0  |
| <a name="provider_kubernetes"></a> [kubernetes](#provider_kubernetes) | >= 2.0  |
| <a name="provider_tls"></a> [tls](#provider_tls)                      | >= 4.0  |

## Modules

| Name                                                                 | Source                | Version |
| -------------------------------------------------------------------- | --------------------- | ------- |
| <a name="module_node_groups"></a> [node_groups](#module_node_groups) | ./modules/node_groups | n/a     |

## Resources

| Name                                                                                                                                            | Type        |
| ----------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group)               | resource    |
| [aws_eks_addon.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon)                                      | resource    |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster)                                 | resource    |
| [aws_iam_openid_connect_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource    |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                       | resource    |
| [kubernetes_config_map_v1_data.aws_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1_data) | resource    |
| [aws_eks_addon_version.latest](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_addon_version)                | data source |
| [tls_certificate.this](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate)                              | data source |

## Inputs

| Name                                                                                                                           | Description                                                                                                                                    | Type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | Default                                                                                    | Required |
| ------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ | :------: |
| <a name="input_addons"></a> [addons](#input_addons)                                                                            | Map of objects 'addon_name => object' of the EKS addons to deploy. By default 'vpc-cni', 'coredns', 'kube-proxy' latest version are installed. | <pre>map(object({<br> version = optional(string)<br> resolve_conflicts_on_create = optional(string, "OVERWRITE")<br> configuration_values = optional(any, {})<br> }))</pre>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | `{}`                                                                                       |    no    |
| <a name="input_admin_roles"></a> [admin_roles](#input_admin_roles)                                                             | Map of 'username => ARN' of the IAM roles who will be granted admin permissions. (e.g. admin_sso)                                              | `map(string)`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | `{}`                                                                                       |    no    |
| <a name="input_admin_users"></a> [admin_users](#input_admin_users)                                                             | Map of 'username => ARN' of the IAM users who will be granted admin permissions. (e.g. cicd)                                                   | `map(string)`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | `{}`                                                                                       |    no    |
| <a name="input_cluster_additional_iam_policies"></a> [cluster_additional_iam_policies](#input_cluster_additional_iam_policies) | Additional IAM policies to be assigned to the cluster IAM role                                                                                 | `list(string)`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | `[]`                                                                                       |    no    |
| <a name="input_cluster_log_types"></a> [cluster_log_types](#input_cluster_log_types)                                           | Types of cluster logging to enable                                                                                                             | `set(string)`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | <pre>[<br> "api",<br> "authenticator",<br> "controllerManager",<br> "scheduler"<br>]</pre> |    no    |
| <a name="input_cluster_name"></a> [cluster_name](#input_cluster_name)                                                          | Name of the cluster                                                                                                                            | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | n/a                                                                                        |   yes    |
| <a name="input_cluster_version"></a> [cluster_version](#input_cluster_version)                                                 | Kubernetes version of the cluster                                                                                                              | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | n/a                                                                                        |   yes    |
| <a name="input_node_extra_iam_policies"></a> [node_extra_iam_policies](#input_node_extra_iam_policies)                         | List of policy ARNs to assign to the all the nodes IAM role                                                                                    | `list(string)`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | `[]`                                                                                       |    no    |
| <a name="input_node_groups"></a> [node_groups](#input_node_groups)                                                             | Node group map for all the different Managed Node Groups that we need to manage.                                                               | <pre>map(object({<br> k8s_version = optional(string)<br> min_size = optional(number, 1)<br> desired_size = optional(number, 1)<br> max_size = optional(number, 10)<br> max_unavailable = optional(number, 1)<br> instance_types = optional(list(string), ["t3.large"])<br> ami_type = optional(string, "AL2_x86_64")<br> capacity_type = optional(string, "ON_DEMAND")<br> disk_size = optional(number, 50)<br> subnet_ids = optional(list(string), [])<br> labels = optional(map(string), {})<br> tags = optional(map(string), {})<br><br> self_managed = optional(bool, false)<br> self_managed_configuration = optional(object({<br> extra_bootstrap_flags = optional(string, "") # Extra flags to pass to the bootstrap.sh userdata script<br> spot_instances_percentage = optional(number, 0)<br> warm_instances = optional(number, 0)<br> }), {})<br> }))</pre> | n/a                                                                                        |   yes    |
| <a name="input_subnet_ids"></a> [subnet_ids](#input_subnet_ids)                                                                | Subnet IDs to associate to the cluster                                                                                                         | `list(string)`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | n/a                                                                                        |   yes    |

## Outputs

| Name                                                                                                                                                        | Description                                                                  |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| <a name="output_autoscaling_group_names"></a> [autoscaling_group_names](#output_autoscaling_group_names)                                                    | The autoscaling group names                                                  |
| <a name="output_cluster_arn"></a> [cluster_arn](#output_cluster_arn)                                                                                        | The cluster arn                                                              |
| <a name="output_cluster_certificate_authority_data"></a> [cluster_certificate_authority_data](#output_cluster_certificate_authority_data)                   | Base64 encoded certificate data required to communicate with the cluster     |
| <a name="output_cluster_endpoint"></a> [cluster_endpoint](#output_cluster_endpoint)                                                                         | The cluster endpoint                                                         |
| <a name="output_cluster_iam_role_arn"></a> [cluster_iam_role_arn](#output_cluster_iam_role_arn)                                                             | The cluster iam role arn                                                     |
| <a name="output_cluster_id"></a> [cluster_id](#output_cluster_id)                                                                                           | The cluster id                                                               |
| <a name="output_cluster_name"></a> [cluster_name](#output_cluster_name)                                                                                     | The cluster name                                                             |
| <a name="output_cluster_oidc_issuer_url"></a> [cluster_oidc_issuer_url](#output_cluster_oidc_issuer_url)                                                    | The URL on the EKS cluster for the OpenID Connect identity provider          |
| <a name="output_cluster_oidc_provider"></a> [cluster_oidc_provider](#output_cluster_oidc_provider)                                                          | The OpenID Connect identity provider (issuer URL without leading `https://`) |
| <a name="output_cluster_oidc_provider_arn"></a> [cluster_oidc_provider_arn](#output_cluster_oidc_provider_arn)                                              | The ARN of the OIDC Provider if `enable_irsa = true`                         |
| <a name="output_cluster_tls_certificate_sha1_fingerprint"></a> [cluster_tls_certificate_sha1_fingerprint](#output_cluster_tls_certificate_sha1_fingerprint) | The SHA1 fingerprint of the public key of the cluster's certificate          |
| <a name="output_cluster_version"></a> [cluster_version](#output_cluster_version)                                                                            | The cluster version                                                          |
| <a name="output_node_group_role_arns"></a> [node_group_role_arns](#output_node_group_role_arns)                                                             | The node group role arns                                                     |
| <a name="output_node_groups"></a> [node_groups](#output_node_groups)                                                                                        | The node groups                                                              |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

Module is maintained by [Alfredo Gottardo](https://github.com/AlfGot), [David Beauvererd](https://github.com/Davidoutz), [Davide Cammarata](https://github.com/DCamma), [Demetrio Carrara](https://github.com/sgametrio) and [Roland Bapst](https://github.com/rbapst-tamedia)

## License

Apache 2 Licensed. See [LICENSE](< link to license file >) for full details.
