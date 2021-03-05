local restrictedPodSecurityPolicy = {
  apiVersion: 'policy/v1beta1',
  kind: 'PodSecurityPolicy',
  metadata: {
    name: 'restricted',
  },
  spec: {
    privileged: false,
    // Required to prevent escalations to root.
    allowPrivilegeEscalation: false,
    // This is redundant with non-root + disallow privilege escalation,
    // but we can provide it for defense in depth.
    requiredDropCapabilities: ['ALL'],
    // Allow core volume types.
    volumes: [
      'configMap',
      'emptyDir',
      'secret',
      // Assume that persistentVolumes set up by the cluster admin are safe to use.
      'persistentVolumeClaim',
    ],
    hostNetwork: false,
    hostIPC: false,
    hostPID: false,
    runAsUser: {
      // Require the container to run without root privileges.
      rule: 'MustRunAsNonRoot',
    },
    seLinux: {
      // This policy assumes the nodes are using AppArmor rather than SELinux.
      rule: 'RunAsAny',
    },
    supplementalGroups: {
      rule: 'MustRunAs',
      ranges: [{
        // Forbid adding the root group.
        min: 1,
        max: 65535,
      }],
    },
    fsGroup: {
      rule: 'MustRunAs',
      ranges: [{
        // Forbid adding the root group.
        min: 1,
        max: 65535,
      }],
    },
    readOnlyRootFilesystem: false,
  },
};

{
  restrictedPodSecurityPolicy: restrictedPodSecurityPolicy,

  alertmanager+: {
    role: {
      apiVersion: 'rbac.authorization.k8s.io/v1',
      kind: 'Role',
      metadata: {
        name: 'alertmanager-' + $.values.alertmanager.name,
      },
      rules: [{
        apiGroups: ['policy'],
        resources: ['podsecuritypolicies'],
        verbs: ['use'],
        resourceNames: [restrictedPodSecurityPolicy.metadata.name],
      }],
    },

    roleBinding: {
      apiVersion: 'rbac.authorization.k8s.io/v1',
      kind: 'RoleBinding',
      metadata: {
        name: 'alertmanager-' + $.values.alertmanager.name,
      },
      roleRef: {
        apiGroup: 'rbac.authorization.k8s.io',
        kind: 'Role',
        name: 'alertmanager-' + $.values.alertmanager.name,
      },
      subjects: [{
        kind: 'ServiceAccount',
        name: 'alertmanager-' + $.values.alertmanager.name,
        namespace: $.values.alertmanager.namespace,
      }],
    },
  },

  blackboxExporter+: {
    clusterRole+: {
      rules+: [
        {
          apiGroups: ['policy'],
          resources: ['podsecuritypolicies'],
          verbs: ['use'],
          resourceNames: ['blackbox-exporter-psp'],
        },
      ],
    },

    podSecurityPolicy:
      local blackboxExporterPspPrivileged =
        if $.blackboxExporter.config.privileged then
          {
            metadata+: {
              name: 'blackbox-exporter-psp',
            },
            spec+: {
              privileged: true,
              allowedCapabilities: ['NET_RAW'],
              runAsUser: {
                rule: 'RunAsAny',
              },
            },
          }
        else
          {};

      restrictedPodSecurityPolicy + blackboxExporterPspPrivileged,
  },

  grafana+: {
    role: {
      apiVersion: 'rbac.authorization.k8s.io/v1',
      kind: 'Role',
      metadata: {
        name: 'grafana',
      },
      rules: [{
        apiGroups: ['policy'],
        resources: ['podsecuritypolicies'],
        verbs: ['use'],
        resourceNames: [restrictedPodSecurityPolicy.metadata.name],
      }],
    },

    roleBinding: {
      apiVersion: 'rbac.authorization.k8s.io/v1',
      kind: 'RoleBinding',
      metadata: {
        name: 'grafana',
      },
      roleRef: {
        apiGroup: 'rbac.authorization.k8s.io',
        kind: 'Role',
        name: 'grafana',
      },
      subjects: [{
        kind: 'ServiceAccount',
        name: $.grafana.serviceAccount.metadata.name,
        namespace: $.grafana.serviceAccount.metadata.namespace,
      }],
    },
  },

  kubeStateMetrics+: {
    clusterRole+: {
      rules+: [{
        apiGroups: ['policy'],
        resources: ['podsecuritypolicies'],
        verbs: ['use'],
        resourceNames: [restrictedPodSecurityPolicy.metadata.name],
      }],
    },
  },

  nodeExporter+: {
    clusterRole+: {
      rules+: [{
        apiGroups: ['policy'],
        resources: ['podsecuritypolicies'],
        verbs: ['use'],
        resourceNames: ['node-exporter-psp'],
      }],
    },

    podSecurityPolicy: restrictedPodSecurityPolicy {
      metadata+: {
        name: 'node-exporter-psp',
      },
      spec+: {
        allowedHostPaths+: [
          {
            pathPrefix: '/proc',
            readOnly: true,
          },
          {
            pathPrefix: '/sys',
            readOnly: true,
          },
          {
            pathPrefix: '/',
            readOnly: true,
          },
        ],
        hostNetwork: true,
        hostPID: true,
        hostPorts: [
          {
            max: 9100,
            min: 9100,
          },
        ],
        readOnlyRootFilesystem: true,
      },
    },
  },

  prometheusAdapter+: {
    clusterRole+: {
      rules+: [{
        apiGroups: ['policy'],
        resources: ['podsecuritypolicies'],
        verbs: ['use'],
        resourceNames: [restrictedPodSecurityPolicy.metadata.name],
      }],
    },
  },

  prometheusOperator+: {
    clusterRole+: {
      rules+: [{
        apiGroups: ['policy'],
        resources: ['podsecuritypolicies'],
        verbs: ['use'],
        resourceNames: [restrictedPodSecurityPolicy.metadata.name],
      }],
    },
  },

  prometheus+: {
    clusterRole+: {
      rules+: [{
        apiGroups: ['policy'],
        resources: ['podsecuritypolicies'],
        verbs: ['use'],
        resourceNames: [restrictedPodSecurityPolicy.metadata.name],
      }],
    },
  },
}
