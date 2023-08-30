# ProxySQL

[ProxySQL](/https://www.proxysql.com/) is a High-performance MySQL proxy with a GPL license.

## TL;DR;

```bash
$ helm repo add dysnix https://dysnix.github.io/charts/
$ helm install my-release dysnix/proxysql
```

## Introduction

This chart bootstraps a [ProxySQL](https://hub.docker.com/r/proxysql/proxysql) proxy deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Kubernetes 1.12+
- Helm 2.11+ or Helm 3.0-beta3+
- PV provisioner support in the underlying infrastructure

## Installing the Chart

To install the chart with the release name `my-release`:

```bash
$ helm install my-release dysnix/proxysql
```

The command deploys ProxySQL on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```bash
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Parameters

The following table lists the configurable parameters of the ProxySQL chart and their default values.

| Parameter                                   | Description                                         | Default                                                           |
|---------------------------------------------|-----------------------------------------------------|-------------------------------------------------------------------|
| `image.registry`                            | ProxySQL image registry                              | `docker.io`                                                      |
| `image.repository`                          | ProxySQL Image name                                  | `proxysql/proxysql`                                              |
| `image.tag`                                 | ProxySQL Image tag                                   | `2.0.9`                                                          |
| `image.pullPolicy`                          | ProxySQL image pull policy                           | `IfNotPresent`                                                   |
| `image.pullSecrets`                         | Specify docker-registry secret names as an array    | `[]` (does not add image pull secrets to deployed pods)           |
| `livenessProbe`                             | Specify livenessProbe for ProxySQL container | `{}`                                                                     |
| `readinessProbe`                            | Specify readinessProbe for ProxySQL container | (see values.yaml)                                                       |
| `nameOverride`                              | String to partially override proxysql.fullname template with a string (will prepend the release name) | `nil`            |
| `fullnameOverride`                          | String to fully override proxysql.fullname template with a string                                     | `nil`            |
| `service.type`                              | Kubernetes service type                             | `ClusterIP`                                                       |
| `service.clusterIP`                         | Specific cluster IP when service type is cluster IP. Use None for headless service | `nil`                              |
| `service.port`                              | ProxySQL service port                               | `6033`                                                            |
| `serviceAccount.create`                     | Specifies whether a ServiceAccount should be created | `false`                                                          |
| `serviceAccount.name`                       | The name of the ServiceAccount to create            | Generated using the proxysql.fullname template                    |
| `securityContext.enabled`                   | Enable [a container security context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container)                      | `false`                                                            |
| `podSecurityContext.runAsNonRoot`           | Run pod as unprivileged user                       | `true`                                                             |
| `podSecurityContext.fsGroup`                | Filesystem group ID for the pod containers         | `999`                                                              |
| `podSecurityContext.runAsUser`              | Run pod containers with the specified user ID      | `999`                                                              |
| `podSecurityContext.runAsGroup`             | Run pod containers with the specified group ID     | `999`                                                              |
| `podDisruptionBudget.enabled`               | If true, create a pod disruption budget for master pods. | `false`                                                      |
| `podDisruptionBudget.minAvailable`          | Minimum number / percentage of pods that should remain scheduled | `1`                                                  |
| `podDisruptionBudget.maxUnavailable`        | Maximum number / percentage of pods that may be made unavailable | 
| `proxysql_cluster.core.enabled` | Deploy core ProxySQL workload | `true`
| `proxysql_cluster.core.exit_on_error` | Restart ProxySQL if crashes | `false`
| `proxysql_cluster.core.replicas` | Number of core/main ProxySQL nodes to listen on | `3`
| `proxysql_cluster.core.service.exposeProxyPort` | Expose the proxy (to MySQL servers) port | `false`
| `proxysql_cluster.core.service.name` | Override default core service name | `nil`
| `proxysql_cluster.core.statefulset.affinity` | Set core Pod affinity | `{}`
| `proxysql_cluster.core.statefulset.nodeSelector` | Set core Pod node selector | `{}`
| `proxysql_cluster.core.statefulset.podAnnotations` | Set core Pod annotations | `{}`
| `proxysql_cluster.core.statefulset.resources` | Set core Pod resources (requests and limits) | `{}`
| `proxysql_cluster.core.statefulset.tolerations` | Set core Pod tolerations | `[]`
| `proxysql_cluster.enabled` | Deploy ProxySQL (clustered) workloads | `false` | 
| `proxysql_cluster.healthcheck.sidecar.command` | Command to run for healthcheck sidecar | `["/usr/local/bin/proxysql_cluster_healthcheck.sh"]`
| `proxysql_cluster.healthcheck.sidecar.config.diff_check_limit` | How many diff_check errors are tolerated before the healthcheck fails | `10`
| `proxysql_cluster.healthcheck.sidecar.config.kill_if_healthcheck_failed` | Kill proxysql daemon if the healthcheck fails the test | `true`
| `proxysql_cluster.healthcheck.sidecar.config.psql_host` | The listening core host/pod | `"127.0.0.1"`
| `proxysql_cluster.healthcheck.sidecar.config.psql_host_port` | The admin port | `6032`
| `proxysql_cluster.healthcheck.sidecar.config.psql_pass` | Monitor user | `"monitor"`
| `proxysql_cluster.healthcheck.sidecar.config.psql_user` | Monitor password | `"monitor"`
| `proxysql_cluster.healthcheck.sidecar.enabled` | Inject a healthcheck sidecar container to all proxysql clustering Pods | `false`
| `proxysql_cluster.healthcheck.sidecar.image` | Container image | `"mysql:debian"`
| `proxysql_cluster.healthcheck.sidecar.securityContext` | Set healthcheck sidecar security context | (see values.yaml)
| `proxysql_cluster.job.affinity` | Set Job affinity | `{}`
| `proxysql_cluster.job.backoffLimit` | Set Job backoff limit | `3`
| `proxysql_cluster.job.enabled` | Deploy Kubernetes Job to initialize cluster | `true`
| `proxysql_cluster.job.image.pullPolicy` | Set Job image pull policy | `"IfNotPresent"`
| `proxysql_cluster.job.image.registry` | Set Job image registry | `"docker.io"`
| `proxysql_cluster.job.image.repository` | Set Job image repository | `"mysql"`
| `proxysql_cluster.job.image.tag` | Set Job image tag | `"8"`
| `proxysql_cluster.job.nodeSelector` | Set Job Pod node selector | `{}`
| `proxysql_cluster.job.podAnnotations` | Set Job Pod annotations | `{}`
| `proxysql_cluster.job.resources` | Set Job Pod resources (requests and limits) | `{}`
| `proxysql_cluster.job.tolerations` | Set Job Pod tolerations | `[]`
| `proxysql_cluster.job.ttlSecondsAfterFinished` | Set Job time-to-live seconds after finished | `3600`
| `proxysql_cluster.satellite.daemonset.affinity` | Set DaemonSet Pod affinity | `{}`
| `proxysql_cluster.satellite.daemonset.nodeSelector` | Set DaemonSet Pod node selector | `{}`
| `proxysql_cluster.satellite.daemonset.podAnnotations` | Set DaemonSet Pod annotations | `{}`
| `proxysql_cluster.satellite.daemonset.resources` | Set DaemonSet Pod resources (requests and limits) | `{}`
| `proxysql_cluster.satellite.daemonset.tolerations` | Set DaemonSet Pod tolerations | `[]`
| `proxysql_cluster.satellite.enabled` | Deploy satellite ProxySQL workload | `true`
| `proxysql_cluster.satellite.exit_on_error` | Job Pod | `false`
| `proxysql_cluster.satellite.kind` | Workload type for satellite ProxySQL | `"DaemonSet"`
| `proxysql_cluster.satellite.replicas` | Number of satellite ProxySQL nodes to listen on | `3`
| `proxysql_cluster.satellite.service.name` | Override default satellite service name | `nil`
| `proxysql_cluster.secret.cluster_password` | This are the variables to set `admin_credentials` and corresponding `cluster_` variables | `"proxysql"`
| `proxysql_cluster.secret.cluster_username` | This are the variables to set `admin_credentials` and corresponding `cluster_` variables | `"proxysql-cluster"`
| `admin_variables.admin_credentials`         | ProxySQL admin credentials for the management (127.0.0.1:6032)  | `admin:admin`                                         |
| `admin_variables.debug`                     | ProxySQL debug mode                                | `false`                                                            |
| `admin_variables_include`                   | A list of files to @include in the `admin_variables` section | `[]`                                                     |
| `mysql_variables.threads`                   | The number of background threads that ProxySQL uses in order to process MySQL traffic. | `4`                            |
| `mysql_variables.max_connections`           | The maximum number of client connections that the proxy can handle. | `2048`                                            |
| `mysql_variables.default_query_delay`       | Simple throttling mechanism for queries to the backends. Setting this variable to a non-zero value (in miliseconds) will delay the execution of all queries, globally.                                     | `0`                                                |
| `mysql_variables.default_query_timeout`     | Mechanism for specifying the maximal duration of queries to the backend MySQL servers until ProxySQL should return an error to the MySQL client.                                                                 | `3600000` milliseconds                             |
| `mysql_variables.monitor`                   | Enables or disables MySQL Monitor module.           | `false`                                                           |
| `mysql_variables_include`                   | A list of files to @include in the `mysql_variables` section | `[]`                                                     |
| `mysql_users`                               | Defines ProxySQL [users configuration](https://github.com/sysown/proxysql/wiki/Users-configuration)         | `[]`      |
| `mysql_users_include`                       | A list of files to @include in the `mysql_users` section | `[]`                                                         |
| `mysql_servers`                             | Defines ProxySQL [backend servers configuration](https://github.com/sysown/proxysql/wiki/MySQL-Server-Configuration) | `[]`  |
| `mysql_query_rules`                         | Defines ProxySQL [Query Rules (routing)] (https://github.com/sysown/proxysql#configuring-proxysql-through-the-config-file) | `[]`  |
| `scheduler`                                 | Define ProxySQL [scheduler jobs](https://proxysql.com/documentation/scheduler/) | (see values.yaml)                      |
| `ssl.auto`                                  | Automatically set `use_ssl` to `1` when the SSL configuration is provided | `true`  |
| `ssl.ca`                                    | CA authority certificate to use | `""`  |
| `ssl.cert`                                  | ProxySQL SSL certificate | `""`  |
| `ssl.key`                                   | ProxySQL SSL key | `""`  |
| `ssl.fromSecret`                            | Specify a secret containing `ca.pem`, `cert.pem` and `key.pem` SSL configuration | `""`  |
| `volumes`                                   | Configure volumes for the ProxySQL pods | `[]`                                                                          |
| `volumeMounts`                              | Configure volumeMounts for the ProxySQL container | `[]`                                                                |

For more information please refer to the proxysql [config file](https://github.com/sysown/proxysql#configuring-proxysql-through-the-config-file) and [global variables](https://github.com/sysown/proxysql/wiki/Global-variables).

> **Tip**: You can use the default [values.yaml](values.yaml)

## Configuration and installation details

ProxySQL persists its configuration in SQLite, however this deployment is stateless i.e. no data is persisted. Since the configuration is managed via kubernetes and admin ProxySQL CLI is not meant for the configuration purposes all you need is to provide a `values.yaml` input file, for example:

```yaml
mysql_servers:
  - address: "172.17.0.1"
    port: 3306
    hostgroup: 0
    max_connections: 200

mysql_users:
  - username: "test"
    password: "p@ssword"
    default_hostgroup: 0
```

```bash
$ helm install my-release dysnix/proxysql -f values.yaml
```

The configuration is immutable thus the ProxySQL helm chart sets `active` to *1* for `mysql_users` and substitutes the `rule_id` for `mysql_query_rules` automatically.

### SSL configuration

ProxySQL can be used to safely route unencrypted MySQL traffic from applications wrapping it into SSL in case these applications do not support SSL configuration. To enable this you need to provide `ssl.*` options. When either `ssl.fromSecret` or `ssl.cert` together with `ssl.key` is provided and the `ssl.auto` is set to *true* (which is default) `mysql_servers` will get `use_ssl` set to *1* automatically if not specifically provided.

### ProxySQL and MySQL 8.0

ProxySQL supports MySQL 8.0 , although there are some limitations for the [details refer to the documentation](https://github.com/sysown/proxysql/wiki/MySQL-8.0).
