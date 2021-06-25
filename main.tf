# Apelarea modulului aws-organization pentru a crea cele
# trei conturi: prod, dev si audit
module "setup_organization" {
  source = "github.com/roxanapopa97/aws-organization?ref=v0.2"
  create_organization = true
  organizational_units = [
    "prod", "dev", "audit"
  ]
  member_accounts = {
    "prod_account" : {
      "name"  : "prod",         
      "email" : "terraformtestcicd+prod@gmail.com",
      "has_access_to_billing" : "DENY",
      "ou_name" : "prod",
      "role_name" : "TerraformAutomationRole"
    },
    "dev_account" : {
      "name"  : "dev",         
      "email" : "terraformtestcicd+dev@gmail.com",
      "has_access_to_billing" : "DENY",
      "ou_name" : "dev",
      "role_name" : "TerraformAutomationRole"
    },
    "audit_account" : {
      "name"  : "audit",         
      "email" : "terraformtestcicd+audit@gmail.com",
      "has_access_to_billing" : "ALLOW",
      "ou_name" : "audit",
      "role_name" : "TerraformAutomationRole"
    }
  }
}


locals {
    # Extract account ids
    audit_account_id = module.setup_organization.non_master_accounts[2].id
    prod_account_id = module.setup_organization.non_master_accounts[0].id
    dev_account_id = module.setup_organization.non_master_accounts[1].id
    # audit_account_id = coalesce([ for account in module.setup_organization.non_master_accounts[*]: account.name == "audit" ? account.id : null ])     
    # prod_account_id = coalesce([ for account in module.setup_organization.non_master_accounts[*]: account.name == "prod" ? account.id : null ])
    # dev_account_id = coalesce([ for account in module.setup_organization.non_master_accounts[*]: account.name == "dev" ? account.id : null ])
}

# Contul de audit trebuie sa devina delegated administrator
# pentru a putea colecta informatiile din toata organizatia
resource "aws_organizations_delegated_administrator" "audit" {
  account_id        = local.audit_account_id
  service_principal = "config.amazonaws.com"
}

# Este necesara crearea unui provider pentru fiecare cont
# pentru a putea face assume role in fiecare account in parte
provider "aws" {
  alias = "prod"
  assume_role {
    role_arn     = "arn:aws:iam::${local.prod_account_id}:role/TerraformAutomationRole"
    session_name = "terraform-ci-cd-prod-session"
  }
}

provider "aws" {
  alias = "dev"
  assume_role {
    role_arn     = "arn:aws:iam::${local.dev_account_id}:role/TerraformAutomationRole"
    session_name = "terraform-ci-cd-prod-session"
  }
}

provider "aws" {
  alias = "audit"
  assume_role {
    role_arn     = "arn:aws:iam::${local.audit_account_id}:role/TerraformAutomationRole"
    session_name = "terraform-ci-cd-prod-session"
  }
}

module "setup_config_prod" {
  source = "github.com/roxanapopa97/aws-config?ref=v0.1"
  providers = {
    aws = aws.prod
  }
  create_conformance_pack = false
  create_aggregator       = false
  setup_config            = true
  aws_config_bucket_name  = "aws-config-bucket-${local.prod_account_id}"
}

module "setup_config_dev" {
  source = "github.com/roxanapopa97/aws-config?ref=v0.1"
  providers = {
    aws = aws.dev
  }
  create_conformance_pack = false
  create_aggregator       = false
  setup_config            = true
  aws_config_bucket_name  = "aws-config-bucket-${local.dev_account_id}"
}

module "setup_config_audit" {
  source = "github.com/roxanapopa97/aws-config?ref=v0.1"
  providers = {
    aws = aws.audit
  }
  create_conformance_pack = false
  create_aggregator       = false
  setup_config            = true
  aws_config_bucket_name  = "aws-config-bucket-${local.audit_account_id}"
}

module "deploy_config_aggregator" {
  source = "github.com/roxanapopa97/aws-config?ref=v0.1"
  providers = {
    aws = aws.audit
  }
  create_conformance_pack = false
  create_aggregator       = true
  setup_config            = false
}