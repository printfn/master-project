resource "aws_cloudwatch_event_rule" "every_ten_minutes" {
  name = "every-ten-minutes"
  description = "Fires every ten minutes"
  schedule_expression = "rate(10 minutes)"
  tags = local.tags
}

resource "aws_cloudwatch_event_target" "keep_lambda_warm" {
  rule = "${aws_cloudwatch_event_rule.every_ten_minutes.name}"
  arn = "${aws_lambda_function.l42_lambda.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_foo" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.l42_lambda.function_name}"
  principal = "events.amazonaws.com"
  source_arn = "${aws_cloudwatch_event_rule.every_ten_minutes.arn}"
}
