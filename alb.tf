resource "aws_lb" "load_b" {
  name               = "load"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_sg.id]
  subnets            = [aws_subnet.pub.id,aws_subnet.pri.id]

  enable_deletion_protection = false

  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.id
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  tags = {
    Environment = "production"
  }
}

resource "aws_security_group" "load_sg" {
  name        = "load_sg"
  description = "Allow  inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.main.cidr_block]
  }

  ingress {
    description      = "http from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_lb_target_group" "test" {
  name     = "3-tier-testing"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.ins.id
  port             = 80
}

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "example" {
  autoscaling_group_name = aws_autoscaling_group.asg.name
  lb_target_group_arn    = aws_lb_target_group.test.arn
}

resource "aws_lb_listener" "lb_listen" {
  load_balancer_arn = aws_lb.load_b.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.acm_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test.arn
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "example"
  type    = "A"

  alias {
    name                   = aws_lb.load_b.dns_name
    zone_id                = aws_lb.load_b.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "uuu" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "trial"
  type    = "A"
  ttl     = 300
  records = [aws_instance.ins.public_ip]
}


resource "aws_route53_zone" "primary" {
  name = "satya.aws.crlabs.cloud"
}

resource "aws_route53_record" "test_record" {
  for_each = {
    for dvo in aws_acm_certificate.acm_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.primary.zone_id
}

resource "aws_acm_certificate" "acm_cert" {
  domain_name       = "satya.aws.crlabs.cloud"
  validation_method = "DNS"
}

resource "aws_acm_certificate_validation" "example" {
  certificate_arn         = aws_acm_certificate.acm_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.test_record : record.fqdn]
}

resource "aws_launch_template" "alt" {
  name_prefix   = "alt"
  image_id      = data.aws_ami.example.id
  instance_type = "t2.micro"
}

resource "aws_autoscaling_group" "asg" {
  desired_capacity   = 2
  max_size           = 2
  min_size           = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  vpc_zone_identifier     = [aws_subnet.pub.id, aws_subnet.pri.id]


  launch_template {
    id      = aws_launch_template.alt.id
    version = aws_launch_template.alt.latest_version
  }
}
