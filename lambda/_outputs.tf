output "editor_url" {
  description = "url to launch L42 editor"
  value = join("", [
    "https://printfn.github.io/master-project/editor/?server=",
    urlencode(
      trimprefix(
        trimsuffix(aws_lambda_function_url.l42_lambda_url.function_url, "/"),
        "https://"
      )
    )
  ])
}