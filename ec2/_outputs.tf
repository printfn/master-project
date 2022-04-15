// networking
output "vpc_id" {
  value = aws_vpc.l42_vpc.id
}
output "igw_id" {
  value = aws_internet_gateway.l42_igw.id
}
output "subpub_ids" {
  value = aws_subnet.l42_subpub.*.id
}
output "subprv_ids" {
  value = aws_subnet.l42_subprv.*.id
}
output "sg_id" {
  value = aws_security_group.l42_sg.id
}
output "rtpub_ids" {
  value = aws_route_table.l42_rtpub.*.id
}
output "rtprv_ids" {
  value = aws_default_route_table.l42_rtprv.*.id
}

// compute
output "alb_dns" {
  value = aws_lb.alb.dns_name
}

output "alb_name" {
  value = aws_lb.alb.name
}

output "alb_zone_id" {
  value = aws_lb.alb.zone_id
}

output "asg_name" {
  value = aws_autoscaling_group.asg.name
}
