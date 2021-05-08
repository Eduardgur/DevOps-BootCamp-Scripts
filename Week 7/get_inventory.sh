#!/bin/bash

# az login --service-principal -u $1 -p $2 -t $3
# az account set -s $4


# public_ip=$(az network public-ip list -g DEV-WeightTracker-ResourceGroup --query [0].ipAddress -o json)
# b_server_name=$(az postgres server list -g DEV-WeightTracker-ResourceGroup --query [0].name)
# db_server_endpoint_id=$(az postgres server list -g DEV-WeightTracker-ResourceGroup --query [0].privateEndpointConnections[0].id)


stage_inventory=$(az network nic list --query "[?resourceGroup=='$1'].ipConfigurations[?[0].loadBalancerBackendAddressPools!=null] | [].privateIpAddress")
stage_inventory="$(echo "$stage_inventory" | sed 's/[][]//g' | sed -r 's/(.*)"/\1:/' | sed 's/[,"]//g' | sed 's/\(.*\)/                \1/')"
prod_inventory=$(az network nic list --query "[?resourceGroup=='$2'].ipConfigurations[?[0].loadBalancerBackendAddressPools!=null] | [].privateIpAddress") 
prod_inventory="$(echo "$prod_inventory" | sed 's/[][]//g' | sed -r 's/(.*)"/\1:/' | sed 's/[,"]//g' | sed 's/\(.*\)/                \1/')"

read -r -d '' host_list <<-EOF
---
#### YAML inventory file
all:
    children:
        stage:
            hosts: $stage_inventory
        prod:
            hosts: $prod_inventory
EOF
echo "$host_list"  > ./inventory.yml
 