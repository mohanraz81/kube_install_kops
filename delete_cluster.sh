#!/bin/bash
if [ -f kops_cluster_data ]
then
  source kops_cluster_data 
  kops get cluster
  kops delete cluster $NAME --yes
  bucket=`echo $KOPS_STATE_STORE|sed -e 's[s3://[[g'`
  uname -a|grep -i ubuntu
  if [ $? -eq 0 ]
  then
    sudo apt-get -y install jq
  else
    sudo yum -y install jq
  fi
    echo "Removing all versions from $bucket"
    
    versions=`aws s3api list-object-versions --bucket $bucket |jq '.Versions'`
    markers=`aws s3api list-object-versions --bucket $bucket |jq '.DeleteMarkers'`
    
    echo "removing files"
    for version in $(echo "${versions}" | jq -r '.[] | @base64'); do 
        version=$(echo ${version} | base64 --decode)
    
        key=`echo $version | jq -r .Key`
        versionId=`echo $version | jq -r .VersionId `
        cmd="aws s3api delete-object --bucket $bucket --key $key --version-id $versionId"
        echo $cmd
        $cmd
    done
    
    echo "removing delete markers"
    for marker in $(echo "${markers}" | jq -r '.[] | @base64'); do 
        marker=$(echo ${marker} | base64 --decode)
    
        key=`echo $marker | jq -r .Key`
        versionId=`echo $marker | jq -r .VersionId `
        cmd="aws s3api delete-object --bucket $bucket --key $key --version-id $versionId"
        echo $cmd
        $cmd
    done
  aws s3 rb $KOPS_STATE_STORE --force 
  rm -f id_rsa id_rsa.pub kops1.yaml kopsig1.yaml kops_cluster_data
else
  echo "kops_cluster_data file not found"
  exit 10
fi