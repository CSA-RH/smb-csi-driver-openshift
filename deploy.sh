#!/bin/bash

# Create the namespace for the csi driver
oc new-project csi-smb-provisioner
# Install rbac + csi driver
oc apply -f component-rbac.yaml
oc apply -f component-csidriver.yaml
oc adm policy add-scc-to-user privileged -z csi-smb-node-sa
oc adm policy add-scc-to-user privileged -z csi-smb-controller-sa
sleep 10
# Install the components
oc apply -f component-deployment.yaml
oc apply -f component-daemonset.yaml

sleep 20

# Create a SMB server on k8s (ephemeral storage)
#oc new-project demo-smb-server
oc create sa demo-smb-server
oc adm policy add-scc-to-user privileged -z demo-smb-server
kubectl create secret generic smbcreds --from-literal username=testuser --from-literal password="TESTPASSWORD"
oc apply -f demo-deployment.yaml
# shared should be available under //smb-server.smb-server.svc.cluster.local/share

sleep 20

# Create a test pod
#oc new-project smb-test
#oc create secret generic smb-creds --from-literal username=testuser --from-literal domain="smb-server.demo-smb-server.svc.cluster.local" --from-literal password="TESTPASSWORD"
# domain is optional according to https://github.com/kubernetes-csi/csi-driver-smb/blob/master/docs/driver-parameters.md
#oc create secret generic smbcreds --from-literal username=testuser --from-literal password="TESTPASSWORD"
oc apply -f test-pv.yaml
oc apply -f test-pvc.yaml
oc create sa test-deploy-smb-pod
oc adm policy add-scc-to-user privileged -z test-deploy-smb-pod
oc adm policy add-scc-to-user anyuid -z test-deploy-smb-pod
oc apply -f test-deployment.yaml
sleep 10

oc apply -f test2-storageclass.yaml
oc apply -f test2-statefulset.yaml
sleep 10
oc get pod