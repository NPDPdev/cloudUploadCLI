#!/bin/bash

# if [ -d "$/usr/local/putcloud" ]; then
#   echo "putCloud seems to be installed already, exiting."
#   echo "Run "install-putcloud.sh uninstall" to remove putCloud and its files."
#   exit 1 #actually make uninstall option
# fi

# mkdir "/usr/local/putcloud"
# pushd "/usr/local/putcloud"


# #Create config file.

# cat > putcloud.conf << EOF
# ConnectionType none
# StorageContainer none
# EOF


# popd





#cat >/usr/local/bin/putcloud <<EOF





#Setup Azure Authentication
azSetup() { 

    #Install Azure cli if not currently installed
    if ! [ -x "$(command -v az)" ]; then

      curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

    else

      echo "Azure CLI is already installed, skipping install!"

    fi

    #Login and auth verification
    az login --use-device-code
    az account show > /dev/null

    if [[ $? -eq 0 ]]; then
      echo "Successfully authenticated with Azure! Setup complete."
    else
      echo "There may have been an error authenticating with Azure."
      echo "Please try running setup again."
      exit 1
    fi
    


    #section to specify default azure blob

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



    #Login and auth verification
    local awsAuthType
    read -p 'Would you like to authenticate with [SSO] or Access Key [AK]: ' awsAuthType
  
    case $awsAuthType in
      SSO | sso) 
        aws configure sso;;
      AK | ak) 
        aws configure;;
      *) 
        echo 'You failed to input "SSO" or "AK", quitting.'
        exit 1;;
    esac

    aws sts get-caller-identity > /dev/null

    if [[ $? -eq 0 ]]; then
      echo "Successfully authenticated with AWS! Setup complete."
    else
      echo "There may have been an error authenticating with AWS."
      echo "Please try running setup again."
      exit 1
    fi
    


  #section to specify default aws bucket



}














#colon in front of hs disables error reporting but may lead to bad stuff!!
while getopts ":hs" clArg; do
  case "${clArg}" in
    h)
      #help information
      echo "tempHelp"

      exit 0
      ;;
    
    s)

      #Authentication and installation of AWS CLI or Azure CLI
      read -p 'Authenticate with [Azure] or [AWS]: ' hostSelection
      case $hostSelection in
        Azure | azure) 
          azSetup;;
        AWS | aws) 
          awsSetup;;
        *) 
          echo 'You failed to input "Azure" or "AWS", quitting.';;
      esac
      ;;


    *)
      echo "Invalid parameters. Run 'putcloud -h' for help."
      exit 1
      ;;
  esac
done





#EOF


#AWS
#assume they'll use aws cli for most management stuff, don't need to reimpliment anything more than basic stuff
#upload, upload status failed or succeded (report errors), allow multiple uploads, ow/skip/rename, specify remote directory


##check if user is root
##check if aws and azure is already installed
#make uninstall flag