# Terraform Deployment
The `loyalty-application` project uses Terraform to deploy its resource onto AWS with the `AWS Provisioner`

This page aims to cover the basics of setting up and deploying this project with Terraform.
You are advised to follow the steps documented even as an experienced Terraform user

## Introduction
When deploying the resources, make sure to follow the order below: 
1. base
2. mongo
3. kafka
4. nextjs-frontend
5. go-gin-backend
6. go-sftp-txn
7. go-worker-node

In the `deployment` folder, there are 7 folders, each representing one of the deployments stated previously

Within each folder, there is also a `terraform.auto.tfvars.example` file which contains the variables required for that folder's deployment. 

You will need to make a copy of this file and rename it as `terraform.auto.tf` and fill in the variables required for the deployment. 

More specific documentation can also be found in the form of a `README.md` file within each folder.

## Setup
Before you start deploying the resources, you will need the following:
1. [terraform-cli](https://developer.hashicorp.com/terraform/downloads?product_intent=terraform)
2. AWS Account
3. MongoDB Atlas Account

### terraform-cli
Go to [https://terraform.io](https://terraform.io) and head to their downloads page to download terraform-cli for your specific OS

### AWS Account
Login to your AWS Account and create a API Key Pair, this is to allow terraform access to your AWS Account's privileges to deploy resources


