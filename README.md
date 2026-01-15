# Istio SecOps Practice

<https://istio.io/latest/docs/>

Prequisites:

- Istio Install [istio-install.sh](./istio-install.sh)
- Client Pod Install `kubectl apply -f client/k8s/`
- Kiali Setup
  - `kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/addons/kiali.yaml`
  - `kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/addons/prometheus.yaml`
  - `k port-forward -n istio-system svc/kiali 20001:20001`

## Table of Contents

- [Istio SecOps Practice](#istio-secops-practice)
  - [Table of Contents](#table-of-contents)
  - [`app01`: VirtualService and DestinationRule example](#app01-virtualservice-and-destinationrule-example)
  - [`app02`: VirtualService and DestinationRule with Gateway example](#app02-virtualservice-and-destinationrule-with-gateway-example)
  - [`app03`: PeerAuthentication example](#app03-peerauthentication-example)
  - [`app04`: AuthorizationPolicy example](#app04-authorizationpolicy-example)
  - [`app05`: FaultInjection example](#app05-faultinjection-example)
  - [`app06`: Mirroring example](#app06-mirroring-example)
  - [`app07`: CircuitBreaking example](#app07-circuitbreaking-example)
  - [`app08`: RequestTimeout example](#app08-requesttimeout-example)
  - [Ambient Mode](#ambient-mode)

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

- 1 deployment of application in `app04` namespace. Namespace is istio-injected.
- 1 pod in `client` namespace to make requests to the application in `app04` namespace. Both namespaces are istio-injected.
- AuthorizationPolicy is used to control access to the application based on source namespace and operations.
- Demo shows three scenarios: default allow, deny-all, and selective allow policies.

**Scenario 1: Default behavior (no AuthorizationPolicy)**

```sh
kubectl apply -f app04/namespace.yaml
kubectl apply -f app04/deployment-v1.yaml
kubectl apply -f app04/service.yaml
kubectl apply -f client/k8s/

kubectl exec -it -n client nginx -- curl app04-svc.app04.svc
```

output:

```json
{"version":"v1","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}
```

- Without any AuthorizationPolicy, all traffic is allowed by default.

**Scenario 2: Deny all traffic**

```sh
kubectl apply -f app04/authorization-policy-deny-all.yaml

kubectl exec -it -n client nginx -- curl app04-svc.app04.svc
```

output:

```sh
RBAC: access denied
```

- The deny-all policy blocks all traffic to the app04 workloads.
- This demonstrates the default-deny approach for zero-trust security.

**Scenario 3: Allow traffic from specific namespace**

```sh
kubectl delete -f app04/authorization-policy-deny-all.yaml
kubectl apply -f app04/authorization-policy-allow-client.yaml

kubectl exec -it -n client nginx -- curl app04-svc.app04.svc
```

output:

```json
{"version":"v1","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}
```

- The allow policy explicitly permits traffic from the `client` namespace.
- Traffic from other namespaces would be denied (default deny when ALLOW policies exist).

**Scenario 4: Allow only GET methods**

```sh
kubectl delete -f app04/authorization-policy-allow-client.yaml
kubectl apply -f app04/authorization-policy-allow-get-only.yaml

# GET request (allowed)
kubectl exec -it -n client nginx -- curl app04-svc.app04.svc

# POST request (denied)
kubectl exec -it -n client nginx -- curl -X POST app04-svc.app04.svc
```

output:

```sh
# GET succeeds
{"version":"v1","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}

# POST fails
RBAC: access denied
```

- The policy allows only GET requests from the `client` namespace.
- All other HTTP methods (POST, PUT, DELETE, etc.) are denied.

**Cleanup:**

```sh
kubectl delete -f app04/
```

## `app05`: FaultInjection example

- 1 deployment of application in `app05` namespace. Namespace is istio-injected.
- VirtualService with fault injection rules to simulate network delays and service failures.
- Demonstrates delay injection, abort injection, and combined fault scenarios for testing application resilience.

**Setup:**

```sh
kubectl apply -f app05/namespace.yaml
kubectl apply -f app05/deployment-v1.yaml
kubectl apply -f app05/service.yaml
kubectl apply -f app05/destination-rule.yaml
kubectl apply -f client/k8s/
```

**Scenario 1: Normal behavior (no fault injection)**

```sh
kubectl apply -f app05/virtual-service-no-fault.yaml

time kubectl exec -it -n client nginx -- curl app05-svc.app05.svc/api/devices
```

output:

```json
{"version":"v1","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}

real    0m0.123s
```

- Without fault injection, requests complete quickly with normal response time.

**Scenario 2: Delay injection (network latency simulation)**

```sh
kubectl apply -f app05/virtual-service-delay.yaml

time kubectl exec -it -n client nginx -- curl app05-svc.app05.svc/api/devices
```

output:

```json
{"version":"v1","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}

real    0m5.245s
```

- 100% of requests experience a 5-second delay before the response.
- Useful for testing timeout handling and user experience under high latency.
- The response is successful but delayed by exactly 5 seconds.

**Scenario 3: Abort injection (service failure simulation)**

```sh
kubectl apply -f app05/virtual-service-abort.yaml

kubectl exec -it -n client nginx -- curl -v app05-svc.app05.svc/api/devices
```

output:

```sh
< HTTP/1.1 503 Service Unavailable
...
fault filter abort
```

- 100% of requests return HTTP 503 (Service Unavailable) error.
- The request never reaches the actual service; the fault is injected by the Envoy proxy.
- Useful for testing error handling, circuit breakers, and retry logic.

**Scenario 4: Combined fault injection (realistic chaos testing)**

```sh
kubectl apply -f app05/virtual-service-combined.yaml

# Run multiple requests to see different behaviors
for i in {1..10}; do 
  echo "Request $i:"
  time kubectl exec -it -n client nginx -- curl -s app05-svc.app05.svc/api/devices || echo "Failed"
  echo "---"
done
```

output:

```sh
Request 1:
{"version":"v1","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}
real    0m3.156s
---
Request 2:
fault filter abort
Failed
real    0m0.089s
---
Request 3:
{"version":"v1","devices":[{"id":1,"mac":"5F-33-CC-1F-43-82","firmware":"2.1.6"}]}
real    0m0.098s
---
```

- 50% of requests experience a 3-second delay.
- 30% of requests fail with HTTP 500 (Internal Server Error).
- Remaining 20% proceed normally.
- This simulates realistic production issues for comprehensive resilience testing.
- Use this to validate retry mechanisms, circuit breakers, and fallback strategies.

**Key concepts:**

- **Delay injection**: Tests application behavior under network latency without actual network issues.
- **Abort injection**: Simulates service failures to validate error handling and recovery mechanisms.
- **Percentage-based faults**: Allows gradual testing and realistic chaos engineering scenarios.
- **Envoy proxy injection**: Faults are injected at the proxy level, not in application code.

**Cleanup:**

```sh
kubectl delete -f app05/
```

## `app06`: Mirroring example

## `app07`: CircuitBreaking example

## `app08`: RequestTimeout example

## Ambient Mode
