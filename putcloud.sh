#!/bin/bash

#Setup Azure Authentication

azSetup() { 
    # Install az cli
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    # Login
    az login --use-device-code
    echo 'Login Successful'
}






if[$1='setup'];
then
  read -p 'Authenticate with [1]Azure or [2]AWS: ' hostSelection
  
  case $hostSelection in
    Azure) 
        echo "Chose Azure";;
    AWS) 
        echo "Chose AWS";;
    *) 
        echo 'You failed to input "Azure" or "AWS"';;
  esac
  
else
  #establish other functions like put, list, etc
fi
  


#Setup AWS Authentication
