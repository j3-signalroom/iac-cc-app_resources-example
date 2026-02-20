resource "confluent_service_account" "shared_cluster_app_manager" {
  display_name = "shared_cluster_app_manager"
  description  = "Shared Cluster Sharing Service account to manage Kafka cluster"
}

resource "confluent_role_binding" "shared_cluster_app_manager_kafka_cluster_admin" {
  principal   = "User:${confluent_service_account.shared_cluster_app_manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = data.confluent_kafka_cluster.shared_cluster.rbac_crn

  depends_on = [ 
    confluent_service_account.shared_cluster_app_manager
  ]
}

# Creates the shared_cluster_app_manager Kafka Cluster API Key Pairs, rotate them in accordance to a time schedule,
# and provide the current acitve API Key Pair to use
module "kafka_shared_cluster_app_manager_api_key" {
  source = "github.com/j3-signalroom/iac-confluent-api_key_rotation-tf_module?ref=v0.23.00.000"

  #Required Input(s)
  owner = {
    id          = confluent_service_account.shared_cluster_app_manager.id
    api_version = confluent_service_account.shared_cluster_app_manager.api_version
    kind        = confluent_service_account.shared_cluster_app_manager.kind
  }

  resource = {
    id          = data.confluent_kafka_cluster.shared_cluster.id
    api_version = data.confluent_kafka_cluster.shared_cluster.api_version
    kind        = data.confluent_kafka_cluster.shared_cluster.kind

    environment = {
      id = data.confluent_environment.non_prod.id
    }
  }

  # Optional Input(s)
  key_display_name             = "Confluent Kafka Cluster Service Account API Key - {date} - Managed by Terraform Cloud"
  number_of_api_keys_to_retain = var.number_of_api_keys_to_retain
  day_count                    = var.day_count
  disable_wait_for_ready       = true
  
  depends_on = [
    confluent_service_account.shared_cluster_app_manager
  ]
}

# Wait for Shared API Key propagation before creating resources that depend on it
resource "time_sleep" "wait_for_shared_api_key_propagation" {
  depends_on = [
    confluent_role_binding.shared_cluster_app_manager_kafka_cluster_admin,
    module.kafka_shared_cluster_app_manager_api_key
  ]
  
  create_duration = "90s"
}

resource "confluent_service_account" "shared_cluster_app_consumer" {
  display_name = "shared_cluster_app_consumer"
  description  = "Shared Cluster App Consumer Service account to consume from 'stock_trades' topic"
}

module "kafka_shared_cluster_app_consumer_api_key" {
  source = "github.com/j3-signalroom/iac-confluent-api_key_rotation-tf_module?ref=v0.23.00.000"

  #Required Input(s)
  owner = {
    id          = confluent_service_account.shared_cluster_app_consumer.id
    api_version = confluent_service_account.shared_cluster_app_consumer.api_version
    kind        = confluent_service_account.shared_cluster_app_consumer.kind
  }

  resource = {
    id          = data.confluent_kafka_cluster.shared_cluster.id
    api_version = data.confluent_kafka_cluster.shared_cluster.api_version
    kind        = data.confluent_kafka_cluster.shared_cluster.kind

    environment = {
      id = data.confluent_environment.non_prod.id
    }
  }

  # Optional Input(s)
  key_display_name             = "Shared Kafka Cluster Service Account API Key - {date} - Managed by Terraform Cloud"
  number_of_api_keys_to_retain = var.number_of_api_keys_to_retain
  day_count                    = var.day_count
  disable_wait_for_ready       = true

  depends_on = [
    confluent_service_account.shared_cluster_app_consumer
  ]
}

resource "confluent_kafka_acl" "shared_cluster_app_consumer_read_on_group" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.shared_cluster.id
  }
  resource_type = "GROUP"
  resource_name = "shared_aws_example_"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.shared_cluster_app_consumer.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = local.shared_cluster_rest_endpoint
  credentials {
    key    = module.kafka_shared_cluster_app_manager_api_key.active_api_key.id
    secret = module.kafka_shared_cluster_app_manager_api_key.active_api_key.secret
  }

  depends_on = [
    module.kafka_shared_cluster_app_consumer_api_key,
    time_sleep.wait_for_shared_api_key_propagation
  ]
}
