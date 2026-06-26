output "cluster_name"      { value = aws_eks_cluster.eks.name }
output "cluster_endpoint"  { value = aws_eks_cluster.eks.endpoint }
output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.eks.name}"
}
output "cluster_security_group_id" {
  value = aws_security_group.eks_sg.id
}
