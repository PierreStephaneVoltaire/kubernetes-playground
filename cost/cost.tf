resource "aws_budgets_budget" "monthly_budget" {
  name         = "Monthly${var.app_name}Budget"
  budget_type  = "COST"
  limit_amount = "200"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name = "TagKeyValue"
    values = ["Project${"$"}${var.tags.Project}"

    ]
  }
  cost_filter {
    name = "Service"
    values = [
      "Amazon EC2 Container Registry (ECR)",
      "Amazon Elastic Load Balancing",
      "Amazon Elastic Container Service for Kubernetes",
      "Amazon Elastic File System",
      "Amazon Virtual Private Cloud",
      "Tax",
      "Amazon Elastic Container Service",
      "Amazon Elastic Container Registry Public",
      "Amazon Elastic Block Store",
      "Amazon Elastic Compute Cloud  Compute",
      "Amazon DynamoDB",
      "Amazon Cognito",
      "AmazonCloudWatch",
      "Amazon CloudFront",
      "AWS Key Management Service",
      "Amazon Registrar",
      "Amazon Route 53",
      "Amazon Relational Database Service",
      "Amazon Simple Storage Service",
      "AWS Secrets Manager",
      "Amazon Simple Notification Service",
      "Amazon Simple Queue Service",
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
