
resource "aws_cloudwatch_log_group" "ec2" {
  name              = "/maple-storage/ec2"
  retention_in_days = 7

  tags = {
    Name        = "MapleStorage-EC2-Logs"
    Environment = "producao"
  }
}


resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.criar_tabelas.function_name}"
  retention_in_days = 7

  tags = {
    Name        = "MapleStorage-Lambda-Logs"
    Environment = "producao"
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_status" {
  alarm_name          = "maple-storage-ec2-status"
  alarm_description   = "A EC2 apresentou falha de status"
  comparison_operator = "GreaterThanThreshold"

  evaluation_periods = 2
  metric_name        = "StatusCheckFailed"
  namespace          = "AWS/EC2"

  period    = 60
  statistic = "Maximum"
  threshold = 0

  dimensions = {
    InstanceId = aws_instance.instancia.id
  }

  treat_missing_data = "breaching"

  tags = {
    Name        = "MapleStorage-EC2-Status"
    Environment = "producao"
  }
}






