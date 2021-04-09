local rootDomain = 'home.doxsey.net';

local PomeriumPolicy = function() std.flattenArrays(
  [
    [
      {
        from: 'https://kubernetes-dashboard.' + rootDomain,
        to: 'https://kubernetes-dashboard.default.svc.cluster.local',
        allowed_domains: ['doxsey.net', 'pomerium.com'],
      },
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
      {
        from: 'https://google-jwt-access-token.' + rootDomain,
        to: 'http://google-jwt-access-token.default.svc.cluster.local',
        allow_public_unauthenticated_access: true,
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
          image: 'pomerium/pomerium:v0.13.3',
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

local ServiceAccount = function() {
  apiVersion: 'v1',
  kind: 'ServiceAccount',
  metadata: {
    namespace: 'default',
    name: 'pomerium',
  },
};

local ClusterRole = function() {
  apiVersion: 'rbac.authorization.k8s.io/v1',
  kind: 'ClusterRole',
  metadata: {
    name: 'pomerium-impersonation',
  },
  rules: [
    {
      apiGroups: [
        '',
      ],
      resources: [
        'users',
        'groups',
        'serviceaccounts',
      ],
      verbs: [
        'impersonate',
      ],
    },
    {
      apiGroups: [
        'authorization.k8s.io',
      ],
      resources: [
        'selfsubjectaccessreviews',
      ],
      verbs: [
        'create',
      ],
    },
  ],
};

local PomeriumClusterRoleBinding = function() {
  apiVersion: 'rbac.authorization.k8s.io/v1',
  kind: 'ClusterRoleBinding',
  metadata: {
    name: 'pomerium',
  },
  roleRef: {
    apiGroup: 'rbac.authorization.k8s.io',
    kind: 'ClusterRole',
    name: 'pomerium-impersonation',
  },
  subjects: [
    {
      kind: 'ServiceAccount',
      name: 'pomerium',
      namespace: 'default',
    },
  ],
};

local ClusterRoleBinding = function() {
  apiVersion: 'rbac.authorization.k8s.io/v1',
  kind: 'ClusterRoleBinding',
  metadata: {
    name: 'cluster-admin-crb',
  },
  roleRef: {
    apiGroup: 'rbac.authorization.k8s.io',
    kind: 'ClusterRole',
    name: 'cluster-admin',
  },
  subjects: [
    {
      apiGroup: 'rbac.authorization.k8s.io',
      kind: 'Group',
      name: 'admins',
    },
  ],
};

{
  config: PomeriumConfigMap(),
  deployment: PomeriumDeployment(),
  service: PomeriumNodePortService(),
  metrics: PomeriumMetricsService(),
  serviceAccount: ServiceAccount(),
  clusterRole: ClusterRole(),
  pomeriumClusterRoleBinding: PomeriumClusterRoleBinding(),
  clusterRoleBinding: ClusterRoleBinding(),
}
