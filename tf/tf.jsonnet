// invoke with: jsonnet -m . tf.jsonnet

/* Some one time manual bootstrapping of service account and assocaited
permisions is needed - see
https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform. Although
note that just following those instructions still leads to permissions errors.
I'll write up the correct steps once I'm confident I understand exactly what
permissions are necessary

*/

/* docs suggest keeping the project for the terraform state seperate - although
this has caused some permissions wrangling :/
*/

local tf_admin_project = 'xamaral-tf-admin';
local project = 'xamaral';

local zone = 'europe-west2-a';

{
  'backend.tf.json': {
    terraform: {
      backend: {
        gcs: {
          bucket: tf_admin_project,
          prefix: 'terraform/state',
        },
      },
    },
  },

  'main.tf.json': {
    provider: {
      google: {
        project: project,
        region: 'europe-west',
      },
    },

    resource: {

      google_container_cluster: {
        primary: {

          name: 'xamaral',
          location: zone,


          // See comments at https://www.terraform.io/docs/providers/google/r/container_cluster.html
          remove_default_node_pool: true,
          initial_node_count: 1,

          master_auth: {
            username: '',
            password: '',
            client_certificate_config: {
              issue_client_certificate: false,
            },
          },
        },
      },

      google_container_node_pool: {
        primary_nodes: {
          name: 'xamaral-k8s-node-pool',
          location: zone,
          cluster: '${google_container_cluster.primary.name}',
          node_count: 1,

          autoscaling: {
            max_node_count: 5,
            min_node_count: 1,
          },
          node_config: {
            preemptible: false,
            machine_type: 'g1-small',

            metadata: {
              'disable-legacy-endpoints': true,
            },

            oauth_scopes: [
              'https://www.googleapis.com/auth/logging.write',
              'https://www.googleapis.com/auth/monitoring',
              'https://www.googleapis.com/auth/devstorage.read_only',

              # needed for external dns
              'https://www.googleapis.com/auth/ndev.clouddns.readwrite',
            ],

          },
        },
      },
    },
  },
}
