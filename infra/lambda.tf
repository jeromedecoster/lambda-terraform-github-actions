data "archive_file" "zip" {
  type        = "zip"
  source_file = "../lambda/hello.js"
  output_path = "../lambda/hello.zip"
}

resource "aws_lambda_function" "hello" {
  filename         = data.archive_file.zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.zip.output_path)

  function_name = var.project_name
  role          = aws_iam_role.lambda_role.arn
  handler       = "hello.handler"
  runtime       = "nodejs12.x"
  timeout       = 10
  # publish       = true
}

resource "aws_lambda_alias" "alias_dev" {
  name             = "dev"
  description      = "dev"
  function_name    = aws_lambda_function.hello.arn
  function_version = "$LATEST"
}

resource "aws_lambda_alias" "alias_prod" {
  name             = "prod"
  description      = "prod"
  function_name    = aws_lambda_function.hello.arn
  function_version = "$LATEST"
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/*"
}

resource "aws_lambda_permission" "permission_dev" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.hello.function_name}:dev"
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/GET/hello"
}

resource "aws_lambda_permission" "permission_prod" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.hello.function_name}:prod"
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/GET/hello"
}


resource "aws_cloudwatch_log_group" "convert_log_group" {
  name = "/aws/lambda/${aws_lambda_function.hello.function_name}"
}