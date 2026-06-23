output "user_created_queue_url" {
  value = aws_sqs_queue.user_created_queue.url
}

output "donation_processed_queue_url" {
  value = aws_sqs_queue.donation_processed_queue.url
}

