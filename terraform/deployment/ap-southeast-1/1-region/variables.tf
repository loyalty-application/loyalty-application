# required variables ---
# aws
variable "aws_region_index" {
  type        = number
  description = "the list index of the region you're deploying to in global deployment's aws_regions variable"
}

# document db 
variable "docdb_mongo_username" {
  type        = string
  description = "username you wish to set for an admin account in mongodb"
}

variable "docdb_mongo_password" {
  type        = string
  description = "password you wish to set for an admin account in mongodb"
}

# vpc
variable "vpc" {
  type = object({
    cidr            = string
    azs             = list(string)
    private_subnets = list(string)
    public_subnets  = list(string)
  })
}

# ssh keys
variable "key_pairs" {
  type = map(string)
}

# optional variables
variable "project_name" {
  type        = string
  description = "name to use for all deployed resources"
  default     = "loyalty-application"
}

variable "ecr_project_names" {
  type        = list(string)
  description = "names of ecr repositories to create for the project - note that this may not be required for you as this is for development"
  default     = []
}

