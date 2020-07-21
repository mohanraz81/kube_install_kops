echo -e '{\n"Version": "2012-10-17",\n"Statement": {\n"Effect": "Allow",\n"Principal": {"Service": "ec2.amazonaws.com"},\n"Action": "sts:AssumeRole"\n}\n}' > trustrole.json

aws iam create-role --role-name kopsrole --assume-role-policy-document file://trustrole.json

for i in `echo AmazonEC2FullAccess IAMFullAccess AmazonS3FullAccess AmazonVPCFullAccess AmazonRoute53FullAccess`
do
aws iam attach-role-policy --role-name kopsrole --policy-arn arn:aws:iam::aws:policy/$i
done

aws iam create-instance-profile --instance-profile-name kopsrole-ip

aws iam add-role-to-instance-profile --role-name kopsrole --instance-profile-name kopsrole-ip

sleep 60
aws ec2 associate-iam-instance-profile --instance-id `curl http://169.254.169.254/latest/meta-data/instance-id` --iam-instance-profile Name=kopsrole-ip

sudo yum -y install jq

DOMAINNAME=`aws route53 list-hosted-zones|jq .HostedZones[0].Name|awk -F'"' '{print $2}'|sed 's/com./com/g'`

rm -rf ~/.aws

./create_cluster.sh $DOMAINNAME kopsrole

export DASHBOARD_VERSION="v2.0.0"

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/${DASHBOARD_VERSION}/aio/deploy/recommended.yaml

kubectl proxy --port=8080 --address=0.0.0.0 --disable-filter=true &
echo "/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"