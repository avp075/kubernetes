provider "aws" {
  region = "us-east-1" 
}

resource "aws_instance" "controlplane" {
  ami           = "ami-0f9de6e2d2f067fca"
  instance_type = "t3.2xlarge"
  key_name      = "bastion-host-key.pem"
  security_groups = ["controlplane"]

  root_block_device {
    volume_size = 30
  }

  user_data = <<-EOF
              #!/bin/bash
              hostnamectl set-hostname controlplane
              chmod +x /home/ubuntu/master.sh
              /home/ubuntu/master-setup.sh
              EOF

  tags = {
    Name = "controlplane"
  }
}

resource "aws_instance" "worker" {
  count         = 3
  ami          = "ami-0f9de6e2d2f067fca"
  instance_type = "t3.2xlarge"
  key_name     = "bastion-host-key.pem"
  security_groups = ["workernode"]

  root_block_device {
    volume_size = 30
  }

  user_data = <<-EOF
              #!/bin/bash
              hostnamectl set-hostname worker${count.index + 1}
              chmod +x /home/ubuntu/worker.sh
              /home/ubuntu/worker-setup.sh
              EOF

  tags = {
    Name = "worker${count.index + 1}"
  }
}
