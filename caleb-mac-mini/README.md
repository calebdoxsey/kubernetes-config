## K3D
Using `k3d` to setup the cluster:

```bash
cd $HOME
k3d cluster create \
    --api-port '6443' \
    --no-lb \
    --port '443:30443@server[0]' \
    --port '80:30080@server[0]' \
    --volume 'data:/data'
```

## Secrets
Part of the pomerium config is stored in a secret:

```bash
kubectl create secret generic pomerium \
    --from-literal="SHARED_SECRET=$(head -c32 /dev/urandom | base64)" \
    --from-literal="COOKIE_SECRET=$(head -c32 /dev/urandom | base64)" \
    --from-literal="IDP_CLIENT_ID=..." \
    --from-literal="IDP_CLIENT_SECRET=..." \
    --from-literal="IDP_SERVICE_ACCOUNT=..."
```
