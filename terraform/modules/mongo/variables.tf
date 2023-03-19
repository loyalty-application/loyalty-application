variable "cluster" {
  type = object({
    project_id     = string
    project_region = string
  })
}

variable "cluster_network" {
  type = object({
    vpc_id            = string
    vpc_cidr          = string
    public_subnet_ids = list(string)
  })

}

variable "aws_account_id" {
 type = string
