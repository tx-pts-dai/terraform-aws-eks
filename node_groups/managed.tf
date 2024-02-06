resource "aws_eks_node_group" "this" {
  count = !var.self_managed ? 1 : 0
  # With launch template the type is included in the aws_ami
  ami_type               = var.ami_type
  capacity_type          = var.capacity_type # SPOT or ON_DEMAND
  cluster_name           = var.cluster_name
  disk_size              = var.disk_size
  instance_types         = var.instance_types
  labels                 = var.labels
  node_group_name_prefix = var.name_prefix
  node_role_arn          = aws_iam_role.this.arn

  subnet_ids = var.subnet_ids
  tags = merge(var.tags, {
    Name = var.name_prefix
  })
  # With launch template the version is included in the AMI
  version = var.k8s_version

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  timeouts {}

  update_config {
    max_unavailable = var.max_unavailable
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }
}

locals {
  asg_name = [for asg in flatten(
    [for resources in aws_eks_node_group.this[0].resources : resources.autoscaling_groups]
  ) : asg.name][0] # There is one ASG only per managed node group
}

# Cluster autoscaler needs some tags to scale from 0 to 1 - https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#auto-discovery-setup
resource "aws_autoscaling_group_tag" "this" {
  for_each = var.self_managed ? {} : var.labels

  autoscaling_group_name = local.asg_name

  tag {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/${each.key}"
    value               = each.value
    propagate_at_launch = true
  }
}
