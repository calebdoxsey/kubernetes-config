local Namespace = function() {
  apiVersion: 'v1',
  kind: 'Namespace',
  metadata: {
    name: 'kubernetes-dashboard',
  },
};

local ServiceAccount = function() {
  apiVersion: 'v1',
  kind: 'ServiceAccount',
  metadata: {
    labels: {
      'k8s-app': 'kubernetes-dashboard',
    },
    name: 'kubernetes-dashboard',
    namespace: 'kubernetes-dashboard',
  },
};

local Service = function() {
  kind: 'Service',
  apiVersion: 'v1',
  metadata: {
    labels: {
      'k8s-app': 'kubernetes-dashboard',
    },
    name: 'kubernetes-dashboard',
    namespace: 'kubernetes-dashboard',
  },
  spec: {
    selector: {
      'k8s-app': 'kubernetes-dashboard',
    },
    ports: [{ port: 443, targetPort: 8443 }],
  },
};

local CertsSecret = function() {
  apiVersion: 'v1',
  kind: 'Secret',
  metadata: {
    labels: {
      'k8s-app': 'kubernetes-dashboard',
    },
    name: 'kubernetes-dashboard-certs',
    namespace: 'kubernetes-dashboard',
  },
  type: 'Opaque',
};

local CSRFSecret = function() {
  apiVersion: 'v1',
  kind: 'Secret',
  metadata: {
    labels: {
      'k8s-app': 'kubernetes-dashboard',
    },
    name: 'kubernetes-dashboard-csrf',
    namespace: 'kubernetes-dashboard',
  },
  type: 'Opaque',
  data: {
    csrf: '',
  },
};

local KeyHolderSecret = function() {
  apiVersion: 'v1',
  kind: 'Secret',
  metadata: {
    labels: {
      'k8s-app': 'kubernetes-dashboard',
    },
    name: 'kubernetes-dashboard-key-holder',
    namespace: 'kubernetes-dashboard',
  },
  type: 'Opaque',
};

local SettingsConfigMap = function() {
  kind: 'ConfigMap',
  apiVersion: 'v1',
  metadata: {
    labels: {
      'k8s-app': 'kubernetes-dashboard',
    },
    name: 'kubernetes-dashboard-settings',
    namespace: 'kubernetes-dashboard',
  },
};

local Role = function() {
  kind: 'Role',
  apiVersion: 'rbac.authorization.k8s.io/v1',
  metadata: {
    labels: {
      'k8s-app': 'kubernetes-dashboard',
    },
    name: 'kubernetes-dashboard',
    namespace: 'kubernetes-dashboard',
  },
  rules: [
    {
      apiGroups: [
        '',
      ],
      resources: [
        'secrets',
      ],
      resourceNames: [
        'kubernetes-dashboard-key-holder',
        'kubernetes-dashboard-certs',
        'kubernetes-dashboard-csrf',
      ],
      verbs: [
        'get',
        'update',
        'delete',
      ],
    },
    {
      apiGroups: [
        '',
      ],
      resources: [
        'configmaps',
      ],
      resourceNames: [
        'kubernetes-dashboard-settings',
      ],
      verbs: [
        'get',
        'update',
      ],
    },
    {
      apiGroups: [
        '',
      ],
      resources: [
        'services',
      ],
      resourceNames: [
        'heapster',
        'dashboard-metrics-scraper',
      ],
      verbs: [
        'proxy',
      ],
    },
    {
      apiGroups: [
        '',
      ],
      resources: [
        'services/proxy',
      ],
      resourceNames: [
        'heapster',
        'http:heapster:',
        'https:heapster:',
        'dashboard-metrics-scraper',
        'http:dashboard-metrics-scraper',
      ],
      verbs: [
        'get',
      ],
    },
  ],
};

local ClusterRole = function() {
  kind: 'ClusterRole',
  apiVersion: 'rbac.authorization.k8s.io/v1',
  metadata: {
    labels: {
      'k8s-app': 'kubernetes-dashboard',
    },
    name: 'kubernetes-dashboard',
  },
  rules: [
    {
      apiGroups: [
        'metrics.k8s.io',
      ],
      resources: [
        'pods',
        'nodes',
      ],
      verbs: [
        'get',
        'list',
        'watch',
      ],
    },
  ],
};

local RoleBinding = function() {
  apiVersion: 'rbac.authorization.k8s.io/v1',
  kind: 'RoleBinding',
  metadata: {
    labels: {
      'k8s-app': 'kubernetes-dashboard',
    },
    name: 'kubernetes-dashboard',
    namespace: 'kubernetes-dashboard',
  },
  roleRef: {
    apiGroup: 'rbac.authorization.k8s.io',
    kind: 'Role',
    name: 'kubernetes-dashboard',
  },
  subjects: [
    {
      kind: 'ServiceAccount',
      name: 'kubernetes-dashboard',
      namespace: 'kubernetes-dashboard',
    },
  ],
};

local ClusterRoleBinding = function() {
  apiVersion: 'rbac.authorization.k8s.io/v1',
  kind: 'ClusterRoleBinding',
  metadata: {
    name: 'kubernetes-dashboard',
  },
  roleRef: {
    apiGroup: 'rbac.authorization.k8s.io',
    kind: 'ClusterRole',
    name: 'kubernetes-dashboard',
  },
  subjects: [
    {
      kind: 'ServiceAccount',
      name: 'kubernetes-dashboard',
      namespace: 'kubernetes-dashboard',
    },
  ],
};

local Deployment = function() {
  kind: 'Deployment',
  apiVersion: 'apps/v1',
  metadata: {
    labels: {
      'k8s-app': 'kubernetes-dashboard',
    },
    name: 'kubernetes-dashboard',
    namespace: 'kubernetes-dashboard',
  },
  spec: {
    replicas: 1,
    revisionHistoryLimit: 10,
    selector: {
      matchLabels: {
        'k8s-app': 'kubernetes-dashboard',
      },
    },
    template: {
      metadata: {
        labels: {
          'k8s-app': 'kubernetes-dashboard',
        },
      },
      spec: {
        containers: [
          {
            name: 'kubernetes-dashboard',
            image: 'kubernetesui/dashboard:v2.0.0',
            imagePullPolicy: 'Always',
            ports: [
              {
                containerPort: 8443,
                protocol: 'TCP',
              },
            ],
            args: [
              '--auto-generate-certificates',
              '--namespace=kubernetes-dashboard',
            ],
            volumeMounts: [
              {
                name: 'kubernetes-dashboard-certs',
                mountPath: '/certs',
              },
              {
                mountPath: '/tmp',
                name: 'tmp-volume',
              },
            ],
            livenessProbe: {
              httpGet: {
                scheme: 'HTTPS',
                path: '/',
                port: 8443,
              },
              initialDelaySeconds: 30,
              timeoutSeconds: 30,
            },
            securityContext: {
              allowPrivilegeEscalation: false,
              readOnlyRootFilesystem: true,
              runAsUser: 1001,
              runAsGroup: 2001,
            },
          },
        ],
        volumes: [
          {
            name: 'kubernetes-dashboard-certs',
            secret: {
              secretName: 'kubernetes-dashboard-certs',
            },
          },
          {
            name: 'tmp-volume',
            emptyDir: {},
          },
        ],
        serviceAccountName: 'kubernetes-dashboard',
        nodeSelector: {
          'kubernetes.io/os': 'linux',
        },
        tolerations: [
          {
            key: 'node-role.kubernetes.io/master',
            effect: 'NoSchedule',
          },
        ],
      },
    },
  },
};

local MetricsService = function() {
  kind: 'Service',
  apiVersion: 'v1',
  metadata: {
    labels: {
      'k8s-app': 'dashboard-metrics-scraper',
    },
    name: 'dashboard-metrics-scraper',
    namespace: 'kubernetes-dashboard',
  },
  spec: {
    ports: [
      {
        port: 8000,
        targetPort: 8000,
      },
    ],
    selector: {
      'k8s-app': 'dashboard-metrics-scraper',
    },
  },
};

local MetricsDeployment = function() {
  kind: 'Deployment',
  apiVersion: 'apps/v1',
  metadata: {
    labels: {
      'k8s-app': 'dashboard-metrics-scraper',
    },
    name: 'dashboard-metrics-scraper',
    namespace: 'kubernetes-dashboard',
  },
  spec: {
    replicas: 1,
    revisionHistoryLimit: 10,
    selector: {
      matchLabels: {
        'k8s-app': 'dashboard-metrics-scraper',
      },
    },
    template: {
      metadata: {
        labels: {
          'k8s-app': 'dashboard-metrics-scraper',
        },
        annotations: {
          'seccomp.security.alpha.kubernetes.io/pod': 'runtime/default',
        },
      },
      spec: {
        containers: [
          {
            name: 'dashboard-metrics-scraper',
            image: 'kubernetesui/metrics-scraper:v1.0.4',
            ports: [
              {
                containerPort: 8000,
                protocol: 'TCP',
              },
            ],
            livenessProbe: {
              httpGet: {
                scheme: 'HTTP',
                path: '/',
                port: 8000,
              },
              initialDelaySeconds: 30,
              timeoutSeconds: 30,
            },
            volumeMounts: [
              {
                mountPath: '/tmp',
                name: 'tmp-volume',
              },
            ],
            securityContext: {
              allowPrivilegeEscalation: false,
              readOnlyRootFilesystem: true,
              runAsUser: 1001,
              runAsGroup: 2001,
            },
          },
        ],
        serviceAccountName: 'kubernetes-dashboard',
        nodeSelector: {
          'kubernetes.io/os': 'linux',
        },
        tolerations: [
          {
            key: 'node-role.kubernetes.io/master',
            effect: 'NoSchedule',
          },
        ],
        volumes: [
          {
            name: 'tmp-volume',
            emptyDir: {},
          },
        ],
      },
    },
  },
};

{
  namespace: Namespace(),
  serviceAccount: ServiceAccount(),
  service: Service(),
  certsSecret: CertsSecret(),
  cSRFSecret: CSRFSecret(),
  keyHolderSecret: KeyHolderSecret(),
  settingsConfigMap: SettingsConfigMap(),
  role: Role(),
  clusterRole: ClusterRole(),
  roleBinding: RoleBinding(),
  clusterRoleBinding: ClusterRoleBinding(),
  deployment: Deployment(),
  metricsService: MetricsService(),
  metricsDeployment: MetricsDeployment(),
}
