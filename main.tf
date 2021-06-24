module "setup_organization" {
  source = "github.com/roxanapopa97/aws-organization?ref=v0.1"
  create_organization = true
  organizational_units = {
    "prod_organizational_unit" : {
      "name"      : "prod",
    },
    "dev_organizational_unit" : {
      "name"      : "dev",
    },
    "audit_organizational_unit" : {
      "name"      : "audit",
    }
  }
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

# Extract audit account id
locals {
    audit_account_id = coalesce([ for account in module.setup_organization.non_master_accounts[*]: account.name == "audit" ? account.id : null ])     
}

resource "aws_organizations_delegated_administrator" "audit" {
  account_id        = local.audit_account_id
  service_principal = "config.amazonaws.com"
}
