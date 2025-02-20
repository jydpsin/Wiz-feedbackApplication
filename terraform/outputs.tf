output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "load_balancer_hostname" {
  description = "Hostname of the load balancer"
  value       = kubernetes_service.feedback_app.status[0].load_balancer[0].ingress[0].hostname
}

output "kubernetes_service_name" {
  description = "Name of the Kubernetes service"
  value       = kubernetes_service.feedback_app.metadata[0].name
}

output "service_url" {
  description = "URL of the feedback app service"
  value       = "https://${kubernetes_service.feedback_app.status[0].load_balancer[0].ingress[0].hostname}"
} 