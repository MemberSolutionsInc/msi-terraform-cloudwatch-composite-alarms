# msi-terraform-cloudwatch-composite-alarms

Composite CloudWatch alarms — one per business-critical service, combining underlying
resource alarms with `OR` logic for executive Tier-1 health dashboards.

## Purpose

This module sits downstream of [`msi-terraform-cloudwatch-alarms`](https://github.com/MemberSolutionsInc/msi-terraform-cloudwatch-alarms),
which creates individual `aws_cloudwatch_metric_alarm` resources (ECS/ALB/EC2/Lambda)
and outputs a map of alarm ARNs/names.

For each business-critical service, this module combines that service's set of
underlying alarms into a single `aws_cloudwatch_composite_alarm` using
`ALARM(a) OR ALARM(b) OR ...` logic, so a Tier-1 executive dashboard can show one
green/yellow/red status per service instead of dozens of individual alarms.

The resulting composite alarm ARNs/names are consumed by
[`msi-terraform-cloudwatch-dashboards`](https://github.com/MemberSolutionsInc/msi-terraform-cloudwatch-dashboards)
to build Tier-1 Alarm Status widgets, and composite alarm/ok/insufficient-data
actions typically point at SNS topics created by
[`msi-terraform-sns-teams-notifier`](https://github.com/MemberSolutionsInc/msi-terraform-sns-teams-notifier)
(this module accepts those as plain ARNs and does not couple to that module directly).

## Usage

```hcl
module "composite_alarms" {
  source = "git::https://github.com/MemberSolutionsInc/msi-terraform-cloudwatch-composite-alarms.git?ref=v0.1.0"

  services = {
    checkout-api = {
      alarm_names = [
        "checkout-api-ecs-cpu-high",
        "checkout-api-ecs-memory-high",
        "checkout-api-alb-5xx-high",
        "checkout-api-alb-target-response-time-high",
      ]
      alarm_actions             = [module.sns_teams_notifier.topic_arns["checkout-api"]]
      ok_actions                = [module.sns_teams_notifier.topic_arns["checkout-api"]]
      insufficient_data_actions = [module.sns_teams_notifier.topic_arns["checkout-api"]]
    }

    payments-worker = {
      alarm_names = [
        "payments-worker-lambda-errors-high",
        "payments-worker-lambda-throttles-high",
        "payments-worker-lambda-duration-high",
      ]
      alarm_actions = [module.sns_teams_notifier.topic_arns["payments-worker"]]
      ok_actions    = [module.sns_teams_notifier.topic_arns["payments-worker"]]
    }
  }

  tags = {
    service  = "checkout-api"
    env      = "prod"
    severity = "critical"
    team     = "platform"
    runbook  = "https://runbooks.membersolutions.com/checkout-api"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `services` | Map of business-critical services (keyed by service name). Each entry lists the underlying `alarm_names` to `OR` together, plus optional `alarm_actions` / `ok_actions` / `insufficient_data_actions` ARNs (e.g. SNS topics). | `map(object({ alarm_names = list(string), alarm_actions = optional(list(string), []), ok_actions = optional(list(string), []), insufficient_data_actions = optional(list(string), []) }))` | n/a | yes |
| `tags` | Mandatory tagging convention shared across this observability module family. Must include `service`, `env`, `severity`, `team`, `runbook`. Merged into every composite alarm's tags; `severity` defaults to `"critical"` for Tier-1 composites but is passed through when supplied. | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `composite_alarm_arns` | Map of composite CloudWatch alarm ARNs, keyed by service name. |
| `composite_alarm_names` | Map of composite CloudWatch alarm names, keyed by service name. |

## Requirements

| Name | Version |
|------|---------|
| terraform | `~> 1.0` |
| aws | `~> 5.0` |
