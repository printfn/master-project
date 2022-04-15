// networking

// compute
output "alb_dns" {
  value = aws_lb.alb.dns_name
}

output "user_data_rendered" {
  value = data.template_file.user_data_file.rendered
}
