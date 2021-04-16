{
  prometheusAlerts+:: {
    groups+: [
      {
        name: 'general.rules',
        rules: [
          {
            alert: 'TargetDown',
            annotations: {
              description: '{{ printf "%.4g" $value }}% of the {{ $labels.job }}/{{ $labels.service }} targets in {{ $labels.namespace }} namespace are down.',
            },
            expr: '100 * (count(up == 0) BY (job, namespace, service) / count(up) BY (job, namespace, service)) > 10',
            'for': '10m',
            labels: {
              severity: 'warning',
            },
          },
          {
            alert: 'Watchdog',
            annotations: {
              description: |||
                This is an alert meant to ensure that the entire alerting pipeline is functional.
                This alert is always firing, therefore it should always be firing in Alertmanager
                and always fire against a receiver. There are integrations with various notification
                mechanisms that send a notification when this alert is not firing. For example the
                "DeadMansSnitch" integration in PagerDuty.
              |||,
            },
            expr: 'vector(1)',
            labels: {
              severity: 'none',
            },
          },
        ],
      },
    ],
  },
}
