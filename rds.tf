resource "aws_db_instance" "rds_db" {
  identifier = "server-based-app-rds"
  allocated_storage = 20
  engine = "mysql"  
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  username = "admin"
  password = random_password.rds_password.result
  db_subnet_group_name = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [ aws_security_group.rds_sg.id ]
  skip_final_snapshot = true
  multi_az = true
  publicly_accessible = false
  backup_retention_period = 7
  deletion_protection = false

  tags = {
    Name = "test-rds"
  }

}

resource "random_password" "rds_password" {
  length  = 20
  special = true
  override_special  = "!#$%^&*()-_=+[]{}:?"
}

resource "aws_secretsmanager_secret" "rds_creds" {
  name = "server-based-app/rds/admin"
}

resource "aws_secretsmanager_secret_version" "rds_creds_version" {
  secret_id     = aws_secretsmanager_secret.rds_creds.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.rds_password.result
  })
}
