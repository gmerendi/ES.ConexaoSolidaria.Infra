############################################################################
# Trigger para Email User Created
############################################################################
resource "aws_lambda_event_source_mapping" "user_created_trigger" {
  event_source_arn = aws_sqs_queue.user_created_queue.arn
  function_name    = aws_lambda_function.email_lambda.function_name 
  batch_size       = 5 # Processa até 5 mensagens por vez
  
  # Habilita o reporte de falhas parciais 
  function_response_types = ["ReportBatchItemFailures"]
}


############################################################################
# Trigger para Email Donation Processed
############################################################################
resource "aws_lambda_event_source_mapping" "donation_processed_trigger" {
  event_source_arn = aws_sqs_queue.donation_processed_queue.arn
  function_name    = aws_lambda_function.email_lambda.function_name
  batch_size       = 5
  function_response_types = ["ReportBatchItemFailures"]
}