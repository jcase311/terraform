provider "aws" {
  region = "us-east-1"
}


# Create the organization (or reference existing if already created)
resource "aws_organizations_organization" "org" {
  feature_set = "ALL"
}

data "aws_organizations_organization" "org" {}


# Organizational Units
resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "devops" {
  name      = "DevOps"
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "dev" {
  name      = "Development"
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "prod" {
  name      = "Production"
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "management" {
  name      = "Management"
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

# Region restriction SCP
resource "aws_organizations_policy" "restrict_regions" {
  name        = "AllowOnlyUSEast"
  description = "Deny access to non-US-East regions"
  type        = "SERVICE_CONTROL_POLICY"
  content     = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "DenyOtherRegions",
        Effect = "Deny",
        Action = "*",
        Resource = "*",
        Condition = {
          StringNotEqualsIfExists = {
            "aws:RequestedRegion" = ["us-east-1", "us-east-2"]
          }
        }
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "restrict_regions_root" {
  policy_id = aws_organizations_policy.restrict_regions.id
  target_id = data.aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_policy" "deny_cloudshell" {
  name        = "DenyCloudShell"
  description = "Block access to AWS CloudShell"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "DenyCloudShellUsage",
        Effect = "Deny",
        Action = [
          "cloudshell:*"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_organizations_policy" "deny_kms_key_deletion" {
  name        = "DenyKMSKeyDeletion"
  description = "Prevent accidental or malicious KMS key deletion"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "DenyKMSDeletion",
        Effect = "Deny",
        Action = [
          "kms:ScheduleKeyDeletion",
          "kms:DisableKey"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_organizations_policy" "deny_iam_access_keys" {
  name        = "DenyAccessKeyCreation"
  description = "Block access key creation for IAM users"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "DenyAccessKeyCreation",
        Effect = "Deny",
        Action = [
          "iam:CreateAccessKey",
          "iam:UpdateAccessKey"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_organizations_policy" "deny_internet_gateway" {
  name        = "DenyInternetGatewayCreation"
  description = "Prevent creation of internet gateways"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "DenyIGWCreation",
        Effect = "Deny",
        Action = [
          "ec2:CreateInternetGateway",
          "ec2:AttachInternetGateway"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_organizations_policy" "deny_console_login_without_mfa" {
  name        = "DenyConsoleLoginWithoutMFA"
  description = "Deny all AWS Management Console actions if MFA is not used"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "DenyIfNoMFA",
        Effect = "Deny",
        Action = "*",
        Resource = "*",
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent": "false"
          }
        }
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "deny_console_login_without_mfa_attach" {
  policy_id = aws_organizations_policy.deny_console_login_without_mfa.id
  target_id = data.aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_policy" "deny_public_db_access" {
  name        = "DenyPublicDBAccess"
  description = "Deny creation or modification of Redshift and RDS clusters with public accessibility"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "DenyPublicRDSAccess",
        Effect = "Deny",
        Action = [
          "rds:CreateDBInstance",
          "rds:ModifyDBInstance",
          "rds:CreateDBCluster",
          "rds:ModifyDBCluster"
        ],
        Resource = "*",
        Condition = {
          BoolIfExists = {
            "rds:PubliclyAccessible": "true"
          }
        }
      },
      {
        Sid    = "DenyPublicRedshiftAccess",
        Effect = "Deny",
        Action = [
          "redshift:CreateCluster",
          "redshift:ModifyCluster"
        ],
        Resource = "*",
        Condition = {
          BoolIfExists = {
            "redshift:PubliclyAccessible": "true"
          }
        }
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "deny_public_db_access_root" {
  policy_id = aws_organizations_policy.deny_public_db_access.id
  target_id = data.aws_organizations_organization.org.roots[0].id
}


#allow cloudtrail
resource "null_resource" "enable_cloudtrail_org_access" {
  provisioner "local-exec" {
    command = "aws organizations enable-aws-service-access --service-principal cloudtrail.amazonaws.com"
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}

#allow securitylake
resource "null_resource" "enable_securitylake_org_access" {
  provisioner "local-exec" {
    command = "aws organizations enable-aws-service-access --service-principal securitylake.amazonaws.com"
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}


#allow account management
resource "null_resource" "enable_accountmanagement_org_access" {
  provisioner "local-exec" {
    command = "aws organizations enable-aws-service-access --service-principal account.amazonaws.com"
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}
