output "invoke_url" {
  description = "Invoke URL for the REST API."
  value       = "https://${aws_api_gateway_rest_api.this.id}.execute-api.${var.aws_region}.amazonaws.com/${var.stage_name}"
}

output "api_key_name" {
  description = "API key name."
  value       = aws_api_gateway_api_key.this.name
}
