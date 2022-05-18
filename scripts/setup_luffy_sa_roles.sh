#!/bin/bash
set -e
set -o pipefail

SERVICE_ACCOUNT_NAME=$1
KUBE_CTX="$2"
NAMESPACE="$3"

if [[ -z "$1" ]] || [[ -z "$2" ]] || [[ -z "$3" ]]; then
 echo "usage: $0 <service_account_name> <kubectx> <namespace>"
 exit 1
fi

apply_rbac() {
    echo -e -n "\\nApplying RBAC permissions..."
    kubectl apply -f  - << EOF
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ${SERVICE_ACCOUNT_NAME}-${KUBE_CTX}-${NAMESPACE}-clusterrolebinding
  namespace: 
subjects:
  - kind: ServiceAccount
    name: ${SERVICE_ACCOUNT_NAME}
    namespace: ${NAMESPACE}
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: ""
EOF
    printf "done"
}

apply_rbac