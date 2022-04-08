<!--
 * @Author: cnak47
 * @Date: 2022-04-08 11:46:13
 * @LastEditors: cnak47
 * @LastEditTime: 2022-04-08 17:01:51
 * @FilePath: /ak47Docker/k3s/addons/traefik/2.6.3/readme.md
 * @Description: 
 * 
 * Copyright (c) 2022 by cnak47, All Rights Reserved. 
-->
# Install Traefik Kubernetes CRD Ingress Controller

- 001-3-tls-options.yaml 
  (optional),enforces by default that TLS 1.3 is to be used for secure connections
- 002-0-middlewares-basic-auth.yaml 
  (optional),provides username / password authentication and is used in these examples for securing the Traefik dashboard using Basic Authentication
- 002-1-middlewares-secure-headers.yaml 
  (optional), this creates a middleware that can be used to set secure headers on responses
- 002-secrets.yaml
  (optional), 
  - but is needed if using Basic Authentication for the dashboard
  - integrating with LetsEncrypt (depending on your mechanism) for API keys etc. for your DNS provider as per the examples further down
