#!/bin/bash
set -euo pipefail

GITOPS_SUBSCRIPTION_NAME="openshift-gitops-operator"
GITOPS_SUB_NAMESPACE="openshift-gitops-operator"
GITOPS_WATCH_NAMESPACE="openshift-gitops"
RHDH_SUBSCRIPTION_NAME="rhdh-operator"
RHDH_NAMESPACE="backstage"
TIMEOUT=300
SLEEP_INTERVAL=10

wait_for_operator() {
  local subscription_name=$1
  local namespace=$2

  echo "📦 Esperando instalación del operador '$subscription_name' en namespace '$namespace'..."

  local start_time=$(date +%s)

  while true; do
    local csv_name=$(oc get subscription "$subscription_name" -n "$namespace" -o jsonpath='{.status.installedCSV}' 2>/dev/null || echo "")

    if [[ -n "$csv_name" ]]; then
      local phase=$(oc get csv "$csv_name" -n "$namespace" -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
      echo "🔍 CSV: $csv_name | Phase: $phase"

      if [[ "$phase" == "Succeeded" ]]; then
        echo "✅ Operador '$subscription_name' instalado correctamente."
        break
      fi
    fi

    local current_time=$(date +%s)
    local elapsed=$(( current_time - start_time ))

    if (( elapsed > TIMEOUT )); then
      echo "❌ Timeout esperando la instalación del operador '$subscription_name'."
      exit 1
    fi

    sleep $SLEEP_INTERVAL
  done
}

# -------------------- GitOps Operator --------------------

# Crear namespace para el operador GitOps
oc create namespace "$GITOPS_SUB_NAMESPACE" || true
oc label namespace "$GITOPS_SUB_NAMESPACE" openshift.io/cluster-monitoring=true --overwrite
oc create namespace "$GITOPS_WATCH_NAMESPACE" || true

# Aplicar OperatorGroup y Subscription
oc apply -f ./gitops/operator-group.yaml
oc apply -f ./gitops/subscription.yaml

# Esperar instalación del operador de GitOps
wait_for_operator "$GITOPS_SUBSCRIPTION_NAME" "$GITOPS_SUB_NAMESPACE"

# Aplicar instancia de ArgoCD App que instalará Developer Hub
echo "🚀 Creando instancia ArgoCD para Developer Hub..."
oc apply -f ./argo/dev-apps/developer-hub-operator.yaml

# -------------------- Developer Hub Operator --------------------

# Esperar instalación del operador Developer Hub
wait_for_operator "$RHDH_SUBSCRIPTION_NAME" "$RHDH_NAMESPACE"

# Aplicar instancia de Backstage (Developer Hub)
echo "🚀 Creando instancia de Backstage (Developer Hub)..."
oc apply -f ./apps/developer-hub/overlays/dev/developer-hub.yaml