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

  # Confluent requires the dash ("-") characters to be removed from the
  # Access Point ID when constructing the PNI endpoint address
  pni_access_point_id = replace(var.confluent_pni_access_code_id, "-", "")
  sandbox_access_point_id = replace(var.confluent_sandbox_access_code_id, "-", "")
  shared_access_point_id = replace(var.confluent_shared_access_code_id, "-", "")
  
  # Create base address for PNI endpoints using the modified Access Point
  # ID and AWS region
  root_address = "${var.aws_region}.aws.accesspoint.glb.confluent.cloud"
  pni_base_address = "${local.pni_access_point_id}.${local.root_address}"
  sandbox_base_address = "${local.sandbox_access_point_id}.${local.root_address}"
  shared_base_address = "${local.shared_access_point_id}.${local.root_address}"

  # By default, the Confluent Terraform Provider does not generate the 
  # Confluent PNI-enabled endpoint, so it must be configured manually
  # when the Confluent Access Point ID is provided.
  sandbox_cluster_bootstrap_endpoint = var.confluent_pni_access_code_id == "" ? "${var.confluent_sandbox_kafka_cluster_id}-${local.sandbox_base_address}:9092" : "${var.confluent_sandbox_kafka_cluster_id}-${local.pni_base_address}:9092"
  sandbox_cluster_rest_endpoint = var.confluent_pni_access_code_id == "" ? "https://${var.confluent_sandbox_kafka_cluster_id}-${local.sandbox_base_address}:443" : "https://${var.confluent_sandbox_kafka_cluster_id}-${local.pni_base_address}:443"
  shared_cluster_bootstrap_endpoint = var.confluent_pni_access_code_id == "" ? "${var.confluent_shared_kafka_cluster_id}-${local.shared_base_address}:9092" : "${var.confluent_shared_kafka_cluster_id}-${local.pni_base_address}:9092"
  shared_cluster_rest_endpoint = var.confluent_pni_access_code_id == "" ? "https://${var.confluent_shared_kafka_cluster_id}-${local.shared_base_address}:443" : "https://${var.confluent_shared_kafka_cluster_id}-${local.pni_base_address}:443"
}
