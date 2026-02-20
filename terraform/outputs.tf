output "sandbox_cluster_bootstrap_endpoint" {
  description = "Bootstrap endpoint for the Confluent Sandbox Kafka Cluster. If a Confluent Access Point ID is provided, this will be the PNI-enabled endpoint; otherwise, it will be the standard endpoint."
  value = local.sandbox_cluster_bootstrap_endpoint
}

output "shared_cluster_bootstrap_endpoint" {
  description = "Bootstrap endpoint for the Confluent Shared Kafka Cluster. If a Confluent Access Point ID is provided, this will be the PNI-enabled endpoint; otherwise, it will be the standard endpoint."
  value = local.shared_cluster_bootstrap_endpoint
}   