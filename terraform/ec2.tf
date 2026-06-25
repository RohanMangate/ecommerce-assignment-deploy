# -----------------------------------------------
# Data source: Latest Ubuntu 22.04 AMI
# -----------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -----------------------------------------------
# EC2 Instance
# -----------------------------------------------
resource "aws_instance" "ecommerce_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.ecommerce_sg.id]
  associate_public_ip_address = true

  # Ensure enough storage for Docker images
  root_block_device {
    volume_size = 25
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/user_data.sh", {
    dockerhub_username = var.dockerhub_username
  })

  tags = {
    Name = "ecommerce-server"
  }
}
