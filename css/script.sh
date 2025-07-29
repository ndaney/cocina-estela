#!/bin/bash
# Limpia cluster redis y elimina pods
echo "-------------------------------------"
echo "LIMPIANDO PODS, PVC DE REDIS"
echo "-------------------------------------"
# Reiniciando pods
kubectl config use-context gke_reba-test-k8s_us-east1_k8s-test
for x in $(seq 0 5); do kubectl delete -n redis pvc data-redis-cluster-$x --force=true --wait=false; echo "Eliminando PVC data-redis-cluster-$x"; done
for pod in $(kubectl get -n redis pods | grep redis-cluster | awk '{print $1}'); do kubectl delete -n redis pod $pod; echo "Eliminado $pod"; done
# Contador de
echo "SE ESPERAN 105s PARA REPLICAR NODOS"
#sleep 180
# Activate the Redis cluster
echo "-----------------------"
echo "Creando Cluster Redis"
echo "-----------------------"
# Find ClusterIPs of Redis nodes
export REDIS_NODES=$(kubectl get pods -l app=redis-cluster -n redis -o json | jq -r '.items | map(.status.podIP) | join(":6379 ")'):6379
echo "--------------------------------"
echo "Nodos para agregar $REDIS_NODES"
echo "--------------------------------"
kubectl exec -it redis-cluster-0 -n redis -- redis-cli --cluster-yes --cluster create --cluster-replicas 1 ${REDIS_NODES}
# # Check if all went well
#for x in $(seq 0 5); do echo "redis-cluster-$x"; kubectl --kubeconfig /home/rundeck/files/.kube/kubeconfig-test exec redis-cluster-$x -n redis -- redis-cli role; echo "Cluster $x"; done
for item in $(kubectl get -n redis pods -l app=redis-cluster -o name);do
    items=${item#pod/}
    echo $items
    kubectl -n redis exec $items -- redis-cli info replication | grep -E "role|connected_slaves|slave0|master_link_status"
    done