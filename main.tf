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

  # alarm_description enumerates every underlying alarm name for
  # readability, but aws_cloudwatch_composite_alarm caps this field at 1024
  # characters - a service combining a couple dozen alarm_names (e.g. an
  # ALB with many target groups) can blow past that. Fall back to a count-
  # only description rather than truncating the name list mid-string (which
  # would silently drop the closing "is in ALARM state." and read as
  # broken); the full list is always visible in alarm_rule regardless.
  alarm_descriptions_full = {
    for name, service in var.services :
    name => "Tier-1 composite health alarm for ${name}: ALARM if any underlying resource alarm (${join(", ", service.alarm_names)}) is in ALARM state."
  }

  alarm_descriptions = {
    for name, service in var.services :
    name => length(local.alarm_descriptions_full[name]) <= 1024 ? local.alarm_descriptions_full[name] : "Tier-1 composite health alarm for ${name}: ALARM if any of its ${length(service.alarm_names)} underlying resource alarms is in ALARM state (full list omitted here - too long for this field - see this alarm's alarm_rule)."
  }
}

resource "aws_cloudwatch_composite_alarm" "this" {
  for_each = var.services

  alarm_name        = each.key
  alarm_description = local.alarm_descriptions[each.key]
  alarm_rule        = local.alarm_rules[each.key]

  alarm_actions             = each.value.alarm_actions
  ok_actions                = each.value.ok_actions
  insufficient_data_actions = each.value.insufficient_data_actions

  tags = merge(local.merged_tags, {
    Name = each.key
  })
}
