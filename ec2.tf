data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "twk" {
  key_name   = var.ssh_key_name
  public_key = var.ssh_public_key
  tags       = var.tags
}

resource "aws_instance" "dev" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  availability_zone      = var.az
  key_name               = aws_key_pair.twk.key_name
  subnet_id              = aws_subnet.dev.id
  vpc_security_group_ids = [aws_security_group.dev.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = var.system_disk_size
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required" # IMDSv2 only
  }

  tags = merge(var.tags, { Name = var.instance_name })

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [ami] # avoid replacement when a newer Ubuntu AMI appears
  }
}

resource "aws_ebs_volume" "data" {
  availability_zone = var.az
  type              = "gp3"
  size              = var.data_disk_size
  encrypted         = true
  tags              = merge(var.tags, { Name = "${var.instance_name}-data" })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_volume_attachment" "data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.dev.id
}

resource "aws_eip" "dev" {
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.env_prefix}-dev-eip" })

  depends_on = [aws_internet_gateway.twk]
}

resource "aws_eip_association" "dev" {
  allocation_id = aws_eip.dev.id
  instance_id   = aws_instance.dev.id
}
