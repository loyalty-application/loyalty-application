output "aws" {
  value = {
    aws_account_id = var.aws_account_id
    aws_regions    = var.aws_regions
  }
}

output "dns" {
  value = {
    route53_zone    = aws_route53_zone.this
    route53_domains = aws_route53domains_registered_domain.this
  }
}

output "iam" {
  value = {
    # iam roles for ecs
    ecs = {
      service_role     = aws_iam_role.service_role
      instance_role    = aws_iam_role.instance_role
      instance_profile = aws_iam_instance_profile.instance_profile
    }
    # iam roles for msk

  }
}

output "docdb" {
  value = {
    global_cluster = aws_docdb_global_cluster.this
  }
}
