terraform {
  backend "s3" {
    bucket         = "telemedecine-terraform-state-preprod"
    key            = "infrastructure/terraform.tfstate"
    region         = "eu-west-3"
    encrypt        = true
    dynamodb_table = "telemedecine-terraform-locks-preprod"
  }
}
