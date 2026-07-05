# Cost

This project extends the earlier single-server Docker deployment into a production-oriented Kubernetes platform. While the infrastructure costs are higher, the additional expense provides high availability, automated recovery, GitOps deployment, and zero-downtime updates.

---

## Monthly itemized cost

| Item | Spec | Qty | Approx. $/mo |
|---|---|---:|---:|
| Control Plane VM | AWS EC2 t3.small | 1 | $15 |
| Worker VM | AWS EC2 t3.small | 2 | $30 |
| Block Storage | AWS EBS volumes (PVCs) | 3 | $3 |
| Remote Terraform State | Amazon S3 | 1 | <$1 |
| State Locking | Amazon DynamoDB | 1 | <$1 |
| Domain | nip.io (wildcard DNS) | 1 | $0 |
| Load Balancer | K3s Traefik Service | Included | $0 |
| **Total** | | | **≈ $49/month** |

---

## Compared to the single-server Compose + Portainer deployment

The previous Docker Compose deployment required only a single EC2 instance and cost approximately **$15/month**.

This Kubernetes deployment costs approximately **$49/month**, which is over three times more expensive.

The additional cost provides several production-grade capabilities that a single server cannot offer:

- High availability through multiple worker nodes
- Automatic pod rescheduling when a node fails
- Horizontal Pod Autoscaling (HPA)
- Zero-downtime rolling deployments
- Persistent storage using StatefulSets and Persistent Volume Claims
- GitOps deployment using Argo CD
- Automatic TLS certificate management with cert-manager
- Better scalability for future growth

For hobby projects, personal websites, or small internal tools, the additional cost is usually not justified. A single-server Docker deployment is simpler, cheaper, and easier to maintain.

For business-critical applications where uptime, scalability, and reliability are important, the Kubernetes architecture provides significant operational advantages that justify the increased infrastructure cost.

---

## How I'd halve this

If this environment were intended for long-term use, I would reduce costs by using Spot Instances for the worker nodes, since they are significantly cheaper than On-Demand instances. The control plane would remain on an On-Demand instance for stability, while the workers could be recreated automatically if interrupted. I would also resize the control plane to a smaller instance if monitoring showed consistently low resource utilization. If the application did not require high availability, the worker count could be reduced from two to one, lowering the monthly infrastructure cost while still preserving the Kubernetes deployment model. Finally, replacing nip.io with a low-cost domain would have minimal impact on the overall monthly cost while providing a more professional endpoint.