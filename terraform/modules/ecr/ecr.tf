resource "aws_ecr_repository" "ecr" {
    name = "${var.common.env}-${var.common.project}-${var.container_name}"
    image_tag_mutability = var.image_tag_mutability
    image_scanning_configuration {
        scan_on_push = "false"
    }
}