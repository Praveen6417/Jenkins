module "backend" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  
  name = "${var.project_name}-${var.environment}-backend"

  instance_type          = "t3.micro"
  vpc_security_group_ids = [ data.aws_ssm_parameter.backend_sg_id.value ]
  ami = data.aws_ami.ami_id.id
  subnet_id              = local.private_subnet_ids

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-backend"
    }
  )
}

resource "null_resource" "backend" {

  triggers = {
    instance_id = module.backend.id
  }
  
  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
    host     = module.backend.private_ip
  }

  provisioner "file" {
    source      = "Backend.sh"
    destination = "/tmp/backend.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/backend.sh",
      "sudo sh /tmp/backend.sh backend ${var.environment}"
    ]
  } 
}


resource "aws_ec2_instance_state" "backend" {
  instance_id = module.backend.id
  state       = "stopped"

  depends_on = [ null_resource.backend ]
}

resource "aws_ami_from_instance" "backend" {
  name = "backend-ami"
  source_instance_id = module.backend.id

  depends_on = [ aws_ec2_instance_state.backend ]
}

resource "null_resource" "backend_instance" {
  triggers = {
    instance_id = module.backend.id
  }

  connection {
    type = "ssh"
    user = "ec2-user"
    password = "DevOps321"
    host = module.backend.private_ip
  }

  provisioner "local-exec" {
    command = "aws ec2 terminate-instances --instance-ids ${module.backend.id}"
  }

  depends_on = [ aws_ami_from_instance.backend ]

}

resource "aws_launch_template" "backend" {
  name = "${var.project_name}-${var.environment}-backend"
  image_id = aws_ami_from_instance.backend.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type = "t2.micro"
  
  update_default_version = true

  vpc_security_group_ids = [ data.aws_ssm_parameter.backend_sg_id.value ]

   tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.common_tags,
      {
        Name = "${var.project_name}-${var.environment}-backend"
      }
    )
  }
}

resource "aws_lb_target_group" "backend" {
  name        = "backend-alb-target-group"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  health_check {
    protocol = "HTTP"
    path = "/health"
    port = 8080
  }
}

resource "aws_autoscaling_group" "backend" {
  name                      = "backend-auto-scaling-group"

  launch_template {
    id = aws_launch_template.backend.id
    version = "$Latest"
  }

  target_group_arns = [ aws_lb_target_group.backend.arn ]

  max_size                  = 5
  min_size                  = 1
  health_check_grace_period = 60
  health_check_type         = "ELB"
  desired_capacity          = 1

  vpc_zone_identifier       = split(",", data.aws_ssm_parameter.private_subnet_ids.value)

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = "50" #The "min_healthy_percentage" parameter defines the minimum percentage of instances that must remain in a healthy state throughout the refresh process.
    }

    triggers = [ "launch_template" ]
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-backend"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }

  tag {
    key                 = "Project"
    value               = "${var.project_name}"
    propagate_at_launch = false
  }
}

resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "cpu-target-tracking"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.backend.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}

resource "aws_lb_listener_rule" "backend" {
  listener_arn = data.aws_ssm_parameter.app-alb-aws_lb_listener.value
  priority     = 100 # less number will be first validated

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/backend/*"]
    }
  }
}

