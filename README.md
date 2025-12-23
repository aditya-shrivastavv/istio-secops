# Istio SecOps Practice

## `app01`

- 2 deployments of same application. 2 versions v1 and v2 differentiated by just a environment variable.
- DestinationRule and VirtualService is used to send 100% of traffic to v2 version only.
