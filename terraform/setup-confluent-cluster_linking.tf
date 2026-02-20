resource "confluent_service_account" "sandbox_cluster_linking_app_manager" {
  display_name = "sandbox_cluster_linking_app_manager"
  description  = "Sandbox Cluster Linking App Manager Service Account"
}

resource "confluent_role_binding" "sandbox_cluster_linking_app_manager" {
  principal   = "User:${confluent_service_account.sandbox_cluster_linking_app_manager.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = data.confluent_environment.non_prod.resource_name
}

module "sandbox_cluster_linking_app_manager_api_key" {
  source = "github.com/j3-signalroom/iac-confluent-api_key_rotation-tf_module?ref=v0.23.00.000"

  #Required Input(s)
  owner = {
    id          = confluent_service_account.sandbox_cluster_linking_app_manager.id
    api_version = confluent_service_account.sandbox_cluster_linking_app_manager.api_version
    kind        = confluent_service_account.sandbox_cluster_linking_app_manager.kind
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
  key_display_name             = "Sandbox Cluster Linking App Manager Service Account API Key - {date} - Managed by Terraform Cloud"
  number_of_api_keys_to_retain = var.number_of_api_keys_to_retain
  day_count                    = var.day_count
  disable_wait_for_ready       = true

  depends_on = [ 
    confluent_service_account.sandbox_cluster_linking_app_manager
  ]
}

resource "confluent_service_account" "shared_cluster_linking_app_manager" {
  display_name = "shared_cluster_linking_app_manager"
  description  = "Shared Cluster Linking App Manager Service Account"
}

resource "confluent_role_binding" "shared_cluster_linking_app_manager" {
  principal   = "User:${confluent_service_account.shared_cluster_linking_app_manager.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = data.confluent_environment.non_prod.resource_name
}

module "shared_cluster_linking_app_manager_api_key" {
  source = "github.com/j3-signalroom/iac-confluent-api_key_rotation-tf_module?ref=v0.23.00.000"

  #Required Input(s)
  owner = {
    id          = confluent_service_account.shared_cluster_linking_app_manager.id
    api_version = confluent_service_account.shared_cluster_linking_app_manager.api_version
    kind        = confluent_service_account.shared_cluster_linking_app_manager.kind
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
  key_display_name             = "Shared Cluster Linking App Manager Service Account API Key - {date} - Managed by Terraform Cloud"
  number_of_api_keys_to_retain = var.number_of_api_keys_to_retain
  day_count                    = var.day_count
  disable_wait_for_ready       = true

  depends_on = [ 
    confluent_service_account.shared_cluster_linking_app_manager
  ]
}

# Wait for Cluster Linking API Key propagation before creating resources that depend on it
resource "time_sleep" "wait_for_cluster_linking_api_key_propagation" {
  depends_on = [
    confluent_role_binding.sandbox_cluster_linking_app_manager,
    confluent_role_binding.shared_cluster_linking_app_manager,
    module.sandbox_cluster_linking_app_manager_api_key,
    module.shared_cluster_linking_app_manager_api_key
  ]
  
  create_duration = "120s"
}

resource "confluent_cluster_link" "sandbox_to_shared" {
  link_name = "sandbox_to_shared"

  source_kafka_cluster {
    id            = data.confluent_kafka_cluster.sandbox_cluster.id
    bootstrap_endpoint = local.sandbox_cluster_bootstrap_endpoint
    credentials {
      key    = module.sandbox_cluster_linking_app_manager_api_key.active_api_key.id
      secret = module.sandbox_cluster_linking_app_manager_api_key.active_api_key.secret
    }
  }

  destination_kafka_cluster {
    id                 = data.confluent_kafka_cluster.shared_cluster.id
    rest_endpoint = local.shared_cluster_rest_endpoint
    credentials {
      key    = module.shared_cluster_linking_app_manager_api_key.active_api_key.id
      secret = module.shared_cluster_linking_app_manager_api_key.active_api_key.secret
    }
  }

  depends_on = [
    module.sandbox_cluster_linking_app_manager_api_key,
    module.shared_cluster_linking_app_manager_api_key,
    confluent_kafka_topic.source_stock_trades,
    confluent_kafka_acl.sandbox_cluster_app_connector_create_on_data_preview_topics,
    confluent_kafka_acl.sandbox_cluster_app_connector_describe_on_cluster,
    confluent_kafka_acl.sandbox_cluster_app_connector_write_on_data_preview_topics,
    confluent_kafka_acl.sandbox_cluster_app_connector_write_on_target_topic,
    confluent_kafka_acl.sandbox_cluster_app_consumer_read_on_group,
    confluent_kafka_acl.sandbox_cluster_app_consumer_read_on_topic,
    confluent_kafka_acl.sandbox_cluster_app_producer_prefix_acls,
    confluent_connector.source,
    time_sleep.wait_for_cluster_linking_api_key_propagation
  ]
}

resource "confluent_kafka_mirror_topic" "stock_trades_mirror" {
  source_kafka_topic {
    topic_name = confluent_kafka_topic.source_stock_trades.topic_name 
  }
  cluster_link {
    link_name = confluent_cluster_link.sandbox_to_shared.link_name
  }
  
  kafka_cluster {
    id            = data.confluent_kafka_cluster.shared_cluster.id
    rest_endpoint = local.shared_cluster_rest_endpoint

    credentials {
      key    = module.shared_cluster_linking_app_manager_api_key.active_api_key.id
      secret = module.shared_cluster_linking_app_manager_api_key.active_api_key.secret
    }
  }

  depends_on = [
    confluent_cluster_link.sandbox_to_shared,
    time_sleep.wait_for_cluster_linking_api_key_propagation
  ]
}
