terraform {
  backend "s3" {
    bucket = "server-based-app1-bartr"
    key = "prod/terraform.tfstate"
    region = "eu-west-2"
    use_locking = true
    encrypt = true
  }
}