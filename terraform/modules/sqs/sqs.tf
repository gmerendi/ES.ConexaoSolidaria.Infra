###############################################################################
# Módulo SQS - Geral
###############################################################################
locals {
  name_prefix      = "${var.project_prefix}"
}



############################################################################
# FILA PARA EMAIL DE CRIAÇÃO DE USUÁRIO
############################################################################
resource "aws_sqs_queue" "user_created_queue" {
  name                      = "${local.name_prefix}-user-created-queue"
  delay_seconds             = 0
  message_retention_seconds = 86400 # 1 dia
  visibility_timeout_seconds = 60    # Deve ser maior que o timeout da Lambda (ex: 30s)
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.user_created_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "user_created_dlq" {
  name = "${local.name_prefix}-user-created-dlq"
}


############################################################################
# FILA PARA EMAIL DE DOACAO PROCESSADA 
############################################################################
resource "aws_sqs_queue" "donation_processed_queue" {
  name                       = "${local.name_prefix}-donation_processed-queue"
  visibility_timeout_seconds = 60

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.donation_processed_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "donation_processed_dlq" {
  name = "${local.name_prefix}-donation_processed-dlq"
}








############################################################################
# SNS
############################################################################
# Cria o tópico SNS
resource "aws_sns_topic" "email_notifications" {
  name = "${local.name_prefix}-email-notifications"
}

# Subscription com seu email — você receberá um link de confirmação
resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.email_notifications.arn
  protocol  = "email"
  endpoint  = var.admin_email  # <- Email utilizado para a subscricao
}

# Permissão para a Lambda publicar no tópico
resource "aws_sns_topic_policy" "allow_lambda" {
  arn    = aws_sns_topic.email_notifications.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole" }
      Action    = "sns:Publish"
      Resource  = aws_sns_topic.email_notifications.arn
    }]
  })
}
