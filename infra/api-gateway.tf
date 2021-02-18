resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = var.project_name
  description = "created with terraform"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "hello"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.hello.arn}:$${stageVariables.stage}/invocations"
}

resource "aws_api_gateway_deployment" "deployment_dev" {
  depends_on = [
    aws_api_gateway_integration.lambda
  ]

  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
}
  

resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.deployment_dev.id
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  stage_name    = "dev"

  variables = {
    "stage" = "dev"
  }
}

resource "aws_api_gateway_deployment" "deployment_prod" {
  depends_on = [
    aws_api_gateway_integration.lambda
  ]

  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.deployment_prod.id
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  stage_name    = "prod"

  variables = {
    "stage" = "prod"
  }
}

output "api_gateway_id" {
  value = aws_api_gateway_rest_api.api_gateway.id
}

output "hello_dev" {
  value = "${aws_api_gateway_stage.dev.invoke_url}/hello"
}

output "hello_prod" {
  value = "${aws_api_gateway_stage.prod.invoke_url}/hello"
}
