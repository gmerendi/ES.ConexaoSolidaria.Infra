# 1. Compacta o código Python automaticamente
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_code"
  output_path = "${path.module}/lambda_function_payload.zip"
}

data "aws_caller_identity" "current" {}


############################################################################
# LAMBDA 1: SERVIÇO DE E-MAIL
############################################################################
resource "aws_lambda_function" "email_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.name_prefix}-email-service"
  role             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  handler          = "email_sending.handler" # NomeArquivo.NomeFuncao
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.9"
  timeout          = 30

  environment {
    variables = {
      SENDER_EMAIL   = "noreply@${local.name_prefix}.com"
      SENDER_NAME         = var.project_name
      MAILTRAP_API_TOKEN  = var.mailtrap_api_token
      MAILTRAP_INBOX_ID   = var.mailtrap_inbox_id
      SNS_TOPIC_ARN = aws_sns_topic.email_notifications.arn
    }
  }
}