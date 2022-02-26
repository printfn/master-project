output "editor_url" {
  description = "url to launch L42 editor"
  value       = "https://printfn.github.io/master-project/editor/?server=${urlencode(aws_apigatewayv2_stage.l42_lambda.invoke_url)}execute"
}