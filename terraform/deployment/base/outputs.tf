output "vpc" {
  value = {
    id              = module.vpc.vpc_id
    cidr            = module.vpc.vpc_cidr_block
    public_subnets  = module.vpc.public_subnets
    private_subnets = module.vpc.private_subnets
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
