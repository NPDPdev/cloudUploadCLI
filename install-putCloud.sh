#!/bin/bash

#Setup Azure Authentication

azSetup() { 
    #Install az cli
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    #Login
    az login --use-device-code
    echo 'Login Successful'
}


#Setup AWS Authentication

awsSetup() { 
    #Checks if aws cli is NOT installed

    if ! [ -x "$(command -v aws)" ]; then

      #Install aws cli
      pushd "/tmp"
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      unzip awscliv2.zip
      sudo ./aws/install

      #Removes installation files
      rm "awscliv2.zip"
      rm -r "./aws"
      popd

    else

      echo "AWS CLI is already installed, skipping install!"

    fi


    #Authentication procedure
    local awsAuthType
    read -p 'Would you like to authenticate with [SSO] or Access Key [AK]: ' awsAuthType
  
    case $awsAuthType in
      SSO) 
        aws configure sso;;
      AK) 
        aws configure;;
      *) 
        echo 'You failed to input "SSO" or "AK", quitting.';;
    esac

    aws sts get-caller-identity > /dev/null

    if [[ $? -eq 0 ]]; then
      echo "Successfully authenticated with AWS! Setup complete."
    else
      echo "There may have been an error authenticating with AWS."
      echo "Please try running setup again."
    fi
    
}







if [ "$1" == "setup" ] #make case statement
then
  read -p 'Authenticate with [Azure] or [AWS]: ' hostSelection
  
  case $hostSelection in
    Azure) 
        echo "Chose Azure";;
    AWS) 
        echo "Chose AWS"
        awsSetup;;
    *) 
        echo 'You failed to input "Azure" or "AWS", quitting.';;
  esac
  
#else
  #establish other functions like put, list, etc
fi
  


#Setup AWS Authentication
#assume they'll use aws cli for most management stuff, don't need to reimpliment anything more than basic stuff
#upload, upload status failed or succeded (report errors), allow multiple uploads, ow/skip/rename, specify remote directory


##check if user is root
##check if aws and azure is already installed
