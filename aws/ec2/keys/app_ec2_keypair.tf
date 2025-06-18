
provider "tls" {}
provider "local" {}
provider "aws" {
  region = "us-east-2"
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "app"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "private_key" {
  content              = tls_private_key.ssh_key.private_key_pem
  filename             = "/Users/jcase/.ssh/app.pem"
  file_permission      = "0600"
  directory_permission = "0700"
}
