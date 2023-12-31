# CrateDB on Nomad

This document outlines how to get started running CrateDB on HashiCorp Nomad.


## About

[HashiCorp Nomad] is an alternative to the Kubernetes cluster manager.
[HashiCorp Waypoint] is a frontend to build and deploy cluster resources to
different targets, using a similar command-line interface like Docker Compose.

## Setup

Install and start Waypoint using the Docker backend, open the Waypoint UI,
acquire the project repository, and initialize the Waypoint project.

### Ansible (automate the heavy lifting)
We created a Ansible Playbook to setup a 3-node Nomad/Consul cluster. If you
are here for that. Just follow [along](playbooks/nomad/README.md). After all we
figured that there are quite some steps involved in making cratedb containers run
in nomad - as a multi-node cluster.

#### DNS
The cratedb service discovery relies on `SRV` DNS queries to successfully discover
the other nodes in the cluster. Gladly Consul talks DNS on port 8600. You _just_ have to
customize the `"-Cdiscovery.srv.query=` and you are good. But wait there are some more
obstacles until that works:
- Due to how docker (bridged mode) works we need to be able to send queries to either consul
or to the _regular_ resolver on the host - as the container inherits this DNS setup. We choose to solve this with `coredns` and updating the `systemd/resolved` config.
- As the VMs we are running are configured by cloud-init and get their IP configuration via
DHCP, we also need to touch cloud-init to point to DNS on our host to coredns.

Hopefully this does not sound too complicated, either you set it up manually or you rely
on our ansible setup - or at least you can copy it from there.


### Install Waypoint
```
brew tap hashicorp/tap
brew install hashicorp/tap/waypoint
```
```
waypoint install --platform=docker --accept-tos
waypoint ui -authenticate
```

### Acquire sources
```
git clone https://github.com/crate-workbench/cratedb-nomad
cd cratedb-nomad
```

### Initialize project
```
waypoint init
```


## Usage

Start all applications defined by Waypoint project.
```
waypoint up
```

Watch log output.
```
waypoint logs
```

Inquire project and application status.
```
waypoint status
waypoint status -app=cratedb
```


## Connect

Connect to CrateDB using the terminal-based front-ends [crash] and [psql].

First, inquire the host name address for connecting.
```
CONTAINER_NAME=$(waypoint status -app=cratedb -json | jq -r '.DeploymentResourcesSummary[] | select(.Type=="container") | .Name')
```

Connect to container using default network namespace `waypoint`, and dynamic container name.
```
# Use `crash`.
docker run --rm -it --network=waypoint crate \
  crash --hosts ${CONTAINER_NAME} \
    --command 'SELECT mountain, region, prominence FROM sys.summits LIMIT 10;'

# Use `psql`.
docker run --rm -it --network=waypoint postgres \
  psql postgres://crate@${CONTAINER_NAME} \
    --command 'SELECT mountain, region, prominence FROM sys.summits LIMIT 10;'
```



## Resources

- https://developer.hashicorp.com/waypoint/tutorials/get-started-docker/get-started-docker
- https://faun.pub/just-in-time-nomad-managing-nomad-application-deployments-using-waypoint-on-hashiqube-467952b23689
- https://discuss.hashicorp.com/


## Support

This repository is for evaluation purposes only, without any support. Here be dragons.


[crash]: https://github.com/crate/crash
[psql]: https://www.postgresql.org/docs/current/app-psql.html
[HashiCorp Nomad]: https://developer.hashicorp.com/nomad/
[HashiCorp Waypoint]: https://developer.hashicorp.com/waypoint/
