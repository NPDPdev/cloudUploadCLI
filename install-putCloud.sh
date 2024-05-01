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
    local blobDefault

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
    
    
    #Sets ConnectionType to Azure
    sudo sed -i "s/ConnectionType=.*/ConnectionType=Azure/g" /usr/local/putcloud/putcloud.conf




    #Specify default Azure blob
    echo "azure blob selection NYI"
    read -p 'Specify the blob that you will be uploading to: ' blobDefault
    bbSelect $blobDefault > /dev/null

    echo "Default blob is now:" $blobDefault
    echo
    echo "Setup complete!"

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
    
    #Sets ConnectionType to AWS
    sudo sed -i "s/ConnectionType=.*/ConnectionType=AWS/g" /usr/local/putcloud/putcloud.conf


    #Specify default AWS bucket
    read -p 'Specify the bucket that you will be uploading to: ' bucketDefault
    bbSelect $bucketDefault > /dev/null

    echo "Default bucket is now:" $bucketDefault
    echo
    echo "Setup complete!"


}



#Allows user to configure a bucket or blob to upload to
bbSelect(){
  local bbNew
  local tempSed
  local serviceType
  
  #Load Config
  . /usr/local/putcloud/putcloud.conf

  #Check if we should call it a Bucket or Blob
  case "$ConnectionType" in
    AWS)
      serviceType="bucket";;

    Azure)
      serviceType="blob";;

    *)
      echo "Your connection type is unset or misconfigured."
      echo "Please run putcloud with the -s flag to access setup."
      exit 1;;
  esac
  

  if [[ $# = 0 ]]; then
    echo "Current "$serviceType" is: $StorageContainer"
    read -p 'Enter new location: ' bbNew
  else
    bbNew="$1"
    
  fi

  echo 'Updated '$serviceType' from "'$StorageContainer'" to "'$bbNew'".' 
  tempSed="s/StorageContainer=.*/StorageContainer=$bbNew/g" #part of the "this" in question

  sudo sed -i $tempSed /usr/local/putcloud/putcloud.conf #oh this DEFINITELY needs sanitized
}



#Uploads files to preconfigured blob/bucket
fileSend(){
  local safeDest=$2
  
  #removes leading and trailing "/" characters to ensure correct upload path
  if [[ $safeDest == /* ]]; then
    safeDest=${safeDest:1}
  fi
  
  if [[ $safeDest == */ ]]; then
    safeDest=${safeDest::-1}
  fi


  #Load Config
  . /usr/local/putcloud/putcloud.conf


  case "$ConnectionType" in
    AWS)
      aws s3 cp $1 s3://$StorageContainer/$safeDest/

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
      exit 1;;
  esac
  

}









while true; do
    case $1 in

      -h)
        #help information
        echo "putcloud [options] <arguments>"
        echo -e "\t Putcloud allows for uploading of individual or multiple files to AWS/Azure via the command line."
        
        echo
        echo -e "\t -h"
        echo -e "\t Display this help menu."
        echo 
        echo -e "\t -s"
        echo -e "\t Prompts user to setup the program. Includes selecting which cloud provider to use and which form of authentication."
        echo 
        echo -e "\t -b <bucket_blob_location>"
        echo -e "\t Allows user to define which AWS bucket or Azure blob to use. If used without arguments, user will be prompted."
        echo 
        echo -e "\t -p file1 <file2>... -d destination_folder"
        echo -e "\t Allows user to upload one or multiple files. Must be used with -d to specify the remote directory."
        echo 

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
          fixedArgs=$#
          
          

          #Make an array for all arguments beteween -p and -d, which are files to upload
          #Sets destination path once -d argument is reached
          for ((i = 0 ; i < fixedArgs ; i++ )); do
            
            case $1 in
              -d)
                sendDestination="$2"
                ;;
              *)
              multiFileArray[i]=$1
              shift;;

            esac
            
          done

          if [ -z "$sendDestination" ]; then
            echo "Missing -d flag for upload destination."
            echo 'Run "putcloud -h" for help.'
            exit 2
          fi

          

          #Loops through array, sending each file individually
          for fileToSend in ${multiFileArray[@]}; do
            fileSend $fileToSend $sendDestination
          done
          


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
#putcloud -s




##check if user being root matters
#make uninstall flag




#test Azure auth (may need to reimpliment -f filename in fileSend function if azure has less descriptive "file not found" error message than AWS)

#1 check if file exists in cloud (ow/skip/rename) and allow flag to automatically determine this

#2
#Sanitize bbSelect function input

#3
#Do Documentation
#Make installable

#4? allow for standalone -d option to choose default remote directory?




#help temp
#putcloud -p yourLocalFile -d remoteDestination