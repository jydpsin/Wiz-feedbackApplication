# Add a null_resource to update kubeconfig
resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}"
  }

  depends_on = [aws_eks_cluster.main]
}

resource "time_sleep" "wait_for_kubernetes" {
  depends_on = [
    aws_eks_cluster.main,
    null_resource.update_kubeconfig
  ]

  create_duration = "30s"
}

resource "kubernetes_deployment" "feedback_app" {
  metadata {
    name = "feedback-app"
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "feedback-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "feedback-app"
        }
      }

      spec {
        node_selector = {
          "kubernetes.io/os"     = "linux"
          "kubernetes.io/arch"   = "amd64"
        }
        
        container {
          image = "docker.io/joysdockers/feedback-app:latest"
          name  = "feedback-app"
          image_pull_policy = "Always"

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }

          port {
            container_port = 3006
          }

          env {
            name  = "PORT"
            value = "3006"
          }

          env {
            name  = "NODE_ENV"
            value = "production"
          }

          # Add more environment variables for debugging
          env {
            name  = "DEBUG"
            value = "mongoose:*"
          }

          # Modify probes to be more lenient
          startup_probe {
            http_get {
              path = "/"
              port = 3006
            }
            initial_delay_seconds = 10
            period_seconds       = 5
            failure_threshold    = 30
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 3006
            }
            initial_delay_seconds = 60
            period_seconds       = 10
            timeout_seconds      = 5
            failure_threshold    = 3
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 3006
            }
            initial_delay_seconds = 30
            period_seconds       = 10
            timeout_seconds      = 5
            failure_threshold    = 3
          }

          env {
            name  = "MONGODB_DEBUG"
            value = "true"
          }

          # Add MongoDB connection timeout
          env {
            name  = "MONGODB_CONNECT_TIMEOUT_MS"
            value = "30000"
          }

          # Add AWS configuration
          env {
            name  = "AWS_REGION"
            value = var.aws_region
          }
        }

        # Important: Add service account
        service_account_name = kubernetes_service_account.app_service_account.metadata[0].name
      }
    }
  }

  depends_on = [
    time_sleep.wait_for_kubernetes,
    kubernetes_service_account.app_service_account,
    aws_iam_role_policy.app_policy
  ]
}

resource "kubernetes_service" "feedback_app" {
  metadata {
    name = "feedback-app-service"
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
    }
  }

  spec {
    selector = {
      app = "feedback-app"
    }

    port {
      port        = 80
      target_port = 3006
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }

  depends_on = [kubernetes_deployment.feedback_app]
}

# Create a service account for the application
resource "kubernetes_service_account" "app_service_account" {
  metadata {
    name = "feedback-app-sa"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.app_role.arn
    }
  }
}

# Create IAM role for the service account
resource "aws_iam_role" "app_role" {
  name = "feedback-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:default:feedback-app-sa"
          }
        }
      }
    ]
  })
}

# Add policy for Secrets Manager access
resource "aws_iam_role_policy" "app_policy" {
  name = "feedback-app-policy"
  role = aws_iam_role.app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = ["arn:aws:secretsmanager:${var.aws_region}:*:secret:my-app-secret*"]
      }
    ]
  })
}

# Create OIDC provider for service account
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# Get EKS OIDC certificate
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# Add cluster-admin binding for the application service account
resource "kubernetes_cluster_role_binding" "app_cluster_admin" {
  metadata {
    name = "feedback-app-cluster-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"  # Using the built-in cluster-admin role
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.app_service_account.metadata[0].name
    namespace = "default"  # Adjust if your service account is in a different namespace
  }

  depends_on = [kubernetes_service_account.app_service_account]
}