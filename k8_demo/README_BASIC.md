# Kubernetes + PostgreSQL Deployment Guide (WSL Edition)

This walkthrough documents the process I used to stand up a local Kubernetes cluster on **Windows Subsystem for Linux (WSL)** using **Kind**, deploy a PostgreSQL database, and connect an application to it.  
It’s meant to be lightweight, repeatable, and useful for testing workloads or demos.

---

## Prerequisites

- Docker Desktop (with WSL integration enabled)
- WSL 2 running Ubuntu
- Internet access

Before starting, confirm Docker is accessible inside WSL:

```bash
docker ps
```

If this errors out, open Docker Desktop → Settings → **Resources → WSL Integration** and enable it for your Ubuntu distro.

---

## 1. Install Required Tools

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl ca-certificates gnupg lsb-release apt-transport-https jq
curl -fsSL https://dl.k8s.io/release/stable.txt -o /tmp/k8sver
KVER=$(cat /tmp/k8sver)
curl -LO "https://dl.k8s.io/release/${KVER}/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64"
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
sudo apt install -y postgresql-client
kubectl version --client --short
kind --version
psql --version
```

---

## 2. Create Cluster

```bash
cat > kind-config.yaml <<'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
EOF

kind create cluster --name wsl-demo --config kind-config.yaml
kubectl cluster-info --context kind-wsl-demo
kubectl get nodes
```

---

## 3. Namespace + Secret

```bash
kubectl create ns demo
kubectl create secret generic postgres-secret --from-literal=POSTGRES_PASSWORD='mysecretpassword' -n demo
```

---

## 4. Deploy PostgreSQL

Save as `postgres.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: demo
spec:
  type: ClusterIP
  ports:
    - port: 5432
      targetPort: 5432
  selector:
    app: postgres
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: demo
spec:
  serviceName: "postgres"
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: demo
        - name: POSTGRES_USER
          value: demo_user
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: POSTGRES_PASSWORD
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi
```
```bash
kubectl apply -f postgres.yaml
kubectl -n demo get pods,svc
```

---

## 5. Connect

```bash
kubectl -n demo port-forward svc/postgres 5432:5432
psql "host=127.0.0.1 port=5432 user=demo_user dbname=demo password=mysecretpassword"
```

or

```bash
kubectl -n demo exec -it statefulset/postgres -- bash
psql -U demo_user -d demo
```

---

## 6. Deploy App

Save as `app.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: demo-app
  template:
    metadata:
      labels:
        app: demo-app
    spec:
      containers:
      - name: demo-app
        image: busybox
        command: ["sh", "-c", "while true; do env; sleep 60; done"]
        env:
        - name: DB_HOST
          value: postgres
        - name: DB_PORT
          value: "5432"
        - name: DB_USER
          value: demo_user
        - name: DB_PASS
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: POSTGRES_PASSWORD
---
apiVersion: v1
kind: Service
metadata:
  name: demo-app
  namespace: demo
spec:
  type: ClusterIP
  ports:
  - port: 8080
    targetPort: 8080
  selector:
    app: demo-app
```
```bash
kubectl apply -f app.yaml
kubectl -n demo get pods,svc
```

---

## 7. Cleanup

```bash
kubectl delete ns demo
kind delete cluster --name wsl-demo
```
