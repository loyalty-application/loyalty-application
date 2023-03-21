data "aws_iam_policy_document" "this" {
  statement {
    sid = "readS3Objects"
    actions = [
      "s3:Get*",
      "s3:List*",
      "s3-object-lambda:Get*",
    "s3-object-lambda:List*"]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    sid = "mskCluster"
    actions = [
      "kafka-cluster:Connect",
      "kafka-cluster:ReadData",
      "kafka-cluster:WriteData",
      "kafka-cluster:DescribeGroup",
      "kafka-cluster:AlterGroup",
      "kafka-cluster:WriteDataIdempotently",
      "kafka-cluster:DescribeTransactionalId",
      "kafka-cluster:AlterTransactionalId",
      "kafka-cluster:DescribeClusterDynamicConfiguration",
    "kafka-cluster:*Topic"]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    sid = "readSecrets"
    actions = [
    "secretsmanager:GetSecretValue"]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    sid = "readKMS"
    actions = [
      "kms:Decrypt",
    "kms:DescribeKey"]
    effect    = "Allow"
    resources = ["*"]
  }
}
