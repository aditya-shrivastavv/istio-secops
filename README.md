# Istio SecOps Practice

<https://istio.io/latest/docs/>

Prequisites:

- Istio Install [istio-install.sh](./istio-install.sh)
- Client Pod Install `kubectl apply -f client/k8s/`
- Kiali Setup
  - `kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/addons/kiali.yaml`
  - `kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/addons/prometheus.yaml`
  - `k port-forward -n istio-system svc/kiali 20001:20001`

## `app01`: VirtualService and DestinationRule example

- 2 deployments of same application. 2 versions v1 and v2 differentiated by just a environment variable.
- DestinationRule and VirtualService is used to send 100% of traffic to v2 version only.

```sh
kubectl apply -f app01/

for i in {1..10}; do k exec -it -n client nginx -- curl app01.staging.svc/api/devices; echo; done
```

output:

```json
{"version":"v2","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}
{"version":"v2","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}
{"version":"v2","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}
{"version":"v2","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}
{"version":"v2","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}
{"version":"v2","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}
{"version":"v2","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}
{"version":"v2","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}
{"version":"v2","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}
{"version":"v2","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}
```

## `app02`: VirtualService and DestinationRule with Gateway example

- 2 deployments of same application. 2 versions v1 and v2 differentiated by just a environment variable.
- DestinationRule and VirtualService is used to send 100% of traffic to v2 version only.
- Gateway is used to expose the application outside the cluster.

```sh
kubectl apply -f app02/

for i in {1..10}; do k exec -it -n client nginx -- curl -H "Host: app.easydevops.com" http://192.168.49.2:30562/api/devices; echo; done
```

output:

```json
{"version":"v2","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}
{"version":"v2","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}
{"version":"v2","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}
{"version":"v2","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}
{"version":"v2","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}
{"version":"v2","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}
{"version":"v2","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}
{"version":"v2","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}
{"version":"v2","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}
{"version":"v2","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}
```

- The IP is the Minikube IP and the port is the NodePort of the Gateway Service.
  - `minikube ip`
- Port is obtained from:
  - `kubectl get svc -n istio-system istio-ingressgateway`
- Making curl requests without IP and host address from the client pod will work but not as expected.
  - It would work like a simple kubernetes service without any traffic management. So traffic would be distributed between v1 and v2 versions.
  - This is because the Gateway is not being used in this case.
  - To make it work in this case, we need to add `mesh` gateway in the VirtualService. So that the requests from within the cluster also goes through the Gateway.

## `app03`: PeerAuthentication example

- 1 deployment of application in `production` namespace. Namespace is istio-injected.
- 1 pod in `client` namespace to make requests to the application in `production` namespace. Namespace is istio-injected.
- PeerAuthentication is used to enforce mTLS in `production` namespace. Policy requires mTLS traffic for all workloads under namespace `production`.

```sh
kubectl apply -f app03/
kubectl apply -f client/k8s/

kubectl exec -it -n client nginx -- curl app03-svc.production.svc/api/devices
```

output:

```json
{"version":"v1","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}
```

- Since mTLS is enforced in `production` namespace, the requests from `client` namespace to `production` namespace will be encrypted using mTLS.
- If one of the namespaces is not istio-injected, the request will fail.

```sh
kubectl label ns client istio-injection-
kubectl replace -f client/k8s/pod.yaml --force

kubectl exec -it -n client nginx -- curl app03-svc.production.svc/api/devices
```

output:

```sh
curl: (56) Recv failure: Connection reset by peer
command terminated with exit code 56
```

- The error indicates that the connection was reset because the request was not using mTLS, which is required by the PeerAuthentication policy in the `production` namespace.

## `app04`: AuthorizationPolicy example

## `app05`: FaultInjection example

## `app06`: Mirroring example

## `app07`: CircuitBreaking example

## `app08`: RequestTimeout example

## Ambient Mode
