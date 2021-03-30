local rootDomain = 'home.doxsey.net';

local PomeriumPolicy = function() std.flattenArrays(
  [
    [
      {
        from: 'https://verify.' + rootDomain,
        to: 'https://verify.pomerium.com',
        allowed_domains: ['doxsey.net', 'pomerium.com'],
      },
      {
        from: 'https://podcasts.' + rootDomain,
        to: 'http://podcasts.default.svc.cluster.local',
        allowed_domains: ['doxsey.net', 'pomerium.com'],
      },
      {
        from: 'https://pomerium-metrics.' + rootDomain,
        to: 'http://pomerium-metrics.default.svc.cluster.local',
        allowed_domains: ['doxsey.net', 'pomerium.com'],
      },
      {
        from: 'https://prometheus.' + rootDomain,
        to: 'http://prometheus.default.svc.cluster.local',
        allowed_domains: ['doxsey.net', 'pomerium.com'],
      },
      {
        from: 'https://grafana.' + rootDomain,
        to: 'http://grafana.default.svc.cluster.local',
        allowed_domains: ['doxsey.net', 'pomerium.com'],
        pass_identity_headers: true,
      },
      // tcp tunnels
      {
        from: 'tcp+https://tcp.' + rootDomain + ':22',
        to: 'tcp://host.k3d.internal:22',
        allowed_domains: ['doxsey.net', 'pomerium.com'],
      },
      {
        from: 'tcp+https://tcp.' + rootDomain + ':5900',
        to: 'tcp://host.k3d.internal:5900',
        allowed_domains: ['doxsey.net', 'pomerium.com'],
      },
    ],
  ]
);

local PomeriumConfigMap = function() {
  apiVersion: 'v1',
  kind: 'ConfigMap',
  metadata: {
    namespace: 'default',
    name: 'pomerium',
    labels: {
      'app.kubernetes.io/part-of': 'pomerium',
    },
  },
  data: {
    ADDRESS: ':443',
    GRPC_ADDRESS: ':5443',

    AUTOCERT: 'true',

    AUTHENTICATE_SERVICE_URL: 'https://authenticate.' + rootDomain,
    AUTHENTICATE_CALLBACK_PATH: '/oauth2/callback',
    AUTHORIZE_SERVICE_URL: 'http://localhost:5443',
    DATABROKER_SERVICE_URL: 'http://localhost:5443',

    IDP_PROVIDER: 'google',
    JWT_CLAIMS_HEADERS: 'email',

    METRICS_ADDRESS: ':9902',

    POLICY: std.base64(std.manifestYamlDoc(PomeriumPolicy())),
  },
};

local PomeriumConfigMapHash = std.base64(std.md5(std.manifestJsonEx(PomeriumConfigMap(), '')));

local PomeriumDeployment = function() {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: {
    namespace: 'default',
    name: 'pomerium',
    labels: {
      app: 'pomerium',
      'app.kubernetes.io/part-of': 'pomerium',
    },
  },
  spec: {
    replicas: 1,
    selector: {
      matchLabels: {
        app: 'pomerium',
      },
    },
    template: {
      metadata: {
        labels: {
          app: 'pomerium',
          'app.kubernetes.io/part-of': 'pomerium',
        },
        annotations: {
          version: PomeriumConfigMapHash,
        },
      },
      spec: {
        containers: [{
          name: 'pomerium',
          image: 'quay.io/calebdoxsey/pomerium:dev',
          imagePullPolicy: 'Always',
          envFrom: [
            { configMapRef: { name: 'pomerium' } },
            { secretRef: { name: 'pomerium' } },
          ],
          env: [{
            name: 'SERVICES',
            value: 'all',
          }],
          ports: [
            { name: 'http', containerPort: 80 },
            { name: 'https', containerPort: 443 },
            { name: 'grpc', containerPort: 5443 },
            { name: 'metrics', containerPort: 9902 },
          ],
          volumeMounts: [
            { name: 'pomerium-data', mountPath: '/data' },
            { name: 'pomerium-local-data', mountPath: '/root/.local/share/pomerium' },
          ],
        }],
        volumes: [
          { name: 'pomerium-data', hostPath: { path: '/data/pomerium', type: 'DirectoryOrCreate' } },
          { name: 'pomerium-local-data', hostPath: { path: '/data/pomerium-local', type: 'DirectoryOrCreate' } },
        ],
      },
    },
  },
};

local PomeriumNodePortService = function() {
  apiVersion: 'v1',
  kind: 'Service',
  metadata: {
    namespace: 'default',
    name: 'pomerium-nodeport',
    labels: {
      app: 'pomerium',
      'app.kubernetes.io/part-of': 'pomerium',
    },
  },
  spec: {
    type: 'NodePort',
    ports: [
      { name: 'http', port: 80, protocol: 'TCP', targetPort: 'http', nodePort: 30080 },
      { name: 'https', port: 443, protocol: 'TCP', targetPort: 'https', nodePort: 30443 },
    ],
    selector: {
      app: 'pomerium',
    },
  },
};

local PomeriumMetricsService = function() {
  apiVersion: 'v1',
  kind: 'Service',
  metadata: {
    namespace: 'default',
    name: 'pomerium-metrics',
    labels: {
      app: 'pomerium',
      'app.kubernetes.io/part-of': 'pomerium',
    },
  },
  spec: {
    ports: [
      { name: 'metrics', port: 80, protocol: 'TCP', targetPort: 'metrics' },
    ],
    selector: {
      app: 'pomerium',
    },
  },
};

{
  config: PomeriumConfigMap(),
  deployment: PomeriumDeployment(),
  service: PomeriumNodePortService(),
  metrics: PomeriumMetricsService(),
}
