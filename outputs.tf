output "composite_alarm_arns" {
  description = "Map of composite CloudWatch alarm ARNs, keyed by service name."
  value       = { for name, alarm in aws_cloudwatch_composite_alarm.this : name => alarm.arn }
}

output "composite_alarm_names" {
  description = "Map of composite CloudWatch alarm names, keyed by service name."
  value       = { for name, alarm in aws_cloudwatch_composite_alarm.this : name => alarm.alarm_name }
}
