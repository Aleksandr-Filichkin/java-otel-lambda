resource "aws_cloudwatch_log_group" "lambda_log_group_snapstart" {
  name              ="/aws/lambda/${var.function-name}-snapstart"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}

locals {
  lambda_payload_filename_snapstart = "./../java-lambda-otel-sdk/target/java-lambda-otel-sdk-0.0.1-SNAPSHOT.jar"
}
resource "aws_lambda_function" "lambda-snapstart" {
  function_name    = "${var.function-name}-snapstart"
  source_code_hash = base64sha256(filebase64(local.lambda_payload_filename_snapstart))
  runtime          = "java21"
  handler          = "com.filichkin.lambda.SampleHandler::handleRequest"
  filename         = local.lambda_payload_filename_snapstart
  role             = aws_iam_role.lambda_role.arn
  memory_size      = 256
  timeout          = 20
  snap_start {
    apply_on = "PublishedVersions"
  }
  publish = true
}
