
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


resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name          = "maple-storage-ec2-cpu-alta"
  alarm_description   = "CPU da EC2 acima de 80%"
  comparison_operator = "GreaterThanThreshold"

  evaluation_periods = 2
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"

  period    = 300
  statistic = "Average"
  threshold = 80

  dimensions = {
    InstanceId = aws_instance.instancia.id
  }

  treat_missing_data = "notBreaching"

  tags = {
    Name        = "MapleStorage-EC2-CPU"
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


resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "maple-storage-rds-cpu-alta"
  alarm_description   = "CPU do RDS acima de 80%"
  comparison_operator = "GreaterThanThreshold"

  evaluation_periods = 2
  metric_name        = "CPUUtilization"
  namespace          = "AWS/RDS"

  period    = 300
  statistic = "Average"
  threshold = 80

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.rds_db.id
  }

  treat_missing_data = "notBreaching"

  tags = {
    Name        = "MapleStorage-RDS-CPU"
    Environment = "producao"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "maple-storage-rds-storage-baixo"
  alarm_description   = "Espaco livre do RDS abaixo de 2 GB"
  comparison_operator = "LessThanThreshold"

  evaluation_periods = 2
  metric_name        = "FreeStorageSpace"
  namespace          = "AWS/RDS"

  period    = 300
  statistic = "Average"

  # 2 GB = 2147483648 bytes
  threshold = 2147483648

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.rds_db.id
  }

  treat_missing_data = "notBreaching"

  tags = {
    Name        = "MapleStorage-RDS-Storage"
    Environment = "producao"
  }
}


resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "maple-storage-rds-conexoes-altas"
  alarm_description   = "Quantidade de conexoes do RDS acima de 80"
  comparison_operator = "GreaterThanThreshold"

  evaluation_periods = 2
  metric_name        = "DatabaseConnections"
  namespace          = "AWS/RDS"

  period    = 300
  statistic = "Average"
  threshold = 80

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.rds_db.id
  }

  treat_missing_data = "notBreaching"

  tags = {
    Name        = "MapleStorage-RDS-Connections"
    Environment = "producao"
  }
}


