## K3D
Using `k3d` to setup the cluster:

```bash
cd $HOME
k3d registry create \
    'registry.localhost.pomerium.io' \
    --port '5000'

k3d cluster create \
    --api-port '6443' \
    --no-lb \
    --port '443:30443@server[0]' \
    --port '80:30080@server[0]' \
    --volume "$HOME/data:/data" \
    --registry-use 'k3d-registry.localhost.pomerium.io:5000'
```

## Load Console

```bash
docker pull \
    'gcr.io/pomerium-registry/pomerium-console:master'
docker tag \
    'gcr.io/pomerium-registry/pomerium-console:master' \
    'k3d-registry.localhost.pomerium.io:5000/pomerium-console:master'
docker push \
    'k3d-registry.localhost.pomerium.io:5000/pomerium-console:master'
```

## Secrets
Part of the pomerium config is stored in a secret:

```bash
# pomerium
kubectl create secret generic pomerium \
    --from-literal="SHARED_SECRET=$(head -c32 /dev/urandom | base64)" \
    --from-literal="COOKIE_SECRET=$(head -c32 /dev/urandom | base64)" \
    --from-literal="DATABASE_ENCRYPTION_KEY=$(head -c32 /dev/urandom | base64)" \
    --from-literal="SIGNING_KEY=?" \
    --from-literal="IDP_CLIENT_ID=?" \
    --from-literal="IDP_CLIENT_SECRET=?" \
    --from-literal="IDP_SERVICE_ACCOUNT=?"

# minio
kubectl create secret generic minio \
    --from-literal="MINIO_SECRET_KEY=?" \
    --from-literal="MINIO_ROOT_PASSWORD=?"
```


