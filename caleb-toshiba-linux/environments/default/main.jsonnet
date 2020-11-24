{
  main: {
    namespace: {
      apiVersion: 'v1',
      kind: 'Namespace',
      metadata: {
        name: 'default',
      },
    },
  },

  minio: {
    deployment: {
      apiVersion: 'apps/v1',
      kind: 'Deployment',
      metadata: {
        name: 'minio',
      },
      spec: {
        selector: {
          matchLabels: {
            name: 'minio',
          },
        },
        template: {
          metadata: {
            labels: {
              name: 'minio',
            },
          },
          spec: {
            initContainers: [{
              image: 'minio/minio',
              name: 'minio-init',
              command: [
                'sh',
                '-c',
                'mkdir -p /root/.minio/certs ;' +
                'cp /certs/tls.crt /root/.minio/certs/public.crt ;' +
                'cp /certs/tls.key /root/.minio/certs/private.key',
              ],
              volumeMounts: [
                {
                  name: 'root-tls',
                  mountPath: '/certs',
                },
                {
                  name: 'minio-config',
                  mountPath: '/root/.minio',
                },
              ],
            }],
            containers: [{
              image: 'minio/minio',
              name: 'minio',
              args: ['server', '/data'],
              ports: [{
                containerPort: 9000,
                name: 'minio',
              }],
              env: [
                {
                  name: 'MINIO_ACCESS_KEY',
                  valueFrom: {
                    secretKeyRef: {
                      name: 'minio',
                      key: 'MINIO_ACCESS_KEY',
                    },
                  },
                },
                {
                  name: 'MINIO_SECRET_KEY',
                  valueFrom: {
                    secretKeyRef: {
                      name: 'minio',
                      key: 'MINIO_SECRET_KEY',
                    },
                  },
                },
              ],
              volumeMounts: [{
                name: 'minio-config',
                mountPath: '/root/.minio',
              }],
            }],
            volumes: [
              {
                name: 'root-tls',
                secret: {
                  secretName: 'root-tls',
                },
              },
              {
                name: 'minio-config',
                emptyDir: {},
              },
            ],
          },
        },
      },
    },
    service: {
      apiVersion: 'v1',
      kind: 'Service',
      metadata: {
        name: 'minio',
        labels: {
          name: 'minio',
        },
      },
      spec: {
        type: 'NodePort',
        selector: {
          name: 'minio',
        },
        ports: [{
          name: 'minio',
          port: 9000,
          targetPort: 9000,
          nodePort: 30721,
        }],
      },
    },
  },

  certmanager: {
    issuer: {
      staging: {
        apiVersion: 'cert-manager.io/v1',
        kind: 'Issuer',
        metadata: {
          name: 'letsencrypt-staging',
        },
        spec: {
          acme: {
            email: 'caleb@doxsey.net',
            server: 'https://acme-staging-v02.api.letsencrypt.org/directory',
            privateKeySecretRef: {
              name: 'letsencrypt-staging',
            },
            solvers: [
              {
                dns01: {
                  cloudflare: {
                    email: 'caleb@doxsey.net',
                    apiKeySecretRef: {
                      name: 'cloudflare',
                      key: 'api-key',
                    },
                  },
                },
              },
            ],
          },
        },
      },
      prod: {
        apiVersion: 'cert-manager.io/v1',
        kind: 'Issuer',
        metadata: {
          name: 'letsencrypt-prod',
        },
        spec: {
          acme: {
            email: 'caleb@doxsey.net',
            server: 'https://acme-v02.api.letsencrypt.org/directory',
            privateKeySecretRef: {
              name: 'letsencrypt-prod',
            },
            solvers: [
              {
                dns01: {
                  cloudflare: {
                    email: 'caleb@doxsey.net',
                    apiKeySecretRef: {
                      name: 'cloudflare',
                      key: 'api-key',
                    },
                  },
                },
              },
            ],
          },
        },
      },
    },

    certificates: {
      root: {
        apiVersion: 'cert-manager.io/v1',
        kind: 'Certificate',
        metadata: {
          name: 'root-tls',
        },
        spec: {
          secretName: 'root-tls',
          issuerRef: {
            name: 'letsencrypt-prod',
          },
          commonName: 'caleb-toshiba-linux.doxsey.net',
          dnsNames: [
            'caleb-toshiba-linux.doxsey.net',
          ],
        },
      },
    },
  },
}
