
provider "aws" {
  region     = var.region
}

terraform {
  backend "s3" {
    bucket         = "terraform-state-alex-chat-bot"
    key            = "test/java-otel-lambda"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-locking"
  }
}