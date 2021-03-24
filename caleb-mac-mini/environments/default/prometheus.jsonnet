local ConfigMap = function() {
  apiVersion: 'v1',
  kind: 'ConfigMap',
  metadata: {
    namespace: 'default',
    name: 'prometheus',
    labels: {
      app: 'prometheus',
    },
  },
  data: {
    'prometheus.yaml': std.manifestYamlDoc({
      scrape_configs: [
        {
          job_name: 'prometheus',
          static_configs: [{
            targets: ['localhost:9090'],
          }],
        },
        {
          job_name: 'pomerium',
          static_configs: [{
            targets: ['pomerium-metrics.default.svc.cluster.local'],
          }],
        },
      ],
    }),
  },
};

local Deployment = function() {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: {
    namespace: 'default',
    name: 'prometheus',
    labels: {
      app: 'prometheus',
    },
  },
  spec: {
    replicas: 1,
    selector: {
      matchLabels: {
        app: 'prometheus',
      },
    },
    template: {
      metadata: {
        labels: {
          app: 'prometheus',
        },
      },
      spec: {
        containers: [{
          name: 'prometheus',
          image: 'prom/prometheus:v2.25.2',
          args: [
            '--config.file=/etc/prometheus/prometheus.yaml',
          ],
          ports: [
            { name: 'http', containerPort: 9090 },
          ],
          volumeMounts: [
            { name: 'prometheus-config', mountPath: '/etc/prometheus' },
          ],
        }],
        volumes: [
          {
            name: 'prometheus-config',
            configMap: {
              name: 'prometheus',
            },
          },
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
    name: 'prometheus',
    labels: {
      app: 'prometheus',
    },
  },
  spec: {
    ports: [
      { name: 'http', port: 80, protocol: 'TCP', targetPort: 'http' },
    ],
    selector: {
      app: 'prometheus',
    },
  },
};

{
  configMap: ConfigMap(),
  deployment: Deployment(),
  service: Service(),
}
