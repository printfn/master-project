output "editor_url" {
  description = "url to launch L42 editor"
  value       = "https://printfn.github.io/master-project/editor/?server=${urlencode(aws_apigatewayv2_stage.l42_lambda.invoke_url)}execute"
}

output "editor_url_2" {
  description = "url to launch L42 editor"
  value = join("", [
    "https://printfn.github.io/master-project/editor/?server=",
    urlencode(trimprefix("https://", aws_lambda_function_url.l42_lambda_url.function_url))
  ])
}