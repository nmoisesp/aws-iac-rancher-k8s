output "rancher_server_private_ip" {
  value = aws_instance.rancher-server.private_ip
}

output "rancher_server_public_ip" {
  value = aws_instance.rancher-server.public_dns
}

output "ubuntu_image_id" {
  value = data.aws_ami.ubuntu.id
}

output "ssh_private_key_pem" {
  sensitive = true
  value     = tls_private_key.ssh.private_key_pem
}

output "ssh_public_key_pem" {
  sensitive = true
  value     = tls_private_key.ssh.public_key_pem
}

output "nat_gateway_ip" {
  value = aws_eip.eip-nat-gtw-k8s.public_ip
}