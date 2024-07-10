resource "aws_instance" "sample" {
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

resource "null_resource" "sample_master" {

  count = 1
  
  connection {
    user = "ec2-user"
    password = "DevOps321"
    host = aws_instance.sample[0].public_ip
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

  depends_on = [ aws_instance.sample[0] ]
}

resource "null_resource" "sample_node" {

  count = 1
  
  connection {
    user = "ec2-user"
    password = "DevOps321"
    host = aws_instance.sample[1].public_ip
  }

  provisioner "remote-exec" {
    inline = [ "sudo yum install fontconfig java-17-openjdk -y" ]
  }

  depends_on = [ aws_instance.sample[1] ]
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