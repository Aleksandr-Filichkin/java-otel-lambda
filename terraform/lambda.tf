resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              ="/aws/lambda/${var.function-name}"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}

locals {
  lambda_payload_filename = "./../java-lambda/target/java-lambda-0.0.1-SNAPSHOT.jar"
}
resource "aws_lambda_function" "example_lambda_with_layer" {
  function_name    = var.function-name
  source_code_hash = base64sha256(filebase64(local.lambda_payload_filename))
  runtime          = "java21"
  handler          = "com.filichkin.lambda.SampleHandler::handleRequest"
  filename         = local.lambda_payload_filename
  role             = aws_iam_role.lambda_role.arn
  memory_size      = 256
  timeout          = 20
  environment {
    variables = {
      AWS_LAMBDA_EXEC_WRAPPER = "/opt/otel-handler"
      OTEL_EXPORTER_OTLP_ENDPOINT= "http://18.200.252.40:4317"
    }

  }
  layers = [
  "arn:aws:lambda:eu-west-1:901920570463:layer:aws-otel-java-wrapper-amd64-ver-1-32-0:3"
  ]
}
