output "address" {
  value = aws_db_instance.prod-example.address
  description = "endpoint of the database"
}
output "port" {
  value = aws_db_instance.prod-example.port
  description = "the port the database is listening on"
}

