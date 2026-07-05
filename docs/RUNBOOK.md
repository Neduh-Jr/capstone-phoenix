# Runbook

This document describes how to provision, deploy, operate, and recover the TaskApp Kubernetes cluster from scratch.

---

# Provision from zero

## 1. Provision the infrastructure

```bash
cd infra/terraform

terraform init
terraform plan
terraform apply
```

Terraform provisions:

- 1 K3s control-plane EC2 instance
- 2 K3s worker EC2 instances
- Security Groups
- Remote Terraform state (S3)
- DynamoDB state locking

---

## 2. Configure the Kubernetes cluster

```bash
cd ../ansible

ansible-playbook -i inventory site.yml
```

This playbook:

- Hardens the servers
- Installs K3s on the control-plane
- Joins the worker nodes
- Retrieves the kubeconfig

---

## 3. Configure kubectl

```bash
export KUBECONFIG=./kubeconfig

kubectl get nodes
```

Expected output:

- Control-plane Ready
- Worker 1 Ready
- Worker 2 Ready

---

## 4. Install platform components

Install cert-manager

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
```

Install Argo CD

```bash
kubectl create namespace argocd

kubectl apply \
-n argocd \
-f https://raw.githubusercontent.com/argoproj/argo-cd/v2.10.0/manifests/install.yaml
```

Expose the Argo CD UI

```bash
kubectl port-forward svc/argocd-server \
-n argocd \
8080:443
```

Metrics Server is included with K3s.

---

## 5. GitOps takes over

Deploy the Argo CD Application

```bash
kubectl apply -f gitops/taskapp-application.yaml
```

From this point onward, the desired cluster state is managed through Git. Any changes should be committed to GitHub, where Argo CD automatically synchronizes them to the cluster.

---

# Day-2 Operations

## Scale a workload

Preferred method:

- Edit the Deployment manifest in Git.
- Commit the change.
- Push to GitHub.
- Allow Argo CD to synchronize automatically.

Emergency (not recommended):

```bash
kubectl scale deployment backend \
--replicas=5 \
-n taskapp
```

This will eventually be overwritten by Argo CD.

---

## Roll back a bad deployment

```bash
git revert <commit>

git push origin development
```

Argo CD automatically detects the reverted commit and restores the previous working deployment.

---

## Run a new database migration

Update the migration Job manifest in Git.

Commit and push.

Allow Argo CD to deploy the migration Job before updating the backend Deployment.

This prevents migration races between multiple backend replicas.

---

## Rotate a secret

Update the Secret manifest.

```bash
kubectl create secret generic ...
```

or update the YAML in Git.

Commit the change.

Push to GitHub.

Argo CD synchronizes the updated Secret.

Restart affected Deployments if required.

---

# Failure Recovery

## Worker node failure or maintenance

Drain the worker node

```bash
kubectl drain <node> \
--ignore-daemonsets \
--delete-emptydir-data
```

Expected behaviour:

- Pods are evicted.
- Kubernetes schedules replacements on healthy nodes.
- Services continue serving traffic.
- PodDisruptionBudgets prevent excessive disruption.
- HPA continues operating normally.

Recovery time is typically less than one minute.

Return the node to service

```bash
kubectl uncordon <node>
```

---

## Backend Pod CrashLoopBackOff

Inspect pod status

```bash
kubectl describe pod <pod-name> -n taskapp
```

View logs

```bash
kubectl logs <pod-name> -n taskapp

kubectl logs --previous <pod-name> -n taskapp
```

Inspect cluster events

```bash
kubectl get events \
-n taskapp \
--sort-by=.lastTimestamp
```

Typical causes include:

- Incorrect environment variables
- Database connectivity issues
- Failed application startup
- Image errors

---

## Bad database migration

Revert the migration commit

```bash
git revert <commit>

git push origin development
```

Allow Argo CD to synchronize.

If schema rollback is required, restore the database from the latest backup before redeploying the application.

---

## PostgreSQL Pod rescheduled

Delete the pod

```bash
kubectl delete pod postgres-0 \
-n taskapp
```

Verify Kubernetes recreates the pod

```bash
kubectl get pods -n taskapp
```

Verify the Persistent Volume Claim remains attached

```bash
kubectl get pvc -n taskapp
```

Log into the application and verify previously created users and application data still exist.

This confirms that persistent storage survives Pod recreation.