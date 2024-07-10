output "public_ip_master" {
  value = aws_instance.sample[0].public_ip
}

output "public_ip_node" {
  value = aws_instance.sample[1].public_ip
}

output "private_ip_master" {
  value = aws_instance.sample[0].private_ip 
}

output "private_ip_node" {
  value = aws_instance.sample[1].private_ip
}