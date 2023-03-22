terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws.region
}

locals {
  project_name  = "loyalty-application"
  kafka_version = "3.2.0"
}

resource "aws_security_group" "this" {
  name   = "${local.project_name}-sg-msk"
  vpc_id = var.vpc.id
  ingress {
    description = "TLS from VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

resource "aws_msk_configuration" "this" {
  kafka_versions = [local.kafka_version]
  name           = "${local.project_name}-configuration"

  server_properties = <<PROPERTIES
# HIGH ===============
# advertised.listeners
# broker.id
min.insync.replicas=1
# node.id
offsets.topic.replication.factor=2
# process.roles
transaction.state.log.min.isr=1
transaction.state.log.replication.factor=1
# MEDIUM ===============
default.replication.factor=3
group.initial.rebalance.delay.ms=0
  PROPERTIES
}

# msk cluster deployment
resource "aws_msk_cluster" "this" {
  # required
  cluster_name           = local.project_name
  kafka_version          = local.kafka_version
  number_of_broker_nodes = 3
  broker_node_group_info {
    instance_type  = "kafka.m5.large"
    client_subnets = var.vpc.subnets
    storage_info {
      ebs_storage_info {
        volume_size = 10
      }
    }
    security_groups = [aws_security_group.this.id]
  }

  configuration_info {
    arn      = aws_msk_configuration.this.arn
    revision = aws_msk_configuration.this.latest_revision
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS_PLAINTEXT"
    }
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = true
      }
      node_exporter {
        enabled_in_broker = false
      }
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.this.name
      }
    }
  }
}

# logs for msk
resource "aws_cloudwatch_log_group" "this" {
  name = "${local.project_name}-broker-logs"
}

## create s3 bucket to upload connector to
#resource "aws_s3_bucket" "this" {
#bucket = "${local.project_name}-bucket"
#}

## create the custom connector as s3 object and upload it
#resource "aws_s3_object" "this" {
#bucket = aws_s3_bucket.this.id
#key    = "jcustenborder-kafka-connect-spooldir.zip"
#source = "./jcustenborder-kafka-connect-spooldir.zip"

#etag = filemd5("./jcustenborder-kafka-connect-spooldir.zip")
#}

## create plugin with the connector
#resource "aws_mskconnect_custom_plugin" "this" {
#name         = "${local.project_name}-custom-plugin-${local.connector_revision}"
#content_type = "ZIP"
#location {
#s3 {
#bucket_arn = aws_s3_bucket.this.arn
#file_key   = aws_s3_object.this.key
#}
#}
#}

## msk custom worker
##resource "aws_mskconnect_worker_configuration" "this" {
##name                    = "${local.project_name}-worker-v1-0"
##properties_file_content = <<EOT
##key.converter=org.apache.kafka.connect.storage.StringConverter
##value.converter=org.apache.kafka.connect.storage.StringConverter
###config.storage.topic -> NOT SUPPORTED
###group.id -> NOT SUPPORTED
##offset.storage.topic=docker-connect-offsets 
###https://docs.aws.amazon.com/msk/latest/developerguide/msk-connect-workers.html -> specific guide
###status.storage.topic -> NOT SUPPORTED
###bootstrap.servers -> NOT SUPPORTED
##config.storage.replication.factor=1
##offset.flush.interval.ms=10000
##offset.storage.replication.factor=1
###plugin.path -> TBC
###rest.advertised.host.name -> TBC
##status.storage.replication.factor=1
###value.converted.schema.registry.url
##EOT
##}

#data "aws_mskconnect_worker_configuration" "this" {
#name = "${local.project_name}-worker-v1-0"
#}

#locals {
#aws_mskconnect_worker_config = data.aws_mskconnect_worker_configuration.this
#connector_revision           = 3
#}

## kafka connect
#resource "aws_mskconnect_connector" "this" {
#name                 = "${local.project_name}-connector-${local.connector_revision}"
#kafkaconnect_version = "2.7.1"
#capacity {
#autoscaling {
#mcu_count        = 1
#min_worker_count = 1
#max_worker_count = 2
#scale_in_policy {
#cpu_utilization_percentage = 20
#}
#scale_out_policy {
#cpu_utilization_percentage = 80
#}
#}
#}
#connector_configuration = {
#"connector.class" : "com.github.jcustenborder.kafka.connect.spooldir.SpoolDirCsvSourceConnector",
#"tasks.max" : "2",
#"cleanup.policy" : "DELETE",
#"topic" : "ftptransactions",
#"input.path" : "/data/unprocessed",
#"finished.path" : "/data/processed",
#"error.path" : "/data/error",
#"input.file.pattern" : ".*\\.csv",
#"key.schema" : "{\"name\":\"com.github.jcustenborder.kafka.connect.model.Key\",\"type\":\"STRUCT\",\"isOptional\":false,\"fieldSchemas\":{\"id\":{\"type\":\"STRING\",\"isOptional\":true}}}",
#"value.schema" : "{\"name\":\"com.github.jcustenborder.kafka.connect.model.Value\",\"type\":\"STRUCT\",\"isOptional\":false,\"fieldSchemas\":{\"id\":{\"type\":\"STRING\",\"isOptional\":true},\"transaction_id\":{\"type\":\"STRING\",\"isOptional\":true},\"merchant\":{\"type\":\"STRING\",\"isOptional\":true},\"mcc\":{\"type\":\"STRING\",\"isOptional\":true},\"currency\":{\"type\":\"STRING\",\"isOptional\":true},\"amount\":{\"type\":\"STRING\",\"isOptional\":true},\"transaction_date\":{\"type\":\"STRING\",\"isOptional\":true},\"card_id\":{\"type\":\"STRING\",\"isOptional\":true},\"card_pan\":{\"type\":\"STRING\",\"isOptional\":true},\"card_type\":{\"type\":\"STRING\",\"isOptional\":true}}}", "value.converter" : "org.apache.kafka.connect.json.JsonConverter",
#"value.converter.schemas.enable" : "false",
#"producer.override.enable.idempotence" : "true",
#"producer.override.acks" : "all",
#"transforms" : "cast,setDefaultValueToInt",
#"transforms.cast.type" : "org.apache.kafka.connect.transforms.Cast$Value",
#"transforms.cast.spec" : "amount:float64",
#"transforms.setDefaultValueToInt.type" : "org.apache.kafka.connect.transforms.ReplaceField$Value",
#"transforms.setDefaultValueToInt.field" : "mcc",
#"transforms.setDefaultValueToInt.default" : 0,
#"transforms.setDefaultValueToInt.type.to" : "int32"
#}
#kafka_cluster {
#apache_kafka_cluster {
#bootstrap_servers = aws_msk_cluster.this.bootstrap_brokers_tls
#vpc {
#security_groups = [aws_security_group.this.id]
#subnets         = var.vpc.subnets
#}
#}
#}
#kafka_cluster_client_authentication {
#authentication_type = "NONE"
#}
#kafka_cluster_encryption_in_transit {
#encryption_type = "TLS"
#}
## use the custom worker defined
#worker_configuration {
#arn      = local.aws_mskconnect_worker_config.arn
#revision = local.aws_mskconnect_worker_config.latest_revision
#}
## user the custom plugin defined
#plugin {
#custom_plugin {
#arn      = aws_mskconnect_custom_plugin.this.arn
#revision = aws_mskconnect_custom_plugin.this.latest_revision
#}
#}
## log to cloud watch
#log_delivery {
#worker_log_delivery {
#cloudwatch_logs {
#enabled   = true
#log_group = aws_cloudwatch_log_group.this.name
#}
#firehose {
#enabled = false
#}
#s3 {
#enabled = false
#}
#}
#}
#service_execution_role_arn = aws_iam_role.this.arn
#}

## iam role for msk connect
#resource "aws_iam_role" "this" {
#name = "${local.project_name}-msk-iam-role"
#assume_role_policy = jsonencode({
#Version = "2012-10-17"
#Statement = [
#{
#Action = "sts:AssumeRole"
#Effect = "Allow"
#Sid    = "mskConnect"
#Principal = {
#Service = [
#"kafkaconnect.amazonaws.com"
#]
#}
#}
#]
#})
#}

## create iam policy
#resource "aws_iam_policy" "this" {
#name   = "iam-policy"
#path   = "/"
#policy = data.aws_iam_policy_document.this.json
#}

## attach policy to role
#resource "aws_iam_role_policy_attachment" "this" {
#role       = aws_iam_role.this.name
#policy_arn = aws_iam_policy.this.arn
#}


