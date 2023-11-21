# smb csi driver for openshift
An example of PoC implementation of csi driver smb on openshift 

# Disclaimer

**/!\ /!\ /!\ This solution is not supported by Red Hat, this is an example of how it can be done for your needs on ROSA /!\ /!\ /!\\**

# Global information
This git repository have been highly inspired by [this article](https://rguske.github.io/post/using-windows-smb-shares-in-kubernetes/#3-validating-write-access)
The main git repository used is [the official smb csi driver](https://github.com/kubernetes-csi/csi-driver-smb/tree/master)

Once everything is deployed, you can adapt the configuration so you can mount your own smb shared volumes from your on-prem infrastructure for instance (hybrid cloud scenario).

You can also modify the configuration so you can deploy everything you need in specific namespace. However, this has been done for a one shot demo so a lot of manifests should be updated. Feel free to contribute with PR if you want.

# Global overview
This git repository aim to deploy
- a `csi-smb-provisioner` project with:
  - The `csi smb controler` controler deployment
  - The `csi smb node` component
  - The `RBAC` required to make the controler work
  - The `CSI driver`
- a `smb server` project with a smb server deployed, so it can be used as an example of shared volumes. Note that this is made with empty storage so any reboot from the pod will result in losing the data
- a `test-1` project with:
  - a `persistent volume` that references the shared volume we wish to mount
  - a `persistent volume claim` for the deployment
  - a `deployment` which mounts the smb shared volume
- a `test-2` project with:
  - a `storage class` which defines the shared volume we wish to mount. Note that a storage class is a cluster resource and note as well that you might need one storage class for each shared volume you want to mount as the source is specified in the parameter field
  - a `statefulset` which will be using the storage class

All the namespace will be provisioned also with a few secrets to make everything works properly.

# Fast install
Just run the script `deploy.sh` and it will deploy everything you need for the PoC.

# Step by step guide

Start from the root directory from this git repository.

1. Install the components
```
oc new-project csi-smb-provisioner
cd components
oc apply -f component-rbac.yaml
oc apply -f component-csidriver.yaml
#oc adm policy add-scc-to-user privileged -z csi-smb-node-sa
#oc adm policy add-scc-to-user privileged -z csi-smb-controller-sa
oc apply -f component-deployment.yaml
oc apply -f component-daemonset.yaml
cd ..
```

2. Install the smb server
```
oc new-project demo-smb-server
cd smb-server
oc create sa demo-smb-server
#oc adm policy add-scc-to-user privileged -z demo-smb-server
oc create secret generic smbcreds --from-literal username=testuser --from-literal password="TESTPASSWORD"
oc apply -f demo-deployment.yaml
cd ..
```

3. Deploy the test workloads
```
oc new-project test-1
cd test-1-pv-pvc
oc create secret generic smbcreds --from-literal username=testuser --from-literal password="TESTPASSWORD"
#oc adm policy add-scc-to-user privileged -z demo-smb-server
oc apply -f pv.yaml
oc apply -f pvc.yaml
oc apply -f test1-deployment.yaml
cd ..

oc new-project test-2
cd test2-storageclass
oc create secret generic smbcreds --from-literal username=testuser --from-literal password="TESTPASSWORD"
oc apply -f test2-storageclass.yaml
oc apply -f test2-statefulset.yaml
cd ..
```

# Results
You should have this kind of output:
