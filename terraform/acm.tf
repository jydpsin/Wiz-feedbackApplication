# Create ACM certificate for the load balancer
resource "aws_acm_certificate" "cert" {
  domain_name       = "joyzards.com"  # This is just for identification
  validation_method = "EMAIL"

  tags = {
    Environment = "production"
    Name        = "feedback-app-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Output the certificate ARN
output "certificate_arn" {
  value = aws_acm_certificate.cert.arn
} 