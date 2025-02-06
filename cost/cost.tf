resource "aws_budgets_budget" "monthly_budget" {
  name         = "Monthly${var.app_name}Budget"
  budget_type  = "COST"
  limit_amount = "200"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  cost_filter {
    name = "TagKeyValue"
    values = ["user:Project${"$"}${var.tags.Project}"

    ]
  }



  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.contact]

  }
}
