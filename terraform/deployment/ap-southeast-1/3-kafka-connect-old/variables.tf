# generic project specific names
variable "project_name" {
  type        = string
  description = "name for the project"
  default     = "kafka-connect"

}

# ecs configs
variable "ecs" {
  type = object({
    instance_type = string
    asg = object({
      desired_capacity = number
      max_size         = number
      min_size         = number
    })
  })
  default = {
    asg = {
      desired_capacity = 1
      max_size         = 2
      min_size         = 1
    }
    instance_type = "t3.medium"
  }
}

# environment variables for task definition
variable "ENV" {
  sensitive = true
  type      = map(string)
  default = {
    "CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL" = "http://schema-registry:8081",
    "CONNECT_CONFIG_STORAGE_TOPIC"                = "docker-connect-configs",
    "CONNECT_GROUP_ID"                            = "compose-connect-group",
    "CONNECT_KEY_CONVERTER"                       = "org.apache.kafka.connect.storage.StringConverter",
    "CONNECT_OFFSET_STORAGE_TOPIC"                = "docker-connect-offsets",
    "CONNECT_STATUS_STORAGE_TOPIC"                = "docker-connect-status",
    "CONNECT_VALUE_CONVERTER"                     = "io.confluent.connect.avro.AvroConverter",
    "CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR"   = "1",
    "CONNECT_OFFSET_FLUSH_INTERVAL_MS"            = "10000",
    "CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR"   = "1",
    "CONNECT_PLUGIN_PATH"                         = "/usr/share/java,/usr/share/confluent-hub-components",
    "CONNECT_REST_ADVERTISED_HOST_NAME"           = "connect",
    "CONNECT_STATUS_STORAGE_REPLICATION_FACTOR"   = "1",
    "CONNECT_INTERNAL_KEY_CONVERTER"              = "org.apache.kafka.connect.json.JsonConverter",
    "CONNECT_INTERNAL_VALUE_CONVERTER"            = "org.apache.kafka.connect.json.JsonConverter",
    "CONNECT_CONSUMER_INTERCEPTOR_CLASSES"        = "io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor",
    "CONNECT_PRODUCER_INTERCEPTOR_CLASSES"        = "io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor",
    "CLASSPATH"                                   = "/usr/share/java/monitoring-interceptors/monitoring-interceptors-7.3.1.jar",
    "CONNECT_LOG4J_LOGGERS"                       = "org.apache.zookeeper=ERROR,org.I0Itec.zkclient=ERROR,org.reflections=ERROR",
  }
}

variable "tg" {
  type = object({
    port = number
    hc = object({
      path                = string
      protocol            = string
      interval            = number
      matcher             = number
      healthy_threshold   = number
      unhealthy_threshold = number
    })
  })
  default = {
    port = 8083
    hc = {
      path                = "/"
      protocol            = "HTTP"
      interval            = 60
      matcher             = "200"
      healthy_threshold   = 2
      unhealthy_threshold = 5
    }
  }
}


