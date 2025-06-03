#!/bin/bash
set -euo pipefail

SUBSCRIPTION_NAME="openshift-gitops-operator"
SUB_NAMESPACE="openshift-gitops-operator"
WATCH_NAMESPACE="openshift-gitops"
TIMEOUT=300
SLEEP_INTERVAL=10

# Crear namespace del operador GitOps
oc create namespace $SUB_NAMESPACE || true
oc label namespace $SUB_NAMESPACE openshift.io/cluster-monitoring=true --overwrite

# Crear namespace de la instancia GitOps
oc create namespace $WATCH_NAMESPACE || true

# Aplicar manifiestos del operador GitOps
oc apply -f ./gitops/operator-group.yaml
oc apply -f ./gitops/subscription.yaml

echo "📦 Esperando instalación del operador OpenShift GitOps..."

start_time=$(date +%s)

while true; do
  CSV_NAME=$(oc get subscription "$SUBSCRIPTION_NAME" -n "$SUB_NAMESPACE" -o jsonpath='{.status.installedCSV}' 2>/dev/null || echo "")
  if [[ -n "$CSV_NAME" ]]; then
    PHASE=$(oc get csv "$CSV_NAME" -n "$SUB_NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
    echo "🔍 CSV: $CSV_NAME | Phase: $PHASE"
    if [[ "$PHASE" == "Succeeded" ]]; then
      echo "✅ OpenShift GitOps instalado correctamente."
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

# Aplicar la App de ArgoCD que instala el operador de Developer Hub
echo "🚀 Creando aplicación en ArgoCD para el operador Red Hat Developer Hub..."
oc apply -f ./argo/dev-apps/developer-hub-operator.yaml

# Esperar sincronización de la App de ArgoCD
APP_NAME="developer-hub-operator"
ARGOCD_NAMESPACE="openshift-gitops"
echo "⏳ Esperando que la aplicación '$APP_NAME' esté sincronizada..."

start_time=$(date +%s)
while true; do
  SYNC_STATUS=$(oc get application "$APP_NAME" -n "$ARGOCD_NAMESPACE" -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "")
  HEALTH_STATUS=$(oc get application "$APP_NAME" -n "$ARGOCD_NAMESPACE" -o jsonpath='{.status.health.status}' 2>/dev/null || echo "")
  echo "🔍 Sync: $SYNC_STATUS | Health: $HEALTH_STATUS"

  if [[ "$SYNC_STATUS" == "Synced" && "$HEALTH_STATUS" == "Healthy" ]]; then
    echo "✅ Aplicación '$APP_NAME' sincronizada correctamente."
    break
  fi

  current_time=$(date +%s)
  elapsed=$(( current_time - start_time ))
  if (( elapsed > TIMEOUT )); then
    echo "❌ Timeout esperando sincronización de la aplicación '$APP_NAME'."
    exit 1
  fi

  sleep $SLEEP_INTERVAL
done

# Esperar a que el operador Developer Hub esté instalado
RHDH_SUBSCRIPTION_NAME="rhdh"
RHDH_NAMESPACE="backstage"
echo "⏳ Esperando instalación del operador 'rhdh-operator' en namespace '$RHDH_NAMESPACE'..."

start_time=$(date +%s)
while true; do
  RHDH_CSV=$(oc get subscription "$RHDH_SUBSCRIPTION_NAME" -n "$RHDH_NAMESPACE" -o jsonpath='{.status.installedCSV}' 2>/dev/null || echo "")
  if [[ -n "$RHDH_CSV" ]]; then
    RHDH_PHASE=$(oc get csv "$RHDH_CSV" -n "$RHDH_NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
    echo "🔍 CSV: $RHDH_CSV | Phase: $RHDH_PHASE"
    if [[ "$RHDH_PHASE" == "Succeeded" ]]; then
      echo "✅ Operador Red Hat Developer Hub instalado correctamente."
      break
    fi
  fi

  current_time=$(date +%s)
  elapsed=$(( current_time - start_time ))
  if (( elapsed > TIMEOUT )); then
    echo "❌ Timeout esperando instalación del operador Red Hat Developer Hub."
    exit 1
  fi

  sleep $SLEEP_INTERVAL
done

# Aplicar instancia de Backstage (Developer Hub)
echo "🚀 Creando aplicación en ArgoCD para la instancia de Red Hat Developer Hub..."
oc apply -f ./argo/dev-apps/developer-hub.yaml

# Esperar sincronización de la App de ArgoCD
APP_NAME="developer-hub"
ARGOCD_NAMESPACE="openshift-gitops"
echo "⏳ Esperando que la aplicación '$APP_NAME' esté sincronizada..."

start_time=$(date +%s)
while true; do
  SYNC_STATUS=$(oc get application "$APP_NAME" -n "$ARGOCD_NAMESPACE" -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "")
  HEALTH_STATUS=$(oc get application "$APP_NAME" -n "$ARGOCD_NAMESPACE" -o jsonpath='{.status.health.status}' 2>/dev/null || echo "")
  echo "🔍 Sync: $SYNC_STATUS | Health: $HEALTH_STATUS"

  if [[ "$SYNC_STATUS" == "Synced" && "$HEALTH_STATUS" == "Healthy" ]]; then
    echo "✅ Aplicación '$APP_NAME' sincronizada correctamente."
    break
  fi

  current_time=$(date +%s)
  elapsed=$(( current_time - start_time ))
  if (( elapsed > TIMEOUT )); then
    echo "❌ Timeout esperando sincronización de la aplicación '$APP_NAME'."
    exit 1
  fi

  sleep $SLEEP_INTERVAL
done

