#!/bin/sh
set -eu

usage() {
  cat <<'USAGE'
Usage:
  ./deploy-root-account.sh plan
  ./deploy-root-account.sh apply

Environment variables:
  DRATA_EXTERNAL_ID            Default: 5c6e3f31-9295-4753-9199-d3cfa1d6bda8
  STACKSET_REGION              Default: us-west-2
  STACK_SET_NAME               Default: drata-role-terraform-stack-set
  DRATA_AWS_ACCOUNT_ID         Default: 269135526815
  ACCOUNT_FILTER_TYPE          Default: UNION

  This script deploys to all accounts in hardcoded OUs:
  - ou-2vnf-7sz2mtcb (PRODUCTION)
  - ou-2vnf-4b1j7jgx (TENANT / clients)
  Plus hardcoded additional account IDs:
  - 216569733182 (SharedService.DevOps.Prod)
  - 400516939372 (SharedService.Networking.Prod)

  AWS_PROFILE                  Default: Labs-Root-Administrator
  AWS_REGION                   Default: ap-southeast-2
  TF_STATE_BUCKET              Default: 603033204797-tf-state
  TF_LOCK_TABLE                Default: 603033204797-tf-lock
  TF_STATE_KEY                 Default: security/drata-stackset-role/terraform.tfstate
USAGE
}

if [ "${1:-}" = "" ]; then
  usage
  exit 1
fi

ACTION="$1"
case "$ACTION" in
  plan|apply) ;;
  *)
    usage
    exit 1
    ;;
esac

TF_STATE_BUCKET="${TF_STATE_BUCKET:-603033204797-tf-state}"
TF_LOCK_TABLE="${TF_LOCK_TABLE:-603033204797-tf-lock}"
AWS_PROFILE="${AWS_PROFILE:-Labs-Root-Administrator}"
AWS_REGION="${AWS_REGION:-ap-southeast-2}"
TF_STATE_KEY="${TF_STATE_KEY:-security/drata-stackset-role/terraform.tfstate}"

DRATA_EXTERNAL_ID="${DRATA_EXTERNAL_ID:-5c6e3f31-9295-4753-9199-d3cfa1d6bda8}"
STACKSET_REGION="${STACKSET_REGION:-us-west-2}"
STACK_SET_NAME="${STACK_SET_NAME:-drata-role-terraform-stack-set}"
DRATA_AWS_ACCOUNT_ID="${DRATA_AWS_ACCOUNT_ID:-269135526815}"
ACCOUNT_FILTER_TYPE="${ACCOUNT_FILTER_TYPE:-UNION}"
ORGANIZATIONAL_UNIT_IDS='["ou-2vnf-7sz2mtcb","ou-2vnf-4b1j7jgx"]'
TARGET_ACCOUNT_IDS='["216569733182","400516939372"]'

export AWS_PROFILE
export AWS_REGION

terraform init -reconfigure \
  -backend-config="bucket=${TF_STATE_BUCKET}" \
  -backend-config="key=${TF_STATE_KEY}" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="profile=${AWS_PROFILE}" \
  -backend-config="encrypt=true" \
  -backend-config="dynamodb_table=${TF_LOCK_TABLE}"

terraform validate

set -- terraform "$ACTION" \
  -var="role_sts_externalid=${DRATA_EXTERNAL_ID}" \
  -var="stackset_region=${STACKSET_REGION}" \
  -var="stack_set_name=${STACK_SET_NAME}" \
  -var="drata_aws_account_id=${DRATA_AWS_ACCOUNT_ID}" \
  -var="account_filter_type=${ACCOUNT_FILTER_TYPE}" \
  -var="organizational_unit_ids=${ORGANIZATIONAL_UNIT_IDS}" \
  -var="target_account_ids=${TARGET_ACCOUNT_IDS}"

"$@"
