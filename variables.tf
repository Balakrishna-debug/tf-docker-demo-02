variable "region" {
  description = "AWS region for hosting our your network"
  default = "eu-north-1"
}
variable "db_username" {
  description = "AWS RDS mysql db username"
}
variable "db_password" {
  description = "AWS RDS mysql db password"
}