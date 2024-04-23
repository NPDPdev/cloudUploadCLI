#!/bin/bash

#Setup Azure Authentication

azSetup() { 
    # Install az cli
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    # Login
    az login --use-device-code
    echo 'Login Successful'
}

#Setup AWS Authentication

awsSetup() { 
    # Install aws cli
    pushd "/tmp"
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install

    rm "awscliv2.zip"
    rm -r "./aws"
    popd


}




if [ "$1" == "setup" ]
then
  read -p 'Authenticate with [Azure] or [AWS]: ' hostSelection
  
  case $hostSelection in
    Azure) 
        echo "Chose Azure";;
    AWS) 
        echo "Chose AWS"
        awsSetup;;
    *) 
        echo 'You failed to input "Azure" or "AWS"';;
  esac
  
#else
  #establish other functions like put, list, etc
fi
  


#Setup AWS Authentication

##check if user is root
##check if aws and azure is already installed
