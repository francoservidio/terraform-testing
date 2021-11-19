output "address" {
  value = aws_db_instance.example.address
  description = "endpoint of the database"
}
output "port" {
  value = aws_db_instance.example.port
  description = "the port the database is listening on"
}

