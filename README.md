# An implementation of the smb csi driver in Openshift
An example of PoC implementation of csi driver smb on openshift 

# Disclaimer

**/!\ /!\ /!\ This solution is not supported by Red Hat /!\ /!\ /!\\**

**/!\ /!\ /!\ This solution is not supported by Red Hat /!\ /!\ /!\\**

**/!\ /!\ /!\ This solution is not supported by Red Hat /!\ /!\ /!\\**

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
oc adm policy add-scc-to-user node-exporter -z csi-smb-node-sa
oc adm policy add-scc-to-user node-exporter -z csi-smb-controller-sa
oc apply -f component-deployment.yaml
oc apply -f component-daemonset.yaml
cd ..
```

2. Install the smb server
```
oc new-project demo-smb-server
cd smb-server
oc create sa demo-smb-server
oc adm policy add-scc-to-user anyuid -z demo-smb-server
oc create secret generic smbcreds --from-literal username=testuser --from-literal password="TESTPASSWORD"
oc apply -f demo-deployment.yaml
oc exec $(oc get pod -o name) -- chmod 755 /root
cd ..
```

3. Deploy the test workloads
```
oc new-project test-1
cd test-1-pv-pvc
oc create secret generic smbcreds --from-literal username=testuser --from-literal password="TESTPASSWORD"
oc adm policy add-scc-to-user anyuid -z test-deploy-smb-pod
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
```
$ oc get pod -n csi-smb-provisioner
NAME                                  READY   STATUS    RESTARTS   AGE
csi-smb-controller-6cc48c4844-vg87l   3/3     Running   0          14m
csi-smb-node-62rqn                    3/3     Running   0          13m
csi-smb-node-dd495                    3/3     Running   0          13m
csi-smb-node-dkkmk                    3/3     Running   0          13m
csi-smb-node-km2kk                    3/3     Running   0          13m
csi-smb-node-lzb5c                    3/3     Running   0          13m
csi-smb-node-q5jsx                    3/3     Running   0          13m
csi-smb-node-q6nr2                    3/3     Running   0          13m

$ oc get pod -n demo-smb-server
NAME                         READY   STATUS    RESTARTS   AGE
smb-server-bf6556db7-ks62c   1/1     Running   0          10m

$ oc get pod,secret -n test-1
NAME                                 READY   STATUS    RESTARTS   AGE
pod/deploy-smb-pod-f6478d6c4-4sxl8   1/1     Running   0          3m49s

NAME                                         TYPE                                  DATA   AGE
secret/builder-dockercfg-dtvhp               kubernetes.io/dockercfg               1      8m46s
secret/builder-token-phnk8                   kubernetes.io/service-account-token   4      8m46s
secret/default-dockercfg-4gls6               kubernetes.io/dockercfg               1      8m46s
secret/default-token-zmqf5                   kubernetes.io/service-account-token   4      8m46s
secret/deployer-dockercfg-t74p4              kubernetes.io/dockercfg               1      8m46s
secret/deployer-token-9z4sh                  kubernetes.io/service-account-token   4      8m46s
secret/smbcreds                              Opaque                                2      8m46s
secret/test-deploy-smb-pod-dockercfg-255g7   kubernetes.io/dockercfg               1      8m3s
secret/test-deploy-smb-pod-token-2kj6s       kubernetes.io/service-account-token   4      8m3s

$ oc get pod,secret -n test-2
NAME                    READY   STATUS    RESTARTS   AGE
pod/statefulset-smb-0   1/1     Running   0          6m40s

NAME                              TYPE                                  DATA   AGE
secret/builder-dockercfg-zmnlc    kubernetes.io/dockercfg               1      6m42s
secret/builder-token-jqm5z        kubernetes.io/service-account-token   4      6m42s
secret/default-dockercfg-2684v    kubernetes.io/dockercfg               1      6m42s
secret/default-token-446xs        kubernetes.io/service-account-token   4      6m42s
secret/deployer-dockercfg-srcgf   kubernetes.io/dockercfg               1      6m42s
secret/deployer-token-vcxxh       kubernetes.io/service-account-token   4      6m42s
secret/smbcreds                   Opaque                                2      6m42s

$ oc get pvc -A
NAMESPACE              NAME                                    STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
test-1                 pvc-smb                                 Bound    pv-smb                                     50Gi       RWX                           8m43s
test-2                 persistent-storage-statefulset-smb-0    Bound    pvc-9dd28bf2-b77d-4ab9-9ff9-b0746911495c   10Gi       RWO            smb            6m52s
[...]

$ oc get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                                        STORAGECLASS   REASON   AGE
pv-smb                                     50Gi       RWX            Retain           Bound    test-1/pvc-smb                                                                       9m9s
pvc-9dd28bf2-b77d-4ab9-9ff9-b0746911495c   10Gi       RWO            Delete           Bound    test-2/persistent-storage-statefulset-smb-0                  smb                     5m10s
[...]
```

# Testing the shared volumes
```
# Write some files to the shared volume
oc project demo-smb-server
oc exec $(oc get pod -o name) -- bash -c "echo test-1 >> /root/smbshare/1"
oc exec $(oc get pod -o name) -- cat /root/smbshare/1
test-1

# Read the file from the test-1 pod and write another file
oc project test-1
oc exec $(oc get pod -o name) -- cat /mnt/smb/1
test-1
oc exec $(oc get pod -o name) -- bash -c "echo test-2 >> /mnt/smb/2"
oc exec $(oc get pod -o name) -- cat /mnt/smb/2
test-2

# As this is mounted using another stategy, the content is stored in a new directory
# The directory can be seen in the previous ls command from other pod if the workload was already created
# Check the comment on the storage class file and browse the documentation for advanced usage
oc project test-2
oc exec $(oc get pod -o name) -- bash -c "echo test-3 >> /mnt/smb/3"
oc exec $(oc get pod -o name) -- cat /mnt/smb/3
test-3
oc project test-1
oc exec $(oc get pod -o name) -- ls /mnt/smb/
1
2
outfile
pvc-0984b11d-0cf9-4aa7-b6b3-967ed1613a67
# The file is located inside the pvc directory
oc exec $(oc get pod -o name) -- cat /mnt/smb/pvc-0984b11d-0cf9-4aa7-b6b3-967ed1613a67/3
test-3
```

# Troubleshooting
To know which scc should be set to a workload, you can use the command: `oc get deploy <deployment> -o yaml | oc adm policy scc-subject-review -f -` as an admin inside the cluster.

Once you have indentified the scc you can use, you can set up the appropriate one by using this command: `oc adm policy add-scc-to-user -z <service_account>`.

If you do not have a service account for this specific workload already, the best practice would be to create one and map it to the deployment before granting the scc to the service account: `oc create sa <sa> && oc set sa deploy <deployment> <sa>`. Note that if no service account are specified in a workload, then the `default` one of the namespace will be used.

