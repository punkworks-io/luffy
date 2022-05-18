#!/bin/bash
set -e
set -o pipefail

# Add user to k8s using service account, no RBAC (must create RBAC after this script)
if [[ -z "$1" ]] || [[ -z "$2" ]]; then
 echo "usage: $0 <kubectx> <namespace>"
 exit 1
fi

CONTEXT="$1"
NAMESPACE="$2"


#  Setup context & namespace
kubectx ${CONTEXT}
kubens ${NAMESPACE}

helm repo add bitnami https://charts.bitnami.com/bitnami

## Postgres config

# Inject SQL file as config. use this file to create initial dbs 
kubectl --context ${CONTEXT} --namespace ${NAMESPACE} create configmap init-postgresdb.sql --from-file=./environments/local-data-center/postgres/init-postgresdb.sql


# Release the local-data-center chart
helm upgrade --install --kube-context ${CONTEXT} --namespace ${NAMESPACE} -f ./values/local-data-center/values.yaml  local-data-center ./charts/local-data-center


echo "Applying jobs in 20 seconds. Ctrl+C to cancel if you change your mind"
sleep 20

# Start a k8s job to run the above sql
kubectl --context ${CONTEXT} --namespace ${NAMESPACE} apply -f ./environments/local-data-center/postgres
