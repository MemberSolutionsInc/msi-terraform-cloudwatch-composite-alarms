locals {
  # Default tags applied to every composite alarm. var.tags is validated to
  # always provide service/env/severity/team/runbook, so these values are
  # passed through as given; the "critical" default only matters if that
  # guarantee is ever relaxed.
  default_tags = {
    severity = "critical"
  }

  merged_tags = merge(local.default_tags, var.tags)

  # ALARM("<name>") OR ALARM("<name>") OR ... for each service's underlying alarms.
  alarm_rules = {
    for name, service in var.services :
    name => join(" OR ", [for alarm_name in service.alarm_names : "ALARM(\"${alarm_name}\")"])
  }
}

resource "aws_cloudwatch_composite_alarm" "this" {
  for_each = var.services

  alarm_name        = each.key
  alarm_description = "Tier-1 composite health alarm for ${each.key}: ALARM if any underlying resource alarm (${join(", ", each.value.alarm_names)}) is in ALARM state."
  alarm_rule        = local.alarm_rules[each.key]

  alarm_actions             = each.value.alarm_actions
  ok_actions                = each.value.ok_actions
  insufficient_data_actions = each.value.insufficient_data_actions

  tags = merge(local.merged_tags, {
    Name = each.key
  })
}
