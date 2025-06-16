oc project backstage

oc set env deployment/backstage-developer-hub \
        GITLAB_TOKEN=glpat-KmSSwDUmwxmzywGzs5p8 \
        NODE_TLS_REJECT_UNAUTHORIZED=0 \
        JENKINS_TOKEN=1164ae195198dd70d3c0ba67eace2d1b42 \
        OAUTH_CLIENT_SECRET=XYNZOBNpd1o0LFONwyMZ15YmaTsZ0HQT \
        OPENSHIFT_CLUSTER_INGRESS_DOMAIN=apps.cluster-tb8sp.tb8sp.sandbox1673.opentlc.com