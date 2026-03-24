# aws-cloudformation-drata-setup

AWS Cloudformation terraform script to create the Drata Autopilot role across an Organizational Unit.
***NOTE:*** Make sure you run this script with the management account credentials.

_Optionally you may create the CloudFormation StackSet directly in the console, download the [json template](https://github.com/drata/aws-cloudformation-drata-setup/blob/main/drata_cloudformation_stackset_template.json) and upload it as a template resource._

## Root Account Deployment Script

This fork includes `./deploy-root-account.sh` to run `terraform init` (S3 backend), `validate`, and `plan`/`apply` from the management account.

The script currently targets all accounts in hardcoded OUs:
- `ou-2vnf-7sz2mtcb` (PRODUCTION)
- `ou-2vnf-4b1j7jgx` (TENANT / clients)

It also includes additional hardcoded account IDs:
- `216569733182` (`SharedService.DevOps.Prod`)
- `400516939372` (`SharedService.Networking.Prod`)

### Usage

```sh
./deploy-root-account.sh plan
./deploy-root-account.sh apply
```

### Optional Environment Overrides

- `DRATA_EXTERNAL_ID` (default: `5c6e3f31-9295-4753-9199-d3cfa1d6bda8`)
- `STACKSET_REGION` (default: `us-west-2`)
- `STACK_SET_NAME` (default: `drata-role-terraform-stack-set`)
- `DRATA_AWS_ACCOUNT_ID` (default: `269135526815`)
- `ACCOUNT_FILTER_TYPE` (default: `UNION`)
- `AWS_PROFILE` (default: `Labs-Root-Administrator`)
- `AWS_REGION` (default: `ap-southeast-2`)
- `TF_STATE_BUCKET` (default: `603033204797-tf-state`)
- `TF_LOCK_TABLE` (default: `603033204797-tf-lock`)
- `TF_STATE_KEY` (default: `security/drata-stackset-role/terraform.tfstate`)

## Example Usage

The example below uses `ref=main` (which is appended in the URL),  but it is recommended to use a specific tag version (i.e. `ref=1.0.0`) to avoid breaking changes. Go to the [release page](https://github.com/drata/aws-cloudformation-drata-setup/releases) for a list of published versions.

Replace `YOUR_EXTERNAL_ID` with the external id provided in the Drata UI. i.e. `00000000-0000-0000-0000-000000000000`.

```terraform
module "drata_role_cloudformation_stacksets" {
    source = "git::https://github.com/drata/aws-cloudformation-drata-setup.git?ref=main"
    role_sts_externalid = "YOUR_EXTERNAL_ID"

    # Optional: Change the default region (default: us-west-2)
    # stackset_region = "us-east-1"

    # Optional: Specify organizational units (default: organization root)
    # organizational_unit_ids = ["ou-xxxx-xxxxxxxx", "ou-yyyy-yyyyyyyy"]

    # Optional: Target specific account IDs
    # target_account_ids = ["123456789012", "234567890123"]

    # Optional: Control account filtering behavior (default: INTERSECTION)
    # account_filter_type = "INTERSECTION"  # Options: NONE, INTERSECTION, DIFFERENCE, UNION

    # Optional: Customize the StackSet name (default: drata-role-terraform-stack-set)
    # stack_set_name = "my-custom-drata-stackset"

    # Optional: Apply custom tags to resources
    # tags = {
    #   Environment = "production"
    #   Team        = "security"
    #   CostCenter  = "compliance"
    # }

    # Optional: Override Drata's AWS account ID (rarely needed)
    # drata_aws_account_id = "269135526815"
}
```



## Setup

The following steps will guide you on how to run this script.

1. Add the code above to your terraform code.
2. Replace `main` in `ref=main` with the latest version from the [release page](https://github.com/drata/aws-cloudformation-drata-setup/releases).
3. In your browser, open [https://app.drata.com/account-settings/connections/connection?provId=AWS_ORG_UNITS](https://app.drata.com/account-settings/connections/connection?provId=AWS_ORG_UNITS&provTypeSelected=Infrastructure&activeTab=browse&q=aws%20org&page=1).
4. Copy the `Drata External ID` from the AWS Org Units connection panel in Drata and replace `YOUR_EXTERNAL_ID` in the module with the ID you copied.
5. Replace `stackset_region` if the desired region is different than the default value `us-west-2`.
6. **Configure Organizational Units (Optional)**: If you don't wish to assign the role to all accounts in your organization, specify the organizational unit IDs in `organizational_unit_ids`. If omitted, defaults to the organization root.
7. **Target Specific Accounts (Optional)**: To target specific AWS account IDs, add them to `target_account_ids`. Account IDs must be exactly 12 digits. See "Account Targeting Options" below for details on how this interacts with `organizational_unit_ids`.
8. **Configure Account Filtering (Optional)**: When both `organizational_unit_ids` and `target_account_ids` are specified, use `account_filter_type` to control the filtering behavior:
   - `INTERSECTION` (default): Deploy only to specified accounts that exist within the specified OUs
   - `UNION`: Deploy to all accounts in the OUs plus the specified accounts
   - `DIFFERENCE`: Deploy to all accounts in the OUs except the specified accounts
   - `NONE`: Deploy to all accounts in the specified OUs (ignores `target_account_ids`)
9. **Apply Custom Tags (Optional)**: Add custom tags to `tags` if you want to apply them to the StackSet and StackSet Instances resources. Note: Tags are applied to Terraform-managed resources but not to the IAM role created by the CloudFormation template.
10. **Customize StackSet Name (Optional)**: If you need to avoid naming conflicts or prefer a different name, set `stack_set_name`. The default is `drata-role-terraform-stack-set`.
11. **Override Drata Account ID (Rarely Needed)**: `drata_aws_account_id` shouldn't be changed as the default value is sufficient for most use cases.
12. Back in your terminal, run `terraform init` to download/update the module.
13. Run `terraform apply` and **IMPORTANT** review the plan output before typing yes.
14. If successful, go back to the AWS console and verify the Role has been generated in all the target accounts.
15. If you want to roll back the operations this script just performed, type `terraform destroy` and `enter`.

## Account Targeting Options

This module provides flexible options for targeting AWS accounts with fine-grained control over deployment scope.

### Default Behavior (No Configuration)
- When neither `organizational_unit_ids` nor `target_account_ids` is specified, the StackSet targets **all accounts** in your AWS organization (uses the organization root)

### Organizational Unit Targeting
- Set `organizational_unit_ids` to target specific organizational units
- Example: `organizational_unit_ids = ["ou-xxxx-xxxxxxxx", "ou-yyyy-yyyyyyyy"]`
- The StackSet will deploy to all accounts within the specified OUs

### Specific Account Targeting
- This option can only be used in conjunction with `organizational_unit_ids`.
- Set `target_account_ids` to target specific AWS account IDs
- Example: `target_account_ids = ["123456789012", "234567890123"]`
- Account IDs must be exactly 12 digits
- When used alone (without `organizational_unit_ids`), deploys only to the specified accounts

### Combined Targeting with Account Filtering

When both `organizational_unit_ids` and `target_account_ids` are provided, use `account_filter_type` to control the deployment behavior:

#### `INTERSECTION` (Default - Recommended)
- Deploys **only** to accounts that are:
  1. Listed in `target_account_ids` **AND**
  2. Exist within the specified `organizational_unit_ids`
- **Use case**: "Deploy to these specific accounts, but only if they're in these OUs"
- **Example**: Target production accounts within the security OU

#### `UNION`
- Deploys to accounts that are:
  1. In the specified `organizational_unit_ids` **OR**
  2. Listed in `target_account_ids`
- **Use case**: "Deploy to all accounts in these OUs, plus these additional specific accounts"
- **Example**: All dev OU accounts plus a few specific test accounts outside the OU

#### `DIFFERENCE`
- Deploys to accounts that are:
  1. In the specified `organizational_unit_ids` **BUT NOT**
  2. Listed in `target_account_ids`
- **Use case**: "Deploy to all accounts in these OUs except these specific ones"
- **Example**: All accounts in production OU except the legacy account

#### `NONE`
- Deploys to **all accounts** in the specified `organizational_unit_ids`
- Ignores `target_account_ids` completely
- **Use case**: When you want to explicitly ignore account filtering

### Tagging
- Use the `tags` variable to apply custom tags to the StackSet and StackSet Instances resources
- Tags help with cost allocation, resource organization, and compliance tracking
- **Important**: Tags are applied to the Terraform-managed CloudFormation resources (StackSet and StackSet Instances) but **not** to the IAM role created by the CloudFormation template itself

### Examples

**Example 1: All accounts in organization (default)**
```terraform
module "drata_role_cloudformation_stacksets" {
    source = "git::https://github.com/drata/aws-cloudformation-drata-setup.git?ref=main"
    role_sts_externalid = "YOUR_EXTERNAL_ID"
}
```

**Example 2: Specific organizational units only**
```terraform
module "drata_role_cloudformation_stacksets" {
    source = "git::https://github.com/drata/aws-cloudformation-drata-setup.git?ref=main"
    role_sts_externalid = "YOUR_EXTERNAL_ID"
    organizational_unit_ids = ["ou-prod-12345678", "ou-staging-87654321"]
}
```

**Example 3: Specific accounts within OUs (default Intersectionbehavior)**
```terraform
module "drata_role_cloudformation_stacksets" {
    source = "git::https://github.com/drata/aws-cloudformation-drata-setup.git?ref=main"
    role_sts_externalid = "YOUR_EXTERNAL_ID"
    organizational_unit_ids = ["ou-prod-12345678"]
    target_account_ids = ["123456789012", "234567890123"] # Only these accounts if they're in the prod OU
    account_filter_type = "INTERSECTION" # Note: This is the default behavior and is shown here for clarity
}
```

**Example 4: All accounts in specified OUs that are NOT within provided list**
```terraform
module "drata_role_cloudformation_stacksets" {
    source = "git::https://github.com/drata/aws-cloudformation-drata-setup.git?ref=main"
    role_sts_externalid = "YOUR_EXTERNAL_ID"
    organizational_unit_ids = ["ou-prod-12345678"]
    target_account_ids = ["123456789012", "234567890123"] # Accounts to exclude from deployment
    account_filter_type = "DIFFERENCE" # Deploy stacks to all accounts in the prod OU except for specific accounts.
}
```

**Example 5: With custom tags**
```terraform
module "drata_role_cloudformation_stacksets" {
    source = "git::https://github.com/drata/aws-cloudformation-drata-setup.git?ref=main"
    role_sts_externalid = "YOUR_EXTERNAL_ID"
    tags = {
        Environment = "production"
        Team        = "security"
        Compliance  = "drata"
        CostCenter  = "security-ops"
    }
}
```

## Disclaimer

AWS CloudFormation StackSets isn't able to create resources under the management account. If you wish to create the `DrataAutopilotRole` in the management account you can use this [repo](https://github.com/drata/terraform-aws-drata-autopilot-role) or create it manually following our [help documentation](https://help.drata.com/en/articles/5048935-aws-connection-details#h_caf5c48b5d).

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudformation_stack_set.stack_set](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set) | resource |
| [aws_cloudformation_stack_instances.instances](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_instances) | resource |
| [aws_organizations_organization.organization](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_filter_type"></a> [account\_filter\_type](#input\_account\_filter\_type) | The type of account filter to apply when both organizational_unit_ids and target_account_ids are specified: NONE, INTERSECTION, DIFFERENCE, or UNION | `string` | `"INTERSECTION"` | no |
| <a name="input_drata_aws_account_id"></a> [drata\_aws\_account\_id](#input\_drata\_aws\_account\_id) | Drata's AWS account ID | `string` | `"269135526815"` | no |
| <a name="input_organizational_unit_ids"></a> [organizational\_unit\_ids](#input\_organizational\_unit\_ids) | Organizational Unit Ids to assign the role to. | `list(string)` | `null` | no |
| <a name="input_role_sts_externalid"></a> [role\_sts\_externalid](#input\_role\_sts\_externalid) | Drata External ID from the Drata UI. | `string` | n/a | yes |
| <a name="input_stack_set_name"></a> [stack\_set\_name](#input\_stack\_set\_name) | Name of the CloudFormation StackSet. Change this if you need to avoid naming conflicts. | `string` | `"drata-role-terraform-stack-set"` | no |
| <a name="input_stackset_region"></a> [stackset\_region](#input\_stackset\_region) | Region where the stackset instance will be executed. | `string` | `"us-west-2"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to apply to all created resources. | `map(string)` | `{}` | no |
| <a name="input_target_account_ids"></a> [target\_account\_ids](#input\_target\_account\_ids) | List of specific account IDs to target. When provided, only these accounts will be targeted (in combination with organizational_unit_ids if specified). If null, all accounts in the specified OUs will be targeted. | `list(string)` | `null` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
