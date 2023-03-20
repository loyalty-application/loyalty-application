output "connection_strings" {
  value = {
    all = mongodbatlas_advanced_cluster.this.connection_strings
  }
}
