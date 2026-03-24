terraform {
  backend "s3" {}
}

# get the organization info
data "aws_organizations_organization" "organization" {}

locals {
  json_template           = file("${path.module}/drata_cloudformation_stackset_template.json")
  # Default to organization root only if no OUs or accounts specified
  organizational_unit_ids = (
    var.organizational_unit_ids != null ? var.organizational_unit_ids :
    var.target_account_ids == null ? [data.aws_organizations_organization.organization.roots[0].id] : []
  )
  # Include target accounts only when specified
  target_account_ids = var.target_account_ids != null ? var.target_account_ids : []
}

# define the stack set
# this contains the role creation template
resource "aws_cloudformation_stack_set" "stack_set" {
  name             = var.stack_set_name
  permission_model = "SERVICE_MANAGED"
  capabilities     = ["CAPABILITY_NAMED_IAM"]
  auto_deployment {
    enabled = true
  }
  operation_preferences {
    failure_tolerance_count = 0
    max_concurrent_count    = 3
  }
  template_body = local.json_template
  parameters    = { DrataAWSAccountID : var.drata_aws_account_id, RoleSTSExternalID : var.role_sts_externalid }
  tags          = var.tags

  lifecycle {
    ignore_changes = [administration_role_arn]
  }
}

# apply the stack set to the entire organization using the root id
resource "aws_cloudformation_stack_set_instance" "instances" {
  deployment_targets {
    organizational_unit_ids = local.organizational_unit_ids
    accounts                = var.target_account_ids != null ? local.target_account_ids : null
    account_filter_type     = var.organizational_unit_ids != null && var.target_account_ids != null ? var.account_filter_type : null
  }
  stack_set_instance_region = var.stackset_region
  stack_set_name            = aws_cloudformation_stack_set.stack_set.name
}
