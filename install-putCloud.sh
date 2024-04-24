#!/bin/bash

# if [ -d "$/usr/local/putcloud" ]; then
#   echo "putCloud seems to be installed already, exiting."
#   echo "Run "install-putcloud.sh uninstall" to remove putCloud and its files."
#   exit 1 #actually make uninstall option
# fi

# sudo mkdir "/usr/local/putcloud"
# pushd "/usr/local/putcloud"


# #Create config file.

# sudo cat > putcloud.conf << EOF
# ConnectionType=none
# StorageContainer=none
# EOF


# popd





#cat >/usr/local/bin/putcloud <<EOF





#Setup Azure Authentication // Need to modify apropriate configs
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
      echo
    else
      echo "There may have been an error authenticating with Azure."
      echo "Please try running setup again."
      exit 1
    fi
    


    #section to specify default azure blob
    echo "azure blob selection NYI"

}





#Setup AWS Authentication // Need to modify apropriate configs

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
    local bucketDefault

    read -p 'Would you like to authenticate with [SSO] or Access Key [AK]: ' awsAuthType
    echo
  
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
      echo
      echo "Successfully authenticated with AWS!"
      echo
    else
      echo "There may have been an error authenticating with AWS."
      echo "Please try running setup again."
      exit 1
    fi
    
    read -p 'Specify the bucket that you will be uploading to: ' bucketDefault
    bbSelect $bucketDefault > /dev/null

    echo "Default bucket is now:" $bucketDefault
    echo
    echo "Setup complete!"


}



#Change blob/bucket in config
bbSelect(){
  local bbNew
  local tempSed
  
  #Load Config
  . /usr/local/putcloud/putcloud.conf
  
  if [[ $# = 0 ]]; then
    echo "Current value is: $StorageContainer"
    read -p 'Enter new location: ' bbNew
  else
    bbNew="$1"
    
  fi

  echo 'Updated value from "'$StorageContainer'" to "'$bbNew'".'  #Also make it differentiate between "bucket" and "blob" instead of just "value"
  tempSed="s/StorageContainer=.*/StorageContainer=$bbNew/g" #part of the "this" in question

  sudo sed -i $tempSed /usr/local/putcloud/putcloud.conf #oh this DEFINITELY needs sanitized
}



#Uploads files to preconfigured blob/bucket
fileSend(){

  #Load Config
  . /usr/local/putcloud/putcloud.conf

  case "$ConnectionType" in
    AWS)
      aws s3 cp ./$1 s3://$StorageContainer/$2/

      if [[ $? -eq 0 ]]; then
        echo "Upload successful."
      else
        echo "Upload failed."
      fi
      
    ;;
    Azure)
      echo "using Azure to upload (NYI)"
    ;;
    *)
      echo "Your connection type is unset or misconfigured."
      echo "Please run putcloud with the -s flag to access setup."
      ;;
  esac
  

}









while true; do
    case $1 in

      -h)
        #help information
        echo "tempHelp"

        exit 0
        ;;


      -s)

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

        exit 0
        ;;


      -b)

        #Blob/Bucket selection

        if [ $# = 2 ]; then
          bbSelect $2
        else
          bbSelect
        fi

        exit 0
        ;;

      -p) 
        #Shifts between arguments and assigns variables to give to fileSend() function
        #Doing this for now because there is potential to include multiple files
        if [ $# -gt 2 ]; then

          shift
          fileToSend="$1"
          shift
          sendDestination="$1"

          #Sends file to cloud
          fileSend $fileToSend $sendDestination
          


        else

          echo "Incomplete command."
          echo 'Run "putcloud -h" for help.'
          exit 2
        fi
 
        exit 0
        ;;
          
      *)
        if [ $# -gt 1 ]; then
          echo $0': Invalid parameter: "'$1'"' >&2
        fi
        
        echo 'Run "putcloud -h" for help.'
        exit 2;;
    esac
done





#EOF


#AWS
#assume they'll use aws cli for most management stuff, don't need to reimpliment anything more than basic stuff
#upload, upload status failed or succeded (report errors), allow multiple uploads, ow/skip/rename, specify remote directory


##check if user is root
#make uninstall flag