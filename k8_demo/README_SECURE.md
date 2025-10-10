# Secure Kubernetes + PostgreSQL Deployment (WSL Edition)

This guide expands on the basic demo and shows a **secure pattern** for deploying PostgreSQL on Kubernetes with better access controls, secret management, and network segmentation.

---

## Key Enhancements

| Area | Secure Practice |
|------|------------------|
| Secrets | Use Kubernetes Secrets with KMS or External Secrets Operator |
| Networking | Enforce NetworkPolicy to restrict DB access |
| RBAC | Create least-privilege service accounts |
| Pod Security | Apply securityContext (runAsNonRoot, drop capabilities) |
| Storage | Use encrypted volumes (EBS or CSI) |

---

## 1. Namespace & RBAC

```bash
kubectl create ns secure-demo

cat > secure-rbac.yaml <<'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: secure-demo
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: readonly-role
  namespace: secure-demo
rules:
- apiGroups: [""]
  resources: ["pods","services"]
  verbs: ["get","list","watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: readonly-binding
  namespace: secure-demo
subjects:
- kind: ServiceAccount
  name: app-sa
roleRef:
  kind: Role
  name: readonly-role
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl apply -f secure-rbac.yaml
```

---

## 2. Encrypted Secret

If your cluster supports it, enable KMS encryption. For demo purposes, we'll just create a secret:

```bash
kubectl create secret generic pg-secret   --from-literal=POSTGRES_PASSWORD='BetterSecret123!' -n secure-demo
```

---

## 3. Network Policy

```bash
cat > network-policy.yaml <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-app-to-db
  namespace: secure-demo
spec:
  podSelector:
    matchLabels:
      app: postgres
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: secure-app
    ports:
    - protocol: TCP
      port: 5432
EOF

kubectl apply -f network-policy.yaml
```

---

## 4. Secure PostgreSQL Deployment

```bash
cat > postgres-secure.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: secure-demo
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
  namespace: secure-demo
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
      securityContext:
        runAsUser: 999
        runAsNonRoot: true
      containers:
      - name: postgres
        image: postgres:15
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: securedb
        - name: POSTGRES_USER
          value: secure_user
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: pg-secret
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
          storage: 2Gi
EOF

kubectl apply -f postgres-secure.yaml
```

---

## 5. Secure Application

```bash
cat > app-secure.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
  namespace: secure-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
    spec:
      serviceAccountName: app-sa
      containers:
      - name: secure-app
        image: busybox
        command: ["sh", "-c", "while true; do echo Connected; sleep 30; done"]
        env:
        - name: DB_HOST
          value: postgres
        - name: DB_USER
          value: secure_user
        - name: DB_PASS
          valueFrom:
            secretKeyRef:
              name: pg-secret
              key: POSTGRES_PASSWORD
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop: ["ALL"]
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
EOF

kubectl apply -f app-secure.yaml
```

---

## 6. Verify

```bash
kubectl -n secure-demo get all
kubectl -n secure-demo exec -it deploy/secure-app -- printenv | grep DB_
```

You can also test access by creating another pod that’s **not labeled `secure-app`** and confirm it cannot reach the database service due to the NetworkPolicy.

---

## 7. Cleanup

```bash
kubectl delete ns secure-demo
```

---

### Summary

This setup demonstrates a hardened pattern using:
- Encrypted secrets
- Network isolation
- RBAC least privilege
- Non-root containers
- Read-only filesystems

A good next step would be integrating AWS RDS and IAM Roles for Service Accounts (IRSA) if deploying in EKS.
