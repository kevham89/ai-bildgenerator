output "ec2_public_ip" {
  description = "Fast publik IP-adress för AI-bildgeneratorn"
  value       = aws_eip.web.public_ip
}

output "ec2_public_dns_name" {
  description = "Publikt DNS-namn för EC2-instansen"
  value       = aws_instance.web.public_dns
}

output "application_url" {
  description = "URL till AI-bildgeneratorn"
  value       = "http://${aws_eip.web.public_ip}"
}

output "ssh_command" {
  description = "SSH-kommando för att ansluta till servern"
  value       = "ssh -i keys/ec2kp.pem ec2-user@${aws_eip.web.public_ip}"
}
