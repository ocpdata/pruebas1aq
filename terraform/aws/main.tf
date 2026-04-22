data "aws_ssm_parameter" "al2023" {
  name = var.ami_ssm_parameter
}

resource "aws_key_pair" "arcadia" {
  key_name   = var.key_pair_name
  public_key = var.ssh_public_key
}

resource "aws_security_group" "arcadia" {
  name        = "${var.instance_name}-sg"
  description = "Access for the Arcadia lab instance"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_ingress_cidrs
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ingress_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "arcadia_ssm" {
  name = "${var.instance_name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.arcadia_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "arcadia" {
  name = "${var.instance_name}-profile"
  role = aws_iam_role.arcadia_ssm.name
}

resource "aws_instance" "arcadia" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.arcadia.id]
  iam_instance_profile        = aws_iam_instance_profile.arcadia.name
  key_name                    = aws_key_pair.arcadia.key_name

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/user_data.tftpl", {
    arcadia_repo_url = var.arcadia_repo_url
    arcadia_repo_ref = var.arcadia_repo_ref
  })

  tags = {
    Name = var.instance_name
  }
}
