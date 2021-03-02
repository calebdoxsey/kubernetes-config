{
  deployment: {
    apiVersion: 'apps/v1',
    kind: 'Deployment',
    metadata: {
      name: 'podcasts',
      labels: {
        app: 'podcasts',
      },
    },
    spec: {
      selector: {
        matchLabels: {
          app: 'podcasts',
        },
      },
      template: {
        metadata: {
          labels: {
            app: 'podcasts',
          },
        },
        spec: {
          containers: [{
            name: 'podcasts',
            image: 'quay.io/calebdoxsey/podcasts:v0.1.0',
            ports: [
              { name: 'http', containerPort: 8000 },
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
      name: 'podcasts',
      labels: {
        app: 'podcasts',
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
        app: 'podcasts',
      },
    },
  },
}
