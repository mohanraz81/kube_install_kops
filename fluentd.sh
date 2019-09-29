#!/bin/bash
aws logs create-log-group --log-group-name kubernetes
helm install --name fluentd charts/incubator/fluentd-cloudwatch \
  --set awsRegion=us-east-1,rbac.create=true
