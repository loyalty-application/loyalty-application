output "aws" {
  value = {
    aws_region = local.global.aws.aws_regions[var.aws_region_index]
  }
}
output "vpc" {
  value = module.vpc
}

output "sg" {
  value = {
    allow_all_sg = aws_security_group.this
  }
}

output "certificate" {
  value = {
    certificate_arn = aws_acm_certificate.this.arn
  }
}

output "key_pairs" {
  value = {
    names = [for kp in aws_key_pair.this : kp.key_name]
    arns  = [for kp in aws_key_pair.this : kp.arn]
  }
}

output "ecr" {
  value = module.ecr
}


output "efs" {
  value = {
    mount_target = aws_efs_mount_target.this
    file_system  = aws_efs_file_system.this
  }
}

output "docdb" {
  sensitive = true
  value = {
    cluster  = aws_docdb_cluster.this
    instance = aws_docdb_cluster_instance.primary
  }
}

output "cloudwatch" {
  value = {
    log_group = aws_cloudwatch_log_group.this
  }
}

