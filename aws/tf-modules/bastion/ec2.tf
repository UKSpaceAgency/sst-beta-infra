resource "aws_instance" "bastion" {

  instance_type          = "t2.micro"
  ami                    = "ami-0a242269c4b530c5e"
  key_name               = "go_keypair"
  vpc_security_group_ids = var.vpc_security_group_ids
  subnet_id              = var.public_subnet_id
  tags                   = {
    Name = "bastion-host-for-${var.env_name}"
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 100
    volume_type = "gp2"
    delete_on_termination = true
  }
}