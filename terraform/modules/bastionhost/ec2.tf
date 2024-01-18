resource "aws_instance" "bastion" {
  ami = "ami-0c7217cdde317cfec"
  instance_type = "t2.micro"
  subnet_id = var.subnet_id

  #vpc_security_group_ids = "${aws_security_group.allow_ssh.id}"
  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id
  ]
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 10
  }

  tags = {
    Name = "${var.common.env}-${var.common.project}-bastion"
  }
  user_data = file("${path.module}/config.sh")
}

data "aws_secretsmanager_secret" "ugc_secret_dev" {
  name = "ugc_secret_dev"
}

data "aws_secretsmanager_secret_version" "ugc_secret_version" {
  secret_id = data.aws_secretsmanager_secret.ugc_secret_dev.id
}

resource "aws_security_group" "allow_ssh" {
    name = "${var.common.env}-${var.common.project}-bastion"
    vpc_id = var.vpc_id

    ingress {
      from_port = "22"
      to_port = "22"
      protocol = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
      from_port = 8
      to_port = 0
      protocol = "icmp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}
