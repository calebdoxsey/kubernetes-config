{
  deployment: {
    apiVersion: 'apps/v1',
    kind: 'Deployment',
    metadata: {
      name: 'google-jwt-access-token',
      labels: {
        app: 'google-jwt-access-token',
      },
    },
    spec: {
      selector: {
        matchLabels: {
          app: 'google-jwt-access-token',
        },
      },
      template: {
        metadata: {
          labels: {
            app: 'google-jwt-access-token',
          },
        },
        spec: {
          containers: [{
            name: 'google-jwt-access-token',
            image: 'calebdoxsey/google-jwt-access-token:master',
            ports: [
              { name: 'http', containerPort: 8023 },
            ],
          }],
        },
      },
    },
  },
  service: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      namespace: 'default',
      name: 'google-jwt-access-token',
      labels: {
        app: 'google-jwt-access-token',
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
        app: 'google-jwt-access-token',
      },
    },
  },
}
