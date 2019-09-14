#!/bin/bash
DOMAIN=$1
ROLENAME=$2
if [ -f kops_cluster_data ]
then
  source kops_cluster_data 
  kops get cluster
  kops validate cluster
else
  echo "kops_cluster_data file not found"
  exit 10
fi