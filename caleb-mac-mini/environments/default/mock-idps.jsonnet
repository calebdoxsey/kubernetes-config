local Deployment = function(provider) {
  apiVersion: 'apps/v1',
  kind: 'Deployment',
  metadata: {
    name: 'mock-idp-' + provider,
    labels: {
      app: 'mock-idp-' + provider,
    },
  },
  spec: {
    selector: {
      matchLabels: {
        app: 'mock-idp-' + provider,
      },
    },
    template: {
      metadata: {
        labels: {
          app: 'mock-idp-' + provider,
        },
      },
      spec: {
        containers: [{
          name: 'mock-idp-' + provider,
          image: 'calebdoxsey/mock-idps:sha-01ce242',
          args: [
            '--provider',
            provider,
          ],
          ports: [
            { name: 'http', containerPort: 8024 },
          ],
        }],
      },
    },
  },
};

local Service = function(provider) {
  apiVersion: 'v1',
  kind: 'Service',
  metadata: {
    namespace: 'default',
    name: 'mock-idp-' + provider,
    labels: {
      app: 'mock-idp-' + provider,
    },
  },
  spec: {
    ports: [
      {
        name: 'http',
        port: 80,
        targetPort: 'http',
      },
    ],
    selector: {
      app: 'mock-idp-' + provider,
    },
  },
};

{
  deployment: Deployment('ping'),
  service: Service('ping'),
}
