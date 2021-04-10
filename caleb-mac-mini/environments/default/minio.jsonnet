{
  deployment: {
    apiVersion: 'apps/v1',
    kind: 'Deployment',
    metadata: {
      name: 'minio',
    },
    spec: {
      selector: {
        matchLabels: {
          app: 'minio',
        },
      },
      template: {
        metadata: {
          labels: {
            app: 'minio',
          },
        },
        spec: {
          containers: [{
            image: 'minio/minio:RELEASE.2021-04-06T23-11-00Z',
            name: 'minio',
            args: [
              'server',
              '/data',
            ],
            ports: [
              { name: 'http', containerPort: 9000 },
            ],
            envFrom: [
              { secretRef: { name: 'minio' } },
            ],
            env: [
              { name: 'MINIO_ACCESS_KEY', value: 'minio' },
              { name: 'MINIO_ROOT_USER', value: 'minio' },
            ],
            volumeMounts: [
              { name: 'minio-data', mountPath: '/data' },
            ],
          }],
          volumes: [
            { name: 'minio-data', hostPath: { path: '/data/minio', type: 'DirectoryOrCreate' } },
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
        app: 'minio',
      },
    },
    spec: {
      selector: {
        app: 'minio',
      },
      ports: [
        { name: 'http', port: 80, protocol: 'TCP', targetPort: 'http' },
      ],
    },
  },
}
