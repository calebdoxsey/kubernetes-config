local Deployment = function() {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: {
    namespace: 'default',
    name: 'redis',
    labels: {
      app: 'redis',
    },
  },
  spec: {
    replicas: 1,
    selector: {
      matchLabels: {
        app: 'redis',
      },
    },
    template: {
      metadata: {
        labels: {
          app: 'redis',
        },
      },
      spec: {
        containers: [{
          name: 'redis',
          image: 'redis:6.2.1-alpine',
          ports: [
            { name: 'tcp', containerPort: 6379 },
          ],
          args: [
            '--appendonly',
            'yes',
          ],
          volumeMounts: [
            { name: 'redis-data', mountPath: '/data' },
          ],
        }],
        volumes: [
          { name: 'redis-data', hostPath: { path: '/data/redis', type: 'DirectoryOrCreate' } },
        ],
      },
    },
  },
};

local Service = function() {
  apiVersion: 'v1',
  kind: 'Service',
  metadata: {
    namespace: 'default',
    name: 'redis',
    labels: {
      app: 'redis',
    },
  },
  spec: {
    ports: [
      { name: 'tcp', port: 6379, protocol: 'TCP', targetPort: 'tcp' },
    ],
    selector: {
      app: 'redis',
    },
  },
};

{
  deployment: Deployment(),
  service: Service(),
}
