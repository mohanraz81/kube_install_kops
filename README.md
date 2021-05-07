# Install Public Kubernetes Cluster Using KOPS and EC2 Instance in AWS
## Prerequisite
1. AWS Account with Root Previlages
2. A Public Domain Name

## What is Kops?
kops helps you create, destroy, upgrade and maintain production-grade, highly available, Kubernetes clusters from the command line. AWS (Amazon Web Services) is currently officially supported, with GCE and VMware vSphere in alpha and other platforms planned.
https://github.com/kubernetes/kops

## Install Kubernetes in AWS using KOPS

### Step 1: Login to AWS
Login in to AWS with Adminstrator Credentials

### Step 2: Create a Amazon Linux 2 Cloud9 by Following the Below Steps

https://docs.aws.amazon.com/cloud9/latest/user-guide/tutorial-create-environment.html

Open a Terminal in Cloud9 and Follow the Below Steps

### Step 3: Clone this Github
Execute the Below Commands
```
curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
chmod +x kops
sudo mv kops /usr/local/bin/kops
```

### Step 4: 
