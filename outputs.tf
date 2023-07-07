output "ssh_instructions" {
  value = "SSH to the node using: ssh -i ~/.ssh/aws_terraform.key ubuntu@<IP Address>"
}

output "node_public_ips" {
  value = aws_instance.ubuntu_22_04_ami_node[*].public_ip
}
