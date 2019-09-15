#!/bin/bash
DOMAIN=$1
ROLENAME=$2
if [ -z $DOMAIN ]
then
   echo "usage of the command"
   echo "create_cluster.sh <ROUTE53 DOMAIN NAME> <ROLE NAME>"
   exit 10
fi
if [ -z $ROLENAME ]
then
   echo "usage of the command"
   echo "create_cluster.sh <ROUTE53 DOMAIN NAME> <ROLE NAME>"
   exit 10
fi
if [ -f kops_cluster_data ]
then
  source kops_cluster_data 
  kops get cluster
  echo "Above Cluster already Exist"
  exit 10
fi
echo "Checking your Domain"
echo "==============================="
aws route53 list-hosted-zones|grep $DOMAIN
if [ $? -ne 0 ]
then  
  echo "domain name you specified is not available in route53"
  exit 10  
fi
echo "Domain is Fine"
echo "==============================="
aws sts get-caller-identity|grep cross-account-role-session
if [ $? -eq 0 ]
then
     echo "You have not disabled the Cloud 9 temperary credentials"
     echo "Disable it by going to AWS Cloud 9 --> Preferences --> AWS SETTING --> Disable AWS Temperary credentials"
     exit 10
fi
rm -rf ~/.aws
aws sts get-caller-identity|grep $ROLENAME
if [ $? -ne 0 ]
then
     echo "You $ROLENAME role is not in effect"
     echo "Atach the Role by Go to AWS -> Service -> EC2 -> Instances -> Chose Cloud 9 Instance -> Actions -> Instance Setting -> Atach oor Replace IAM Role -> Attach the role"
     exit 10
fi
for i in `echo "AmazonEC2FullAccess IAMFullAccess AmazonS3FullAccess AmazonVPCFullAccess AmazonRoute53FullAccess"`
do
    aws iam  list-attached-role-policies --role-name $ROLENAME|grep $i
    if [ $? -ne 0 ]
    then
         echo "You $ROLENAME role  does not have $i policy"
        echo "Attach the policy by goint to AWS -> Service -> IAM -> Roles -> Choose $ROLENAME --> Attach Policy --> search for $i > Attach"
        exit 10
    else
       echo "Your Role have $i Policy..."
    fi
done


echo "Installing KOPS"
echo "==============================="
curl -LO https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
chmod +x kops-linux-amd64
sudo mv kops-linux-amd64 /usr/local/bin/kops
kops help
echo "Successfully installed KOPS"
echo "==============================="
echo "Installing KUBECTL"
echo "==============================="
wget -O kubectl https://storage.googleapis.com/kubernetes-release/release/v1.8.1/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version
echo "Successfully installed KUBECTL"
echo "==============================="
echo "Creating Bucket"
echo "==============================="
de=`echo $DOMAIN|sed "s/\./-/g"`
dt=`date +%s`
BUCKET=`echo "$de-$dt"`
aws s3api create-bucket --bucket $BUCKET  --region us-east-1
 if [ $? -ne 0 ]
then
     echo "bucket not got created Please check bucket with this name already exist"
     exit 10
else
   echo "Your Bucket is create successfully.."
fi
aws s3api put-bucket-versioning --bucket $BUCKET  --versioning-configuration Status=Enabled
echo "export KOPS_STATE_STORE=s3://$BUCKET" >> ./kops_cluster_data
echo "export NAME=kubecluster.$DOMAIN" >> ./kops_cluster_data
export KOPS_STATE_STORE=s3://$BUCKET
export NAME=kubecluster.$DOMAIN
echo "Done Bucket"
echo "==============================="
echo "ssh keys"
echo "==============================="
 ssh-keygen -f id_rsa -t rsa -N ''
echo "Done SSH KEYS"
echo "==============================="
kops get cluster|grep $NAME
if [ $? -eq 0 ]
then
     echo "Already cluster found with this $NAME name please delete before proceeding with this"
     exit 10
fi
TEST1KOPSYAML=`grep NAME kops.yaml |wc -l`
TEST2KOPSYAML=`grep BUCKET kops.yaml |wc -l`
TESTKOPSIGYAML=`grep NAME kopsig.yaml |wc -l `
if [ $TEST1KOPSYAML -ne 4 -o $TEST2KOPSYAML -ne 1 -o TESTKOPSIGYAML -ne 4 ]
then
  echo "your kops.yaml and kopsig.yaml template files are bad "
  echo "delete the directory and replone using "
  echo "git clone https://github.com/mohanraz81/kube_install_kops "
  exit 10
fi
sed -e "s/NAME/$NAME/g" -e "s/BUCKET/$BUCKET/g"   kops.yaml   > kops1.yaml
sed -e "s/NAME/$NAME/g" kopsig.yaml > kopsig1.yaml
kops create -f kops1.yaml --name $NAME --state s3://$BUCKET
 if [ $? -ne 0 ]
then
     echo "Cluster config is not create successfully"
     exit 10
fi
kops create -f kopsig1.yaml  --name $NAME --state s3://$BUCKET
 if [ $? -ne 0 ]
then
     echo "Instance group config is not create successfully"
     exit 10
fi
kops create secret sshpublickey admin -i id_rsa.pub --name  $NAME --state s3://$BUCKET
 if [ $? -ne 0 ]
then
     echo "SSH Key secret are nt create successfully"
     exit 10
fi
kops update cluster $NAME --yes
 if [ $? -ne 0 ]
then
     echo "Creation of the cluster is not successfull"
     exit 10
fi
while true
do
    sleep 60
    kops validate cluster
     if [ $? -ne 0 ]
    then
         echo "Cluster not created waiting"
    else
      break;
    fi
done