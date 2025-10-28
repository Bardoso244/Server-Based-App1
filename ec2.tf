# Single launch template for EC2s

resource "aws_launch_template" "ec2_frontend_lt" {
  name_prefix = "my-ec2-template-"
  image_id = "ami-002348f9fa9bd4297"
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.frontend_sg.id]
  }
  
  user_data     = base64encode(file("${path.root}/fe_user_data.sh"))

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
  
}

resource "aws_launch_template" "ec2_backend_lt" {
  name = "EC2_Launch_Template"
  image_id = "ami-002348f9fa9bd4297"
  instance_type = "t2.micro"

  network_interfaces {
    security_groups = [aws_security_group.backend_sg.id]
  }

  user_data     = base64encode(file("${path.root}/be_user_data.sh"))

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
}

# Two Autoscaling groups, one for frontend and one for backend servers

resource "aws_autoscaling_group" "asg-frontend" {
  name_prefix = "asg-frontend-"
  max_size = 3
  min_size = 1
  desired_capacity = 2
  target_group_arns = [aws_alb_target_group.frontend_alb_tg.arn]
  health_check_grace_period = 300
  health_check_type = "ELB"
  force_delete = true
  launch_template {
  id      = aws_launch_template.ec2_frontend_lt.id
  version = "$Latest"
  }
  vpc_zone_identifier = [
    aws_subnet.Public_Subnet_1.id, 
    aws_subnet.Public_Subnet_2.id
  ]
  tag {
    key = "ASG"
    value = "Public ASG"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "asg-backend" {
  name_prefix = "asg-backend-"
  max_size = 3
  min_size = 1
  desired_capacity = 2
  target_group_arns = [aws_alb_target_group.backend_tg.arn]
  health_check_grace_period = 300
  health_check_type = "ELB"
  force_delete = true
  launch_template {
  id      = aws_launch_template.ec2_backend_lt.id
  version = "$Latest"
  }
  vpc_zone_identifier = [
    aws_subnet.Private_Subnet_1.id, 
    aws_subnet.Private_Subnet_2.id
  ]
  tag {
    key = "ASG"
    value = "Private ASG"
    propagate_at_launch = true
  }
}