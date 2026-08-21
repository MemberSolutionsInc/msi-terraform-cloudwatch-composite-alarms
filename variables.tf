variable "services" {
  description = <<-EOT
    Map of business-critical services (keyed by service name) to build a single
    composite CloudWatch alarm for. Each entry lists the underlying alarm names
    (from the sibling msi-terraform-cloudwatch-alarms module) to OR together,
    plus optional action ARNs (e.g. SNS topics from msi-terraform-sns-teams-notifier)
    fired on ALARM / OK / INSUFFICIENT_DATA transitions of the composite alarm.
  EOT
  type = map(object({
    alarm_names               = list(string)
    alarm_actions             = optional(list(string), [])
    ok_actions                = optional(list(string), [])
    insufficient_data_actions = optional(list(string), [])
  }))

  validation {
    condition     = alltrue([for k, v in var.services : length(v.alarm_names) > 0])
    error_message = "Each service in var.services must list at least one underlying alarm_name to combine into its composite alarm."
  }
}

variable "tags" {
  description = <<-EOT
    Mandatory tagging convention shared across this observability module family.
    Must include exactly the keys: service, env, severity, team, runbook.
    These are merged into every composite alarm's tags. severity defaults to
    "critical" (Tier-1 composites represent business-critical services) but is
    passed through as given when present.
  EOT
  type        = map(string)

  validation {
    condition = alltrue([
      for key in ["service", "env", "severity", "team", "runbook"] : contains(keys(var.tags), key)
    ])
    error_message = "var.tags must include all of: service, env, severity, team, runbook."
  }
}
