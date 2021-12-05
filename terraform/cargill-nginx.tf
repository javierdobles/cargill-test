data "aws_ami" "atlantic_nginx_ami" {
  filter {
    name   = "image-id"
    values =  ["${lookup(var.ami_ids, "nginx")}"]
  }

  owners      = ["self"]

  provider = aws.atlantic
}


resource "aws_lb" "atlantic_nginx_lb" {
  name               = "cargill-naginx-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.atlantic_nginx_lb_sg.id]

  subnets = [
    "${aws_subnet.atlantic_az_a.id}",
    "${aws_subnet.atlantic_az_b.id}",
  ]

  tags = {
    Region         = "${var.atlantic}"
  }

  provider = aws.atlantic
}

resource "aws_security_group" "atlantic_nginx_lb_sg" {
  name   = "cargill-nginx-lb"
  vpc_id = "${aws_vpc.atlantic_vpc.id}"

  tags = {
    Region         = "${var.atlantic}"
  }

  provider = aws.atlantic
}

resource "aws_security_group_rule" "atlantic_nginx_lb_allow_http_rule" {
  security_group_id = "${aws_security_group.atlantic_nginx_lb_sg.id}"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]

  type             = "ingress"

  provider = aws.atlantic
}

resource "aws_security_group_rule" "atlantic_nginx_lb_allow_egress_rule" {
  security_group_id = "${aws_security_group.atlantic_nginx_lb_sg.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  type              = "egress"

  provider = aws.atlantic
}

resource "aws_lb_target_group" "atlantic_nginx_tg" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.atlantic_vpc.id}"

  provider = aws.atlantic
}

resource "aws_lb_listener" "atlantic_nginx_listener" {
  load_balancer_arn = "${aws_lb.atlantic_nginx_lb.arn}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.atlantic_nginx_tg.arn}"
  }

  provider = aws.atlantic
}


resource "aws_launch_configuration" "atlantic_nginx_lc" {
  root_block_device {
    volume_size           = "${lookup(var.nginx_instance["production"], "instance_root_size")}"
    volume_type           = "gp2"
    delete_on_termination = true
  }

  image_id             = "${data.aws_ami.atlantic_nginx_ami.image_id}"
  instance_type        = "${lookup(var.nginx_instance["production"], "instance_type")}"
  key_name             = "${aws_key_pair.atlantic_key.key_name}"
  security_groups      = ["${aws_security_group.atlantic_nginx_sg.id}"]

  lifecycle {
    create_before_destroy = true
  }

  provider = aws.atlantic
}


resource "aws_autoscaling_group" "atlantic_nginx_asg" {
  desired_capacity          = 2
  max_size                  = 2
  min_size                  = 1
  min_elb_capacity          = 1
  name                      = "nginx-production-asg"
  launch_configuration      = "${aws_launch_configuration.atlantic_nginx_lc.name}"
  target_group_arns         = ["${aws_lb_target_group.atlantic_nginx_tg.arn}"]
  wait_for_capacity_timeout = "30m"

  vpc_zone_identifier = [
    "${aws_subnet.atlantic_az_a.id}",
    "${aws_subnet.atlantic_az_b.id}",
  ]

  tags = [
    {
      key                 = "Name"
      value               = "nginx-production"
      propagate_at_launch = "true"
    },
    {
      key                 = "Region"
      value               = "${var.atlantic}"
      propagate_at_launch = "true"
    },
  ]

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    null_resource.atlantic_subnets,
  ]

  provider = aws.atlantic
}


 resource "aws_security_group" "atlantic_nginx_sg" {
  name   = "nginx-production-sg"
  vpc_id = "${aws_vpc.atlantic_vpc.id}"

  tags = {
    Region         = "${var.atlantic}"
  }

  provider = aws.atlantic
}

resource "aws_security_group_rule" "atlantic_nginx_allow_icmp" {
  security_group_id = "${aws_security_group.atlantic_nginx_sg.id}"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "ingress"

  provider = aws.atlantic
}

resource "aws_security_group_rule" "atlantic_nginx_allow_icmpv6" {
  security_group_id = "${aws_security_group.atlantic_nginx_sg.id}"
  from_port         = -1
  to_port           = -1
  protocol          = "icmpv6"
  ipv6_cidr_blocks  = ["::/0"]
  type              = "ingress"

  provider = aws.atlantic
}

resource "aws_security_group_rule" "atlantic_nginx_allow_ssh" {
  security_group_id = "${aws_security_group.atlantic_nginx_sg.id}"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  type              = "ingress"

  provider = aws.atlantic
}

resource "aws_security_group_rule" "atlantic_nginx_allow_http" {
  security_group_id = "${aws_security_group.atlantic_nginx_sg.id}"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id  = "${aws_security_group.atlantic_nginx_lb_sg.id}"
  type             = "ingress"

  provider = aws.atlantic
}

resource "aws_security_group_rule" "atlantic_nginx_allow_egress" {
  security_group_id = "${aws_security_group.atlantic_nginx_sg.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  type              = "egress"

  provider = aws.atlantic
}