resource "aws_instance" "jenkins" {
  count = length(var.instance_names)
  ami = data.aws_ami.ami_id.id
  vpc_security_group_ids = [aws_security_group.allow_all.id]
  instance_type = "t2.micro"

  tags = merge(
      var.common_tags, 
      {
        Name = var.instance_names[count.index]
      }
  )

}

# resource "aws_key_pair" "tools" {
#   key_name = "tools"
#   public_key = file("~/.ssh/tools.pub")
# }

# module "nexus" {
#   source  = "terraform-aws-modules/ec2-instance/aws"

#   name = "nexus"

#   instance_type          = "t3.medium"
#   vpc_security_group_ids = [aws_security_group.allow_all.id]
#   ami = data.aws_ami.ami_id_Nexus.id
#   key_name = aws_key_pair.tools.key_name
#   root_block_device = [
#     {
#       volume_type = "gp3"
#       volume_size = 30
#     }
#   ]
#   tags = {
#     Name = "nexus"
#   }
# }

resource "null_resource" "jenkins_master" {

  count = 1
  
  connection {
    user = "ec2-user"
    password = "DevOps321"
    type = "ssh"
    host = aws_instance.jenkins[0].public_ip
  }

  provisioner "file" {
    source = "jenkins.repo"
    destination = "/home/ec2-user/jenkins.repo"
  }

  provisioner "remote-exec" {
    inline = [ "sudo mv /home/ec2-user/jenkins.repo /etc/yum.repos.d/jenkins.repo",
    "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key", 
    "sudo yum install fontconfig java-17-openjdk -y",
    "sudo yum install jenkins -y", "sudo systemctl enable jenkins", 
    "sudo systemctl start jenkins", "sudo systemctl daemon-reload" ]
  }

  provisioner "remote-exec" {
    inline = [ "sudo yum install fontconfig java-17-openjdk -y" ]
  }

  depends_on = [ aws_instance.jenkins[0] ]
}

resource "null_resource" "jenkins_node" {
  
triggers = {
  instance_id = aws_instance.jenkins[1]
}

  connection {
    user = "ec2-user"
    password = "DevOps321"
    type = "ssh"
    host = aws_instance.jenkins[1].public_ip
  }

  provisioner "remote-exec" {
    inline = [ "sudo yum install fontconfig java-17-openjdk -y",
    # Download Terraform
    "wget https://releases.hashicorp.com/terraform/1.5.3/terraform_1.5.3_linux_amd64.zip",

    # Unzip the downloaded package
    "unzip terraform_1.5.3_linux_amd64.zip",

    # Move the terraform binary to /usr/local/bin
    "sudo mv terraform /usr/local/bin/",

    # Verify the installation
    "terraform version",

    "sudo dnf module disable nodejs -y",
    "sudo dnf module enable nodejs:20 -y",
    "sudo dnf install nodejs -y" ]
  }

  depends_on = [ aws_instance.jenkins[1] ]
}

resource "aws_security_group" "allow_all" {
    name= "allow_all"
    description= "Allowing everything"
  
  ingress {
    from_port   = var.ingress_port_no
    to_port     = var.ingress_port_no
    protocol    = "-1"
    cidr_blocks = var.cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.cidr_blocks
  }

  tags = {
    Name= "allow_all"
  }
  
}