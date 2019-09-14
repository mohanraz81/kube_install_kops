#!/bin/bash
if [ -z ~/.kube/config ]
then
  echo "kubeconfig file is not found in ~/.kube/config so exiting "
  exit 10
else
  kubectl apply -f metricserver.yaml
  sleep 15
  kubectl get all -n kube-system |grep -i metric
  echo "Metric Server is created"
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
  
    echo "Installing prometheus" 
  kubectl create namespace prometheus
    helm install stable/prometheus \
        --name prometheus \
        --namespace prometheus \
        --set alertmanager.persistentVolume.storageClass="gp2" \
        --set server.persistentVolume.storageClass="gp2"

  
    while true
    do
        sleep 10
        pro_pod=`kubectl get all -n prometheus|grep Running|wc -l`
         if [ $pro_pd -ne 7 ]
        then
             echo "waiting for prometheus pods to come up"
        else
          kubectl get all -n prometheus
          prom_pod=`kubectl get pods -n prometheus|grep prometheus-server|awk -F'/' '{print $1}'`
          kubectl port-forward -n prometheus $prom_pod 8080:9090 &
          break;
        fi
    done
    
    kubectl create namespace grafana
    helm install stable/grafana \
        --name grafana \
        --namespace grafana \
        --set persistence.storageClassName="gp2" \
        --set adminPassword="EKS!sAWSome" \
        --set datasources."datasources\.yaml".apiVersion=1 \
        --set datasources."datasources\.yaml".datasources[0].name=Prometheus \
        --set datasources."datasources\.yaml".datasources[0].type=prometheus \
        --set datasources."datasources\.yaml".datasources[0].url=http://prometheus-server.prometheus.svc.cluster.local \
        --set datasources."datasources\.yaml".datasources[0].access=proxy \
        --set datasources."datasources\.yaml".datasources[0].isDefault=true \
        --set service.type=LoadBalancer
    
    while true
    do
        sleep 10
        pro_pod=`kubectl get all -n grafana|grep Running|wc -l`
         if [ $pro_pd -ne 1 ]
        then
             echo "waiting for grafana pods to come up"
        else
          kubectl get all -n grafana
          GRAFANAELB=$(kubectl get svc -n grafana grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
          GRAFANAPASS=`kubectl get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo`
          GRAFANAUSER=admin
          break;
        fi
    done


   kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
   kubectl proxy --port=9000 --address='0.0.0.0' --disable-filter=true &
   DASHBOARDPORT=9000
   DASHBOARDURL="/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/"
   kubectl apply -f dashboardrbac.yaml
   sleep 10
   DASBOARDTOKEN=`kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')`
   
   echo "Summary of ADD On"
   echo "Installed Metric Server"
   echo "Metric Server can be validated from below command"
   echo " kubectl get pods -n kube-system | grep metrics-server"
   echo " Installed Prometheus "
   echo "Prometheus can be accessed via below link from cloud9 open preview application and paste bwlow URL"
   echo "https://$C9_PID.vfs.cloud9.us-east-1.amazonaws.com/targets"
   echo "Grafana can be accessed via below link in browser window"
   echo "https://$GRAFANAELB"
   echo "Grafana User name: $GRAFANAUSER"
   echo "Grafana User name: $GRAFANAPASS"
   echo "Dashboard can be accessed via below link from cloud9 open preview application and paste bwlow URL"
   echo "https://$C9_PID.vfs.cloud9.us-east-1.amazonaws.com:$DASHBOARDPORT/$DASHBOARDURL"
   echo "Copy paster below as token for dahboard"
   #echo "$DASBOARDTOKEN"
   
fi