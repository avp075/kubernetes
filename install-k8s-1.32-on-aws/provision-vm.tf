provider "aws" {
  region = "us-east-1" 
}

resource "aws_instance" "controlplane" {
  ami           = "ami-0f9de6e2d2f067fca"
  instance_type = "t3.2xlarge"
  key_name      = "bastion-host-key"
  security_groups = ["controlplane"]
  iam_instance_profile = aws_iam_instance_profile.ec2_s3_profile.name

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
              aws s3 cp /home/ubuntu/.kube/config s3://kubeconfig-bucket-avp/kubeconfig
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
  iam_instance_profile = aws_iam_instance_profile.ec2_s3_profile.name

  root_block_device {
    volume_size = 30
  }

  user_data = <<-EOF
              #!/bin/bash
              exec > /var/log/user-data.log 2>&1
              hostnamectl set-hostname worker${count.index + 1}
              sudo apt update ; sudo apt install -y awscli
              mkdir -p /home/ubuntu/.kube
              aws s3 cp s3://kubeconfig-bucket-avp/kubeconfig /home/ubuntu/.kube/config
              chown -R ubuntu:ubuntu /home/ubuntu/.kube
              chmod 644 /home/ubuntu/.kube/config
              export KUBECONFIG=/home/ubuntu/.kube/config
              git clone https://github.com/avp075/kubernetes.git ; cd kubernetes/install-k8s-1.32-on-aws
              chmod +x setup-workernode.sh
              ./setup-workernode.sh
              EOF

tags = {
    Name = "worker${count.index + 1}"
  }

}

resource "aws_iam_role" "ec2_s3_role" {
  name = "ec2-s3-full-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "ec2-s3-full-access-profile"
  role = aws_iam_role.ec2_s3_role.name
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