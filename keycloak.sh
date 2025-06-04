# Certificados TLS Keycloak
openssl req -subj '/CN=demo.keycloak.org/O=Demo Keycloak./C=US' -newkey rsa:2048 -nodes -keyout ./apps/keycloak/overlays/dev/tls/key.pem -x509 -days 365 -out ./apps/keycloak/overlays/dev/tls/certificate.pem

# Create Secret
oc -n keycloak create secret tls rhbk-tls-secret --cert ./apps/keycloak/overlays/dev/tls/certificate.pem --key ./apps/keycloak/overlays/dev/tls/key.pem

# ENV OpenShift
oc set env deployment/keycloak OPENSHIFT_CLUSTER_INGRESS_DOMAIN=apps.cluster-brl4w.brl4w.sandbox968.opentlc.com