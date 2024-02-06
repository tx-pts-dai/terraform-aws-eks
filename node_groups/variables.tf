variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "ami_type" {
  type        = string
  description = "The ami type"
  default     = "AL2_x86_64" # or AL2_ARM_64
}

variable "disk_size" {
  description = "Disk size in GiB for nodes."
  type        = number
  default     = 50
}

variable "capacity_type" {
  description = "Type of capacity associated with the EKS Node Group. Valid values: `ON_DEMAND`, `SPOT`"
  type        = string
  default     = "ON_DEMAND"
}

variable "instance_types" {
  description = "Set of instance types associated with the EKS Node Group."
  type        = list(string)
}

variable "name_prefix" {
  description = "Name prefix of the EKS managed node group. Suffix is auto-generated."
  type        = string
}

# variable "node_role_arn" {
#   type    = string
#   default = null
# }

variable "subnet_ids" {
  description = "A list of subnet IDs where the nodes/node groups will be provisioned."
  type        = list(string)
}

variable "desired_size" {
  description = "Desired number of instances/nodes"
  type        = number
}

variable "min_size" {
  description = "Minimum number of instances/nodes"
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances/nodes"
  type        = number
}

variable "max_unavailable" {
  description = "Max unavailable nodes"
  type        = number
  default     = 1
}

variable "k8s_version" {
  description = "Kubernetes version of the managed node groups. Can't be null if self_managed is true."
  type        = string
  default     = null
}

variable "labels" {
  description = "The map of labels"
  type        = map(string)
  default     = {}
}

variable "node_extra_iam_policies" {
  description = "List of policy ARNs to assign to the Node IAM role"
  type        = list(string)
  default     = []
}

variable "self_managed" {
  description = "If true, the module uses a self-managed node group."
  type        = bool
  default     = false
}

variable "self_managed_configuration" {
  description = "Only used if var.self_managed is true. Pass parameters specific to self-managed node groups"
  type = object({
    extra_bootstrap_flags     = optional(string, "") # Extra flags to pass to the bootstrap.sh userdata script
    spot_instances_percentage = optional(number, 0)
    warm_instances            = optional(number, 0)
    # needed for custom user-data script
    cluster_certificate_authority_data = string
    cluster_security_group_id          = string
    cluster_endpoint                   = string
  })
  default = null
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
