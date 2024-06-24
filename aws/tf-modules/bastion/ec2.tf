resource "aws_iam_role" "ec2_s3_full_access_role" {
  name = "ec2-s3-full-access-role"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "sts:AssumeRole"
          ],
          "Principal" : {
            "Service" : [
              "ec2.amazonaws.com"
            ]
          }
        }
      ]
    }

  )
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3FullAccess", "arn:aws:iam::aws:policy/AmazonECS_FullAccess"]
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "bastion_profile"
  role = aws_iam_role.ec2_s3_full_access_role.name
}

#resource "aws_instance" "bastion" {
#
#  instance_type          = "t2.micro"
#  ami                    = "ami-06464c878dbe46da4" //Amazon Linux 2023 AMI x86 64bit
#  key_name               = "go_keypair"
#  vpc_security_group_ids = var.vpc_security_group_ids
#  subnet_id              = var.public_subnet_id
#  iam_instance_profile   = aws_iam_instance_profile.bastion_profile.name
#  tags = {
#    Name = "bastion-host-for-${var.env_name}"
#  }
#
#  user_data = <<-EOF
#    #!/bin/bash
#    mkfs.ext4 /dev/sdf
#    mkdir /opt/data
#    mount /dev/sdf /opt/data
#    echo '/dev/sdf  /opt/data ext4 defaults 0 0' >> /etc/fstab
#    chown -R ec2-user:ec2-user /opt/data
#    yum install -y postgresql15
#    wget -O /etc/yum.repos.d/cloudfoundry-cli.repo https://packages.cloudfoundry.org/fedora/cloudfoundry-cli.repo
#    yum install -y cf8-cli
#    EOF
#}