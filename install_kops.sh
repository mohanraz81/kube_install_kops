#!/bin/bash
export KOPS_STATE_STORE=s3://$2
sed -i "s/NAME/$1/g" kops.yaml
sed -i "s/NAME/$1/g" kopsig.yaml
sed -i "s/BUCKET/$2/g" kops.yaml
kops create -f kops.yaml
kops create -f kopsig.yaml
kops create secret sshpublickey admin -i ~/.ssh/id_rsa.pub --name $1
#kops update cluster $1 --yes