#resource "aws_organizations_account" "account1" {
#  name      = "onthespotsecurity-security"
#  email     = "jcase311+newawsaccount@gmail.com"
#  role_name = "OrganizationAccountAccessRole"
#  iam_user_access_to_billing = "DENY"
#}

#resource "aws_organizations_account" "security" {
#  name      = "onthespotsecurity-securitylogging"
#  email     = "jcase311+awssecuritylogging@gmail.com"
#  role_name = "OrganizationAccountAccessRole"
#  iam_user_access_to_billing = "DENY"
#}

#create new ones with better names for security

resource "aws_organizations_account" "security" {
  name      = "security"
  email     = "jcase311+security@gmail.com"
  role_name = "OrganizationAccountAccessRole"
  iam_user_access_to_billing = "ALLOW"
}
