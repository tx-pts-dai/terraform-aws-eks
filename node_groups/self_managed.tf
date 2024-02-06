# Use cases where using self-managed node groups is **necessary**:
# - detailed EC2 monitoring
# - "gp3" storage
# - custom userdata / kubelet script flags
# - warm pools
# - spot instances
# Important: make sure that EC2 events are managed correctly inside the cluster. e.g. node-termination-handler
resource "aws_autoscaling_group" "this" {
  count = var.self_managed ? 1 : 0

  name_prefix = var.name_prefix

  capacity_rebalance  = true # https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-capacity-rebalancing.html
  desired_capacity    = var.desired_size
  max_size            = var.max_size
  min_size            = var.min_size
  vpc_zone_identifier = var.subnet_ids

  enabled_metrics = local.enabled_metrics

  instance_refresh {
    strategy = "Rolling"
  }

  ### ON-DEMAND block
  dynamic "launch_template" {
    # Use only with on-demand instances
    for_each = var.self_managed_configuration.spot_instances_percentage == 0 ? [1] : []
    content {
      id      = aws_launch_template.this[count.index].id
      version = aws_launch_template.this[count.index].latest_version
    }
  }

  # Not supported by cluster autoscaler yet... :(
  # https://github.com/kubernetes/autoscaler/issues/4005
  dynamic "warm_pool" {
    for_each = var.self_managed_configuration.warm_instances > 0 ? [1] : []
    content {
      pool_state                  = "Stopped" # TODO: To be tested. "Stopped" can be used too.
      min_size                    = var.self_managed_configuration.warm_instances
      max_group_prepared_capacity = var.self_managed_configuration.warm_instances

      instance_reuse_policy {
        reuse_on_scale_in = true
      }
    }
  }
  ###

  ### SPOT block
  # Spot instances setup -> No warm pools allowed and launch template must be defined in here.
  dynamic "mixed_instances_policy" {
    for_each = var.self_managed_configuration.spot_instances_percentage > 0 ? [1] : []
    content {
      instances_distribution {
        # on_demand_base_capacity                  = 0
        on_demand_percentage_above_base_capacity = 100 - var.self_managed_configuration.spot_instances_percentage
        spot_allocation_strategy                 = "lowest-price"
        spot_instance_pools                      = 2
      }

      launch_template {
        launch_template_specification {
          launch_template_id = aws_launch_template.this[count.index].id
        }

        dynamic "override" {
          for_each = toset(var.instance_types)
          content {
            instance_type = override.value
          }
        }
      }
    }
  }
  ###

  # tags for cluster-autoscaler / karpenter. TODO: Add tags from var.tags
  tag {
    key                 = "Name"
    value               = var.name_prefix
    propagate_at_launch = true
  }
  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }
  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = false
  }
  # Needed for self-managed nodes to join the cluster
  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }
}

data "aws_ami" "eks_default" {
  count       = var.self_managed ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.k8s_version}-v*"]
  }
}

resource "aws_launch_template" "this" {
  count                  = var.self_managed ? 1 : 0
  name_prefix            = var.name_prefix
  image_id               = data.aws_ami.eks_default[count.index].image_id
  instance_type          = var.instance_types[0]
  update_default_version = true

  # Add cluster security group to allow communication between nodes and control plane
  vpc_security_group_ids = [var.self_managed_configuration.cluster_security_group_id]

  ebs_optimized = true
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      volume_size           = var.disk_size
      volume_type           = "gp3"
      encrypted             = true # needed for Warm Pools
    }
  }

  monitoring {
    enabled = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data.tpl", {
    CLUSTER_NAME     = var.cluster_name,
    B64_CLUSTER_CA   = var.self_managed_configuration.cluster_certificate_authority_data,
    API_SERVER_URL   = var.self_managed_configuration.cluster_endpoint
    ADDITIONAL_FLAGS = var.self_managed_configuration.extra_bootstrap_flags
  }))

  iam_instance_profile {
    arn = aws_iam_instance_profile.this[count.index].arn
  }

  dynamic "tag_specifications" {
    for_each = toset(["instance", "network-interface", "volume"])
    content {
      resource_type = tag_specifications.value
      tags = {
        Name = "${tag_specifications.value}-eks-${var.cluster_name}-${local.name_prefix_trimmed}"
      }
    }
  }
}

# EC2 instances are impersonating IAM Instance Profiles so that they can assume the role they are meant to.
# https://medium.com/devops-dudes/the-difference-between-an-aws-role-and-an-instance-profile-ae81abd700d
resource "aws_iam_instance_profile" "this" {
  count       = var.self_managed ? 1 : 0
  name_prefix = var.name_prefix
  role        = aws_iam_role.this.name
}
