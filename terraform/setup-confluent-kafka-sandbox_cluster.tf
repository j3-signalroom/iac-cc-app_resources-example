# 'sandbox_cluster_app_manager' service account is required in this configuration to create 'stock_trades' topic and grant ACLs
# to 'sandbox_cluster_app_producer' and 'sandbox_cluster_app_consumer' service accounts.
resource "confluent_service_account" "sandbox_cluster_app_manager" {
  display_name = "sandbox_cluster_app_manager"
  description  = "Cluster Linking Example Service account to manage Kafka cluster source"
}

resource "confluent_role_binding" "sandbox_cluster_app_manager_kafka_cluster_admin" {
  principal   = "User:${confluent_service_account.sandbox_cluster_app_manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = data.confluent_kafka_cluster.sandbox_cluster.rbac_crn

  depends_on = [ 
    confluent_service_account.sandbox_cluster_app_manager 
  ]
}

# Creates the sandbox_cluster_app_manager Kafka Cluster API Key Pairs, rotate them in accordance to a time schedule,
# and provide the current acitve API Key Pair to use
module "kafka_sandbox_cluster_app_manager_api_key" {
  source = "github.com/j3-signalroom/iac-confluent-api_key_rotation-tf_module?ref=v0.23.00.000"

  #Required Input(s)
  owner = {
    id          = confluent_service_account.sandbox_cluster_app_manager.id
    api_version = confluent_service_account.sandbox_cluster_app_manager.api_version
    kind        = confluent_service_account.sandbox_cluster_app_manager.kind
  }

  resource = {
    id          = data.confluent_kafka_cluster.sandbox_cluster.id
    api_version = data.confluent_kafka_cluster.sandbox_cluster.api_version
    kind        = data.confluent_kafka_cluster.sandbox_cluster.kind

    environment = {
      id = data.confluent_environment.non_prod.id
    }
  }

  # Optional Input(s)
  key_display_name             = "Confluent Kafka Cluster Service Account API Key - {date} - Managed by Terraform Cloud"
  number_of_api_keys_to_retain = var.number_of_api_keys_to_retain
  day_count                    = var.day_count
  disable_wait_for_ready       = true

  depends_on = [ confluent_service_account.sandbox_cluster_app_manager ]
}

# Create the `dev-stock_trades` Kafka topic
resource "confluent_kafka_topic" "source_stock_trades" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.sandbox_cluster.id
  }
  topic_name    = "dev-stock_trades"
  rest_endpoint = data.confluent_kafka_cluster.sandbox_cluster.rest_endpoint
  credentials {
    key    = module.kafka_sandbox_cluster_app_manager_api_key.active_api_key.id
    secret = module.kafka_sandbox_cluster_app_manager_api_key.active_api_key.secret
  }

  depends_on = [ 
    module.kafka_sandbox_cluster_app_manager_api_key
  ]
}

resource "confluent_service_account" "sandbox_cluster_app_consumer" {
  display_name = "sandbox_cluster_app_consumer"
  description  = "Sandbox Cluster Service account to consume from 'stock_trades' topic of Kafka cluster source"
}

module "kafka_sandbox_cluster_app_consumer_api_key" {
  source = "github.com/j3-signalroom/iac-confluent-api_key_rotation-tf_module?ref=v0.23.00.000"

  #Required Input(s)
  owner = {
    id          = confluent_service_account.sandbox_cluster_app_consumer.id
    api_version = confluent_service_account.sandbox_cluster_app_consumer.api_version
    kind        = confluent_service_account.sandbox_cluster_app_consumer.kind
  }

  resource = {
    id          = data.confluent_kafka_cluster.sandbox_cluster.id
    api_version = data.confluent_kafka_cluster.sandbox_cluster.api_version
    kind        = data.confluent_kafka_cluster.sandbox_cluster.kind

    environment = {
      id = data.confluent_environment.non_prod.id
    }
  }

  # Optional Input(s)
  key_display_name             = "Confluent Kafka Cluster Service Account API Key - {date} - Managed by Terraform Cloud"
  number_of_api_keys_to_retain = var.number_of_api_keys_to_retain
  day_count                    = var.day_count
  disable_wait_for_ready       = true

  depends_on = [ confluent_service_account.sandbox_cluster_app_manager ]
}

resource "confluent_kafka_acl" "sandbox_cluster_app_producer_prefix_acls" {
  for_each = toset(local.acl_operations)

  kafka_cluster {
    id = data.confluent_kafka_cluster.sandbox_cluster.id
  }

  resource_type = "TOPIC"
  resource_name = "dev-stock_trades"
  pattern_type  = "LITERAL"

  principal     = "User:${confluent_service_account.sandbox_cluster_app_producer.id}"
  host          = "*"
  operation     = each.value
  permission    = "ALLOW"

  rest_endpoint = data.confluent_kafka_cluster.sandbox_cluster.rest_endpoint

  credentials {
    key    = module.kafka_sandbox_cluster_app_manager_api_key.active_api_key.id
    secret = module.kafka_sandbox_cluster_app_manager_api_key.active_api_key.secret
  }

  depends_on = [
    module.kafka_sandbox_cluster_app_consumer_api_key
  ]
}

resource "confluent_service_account" "sandbox_cluster_app_producer" {
  display_name = "sandbox_cluster_app_producer"
  description  = "Sandbox Cluster Service account to produce to 'stock_trades' topic of Kafka cluster source"
}

module "kafka_sandbox_cluster_app_producer_api_key" {
  source = "github.com/j3-signalroom/iac-confluent-api_key_rotation-tf_module?ref=v0.23.00.000"

  #Required Input(s)
  owner = {
    id          = confluent_service_account.sandbox_cluster_app_producer.id
    api_version = confluent_service_account.sandbox_cluster_app_producer.api_version
    kind        = confluent_service_account.sandbox_cluster_app_producer.kind
  }

  resource = {
    id          = data.confluent_kafka_cluster.sandbox_cluster.id
    api_version = data.confluent_kafka_cluster.sandbox_cluster.api_version
    kind        = data.confluent_kafka_cluster.sandbox_cluster.kind

    environment = {
      id = data.confluent_environment.non_prod.id
    }
  }

  # Optional Input(s)
  key_display_name             = "Confluent Kafka Cluster Service Account API Key - {date} - Managed by Terraform Cloud"
  number_of_api_keys_to_retain = var.number_of_api_keys_to_retain
  day_count                    = var.day_count
  disable_wait_for_ready       = true

  depends_on = [ confluent_service_account.sandbox_cluster_app_producer ]
}

resource "confluent_kafka_acl" "sandbox_cluster_app_consumer_read_on_group" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.sandbox_cluster.id
  }
  resource_type = "GROUP"
  resource_name = "sandbox_aws_example_"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.sandbox_cluster_app_consumer.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = data.confluent_kafka_cluster.sandbox_cluster.rest_endpoint
  credentials {
    key    = module.kafka_sandbox_cluster_app_manager_api_key.active_api_key.id
    secret = module.kafka_sandbox_cluster_app_manager_api_key.active_api_key.secret
  }

  depends_on = [
    module.kafka_sandbox_cluster_app_manager_api_key
  ]
}

resource "confluent_kafka_acl" "sandbox_cluster_app_consumer_read_on_topic" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.sandbox_cluster.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.source_stock_trades.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.sandbox_cluster_app_consumer.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = data.confluent_kafka_cluster.sandbox_cluster.rest_endpoint
  credentials {
    key    = module.kafka_sandbox_cluster_app_manager_api_key.active_api_key.id
    secret = module.kafka_sandbox_cluster_app_manager_api_key.active_api_key.secret
  }

  depends_on = [
    module.kafka_sandbox_cluster_app_manager_api_key
  ]
}

resource "confluent_service_account" "sandbox_cluster_app_connector" {
  display_name = "sandbox_cluster_app_connector"
  description  = "DataGen Source Connector to produce to the 'stock_trades' topic of the Kafka cluster source"
}

resource "confluent_kafka_acl" "sandbox_cluster_app_connector_describe_on_cluster" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.sandbox_cluster.id
  }
  resource_type = "CLUSTER"
  resource_name = "kafka-cluster"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.sandbox_cluster_app_connector.id}"
  host          = "*"
  operation     = "DESCRIBE"
  permission    = "ALLOW"
  rest_endpoint = data.confluent_kafka_cluster.sandbox_cluster.rest_endpoint
  credentials {
    key    = module.kafka_sandbox_cluster_app_manager_api_key.active_api_key.id
    secret = module.kafka_sandbox_cluster_app_manager_api_key.active_api_key.secret
  }

  depends_on = [
    module.kafka_sandbox_cluster_app_manager_api_key
  ]
}

resource "confluent_kafka_acl" "sandbox_cluster_app_connector_write_on_target_topic" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.sandbox_cluster.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.source_stock_trades.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.sandbox_cluster_app_connector.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = data.confluent_kafka_cluster.sandbox_cluster.rest_endpoint
  credentials {
    key    = module.kafka_sandbox_cluster_app_manager_api_key.active_api_key.id
    secret = module.kafka_sandbox_cluster_app_manager_api_key.active_api_key.secret
  }

  depends_on = [
    module.kafka_sandbox_cluster_app_manager_api_key
  ]
}

resource "confluent_kafka_acl" "sandbox_cluster_app_connector_create_on_data_preview_topics" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.sandbox_cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "sandbox_aws_example_"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.sandbox_cluster_app_connector.id}"
  host          = "*"
  operation     = "CREATE"
  permission    = "ALLOW"
  rest_endpoint = data.confluent_kafka_cluster.sandbox_cluster.rest_endpoint
  credentials {
    key    = module.kafka_sandbox_cluster_app_manager_api_key.active_api_key.id
    secret = module.kafka_sandbox_cluster_app_manager_api_key.active_api_key.secret
  }

  depends_on = [
    module.kafka_sandbox_cluster_app_manager_api_key
  ]
}

resource "confluent_kafka_acl" "sandbox_cluster_app_connector_write_on_data_preview_topics" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.sandbox_cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "sandbox_aws_example_"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.sandbox_cluster_app_connector.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = data.confluent_kafka_cluster.sandbox_cluster.rest_endpoint
  credentials {
    key    = module.kafka_sandbox_cluster_app_manager_api_key.active_api_key.id
    secret = module.kafka_sandbox_cluster_app_manager_api_key.active_api_key.secret
  }

  depends_on = [
    module.kafka_sandbox_cluster_app_manager_api_key
  ]
}

resource "confluent_connector" "source" {
  environment {
    id = data.confluent_environment.non_prod.id
  }
  kafka_cluster {
    id = data.confluent_kafka_cluster.sandbox_cluster.id
  }

  config_sensitive = {}

  config_nonsensitive = {
    "connector.class"          = "DatagenSource"
    "name"                     = "sandbox_aws_example_source_datagen_connector"
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = confluent_service_account.sandbox_cluster_app_connector.id
    "kafka.topic"              = confluent_kafka_topic.source_stock_trades.topic_name
    "output.data.format"       = "AVRO"
    "quickstart"               = "STOCK_TRADES"
    "tasks.max"                = "1"
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    confluent_kafka_acl.sandbox_cluster_app_connector_describe_on_cluster,
    confluent_kafka_acl.sandbox_cluster_app_connector_write_on_target_topic,
    confluent_kafka_acl.sandbox_cluster_app_connector_create_on_data_preview_topics,
    confluent_kafka_acl.sandbox_cluster_app_connector_write_on_data_preview_topics,
  ]
}
