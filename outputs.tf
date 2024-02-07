output "cluster_iam_role_arn" {
  description = "The cluster iam role arn"
  value       = aws_eks_cluster.this.role_arn
}

output "cluster_id" {
  description = "The cluster id"
  value       = aws_eks_cluster.this.id
}

output "cluster_name" {
  description = "The cluster name"
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "The cluster arn"
  value       = aws_eks_cluster.this.arn
}

output "cluster_version" {
  description = "The cluster version"
  value       = aws_eks_cluster.this.version
}

output "cluster_endpoint" {
  description = "The cluster endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "cluster_oidc_provider" {
  description = "The OpenID Connect identity provider (issuer URL without leading `https://`)"
  value       = replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}

output "cluster_oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if `enable_irsa = true`"
  value       = aws_iam_openid_connect_provider.this.arn
}

output "cluster_tls_certificate_sha1_fingerprint" {
  description = "The SHA1 fingerprint of the public key of the cluster's certificate"
  value       = data.tls_certificate.this.certificates[0].sha1_fingerprint
}

output "node_group_role_arns" {
  description = "The node group role arns"
  value       = [for node in module.node_groups : node.node_iam_role_arn]
}

output "autoscaling_group_names" {
  description = "The autoscaling group names"
  value       = [for node in module.node_groups : node.asg_name]
}

output "node_groups" {
  description = "The node groups"
  value       = module.node_groups
}
