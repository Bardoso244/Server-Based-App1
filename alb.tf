resource "aws_lb" "alb_main" {
  name = "load-balancer-main"
  load_balancer_type = "application"
  security_groups = [ aws_security_group.alb_sg.id ]
  subnets = [aws_subnet.Public_Subnet_1.id, aws_subnet.Public_Subnet_2.id]
  internal = "false"
}

resource "aws_alb_target_group" "frontend_alb_tg" {
  name = "frontend-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main_vpc.id
  target_type = "instance"

  health_check {
    path = "/"
    protocol = "HTTP"
  }
}

resource "aws_alb_target_group" "backend_tg" {
  name     = "backend-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id
}


resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb_main.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.frontend_alb_tg.arn

  }
}

# resource "aws_autoscaling_attachment" "frontend_asg_att" {
#   autoscaling_group_name = aws_autoscaling_group.asg-frontend.id
#   lb_target_group_arn    = aws_alb_target_group.frontend_alb-tg.arn
# }

# resource "aws_autoscaling_attachment" "backend_asg_att" {
#   autoscaling_group_name = aws_autoscaling_group.asg-backend.id
#   lb_target_group_arn = aws_alb_target_group.backend_tg.arn
# }