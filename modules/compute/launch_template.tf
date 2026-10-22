data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-minimal-*-kernel-6.12-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "terraform-3tier-${var.environment}-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [var.app_security_group_id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = data.aws_ami.amazon_linux.root_device_name

    ebs {
      volume_size           = 8
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -euxo pipefail

    cat > /opt/terraform-app.py <<'PYTHON'
    from http.server import BaseHTTPRequestHandler, HTTPServer

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            body = b"Hello from Terraform!"
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

    HTTPServer(("0.0.0.0", 80), Handler).serve_forever()
    PYTHON

    cat > /etc/systemd/system/terraform-app.service <<'SERVICE'
    [Unit]
    Description=Terraform demo web application
    After=network.target

    [Service]
    Type=simple
    ExecStart=/usr/bin/python3 /opt/terraform-app.py
    Restart=always
    RestartSec=3

    [Install]
    WantedBy=multi-user.target
    SERVICE

    systemctl daemon-reload
    systemctl enable --now terraform-app.service
  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "terraform-3tier-${var.environment}-app"
      Project     = "terraform-aws-3tier-app"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name        = "terraform-3tier-${var.environment}-app-volume"
      Project     = "terraform-aws-3tier-app"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }

  tags = {
    Name        = "terraform-3tier-${var.environment}-launch-template"
    Project     = "terraform-aws-3tier-app"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}
