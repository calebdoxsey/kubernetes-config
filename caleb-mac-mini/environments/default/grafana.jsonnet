local ConfigMap = function() {
  apiVersion: 'v1',
  kind: 'ConfigMap',
  metadata: {
    namespace: 'default',
    name: 'grafana',
    labels: {
      app: 'grafana',
    },
  },
  data: {
    'grafana.ini': |||
      [users]
      allow_sign_up = false
      auto_assign_org = true
      auto_assign_org_role = Admin

      [auth.proxy]
      enabled = true
      header_name = X-Pomerium-Claim-Email
      header_property = username
      auto_sign_up = true
      sync_ttl = 60
      enable_login_token = false
    |||,
  },
};

local ConfigMapHash = std.base64(std.md5(std.manifestJsonEx(ConfigMap(), '')));

local Deployment = function() {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: {
    namespace: 'default',
    name: 'grafana',
    labels: {
      app: 'grafana',
    },
  },
  spec: {
    replicas: 1,
    selector: {
      matchLabels: {
        app: 'grafana',
      },
    },
    template: {
      metadata: {
        labels: {
          app: 'grafana',
        },
        annotations: {
          version: ConfigMapHash,
        },
      },
      spec: {
        containers: [{
          name: 'grafana',
          image: 'grafana/grafana:6.7.6',
          ports: [
            { name: 'http', containerPort: 3000 },
          ],
          volumeMounts: [
            { name: 'grafana-config', mountPath: '/etc/grafana' },
            { name: 'grafana-data', mountPath: '/var/lib/grafana' },
          ],
        }],
        volumes: [
          { name: 'grafana-config', configMap: { name: 'grafana' } },
          { name: 'grafana-data', hostPath: { path: '/data/grafana', type: 'DirectoryOrCreate' } },
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
    name: 'grafana',
    labels: {
      app: 'grafana',
    },
  },
  spec: {
    ports: [
      { name: 'http', port: 80, protocol: 'TCP', targetPort: 'http' },
    ],
    selector: {
      app: 'grafana',
    },
  },
};

{
  configMap: ConfigMap(),
  deployment: Deployment(),
  service: Service(),
}
