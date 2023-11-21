#!/bin/bash

# Create the namespace for the csi driver
oc new-project csi-smb-provisioner
# Install rbac + csi driver
oc apply -f components/component-rbac.yaml
oc apply -f components/component-csidriver.yaml
oc adm policy add-scc-to-user node-exporter -z csi-smb-node-sa
oc adm policy add-scc-to-user node-exporter -z csi-smb-controller-sa
oc apply -f components/component-deployment.yaml
oc apply -f components/component-daemonset.yaml

sleep 10
oc get pod -o wide

# Create a SMB server on k8s (ephemeral storage)
oc new-project demo-smb-server
oc create sa demo-smb-server
oc adm policy add-scc-to-user anyuid -z demo-smb-server
kubectl create secret generic smbcreds --from-literal username=testuser --from-literal password="TESTPASSWORD"
oc apply -f smb-server/demo-deployment.yaml
sleep 10
oc exec $(oc get pod -o name) -- chmod 755 /root
# shared should now be available under //smb-server.smb-server.svc.cluster.local/share

sleep 10
oc get pod -o wide

# Create a test pod using pv and pvc
oc new-project test-1
oc create secret generic smbcreds --from-literal username=testuser --from-literal password="TESTPASSWORD"
oc apply -f test1-pv-pvc/test1-pv.yaml
oc apply -f test1-pv-pvc/test1-pvc.yaml
oc create sa test-deploy-smb-pod
oc adm policy add-scc-to-user anyuid -z test-deploy-smb-pod
oc apply -f test1-pv-pvc/test1-deployment.yaml

sleep 10
oc get pod,pv,pvc -o wide

# Create a test pod using storageclass and statefulset
oc new-project test-2
oc create secret generic smbcreds --from-literal username=testuser --from-literal password="TESTPASSWORD"
oc apply -f test2-storageclass/test2-storageclass.yaml
oc apply -f test2-storageclass/test2-statefulset.yaml

sleep 10
oc get pod,pv,pvc,statefulset -o wide
