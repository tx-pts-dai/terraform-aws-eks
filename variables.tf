variable "addons" {
  description = "Map of objects 'addon_name => object' of the EKS addons to deploy. By default 'vpc-cni', 'coredns', 'kube-proxy' latest version are installed."
  type = map(object({
    version                     = optional(string)
    resolve_conflicts_on_create = optional(string, "OVERWRITE")
    configuration_values        = optional(any, {})
  }))
  default = {}
}

variable "admin_users" {
  description = "Map of 'username => ARN' of the IAM users who will be granted admin permissions. (e.g. cicd)"
  type        = map(string)
  default     = {}
}

variable "admin_roles" {
  description = "Map of 'username => ARN' of the IAM roles who will be granted admin permissions. (e.g. admin_sso)"
  type        = map(string)
  default     = {}
}

variable "cluster_additional_iam_policies" {
  description = "Additional IAM policies to be assigned to the cluster IAM role"
  type        = list(string)
  default     = []
}

variable "cluster_log_types" {
  description = "Types of cluster logging to enable"
  type        = set(string)
  default = [
    "api",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]
}

variable "cluster_name" {
  description = "Name of the cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version of the cluster"
  type        = string
}

variable "node_groups" {
  description = "Node group map for all the different Managed Node Groups that we need to manage."
  type = map(object({
    k8s_version     = optional(string)
    min_size        = optional(number, 1)
    desired_size    = optional(number, 1)
    max_size        = optional(number, 10)
    max_unavailable = optional(number, 1)
    instance_types  = optional(list(string), ["t3.large"])
    ami_type        = optional(string, "AL2_x86_64")
    capacity_type   = optional(string, "ON_DEMAND")
    disk_size       = optional(number, 50)
    subnet_ids      = optional(list(string), [])
    labels          = optional(map(string), {})
    tags            = optional(map(string), {})

    self_managed = optional(bool, false)
    self_managed_configuration = optional(object({
      extra_bootstrap_flags     = optional(string, "") # Extra flags to pass to the bootstrap.sh userdata script
      spot_instances_percentage = optional(number, 0)
      warm_instances            = optional(number, 0)
    }), {})
  }))
}

variable "node_extra_iam_policies" {
  description = "List of policy ARNs to assign to the all the nodes IAM role"
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "Subnet IDs to associate to the cluster"
  type        = list(string)
}

# variable "tags" {
#   type = map(string)
# }
