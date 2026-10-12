# image
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"]
}

# IAM role for Session Manager
resource "aws_iam_role" "adm" {
  name = "adm"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# setting up IAM
resource "aws_iam_role_policy_attachment" "adm-attach" {
  role       = aws_iam_role.adm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "adm-profile" {
  name = "adm_profile"
  role = aws_iam_role.adm.name
}

resource "aws_ssm_document" "session_preferences" {
  name          = "SSM-SessionManagerRunShell"
  document_type = "Session"

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "sh to bash"
    sessionType   = "Standard_Stream"
    inputs = {
      shellProfile = {
        linux   = "exec /bin/bash"
        windows = ""
      }
    }
  })
}

# security groups
resource "aws_security_group" "server_sg_tf" {
  name   = "server-sg-tf"
  vpc_id = var.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "allow_all_egress" {
  security_group_id = aws_security_group.server_sg_tf.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.server_sg_tf.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.server_sg_tf.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443
}


# s3 bucket
resource "aws_s3_bucket" "data" {
  bucket        = "adm-bucket-ddtemp71h-1"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "data_access" {
  bucket = aws_s3_bucket.data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "data_lifecycle" {
  bucket = aws_s3_bucket.data.id

  rule {
    id     = "expire-temp-files"
    status = "Enabled"

    filter {}

    expiration {
      days = 1
    }
  }

  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

# instance
resource "aws_instance" "app_server" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.adm-profile.name

  vpc_security_group_ids = [aws_security_group.server_sg_tf.id]
  subnet_id              = var.subnet_id

  tags = {
    Name    = "k3s-platform-server"
    Project = "k3s-platform"
    Role    = "k3s-server"
  }
}