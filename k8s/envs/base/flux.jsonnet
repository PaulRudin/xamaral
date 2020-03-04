{
  /* see the flux repo on github for some example plain yamls
   https://github.com/fluxcd/flux/blob/master/deploy/
   */
  local k = $.k,
  local env = $.env,
  local name = 'flux',

  # seems that this has to be the name. not sure why
  local secret_name = 'flux-git-deploy',

  local kgdir = '/var/fluxd/keygen',
  local nsmix = {
    metadata+: {
      namespace: 'flux',
    },
  },

  ns: k.Namespace(name),

  deployment: k.Deployment(name) + nsmix + {
    spec+: {
      template+: {
        spec+: {
          serviceAccountName: name,
          containers_+: {
            default: k.Container(name) + {
              image: $.images.flux,
              volumeMounts_+: {
                git_key: {
                  mountPath: '/etc/fluxd/ssh',
                  readOnly: true,
                },
                git_keygen: {
                  mountPath: kgdir,
                },
              },
            
              args: [
                '--memcached-service=',
                '--ssh-keygen-dir=%s' % kgdir,
                '--git-url=git@github.com:PaulRudin/xamaral',
                '--git-path=k8s',
                '--git-branch=master',
                '--git-label=flux-sync',
                '--git-email=paul+flux@rudin.co.uk',
                '--manifest-generation=true',
              ],
              env_: {
                ENV: env,
              },
            },
          },
          volumes_+: {
            git_key: {
              secret: {
                secretName: secret_name,
                defaultMode: std.parseOctal('0400'),
              },
            },
            // for generated ssh key
            git_keygen: {
              emptyDir: {
                medium: 'Memory',
              },
            },
          },
        },
      },
    },
  }, //deployment

  secret: k.Secret(secret_name) + nsmix,

  sa: k.ServiceAccount(name) + nsmix,

  cr: k.ClusterRole(name) {
    rules: [
      {
        apiGroups: ['*'],
        resources: ['*'],
        verbs: ['*'],
      },
      {
        nonResourceURLs: ['*'],
        verbs: ['*'],
      },
    ],
  }, // ClusterRole

  crb: k.ClusterRoleBinding(name) {
    roleRef: {
      apiGroup: 'rbac.authorization.k8s.io',
      kind: 'ClusterRole',
      name: name,
    },
    subjects: [
      {
        kind: 'ServiceAccount',
        name: name,
        namespace: name,
      },
    ],
  }, // crb

  memcached: k.Deployment('memcached') + nsmix + {
    spec+: {
      template+: {
        spec+: {
          containers_+: {
            default: k.Container('memcached') {
              image: $.images.flux_memcached,
              args: [
                '-m 512',
                '-I 5m',
                '-p 11211',
              ],
              ports: [
                {
                  name: 'clients',
                  containerPort: 11211,
                },
              ],
              securityContext: {
                runAsUser: 11211,
                runAsGroup: 11211,
                allowPrivilegeEscalation: false,
              },
            },
          },
        },
      },
    },
  }, // memcached deployment

  memcached_svc: k.Service('memcached') + nsmix + {
    target_pod: $.memcached.spec.template,
  },
}
