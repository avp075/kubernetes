provider "aws" {
  region = "us-east-2" 
}

resource "aws_instance" "controlplane" {
  #ami          = "ami-0f9de6e2d2f067fca" # us-east-1
  ami          = "ami-0cfde0ea8edd312d4" # us-east-2
  instance_type = "t3.2xlarge"
  key_name      = "bastion-host-key"
  security_groups = ["master-sg"]

  root_block_device {
    volume_size = 50
  }

  user_data = file("${path.module}/setup-masternode.sh")

  tags = {
    Name = "master"
  }
}

resource "aws_instance" "worker" {
  count         = 3
  #ami          = "ami-0f9de6e2d2f067fca" # us-east-1
  ami          = "ami-0cfde0ea8edd312d4" # us-east-2
  instance_type = "t3.2xlarge"
  key_name     = "bastion-host-key"
  security_groups = ["worker-sg"]

  root_block_device {
    volume_size = 50
  }


  user_data = file("${path.module}/setup-workernode.sh")

  tags = {
    Name = "worker${count.index + 1}"
  }
}

output "controlplane_ssh" {
  description = "SSH command for controlplane"
  value       = "ssh -o StrictHostKeyChecking=no -i bastion-host-key.pem ubuntu@${aws_instance.controlplane.public_ip}"
}

output "worker_ssh_commands" {
  description = "SSH commands for worker nodes"
  value = [
    for i in aws_instance.worker : "ssh -o StrictHostKeyChecking=no -i bastion-host-key.pem ubuntu@${i.public_ip}"
  ]
}