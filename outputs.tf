output "private_key" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}

# Output the key name
output "key_name" {
  value = aws_key_pair.ssh_key.key_name
}

output "instance_ip" {
  value = aws_instance.app.public_ip
}


# Outputs to fetch RDS details
output "db_host" {
  value = aws_db_instance.app_db.address
}

output "db_user" {
  value = aws_db_instance.app_db.username
}

output "db_password" {
  value = aws_db_instance.app_db.password
  sensitive = true
}

output "db_name" {
  value = aws_db_instance.app_db.db_name
}
