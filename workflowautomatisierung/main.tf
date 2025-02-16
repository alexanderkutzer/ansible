provider "aws" {
  region = "eu-central-1"
}

# SSH-Keypair
# Erst private key erstellen:
resource "tls_private_key" "ansible-key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

# Dann AWS Key pair aus dem public key attribute des private keys:
resource "aws_key_pair" "ansible_key_pair" {
  key_name = "ec2-access"
  public_key = tls_private_key.ansible-key.public_key_openssh
}

# Den privaten Schlüsel lokal speichern:
resource "local_file" "ansible-private_key" {
  content = tls_private_key.ansible-key.private_key_pem
  filename = "ansible-key.pem"
  file_permission = 600
}

# --- SECURITY GROUP ---
resource "aws_security_group" "ansible-sg" {
  name = "Ansible SG"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ansible-ec2" {
  count = 3
  ami = "ami-0c8db01b2e8e5298d"
  instance_type = "t2.micro"
  key_name = aws_key_pair.ansible_key_pair.key_name
  security_groups = [aws_security_group.ansible-sg.name]

  tags = {
    Name = "Ansible-instance-no${count.index}"
  }
}

output "ip_adresses" {
  value = aws_instance.ansible-ec2[*].public_ip
}
