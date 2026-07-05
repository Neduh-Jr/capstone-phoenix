terraform {
  backend "s3" {
    bucket         = "taskapp-phoenix-243050854546-terraform-state"
    key            = "terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "taskapp-phoenix-243050854546-terraform-state-lock"
    encrypt        = true
  }
}