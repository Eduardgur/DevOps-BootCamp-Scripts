#Outputs the linux VM admin password

#Outputs APP public Ip
 output "jenkins_public_ip" {
  value = jenkins.Jenkins.public_ip
}

output "backend_private_ip" {
  value = back_end.backend.postgresql_private_ip_address
}

output "db_name" {
  value = "Servername: ${backend.postgresql_server_name} DBname:${backend.postgresql_db_name}}"
}


 output "jenkins_main_public_ip" {
  value = jenkins.Jenkins.public_ip
}

 output "jenkins_agents_private_ip" {
  value = ["${jenkins.Jenkins.public_ip}"]
}

