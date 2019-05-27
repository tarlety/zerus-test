#!/bin/bash

NAMESPACE=$1
PVCNAME=$2
CAPACITY=$3
PATHNAME=$4
TYPENAME=$5

cat <<EOF | kubectl create -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${NAMESPACE}-${PVCNAME}
spec:
  accessModes:
    - ReadWriteMany
  capacity:
    storage: ${CAPACITY}
  claimRef:
    namespace: ${NAMESPACE}
    name: ${PVCNAME}
  cephfs:
    monitors:
      - 10.13.13.101:6789
    path: /kube-store/${NAMESPACE}/${TYPENAME}
    user: admin
    secretRef:
      name: ceph-secret
    readOnly: false
  persistentVolumeReclaimPolicy: Retain
EOF

kubectl get secret -n ${NAMESPACE} | grep ceph-secret
if [ $? -eq 1 ]
then
	KEYGENERATOR="ws ssh ws sudo cat store/ceph/etc/ceph/admin.secret"

	cat <<EOF | kubectl create -f -
apiVersion: v1
data:
  key: $($KEYGENERATOR | base64)
kind: Secret
metadata:
  name: ceph-secret
  namespace: $NAMESPACE
type: Opaque
EOF
fi

