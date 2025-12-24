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
kubectl apply -f app01/k8s/

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
kubectl apply -f app02/k8s/

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

## `app03`: PeerAuthentication example

## `app04`: AuthorizationPolicy example

## `app05`: FaultInjection example

## `app06`: Mirroring example

## `app07`: CircuitBreaking example

## `app08`: RequestTimeout example
