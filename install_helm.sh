#!/bin/bash
  curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
  chmod +x get_helm.sh
   ./get_helm.sh
   kubectl apply -f helm-rbac.yaml
   helm init --service-account tiller
   while true
   do
        sleep 10
        TILLPOD=`kubectl get pods -n kube-system |grep tiller|wc -1`
        if [ $TILLPOD -ne 1 ]
        then
           echo "tiller pod did not came up waiting"
        else
           sleep 10
           break
        fi
   done
   helm ls
   if [ $? -ne 0 ]
  then
    echo "helm did not come up properly "
    exit 10
  fi
  echo "Helm is installed" 