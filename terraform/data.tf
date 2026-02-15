data "confluent_environment" "non_prod" {
  id = var.confluent_environment_id
}

data "confluent_kafka_cluster" "sandbox_cluster" {
  id = var.confluent_sandbox_kafka_cluster_id

  environment {
    id = data.confluent_environment.non_prod.id
  }
}

data "confluent_kafka_cluster" "shared_cluster" {
  id = var.confluent_shared_kafka_cluster_id

  environment {
    id = data.confluent_environment.non_prod.id
  }
}

locals {
  acl_operations = ["READ", "WRITE", "DESCRIBE"]
}
