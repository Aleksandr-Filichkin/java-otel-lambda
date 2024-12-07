

variable "region" {
  type    = string
  default = "eu-west-1"
}
variable "function-name" {
  description = "the name of Lambda function"
}

variable "dynamodb-table" {
  description = "Dynamodb table"
}