output "private_srv" {
    value = mongodbatlas_advanced_cluster.mongo_cluster.connection_strings[0].private_srv
}
