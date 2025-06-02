provider "aws" {
  region = "us-east-1" 
}

resource "aws_instance" "controlplane" {
  ami           = "ami-0f9de6e2d2f067fca"
  instance_type = "t3.2xlarge"
  key_name      = "bastion-host-key"
  security_groups = ["controlplane"]

  root_block_device {
    volume_size = 30
  }

  user_data = <<-EOF
              #!/bin/bash
              exec > /var/log/user-data.log 2>&1
              hostnamectl set-hostname controlplane
              git clone https://github.com/avp075/kubernetes.git ; cd kubernetes/install-k8s-1.32-on-aws
              chmod +x setup-masternode.sh
              ./setup-masternode.sh
              EOF
  
  tags = {
    Name = "controlplane"
  }

} 

resource "aws_instance" "worker" {
  count         = 1
  ami          = "ami-0f9de6e2d2f067fca"
  instance_type = "t3.2xlarge"
  key_name     = "bastion-host-key"
  security_groups = ["workernode"]

  root_block_device {
    volume_size = 30
  }

  user_data = <<-EOF
              #!/bin/bash
              exec > /var/log/user-data.log 2>&1
              hostnamectl set-hostname worker${count.index + 1}
              git clone https://github.com/avp075/kubernetes.git ; cd kubernetes/install-k8s-1.32-on-aws
              chmod +x setup-workernode.sh
              ./setup-workernode.sh
              EOF

tags = {
    Name = "worker${count.index + 1}"
  }

}

output "controlplane_ssh" {
  description = "SSH command for controlplane"
  value       = "ssh -i bastion-host-key.pem ubuntu@${aws_instance.controlplane.public_ip}"
}

output "worker_ssh_commands" {
  description = "SSH commands for worker nodes"
  value = [
    for i in aws_instance.worker : "ssh -i bastion-host-key.pem ubuntu@${i.public_ip}"
  ]
}