provider "aws" {
  region = "us-east-1" 
}

resource "aws_instance" "controlplane" {
  ami           = "ami-0f9de6e2d2f067fca"
  instance_type = "t3.2xlarge"
  key_name      = "bastion-host-key"
  security_groups = ["controlplane"]
  iam_instance_profile = aws_iam_instance_profile.secrets_manager_profile.name

  root_block_device {
    volume_size = 30
  }

  user_data = <<-EOF
              #!/bin/bash
              exec > /var/log/user-data.log 2>&1
              sudo apt update ; sudo apt install -y awscli
              hostnamectl set-hostname controlplane
              git clone https://github.com/avp075/kubernetes.git ; cd kubernetes/install-k8s-1.32-on-aws
              chmod +x setup-masternode.sh
              ./setup-masternode.sh
              aws secretsmanager create-secret   --name my-kubeconfig   --secret-string file:///home/ubuntu/.kube/config   --region us-east-1
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
  iam_instance_profile = aws_iam_instance_profile.secrets_manager_profile.name

  root_block_device {
    volume_size = 30
  }

  user_data = <<-EOF
              #!/bin/bash
              exec > /var/log/user-data.log 2>&1
              hostnamectl set-hostname worker${count.index + 1}
              sudo apt update ; sudo apt install -y awscli
              sudo mkdir -p "/home/ubuntu/.kube/"
              sleep 20
              aws secretsmanager get-secret-value   --secret-id my-kubeconfig   --query SecretString   --output text   --region us-east-1 > /home/ubuntu/.kube/config
              chown ubuntu:ubuntu /home/ubuntu/.kube/config ; chmod 644 /home/ubuntu/.kube/config
              git clone https://github.com/avp075/kubernetes.git ; cd kubernetes/install-k8s-1.32-on-aws
              chmod +x setup-workernode.sh
              ./setup-workernode.sh
              EOF

tags = {
    Name = "worker${count.index + 1}"
  }

}

resource "aws_iam_role" "secrets_manager_role" {
  name = "ec2-secretsmanager-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_manager_access" {
  role       = aws_iam_role.secrets_manager_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_instance_profile" "secrets_manager_profile" {
  name = "ec2-secretsmanager-instance-profile"
  role = aws_iam_role.secrets_manager_role.name
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