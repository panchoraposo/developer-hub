#!/bin/bash
ROUTE_URL=$(oc get route -n openshift-console console -o jsonpath='{.spec.host}')
BASE_DOMAIN=$(echo "$ROUTE_URL" | sed -E 's/^[^.]+\.[^.]+\.(.*)$/\1/')
echo "apps.${BASE_DOMAIN}"

oc project backstage
oc set env deployment/backstage-developer-hub NODE_TLS_REJECT_UNAUTHORIZED=0
oc set env deployment/backstage-developer-hub OAUTH_CLIENT_SECRET=FI9rJL53g7GMoTFLPbX8jHQreDyiV32g
oc set env deployment/backstage-developer-hub OAUTH_CLIENT_ID=backstage
oc set env deployment/backstage-developer-hub OPENSHIFT_CLUSTER_INGRESS_DOMAIN=apps.${BASE_DOMAIN}

