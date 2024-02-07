output "node_iam_role_arn" {
  description = "The node iam role arn"
  value       = aws_iam_role.this.arn
}

output "node_self_managed" {
  description = "Is the node self managed"
  value       = var.self_managed
}

output "asg_name" {
  description = "The asg name"
  value       = var.self_managed ? aws_autoscaling_group.this[0].name : aws_eks_node_group.this[0].resources[0].autoscaling_groups[0].name
}
