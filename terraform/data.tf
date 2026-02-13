data "confluent_environment" "non_prod" {
  id = var.confluent_environment_id
}

locals {
  cloud = "AWS"
  acl_operations = ["READ", "WRITE", "DESCRIBE"]
}
