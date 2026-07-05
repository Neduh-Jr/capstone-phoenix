# Architecture

## 1. Topology diagram

```
                                Internet
                                    │
                                    │
                     https://51-21-135-133.nip.io
                                    │
                                    ▼
                          Traefik Ingress Controller
                         (Let's Encrypt TLS via cert-manager)
                                    │
                  ┌─────────────────┴─────────────────┐
                  │                                   │
                  ▼                                   ▼
          Frontend Service                     Backend Service
                  │                                   │
        ┌─────────┴─────────┐             ┌───────────┴───────────┐
        │                   │             │                       │
Frontend Pod          Frontend Pod   Backend Pod            Backend Pod
Worker Node 1         Worker Node 2  Worker Node 1         Worker Node 2
                  │                           │
                  └───────────────/api────────┘
                                  │
                                  ▼
                         PostgreSQL Service
                                  │
                                  ▼
                        PostgreSQL StatefulSet
                     Persistent Volume Claim (PVC)
```

---

## 2. Node & network

### Nodes

| Node | Role | Instance | Region |
|------|------|----------|--------|
| Control Plane | Kubernetes API Server, Scheduler, Controller Manager | t3.small | eu-north-1 |
| Worker 1 | Application workloads | t3.small | eu-north-1 |
| Worker 2 | Application workloads | t3.small | eu-north-1 |

### Network

The infrastructure was provisioned inside a single VPC using private networking between the Kubernetes nodes. Terraform outputs were consumed by Ansible to configure the cluster automatically.

### Firewall

Only the following ports are publicly accessible:

- TCP 22 (restricted to my public IP) for SSH
- TCP 80 for HTTP
- TCP 443 for HTTPS

The Kubernetes API (6443) is **not exposed publicly**. Worker nodes communicate with the control plane using private networking, reducing the attack surface.

---

## 3. Request flow

A user accesses the application through **https://51-21-135-133.nip.io**. DNS resolves the nip.io hostname to the public IP of the control plane. The request reaches the Traefik Ingress Controller, where TLS is terminated using certificates issued by Let's Encrypt through cert-manager. Requests for `/` are forwarded to the Frontend Service on port 80. The React frontend communicates with the Flask backend through the `/api` endpoint, which is routed internally by Kubernetes Services to the Backend Deployment. The backend processes requests and communicates with PostgreSQL through the postgres Service, which forwards traffic to the PostgreSQL StatefulSet backed by a Persistent Volume Claim.

---

## 4. The single-server assumptions you fixed

| Single-server assumption | Why it breaks at scale | How it was fixed |
|---|---|---|
| Database migrations run during application startup | Multiple backend replicas may attempt migrations simultaneously | Database migrations were moved to a dedicated Kubernetes Job before application startup |
| Local Docker volume stores PostgreSQL data | Pods may be rescheduled onto different nodes | PostgreSQL was deployed as a StatefulSet using a Persistent Volume Claim |
| Publishing container ports directly on the host | Multiple replicas across multiple nodes require service discovery | Kubernetes Services and Traefik Ingress provide a single entry point |
| One backend replica is sufficient | Pod failure causes application downtime | Backend deployed with multiple replicas managed by a Deployment |
| One frontend replica is sufficient | Frontend becomes unavailable if a pod fails | Frontend deployed with multiple replicas distributed across worker nodes |
| Containers always remain healthy | Applications may crash without automatic recovery | Liveness, readiness and startup probes restart unhealthy containers automatically |
| Deployments can stop old pods before starting new ones | Users experience downtime during updates | RollingUpdate strategy with `maxUnavailable: 0` ensures zero-downtime deployments |
| Secrets stored inside application files | Credentials become exposed and difficult to rotate | Sensitive values moved into Kubernetes Secrets while non-sensitive configuration uses ConfigMaps |
| Manual deployment with kubectl | Cluster state becomes inconsistent over time | Argo CD continuously synchronizes the cluster from the GitHub repository |

---

## 5. Choices & trade-offs

### Raw YAML vs Helm vs Kustomize

Raw Kubernetes manifests combined with Kustomize were chosen because the project requirements were straightforward and did not require the templating complexity of Helm. Kustomize also integrates natively with kubectl and Argo CD.

### Traefik vs NGINX Ingress

Traefik was selected because it is bundled with K3s, reducing installation complexity while providing native support for Kubernetes Ingress resources and seamless integration with cert-manager.

### CNI / NetworkPolicy

The project uses K3s networking with NetworkPolicy resources to restrict communication between workloads. Only the backend can access PostgreSQL, while external traffic is limited to the ingress controller.

### Secrets Management

Kubernetes Secrets were used because they satisfied the project requirements while keeping sensitive values out of application manifests. Sealed Secrets or External Secrets would provide stronger GitOps security in production environments but were outside the scope of this implementation.

### GitOps

Argo CD was selected to manage the desired cluster state. All Kubernetes manifests reside in GitHub, and changes are automatically synchronized to the cluster without requiring manual `kubectl apply` commands, ensuring consistency and reproducibility.