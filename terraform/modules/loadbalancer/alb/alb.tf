resource "aws_lb" "lb" {
    name = "${var.common.env}-${var.common.project}-lb" // name of lb resource
    internal = false // loadbalancer inside vpc
    load_balancer_type = "application"
    subnets = var.network.subnet_ids
    security_groups = [aws_security_group.sg_lb.id]
}

resource "aws_security_group" "sg_lb" {
    name = "${var.common.env}-${var.common.project}-sg-lb"
    vpc_id = var.network.vpc_id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"] // allow every one access to 
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"] // allow every one access to 
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1" // for almost protocol (UDP, TCP, ICMP,....) 
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_lb_listener" "lb_listener_http" {
    load_balancer_arn = aws_lb.lb.arn
    port = "80"
    protocol = "HTTP"
    default_action {
        type = "redirect"
        redirect {
            protocol = "HTTPS"
            port = "443"
            status_code = "HTTP_301"   
        }
    }
}

resource "aws_lb_listener" "lb_listener_https" {
    load_balancer_arn = aws_lb.lb.arn
    port = "443"
    protocol = "HTTPS"
    certificate_arn = var.dns_cert_arn
    default_action {
        type = "fixed-response"
        fixed_response {
            status_code = "404"
            content_type = "text/plain"
        }
    }
}


output "lb_dns_name" {
  value = aws_lb.lb.dns_name
}

output "lb_zone_id" {
  value = aws_lb.lb.zone_id
}

output "sg_lb" {
  value = aws_security_group.sg_lb.id
}

output "aws_lb_listener_arn" {
  value = aws_lb_listener.lb_listener_https.arn
}