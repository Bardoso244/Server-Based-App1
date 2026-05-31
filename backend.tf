terraform {
  backend "s3" {
    bucket = "server-based-app1-bartr"
    key = "terraform.tfstate"
    region = "eu-west-2"
    use_lockfile = true
    encrypt = true
  }
}