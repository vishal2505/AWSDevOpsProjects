# Create CloudWatch Alarms for Lambda execution time
resource "aws_cloudwatch_metric_alarm" "high_execution_time_alarm" {
  alarm_name          = "HighExecutionTimeAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionTime"
  namespace           = "ImageProcessing"
  period              = 300
  statistic           = "Average"
  threshold           = 1000  # Adjust the threshold as needed
  alarm_description   = "Alarm triggered when Lambda execution time exceeds 1000 milliseconds."

  actions_enabled        = true
  alarm_actions          = ["arn:aws:sns:${var.aws_region}:${var.aws_account_id}:${var.sns_topic_name}"]
  ok_actions             = ["arn:aws:sns:${var.aws_region}:${var.aws_account_id}:${var.sns_topic_name}"]
  insufficient_data_actions = []
}

resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm" {
  alarm_name          = "LambdaInvocationErrorAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300" 
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  alarm_actions          = ["arn:aws:sns:${var.aws_region}:${var.aws_account_id}:${var.sns_topic_name}"]
  ok_actions             = ["arn:aws:sns:${var.aws_region}:${var.aws_account_id}:${var.sns_topic_name}"]
  insufficient_data_actions = []

}