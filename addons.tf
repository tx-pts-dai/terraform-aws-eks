locals {
  default_addons = ["vpc-cni", "coredns", "kube-proxy"]
  # map of "add-on name" => "latest_version" that can be overridden from var.addons
  default_addon_versions = {
    for addon in local.default_addons : addon => {
      version = data.aws_eks_addon_version.latest[addon].version
    }
  }
}

# Get latest version for addons that are not specified
data "aws_eks_addon_version" "latest" {
  for_each           = toset(local.default_addons)
  addon_name         = each.key
  kubernetes_version = aws_eks_cluster.this.version
  most_recent        = true
}

resource "aws_eks_addon" "eks" {
  for_each             = merge(local.default_addon_versions, var.addons)
  cluster_name         = aws_eks_cluster.this.name
  addon_name           = each.key
  addon_version        = each.value.version
  resolve_conflicts    = try(each.value.resolve_conflicts_on_create, null)
  configuration_values = try(jsonencode(each.value.configuration_values), null)
  depends_on           = [aws_eks_cluster.this]
}
