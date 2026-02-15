#!/usr/bin/env bash
set -e

if [ "$#" -eq 0 ]; then
  echo "----------------------------------------"
  echo "Infrastructure Tool Versions"
  echo "----------------------------------------"

  echo -n "OpenTofu:     "
  tofu --version | head -n 1

  echo -n "Terraform:    "
  terraform --version | head -n 1

  echo -n "Terragrunt:   "
  terragrunt --version | head -n 1

  echo -n "AWS CLI:      "
  aws --version
  
  echo -n "Session Manager Version:      "
  session-manager-plugin --version

  echo "----------------------------------------"
  exit 0
fi

# If command is passed → execute it directly
exec "$@"