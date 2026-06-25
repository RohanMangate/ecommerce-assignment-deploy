# -----------------------------------------------
# Outputs
# -----------------------------------------------
output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.ecommerce_server.public_ip
}

output "public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.ecommerce_server.public_dns
}

output "frontend_url" {
  description = "URL to access the frontend application"
  value       = "http://${aws_instance.ecommerce_server.public_ip}"
}

output "user_service_health" {
  description = "User Service health check URL"
  value       = "http://${aws_instance.ecommerce_server.public_ip}:3001/health"
}

output "product_service_health" {
  description = "Product Service health check URL"
  value       = "http://${aws_instance.ecommerce_server.public_ip}:3002/health"
}

output "cart_service_health" {
  description = "Cart Service health check URL"
  value       = "http://${aws_instance.ecommerce_server.public_ip}:3003/health"
}

output "order_service_health" {
  description = "Order Service health check URL"
  value       = "http://${aws_instance.ecommerce_server.public_ip}:3004/health"
}
