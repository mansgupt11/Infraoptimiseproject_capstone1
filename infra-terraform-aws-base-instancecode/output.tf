#Output of private IPs
output "public_ips_subnet1" {
  description = "k8s nodes public IPs"
  value       = [aws_instance.ec2-k8s.*.public_ip]
}

output "private_ips" {
  description = "K8s nodes private IPs"
  value       = [aws_instance.ec2-k8s.*.private_ip]
}

output "public_ips_master" {
  description = "Master Node Private IP"
  value       = [aws_instance.ec2-k8s-master.public_ip]
}

output "private_ip2_master" {
  description = "Master Node Private IP"
  value       = [aws_instance.ec2-k8s-master.private_ip]
}
