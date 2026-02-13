# Create the Schema Registry Cluster Secrets: API Key Pair and REST endpoint for Kafka client
resource "aws_secretsmanager_secret" "src_api_key" {
    name = "${var.confluent_secret_root_path}/schema_registry_cluster"
    description = "Schema Registry Cluster secrets for Kafka client"
}

resource "aws_secretsmanager_secret_version" "src_api_key" {
    secret_id     = aws_secretsmanager_secret.src_api_key.id
    secret_string = jsonencode({"schema.registry.basic.auth.credentials.source": "USER_INFO",
                                "schema.registry.basic.auth.user.info": "${module.src_api_key_rotation.active_api_key.id}:${module.src_api_key_rotation.active_api_key.secret}",
                                "schema.registry.url": "${data.confluent_schema_registry_cluster.src.rest_endpoint}"})
}

# Create the Kafka Cluster Secrets: JAAS (Java Authentication and Authorization) representation
# for Java client and bootstrap server URI
resource "aws_secretsmanager_secret" "kafka_sandbox_cluster_app_manager_api_key_java_client" {
    name = "${var.confluent_secret_root_path}/sandbox_cluster/app_manager/java_client"
    description = "Kafka Cluster secrets for Java client"
}
resource "aws_secretsmanager_secret_version" "kafka_sandbox_cluster_app_manager_api_key_java_client" {
    secret_id     = aws_secretsmanager_secret.kafka_sandbox_cluster_app_manager_api_key_java_client.id
    secret_string = jsonencode({"sasl.jaas.config": "org.apache.kafka.common.security.plain.PlainLoginModule required username='${module.kafka_sandbox_cluster_app_manager_api_key.active_api_key.id}' password='${module.kafka_sandbox_cluster_app_manager_api_key.active_api_key.secret}';",
                                "bootstrap.servers": replace(confluent_kafka_cluster.sandbox_cluster.bootstrap_endpoint, "SASL_SSL://", "")})
}

resource "aws_secretsmanager_secret" "kafka_sandbox_cluster_app_consumer_api_key_java_client" {
    name = "${var.confluent_secret_root_path}/sandbox_cluster/app_consumer/java_client"
    description = "Kafka Cluster secrets for Java client"
}
resource "aws_secretsmanager_secret_version" "kafka_sandbox_cluster_app_consumer_api_key_java_client" {
    secret_id     = aws_secretsmanager_secret.kafka_sandbox_cluster_app_consumer_api_key_java_client.id
    secret_string = jsonencode({"sasl.jaas.config": "org.apache.kafka.common.security.plain.PlainLoginModule required username='${module.kafka_sandbox_cluster_app_consumer_api_key.active_api_key.id}' password='${module.kafka_sandbox_cluster_app_consumer_api_key.active_api_key.secret}';",
                                "bootstrap.servers": replace(confluent_kafka_cluster.sandbox_cluster.bootstrap_endpoint, "SASL_SSL://", "")})
}

resource "aws_secretsmanager_secret" "kafka_sandbox_cluster_app_producer_api_key_java_client" {
    name = "${var.confluent_secret_root_path}/sandbox_cluster/app_producer/java_client"
    description = "Kafka Cluster secrets for Java client"
}
resource "aws_secretsmanager_secret_version" "kafka_sandbox_cluster_app_producer_api_key_java_client" {
    secret_id     = aws_secretsmanager_secret.kafka_sandbox_cluster_app_producer_api_key_java_client.id
    secret_string = jsonencode({"sasl.jaas.config": "org.apache.kafka.common.security.plain.PlainLoginModule required username='${module.kafka_sandbox_cluster_app_producer_api_key.active_api_key.id}' password='${module.kafka_sandbox_cluster_app_producer_api_key.active_api_key.secret}';",
                                "bootstrap.servers": replace(confluent_kafka_cluster.sandbox_cluster.bootstrap_endpoint, "SASL_SSL://", "")})
}

resource "aws_secretsmanager_secret" "kafka_shared_cluster_app_manager_api_key_java_client" {
    name = "${var.confluent_secret_root_path}/shared_cluster/app_manager/java_client"
    description = "Kafka Cluster secrets for Java client"
}
resource "aws_secretsmanager_secret_version" "kafka_shared_cluster_app_manager_api_key_java_client" {
    secret_id     = aws_secretsmanager_secret.kafka_shared_cluster_app_manager_api_key_java_client.id
    secret_string = jsonencode({"sasl.jaas.config": "org.apache.kafka.common.security.plain.PlainLoginModule required username='${module.kafka_shared_cluster_app_manager_api_key.active_api_key.id}' password='${module.kafka_shared_cluster_app_manager_api_key.active_api_key.secret}';",
                                "bootstrap.servers": replace(confluent_kafka_cluster.shared_cluster.bootstrap_endpoint, "SASL_SSL://", "")})
}

resource "aws_secretsmanager_secret" "kafka_shared_cluster_app_consumer_api_key_java_client" {
    name = "${var.confluent_secret_root_path}/shared_cluster/app_consumer/java_client"
    description = "Kafka Cluster secrets for Java client"
}
resource "aws_secretsmanager_secret_version" "kafka_shared_cluster_app_consumer_api_key_java_client" {
    secret_id     = aws_secretsmanager_secret.kafka_shared_cluster_app_consumer_api_key_java_client.id
    secret_string = jsonencode({"sasl.jaas.config": "org.apache.kafka.common.security.plain.PlainLoginModule required username='${module.kafka_shared_cluster_app_consumer_api_key.active_api_key.id}' password='${module.kafka_shared_cluster_app_consumer_api_key.active_api_key.secret}';",
                                "bootstrap.servers": replace(confluent_kafka_cluster.shared_cluster.bootstrap_endpoint, "SASL_SSL://", "")})
}
