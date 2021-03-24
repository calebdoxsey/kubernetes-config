local rootDomain = 'home.doxsey.net';

local PomeriumPolicy = function() std.flattenArrays(
  [
    [
      {
        from: 'https://verify.' + rootDomain,
        to: 'https://verify.pomerium.com',
        allowed_domains: ['pomerium.com', 'doxsey.net'],
      },
      {
        from: 'https://podcasts.' + rootDomain,
        to: 'http://podcasts.default.svc.cluster.local',
        allowed_domains: ['pomerium.com', 'doxsey.net'],
      },
      // tcp tunnels
      {
        from: 'tcp+https://tcp.' + rootDomain + ':22',
        to: 'tcp://host.k3d.internal:22',
        allowed_domains: ['pomerium.com', 'doxsey.net'],
      },
      {
        from: 'tcp+https://tcp.' + rootDomain + ':5900',
        to: 'tcp://host.k3d.internal:5900',
        allowed_domains: ['pomerium.com', 'doxsey.net'],
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
          volumeMounts: [
            { mountPath: '/data', name: 'pomerium-data' },
          ],
        }],
        volumes: [
          { name: 'pomerium-data', hostPath: { path: '/data/pomerium', type: 'DirectoryOrCreate' } },
        ],
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
  redis: {
    deployment: {
      apiVersion: 'apps/v1',
      kind: 'Deployment',
      metadata: {
        name: 'redis',
      },
      spec: {
        selector: {
          matchLabels: {
            name: 'redis',
          },
        },
        template: {
          metadata: {
            labels: {
              name: 'redis',
            },
          },
          spec: {
            containers: [{
              image: 'redis',
              name: 'redis',
            }],
          },
        },
      },
    },
    nodePortService: {
      apiVersion: 'v1',
      kind: 'Service',
      metadata: {
        name: 'redis',
        labels: {
          name: 'redis',
        },
      },
      spec: {
        type: 'NodePort',
        selector: {
          name: 'redis',
        },
        ports: [{
          name: 'redis',
          port: 6379,
          targetPort: 6379,
          nodePort: 30022,
        }],
      },
    },
  },
}
