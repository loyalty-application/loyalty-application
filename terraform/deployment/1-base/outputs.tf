output "vpc" {
  value = module.vpc
}

output "sg" {
  value = {
    allow_all_sg = aws_security_group.this
  }
}

output "dns" {
  value = {
    domain = aws_route53domains_registered_domain.this
    zone   = aws_route53_zone.this
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

output "iam" {
  value = {
    ecs = {
      service_role     = aws_iam_role.service_role
      instance_role    = aws_iam_role.instance_role
      instance_profile = aws_iam_instance_profile.instance_profile
    }
  }
}

output "efs" {
  value = {
    mount_target = aws_efs_mount_target.this
    file_system  = aws_efs_file_system.this
  }
}

output "ecs" {
  value = var.ecs
}
