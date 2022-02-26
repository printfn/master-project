resource "aws_apigatewayv2_api" "l42_lambda" {
  name          = "l42_lambda"
  description   = "API Gateway to communicate with L42 lambda"
  protocol_type = "HTTP"
  tags          = local.tags
}

resource "aws_apigatewayv2_stage" "l42_lambda" {
  api_id = aws_apigatewayv2_api.l42_lambda.id

  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
  tags = local.tags
}

resource "aws_apigatewayv2_integration" "l42_lambda" {
  api_id = aws_apigatewayv2_api.l42_lambda.id

  integration_uri    = aws_lambda_function.l42_lambda.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "execute" {
  api_id = aws_apigatewayv2_api.l42_lambda.id

  route_key = "POST /execute"
  target    = "integrations/${aws_apigatewayv2_integration.l42_lambda.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.l42_lambda.name}"

  retention_in_days = 30
  tags              = local.tags
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.l42_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.l42_lambda.execution_arn}/*/*"
}