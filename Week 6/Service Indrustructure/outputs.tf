 output "jenkins_main_public_ip" {
  value = module.jenkins.main_public_ip
}

 output "ansible_main_public_ip" {
  value = azurerm_public_ip.ansible_public_ip.ip_address
}

//  output "jenkins_agents_private_ip" {
//   value = [module.jenkins.agent_private_ip]
// }

