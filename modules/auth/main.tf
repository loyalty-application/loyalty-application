#  key pair
resource "aws_key_pair" "auth" {
  key_name   = var.key_pair_name
  public_key = var.key_pair_public_key
}

# ec2 service role
resource "aws_iam_role" "ecs-instance-role" {
  name               = var.iam_ecs_instance_role
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs-instance-policy.json
}
resource "aws_iam_instance_profile" "ecs-instance-profile" {
  name = var.iam_ecs_instance_profile
  path = "/"
  role = aws_iam_role.ecs-instance-role.id
}

# ecs service role
resource "aws_iam_role" "ecs-service-role" {
  name               = var.iam_ecs_service_role
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs-service-policy.json
}
resource "aws_iam_role_policy_attachment" "ecs-instance-role-attachment" {
  role       = aws_iam_role.ecs-instance-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
resource "aws_iam_role_policy_attachment" "ecs-service-role-attachment" {
  role       = aws_iam_role.ecs-service-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}
