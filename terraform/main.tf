provider "aws" {
  region     = "us-east-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/*20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = var.key_name
  security_groups = [aws_security_group.allow_ssh_http.name]

  tags = {
    Name = var.ec2_name
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y docker.io",
      "sudo curl -L \"https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "git clone https://github.com/Brilhante29/contact.git",
      "cd contact",
      "docker-compose up --build -d"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/app-ssh-key.pem")
      host        = self.public_ip
    }
  }
}

output "instance_id" {
  value = aws_instance.app_server.id
}

output "instance_public_ip" {
  value = aws_instance.app_server.public_ip
}

variable "aws_access_key" {
  description = "The AWS access key"
  type        = string
}

variable "aws_secret_key" {
  description = "The AWS secret key"
  type        = string
}

variable "key_name" {
  description = "The key name to use for the EC2 instance"
  type        = string
}

variable "ec2_name" {
  description = "The name to use for the EC2 instance"
  type        = string
}
