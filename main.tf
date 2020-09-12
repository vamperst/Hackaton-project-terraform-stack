# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

data "template_file" "script" {
  template = "${file("${path.module}/script.sh.tpl")}"
  vars = {
    ECR_REGISTRY = "${var.ECR_REGISTRY}"
  }
}


variable "project" {
  default = "fiap-lab"
}

data "aws_vpc" "vpc" {
  tags = {
    Name = "${var.project}"
  }
}

data "aws_subnet_ids" "all" {
  vpc_id = "${data.aws_vpc.vpc.id}"

  tags = {
    Tier = "Public"
  }
}

data "aws_subnet" "public" {
  for_each = data.aws_subnet_ids.all.ids
  id = "${each.value}"
}

resource "random_shuffle" "random_subnet" {
  input        = [for s in data.aws_subnet.public : s.id]
  result_count = 1
}



resource "aws_elb" "web" {
  name = "hackton-elb-${var.STAGE}"

  subnets         = data.aws_subnet_ids.all.ids
  security_groups = ["${aws_security_group.allow-ssh.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 6
  }

  # The instances are registered automatically
  instances = aws_instance.web.*.id
}

resource "aws_instance" "web" {
  instance_type = "t2.micro"
  ami           = "${lookup(var.aws_amis, var.aws_region)}"

  count = 1

  subnet_id              = "${random_shuffle.random_subnet.result[0]}"
  vpc_security_group_ids = ["${aws_security_group.allow-ssh.id}"]
  key_name               = "${var.KEY_NAME}"
  iam_instance_profile   = "${aws_iam_instance_profile.ecr_readOnly_profile.name}"

  provisioner "file" {
    content      = "${data.template_file.script.rendered}"
    destination = "$(pwd)/script.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x $(pwd)/script.sh",
      "sudo bash $(pwd)/script.sh"
    ]
  }

  connection {
    user        = "${var.INSTANCE_USERNAME}"
    private_key = "${file("${var.PATH_TO_KEY}")}"
    host = "${self.public_dns}"
  }

  tags = {
    Name = "${format("nginx-hackaton-%03d", count.index + 1)}-${var.STAGE}"
  }
}
