resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name_lb
  subject_alternative_names = ["*.devops.donnytran.com"]
  validation_method = "DNS"

  tags = {
    Environment = var.common.env
  }

  lifecycle {
    create_before_destroy = true
  }
}