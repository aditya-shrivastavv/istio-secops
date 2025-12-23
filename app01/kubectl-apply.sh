# Phase 1: Base

kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment-v1.yaml
kubectl apply -f k8s/deployment-v2.yaml
kubectl apply -f k8s/service.yaml

# temp
kubectl set image deploy app01-v1 app01=wizhubdocker8s/istio-demo:latest -n staging
kubectl set image deploy app01-v2 app01=wizhubdocker8s/istio-demo:latest -n staging

# curl app01.staging.svc.cluster.local:80/api/devices
# will distribute traffic between v1 and v2

# Phase 2: Istio Resources
kubectl apply -f k8s/destination-rule.yaml
kubectl apply -f k8s/virtual-service.yaml

# as per the virtual service, 100% traffic will go to v2 only