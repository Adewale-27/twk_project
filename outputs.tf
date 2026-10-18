output "vpc_id" { value = aws_vpc.twk.id }
output "dev_subnet_id" { value = aws_subnet.dev.id }
output "security_group_id" { value = aws_security_group.dev.id }
output "ec2_id" { value = aws_instance.dev.id }
output "ec2_private_ip" { value = aws_instance.dev.private_ip }
output "ec2_public_ip" { value = aws_eip.dev.public_ip }
output "s3_bucket" { value = aws_s3_bucket.state.bucket }
