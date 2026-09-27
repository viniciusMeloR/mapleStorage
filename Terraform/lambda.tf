
resource "aws_iam_role" "lambda_role" {

  name = "maple-storage-lambda-role"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {

        Effect = "Allow"

        Principal = {
          Service = "lambda.amazonaws.com"
        }

        Action = "sts:AssumeRole"

      }

    ]

  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {

  role = aws_iam_role.lambda_role.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}



resource "aws_iam_role_policy_attachment" "lambda_vpc" {

  role = aws_iam_role.lambda_role.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "archive_file" "lambda_zip" {

  type = "zip"

  source_dir = "${path.module}/lambda"

  output_path = "${path.module}/lambda.zip"
}


# =========================================================
# FUNÇÃO LAMBDA
# =========================================================

resource "aws_lambda_function" "criar_tabelas" {

  function_name = "maple-storage-criar-tabelas"

  role = aws_iam_role.lambda_role.arn

  handler = "index.handler"

  runtime = "nodejs22.x"

  filename = data.archive_file.lambda_zip.output_path

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout = 300

  memory_size = 256


  # -------------------------------------------------------
  # CONFIGURAÇÃO DA VPC
  # -------------------------------------------------------

  vpc_config {

    subnet_ids = [
      aws_subnet.privada.id
    ]

    security_group_ids = [
      aws_security_group.lambda_sg.id
    ]
  }

  environment {

    variables = {

      DB_HOST = aws_db_instance.rds_db.address

      DB_DATABASE = "mapleStorage"

      DB_USER = "admin"

      DB_PASSWORD = var.db_senha

      DB_PORT = "3306"
    }
  }


  depends_on = [

    aws_iam_role_policy_attachment.lambda_logs,

    aws_iam_role_policy_attachment.lambda_vpc

  ]


  tags = {

    Name = "Vinicius MapleStorage-Criar-Tabelas"

  }
}


resource "aws_lambda_invocation" "criar_tabelas" {

  function_name = aws_lambda_function.criar_tabelas.function_name

  input = jsonencode({
    acao = "criar_tabelas"
  })

  depends_on = [
    aws_lambda_function.criar_tabelas,
    aws_db_instance.rds_db
  ]
}