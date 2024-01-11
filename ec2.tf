resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh" {
  key_name   = "ec2-ssh-keypair"
  public_key = tls_private_key.ssh.public_key_openssh

  provisioner "local-exec" {   
    command = <<-EOT
      echo '${tls_private_key.ssh.private_key_pem}' > ec2-ssh-keypair.txt
      chmod 400 ec2-ssh-keypair.txt
    EOT
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ubuntu_ami_name]
  }

  filter {
    name   = "architecture"
    values = [var.ubuntu_ami_architecture]
  }

  owners = [var.ubuntu_ami_owner]
}

resource "aws_instance" "rancher-server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.rancher_instance_type
  subnet_id                   = aws_subnet.public-subnet-rancher-server.id
  security_groups             = [aws_security_group.security-group-rancher-instance.id]
  key_name                    = aws_key_pair.ssh.key_name
  disable_api_termination     = false
  ebs_optimized               = false
  associate_public_ip_address = true

  root_block_device {
    volume_size = "20"
  }

  tags = {
    Name = var.rancher_instance_name
  }

  depends_on = [aws_security_group.security-group-rancher-instance, aws_subnet.public-subnet-rancher-server]
}

resource "aws_instance" "kubernetes-cluster" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.kubernates_instance_type
  subnet_id                   = aws_subnet.private-subnet-kubernetes-cluster.id
  security_groups             = [aws_security_group.security-group-k8s-instances.id]
  key_name                    = aws_key_pair.ssh.key_name
  disable_api_termination     = false
  ebs_optimized               = false
  associate_public_ip_address = false

  root_block_device {
    volume_size = "20"
  }

  for_each = {
    key_0 = "1"
    key_1 = "2"
    key_2 = "3"
  }

  tags = {
    Name = "${var.kubernates_instance_name}-${each.value}"
  }

  depends_on = [aws_security_group.security-group-k8s-instances, aws_subnet.private-subnet-kubernetes-cluster]
}