output "jenkins_main_public_ip" {
  value = linux_vm.main_vm.public_ip
}


 output "jenkins_agent_private_ip" {
  value = ["${linux_vm.agent_vm.agent_private_ip.*}"]
}
