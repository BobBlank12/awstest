output "ssh_instructions" {
  value = <<INSTRUCTION
SSH to the node using:
  ssh -i ~/.ssh/aws_terraform.key ubuntu@${aws_instance.ubuntu_22_04_ami_node.public_ip}
INSTRUCTION
}