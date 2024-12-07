resource "aws_api_gateway_rest_api" "example_api" {
  name = "example"
}
resource "aws_api_gateway_resource" "java-with-layer_resource" {
  rest_api_id = aws_api_gateway_rest_api.example_api.id
  parent_id   = aws_api_gateway_rest_api.example_api.root_resource_id
  path_part   = "otel-layer"
}
resource "aws_api_gateway_resource" "java-snapstart-with-layer_resource" {
  rest_api_id = aws_api_gateway_rest_api.example_api.id
  parent_id   = aws_api_gateway_rest_api.example_api.root_resource_id
  path_part   = "otel-layer-snapstart"
}
resource "aws_lambda_alias" "api_function_alias_live" {
  name             = "snapstart"
  function_name    = aws_lambda_function.lambda-snapstart.function_name
  function_version = aws_lambda_function.lambda-snapstart.version
}

resource "aws_api_gateway_method" "example_method" {
  rest_api_id   = aws_api_gateway_rest_api.example_api.id
  resource_id   = aws_api_gateway_resource.java-with-layer_resource.id
  http_method   = "ANY"
  authorization = "NONE"
}
resource "aws_api_gateway_method" "example_method_snapstart" {
  rest_api_id   = aws_api_gateway_rest_api.example_api.id
  resource_id   = aws_api_gateway_resource.java-snapstart-with-layer_resource.id
  http_method   = "ANY"
  authorization = "NONE"

}


resource "aws_api_gateway_integration" "example_integration" {
  rest_api_id             = aws_api_gateway_rest_api.example_api.id
  resource_id             = aws_api_gateway_resource.java-with-layer_resource.id
  http_method             = aws_api_gateway_method.example_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.example_lambda_with_layer.invoke_arn

}

resource "aws_api_gateway_integration" "example_integration-snapstart" {
  rest_api_id             = aws_api_gateway_rest_api.example_api.id
  resource_id             = aws_api_gateway_resource.java-snapstart-with-layer_resource.id
  http_method             = aws_api_gateway_method.example_method_snapstart.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_alias.api_function_alias_live.invoke_arn
}

# Create a deployment for the API Gateway
resource "aws_api_gateway_deployment" "example_deployment" {
  rest_api_id = aws_api_gateway_rest_api.example_api.id
  triggers    = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.java-with-layer_resource.id,
      aws_api_gateway_method.example_method.id,
      aws_api_gateway_integration.example_integration.id,
      aws_api_gateway_resource.java-snapstart-with-layer_resource.id,
      aws_api_gateway_method.example_method_snapstart.id,
      aws_api_gateway_integration.example_integration-snapstart.id,
    ]))

  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "example" {
  deployment_id = aws_api_gateway_deployment.example_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.example_api.id
  stage_name    = "v1"
}
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example_lambda_with_layer.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.example_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_alias" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda-snapstart.function_name}:${aws_lambda_alias.api_function_alias_live.name}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.example_api.execution_arn}/*/*"
}


output "api_gateway_url" {
  value = "${aws_api_gateway_deployment.example_deployment.invoke_url}"
}