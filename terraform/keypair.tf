resource "aws_key_pair" "atlantic_key" {
  key_name   = "cargill-nginx-prod-keypair"
  public_key = "${file(var.ssh_public_key)}"

  provider = aws.atlantic
}
