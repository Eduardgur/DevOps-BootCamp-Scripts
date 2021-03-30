#!/bin/bash

#input 
password=$1

# Color
RED='\033[31m'
GREEN='\e[32m'
NC='\033[0m' 

failed=0

length_check () {
    if [ ${#1} -lt 10 ]; then
        echo -e "$RED X - Minimum password length is 10 $NC"
        failed=$((failed+=1))
    else
        echo -e "$GREEN V - Length check passed $NC"
    fi  
}

lower_check () {
    if [[ $1 =~ [[:lower:]] ]]; then
        echo -e "$GREEN V - Lowercase check passed $NC"
    else
        echo -e "$RED X - Password must contain lowercase letters $NC"
        failed=$((failed+=1))
    fi  
}

upper_check () {
    if [[ $1 =~ [[:upper:]] ]]; then
        echo -e "$GREEN V - Uppercase check passed $NC"
    else
        echo -e "$RED X - Password must contain uppercase letters $NC"
        failed=$((failed+=1))
    fi
}

num_check () {
    if [[ $1 =~ [[:digit:]] ]]; then
        echo -e "$GREEN V - Numbers check passed $NC"
    else 
        echo -e "$RED X - Password must contain numbers $NC"
        failed=$((failed+=1))
    fi
}

echo "Checking your password now"

length_check $password
lower_check $password
upper_check $password
num_check $password

if [ $failed -ne 0 ]; then
    echo "Bad password please see details above"
    exit 1
else
    echo "Great password"
    exit 0
fi