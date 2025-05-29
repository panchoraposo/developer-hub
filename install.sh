#!/bin/bash
set -euo pipefail

# Nombres y namespaces
SUBSCRIPTION_NAME="openshift-gitops-operator"
SUB_NAMESPACE="openshift-gitops-operator"   # Donde se crea la suscripción
WATCH_NAMESPACE="openshift-gitops"          # Donde se desplegará GitOps
TIMEOUT=300
SLEEP_INTERVAL=10

# Crear namespace para el operador
oc create namespace $SUB_NAMESPACE || true
oc label namespace $SUB_NAMESPACE openshift.io/cluster-monitoring=true --overwrite

# Crear namespace de GitOps (instancia)
oc create namespace $WATCH_NAMESPACE || true

# Aplicar operator group y subscription
oc apply -f ./gitops/operator-group.yaml
oc apply -f ./gitops/subscription.yaml

echo "📦 Esperando instalación del operador GitOps..."

start_time=$(date +%s)

while true; do
  CSV_NAME=$(oc get subscription "$SUBSCRIPTION_NAME" -n "$SUB_NAMESPACE" -o jsonpath='{.status.installedCSV}' 2>/dev/null || echo "")

  if [[ -n "$CSV_NAME" ]]; then
    PHASE=$(oc get csv "$CSV_NAME" -n "$SUB_NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
    echo "🔍 CSV: $CSV_NAME | Phase: $PHASE"

    if [[ "$PHASE" == "Succeeded" ]]; then
      echo "✅ GitOps Operator instalado correctamente."
      break
    fi
  fi

  current_time=$(date +%s)
  elapsed=$(( current_time - start_time ))

  if (( elapsed > TIMEOUT )); then
    echo "❌ Timeout esperando la instalación del operador OpenShift GitOps."
    exit 1
  fi

  sleep $SLEEP_INTERVAL
done

echo "📦 Esperando instalación del operador Red Hat Developer Hub..."
oc apply -f ./argo/dev-apps/developer-hub-operator.yaml

echo "⏳ Esperando disponibilidad del CRD Backstage (rhdh.redhat.com/v1alpha3)..."

CRD_TIMEOUT=120
crd_start_time=$(date +%s)

while true; do
  if oc get crd backstages.rhdh.redhat.com >/dev/null 2>&1; then
    echo "✅ CRD 'Backstage' disponible."
    break
  fi

  current_time=$(date +%s)
  elapsed=$(( current_time - crd_start_time ))

  if (( elapsed > CRD_TIMEOUT )); then
    echo "❌ Timeout esperando la creación del CRD 'Backstage'."
    exit 1
  fi

  sleep $SLEEP_INTERVAL
done