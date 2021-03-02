local rootDomain = 'home.doxsey.net';

local PomeriumPolicy = function() std.flattenArrays(
  [
    [
      {
        from: 'https://verify.' + rootDomain,
        to: 'https://verify.pomerium.com',
        allowed_domains: 'pomerium.com',
      },
      {
        from: 'https://podcasts.' + rootDomain,
        to: 'http://podcasts.default.svc.cluster.local',
        allowed_domains: 'pomerium.com',
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
          image: 'pomerium/pomerium:master',
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
          ],
        }],
      },
    },
  },
};

local PomeriumNodePortServce = function() {
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

{
  config: PomeriumConfigMap(),
  deployment: PomeriumDeployment(),
  service: PomeriumNodePortServce(),
}
