## CertManager

```bash
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml
```

## Secrets:

```bash
# Minio Backup
kubectl create secret generic minio \
    --from-literal=MINIO_ACCESS_KEY='minio' \
    --from-literal=MINIO_SECRET_KEY='???'

# Cloudflare DNS
kubectl create secret generic cloudflare \
    --from-literal=email='caleb@doxsey.net' \
    --from-literal=api-key='???'

# OpenDNS
kubectl create secret generic opendns \
    --from-literal=username='caleb@doxsey.net' \
    --from-literal=password='???'
```
