

# Nomad Setup

## Todo
- Come up with stateful storage options, or at least a reliable way to store data locally.

## Virtual Machines

For the purpose of the exercise three `CX41` Virtual machines had been setup on Hetzner.
Each of the machines having a:
- public IP
- private IP
- protected by a Hetzner Firewall Rule.

eg.
```shell

root@ubuntu-8gb-hel1-1:~# uname -a
Linux ubuntu-8gb-hel1-1 5.15.0-78-generic #85-Ubuntu SMP Fri Jul 7 15:25:09 UTC 2023 x86_64 x86_64 x86_64 GNU/Linux

root@ubuntu-8gb-hel1-1:~# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 96:00:02:63:00:bf brd ff:ff:ff:ff:ff:ff
    inet 95.217.186.98/32 metric 100 scope global dynamic eth0
       valid_lft 57446sec preferred_lft 57446sec
    inet6 fe80::9400:2ff:fe63:bf/64 scope link
       valid_lft forever preferred_lft forever
3: enp7s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc fq_codel state UP group default qlen 1000
    link/ether 86:00:00:52:77:2a brd ff:ff:ff:ff:ff:ff
    inet 10.33.0.2/32 brd 10.33.0.2 scope global dynamic enp7s0
       valid_lft 83014sec preferred_lft 83014sec
    inet6 fe80::8400:ff:fe52:772a/64 scope link
       valid_lft forever preferred_lft forever

root@ubuntu-8gb-hel1-1:~# netstat -rn
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         172.31.1.1      0.0.0.0         UG        0 0          0 eth0
10.33.0.0       10.33.0.1       255.255.0.0     UG        0 0          0 enp7s0
10.33.0.1       0.0.0.0         255.255.255.255 UH        0 0          0 enp7s0
```
## Rules for Hetzner Firewall (Incoming)

From your Management IPs `to` ALLOW
- tcp/22 SSH
- tcp/4646 NOMAD
- tcp/8500 CONSUL
- tcp/5555 HAPROXY-api
- tcp/8404 HAPROXY-stats
- tcp/5432

From the `external IPs of the nodes` to
- tcp/any
- udp/any



```shell

apt install unzip
apt install docker.io

export NOMAD_VERSION="1.6.1"
curl --silent --remote-name https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip
unzip nomad_${NOMAD_VERSION}_linux_amd64.zip
apt update
unzip nomad_${NOMAD_VERSION}_linux_amd64.zip
mkdir /usr/local/bin
mv ./nomad /usr/local/bin
chmod u+x /usr/local/bin/nomad
chown root:root /usr/local/bin/nomad

nomad agent -config=/etc/nomad.d/nomad.hcl


```



# Consul Setup

```shell

curl --fail --silent --show-error --location https://apt.releases.hashicorp.com/gpg |       gpg --dearmor |       sudo dd of=/usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" |  sudo tee -a /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update
apt-cache showpkg consul
apt-cache madison consul
apt install consul
consul
sudo mkdir --parents /etc/consul.d
cd /etc/consul.d
consul keygen
consul tls ca create
consul tls cert create -server -dc dc1 -domain consul



consul agent -config-file=/etc/consul.d/consul.hcl
```



# Post installation
https://developer.hashicorp.com/nomad/docs/install#post-installation-steps

### Install CNI Plugins
```
curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/v1.0.0/cni-plugins-linux-$( [ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)"-v1.0.0.tgz && \
  sudo mkdir -p /opt/cni/bin && \
  sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz

```


### add consul DNS to `systemd-resolved`

https://developer.hashicorp.com/consul/tutorials/networking/dns-forwarding#systemd-resolved-setup

1)  add to `/etc/systemd/resolved.conf`

```
[Resolve]
DNS=127.0.0.1:8600
DNSSEC=false
Domains=~consul
```

2) restart
```
systemctl status systemd-resolved

test eg: dig  5fd9ba62.addr.dc1.consul
```

### install coredns
dns resolution to consul dns does not work inside the docker container. Even if it works on the host. As a quick-fix I went for `coredns`

`enp7s0` is the private interface on Hetzner.
Make sure to disable `cache`  AFAIK it is enough to delete `cache` from the directive block.

```
.:53 {
    bind enp7s0
    forward consul 10.33.0.2:8600
    forward . /etc/resolv.conf
    log
    errors
}

```

This configuration does two things:
- forwards queries to the  `consul` DNS Namespace to `consul:8600`
- the rest of the DNS queries are covered by the existing setup and therefore point to `/etc/resolv.conf`

```
apt install httpie (don't ask)
http --download https://github.com/coredns/coredns/releases/download/v1.10.1/coredns_1.10.1_linux_amd64.tgz
tar -zxvf ./coredns_1.10.1_linux_amd64.tgz
./coredns -conf core.cfg

root      376266  0.0  0.5 764912 40920 pts/3    Sl   15:30   0:00 ./coredns -conf core.cfg

```

### Nomad Docker BRIDGE Mode
The docker container seems to inherit the **DNS Servers** from the `eth0` interface, which are assigned via DHCP from Hetzner. To modify them go to `/etc/netplan` and modify the cloud-init file. Like this they are passed to the docker container and `consul` DNS namespace is resolvable inside the container. Which is required for the dynamich host discovery crate is doing.

```
root@ubuntu-8gb-hel1-1:/etc/netplan# cat 50-cloud-init.yaml
# This file is generated from information provided by the datasource.  Changes
# to it will not persist across an instance reboot.  To disable cloud-init's
# network configuration capabilities, write a file
# /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg with the following:
# network: {config: disabled}
network:
    version: 2
    ethernets:
        eth0:
            dhcp4: true
            match:
                macaddress: 96:00:02:63:00:bf
            set-name: eth0
            nameservers:
              addresses: [10.33.0.2, 185.12.64.1]


netplan apply
```


### Enable grpc for consul
? https://developer.hashicorp.com/nomad/docs/integrations/consul-connect


```hcl
# ...

ports {
  grpc = 8502
  grpc_tlc = 8503
}

connect {
  enabled = true
}

```

### Query Consul with DNS

Default Port is `8600` DNS Port could be set to `53` https://github.com/hashicorp/nomad/issues/8343. But it is [pretty](https://developer.hashicorp.com/consul/tutorials/networking/dns-forwarding#systemd-resolved-setup)
easy to make `systemd-resolved` to talk to consul. But that is only half of it. You also need to make sure that you can resolve from inside a docker container to the consul DNS Server, which was solved by installing coredns and overwriting the DHCP assign DNS Servers on Hetzner in the cloud-init file.

```
dig @127.0.0.1 -p 8600 nomad-client.service.dc1.consul
dig @127.0.0.1 -p 8600 http-rest-name-in-consul.service.dc1.consul

```

```
; <<>> DiG 9.16.23-RH <<>> @10.33.0.2 -p 8600 http-rest-name-in-consul.service.dc1.consul SRV
;; QUESTION SECTION:
;http-rest-name-in-consul.service.dc1.consul. IN	SRV

;; ANSWER SECTION:
http-rest-name-in-consul.service.dc1.consul. 0 IN SRV 1 1 23708 5fd9ba62.addr.dc1.consul.
http-rest-name-in-consul.service.dc1.consul. 0 IN SRV 1 1 20533 5fd9ba62.addr.dc1.consul.
http-rest-name-in-consul.service.dc1.consul. 0 IN SRV 1 1 20764 5fd9ba62.addr.dc1.consul.

;; ADDITIONAL SECTION:
5fd9ba62.addr.dc1.consul. 0	IN	A	95.217.186.98
ubuntu-8gb-hel1-1.node.dc1.consul. 0 IN	TXT	"consul-network-segment="
5fd9ba62.addr.dc1.consul. 0	IN	A	95.217.186.98
ubuntu-8gb-hel1-1.node.dc1.consul. 0 IN	TXT	"consul-network-segment="
5fd9ba62.addr.dc1.consul. 0	IN	A	95.217.186.98

```

##### consul monitor --log-level=debug
```log

2023-07-31T16:57:14.857Z [DEBUG] agent.dns: request served from client: name=http-rest-name-in-consul.service.dc1.consul. type=SRV class=IN latency="373.115µs" client=172.26.64.17:45559 client_network=udp```
```


## CrateDB multi Node Discovery

Key facts:
- Nomad exposes HOST_IP of the docker container
- eg. on Hetzner: if the FIREWALL is enabled you need to allow host-to-host communication
- Nomad exposes a docker internal Port and an EXTERNAL Port
- consul has a built in DNS Server, which runs on Port 8600.
- the SRV format of Consul is different than k8s, so we need to adjust it `-Cdiscovery.srv.query` to `disco-name-in-consul.service.dc1.consul.`
- point `systemd-resolved` to consuls DNS endpoint (`:8600`)
- In case your VMs running nomad/consul are configured via DHCP on the `eth0` interface, you need to work on `/etc/netplan/` .. 50-cloud-init && `netplan apply`. As these are the `nameservers` _passed_ to the `/etc/resolv.conf` in the docker containers
- Setup `coredns` to forward the DNS namespace `consul` into the `consul-dns:8600` - super easy todo.
- remove the `cache` option from `coredns` configuraton
- Initial master node discovery is set to the _string_ `crate-0`. It does not have to be DNS resolvable. To make that work `"-Cnode.name=${NOMAD_GROUP_NAME}-${NOMAD_ALLOC_INDEX}"` is sets, dynamically the cratedb hostname inside the docker container.
- Nomad job `services` can be defined on _group level_ but also also on _task level_: I went for group-level. Which nicely registers `disco` for SRV lookup and `http-rest` for the HAPROXY setup in consul DNS.


#### Nomad Variables: dynamic IPs and Ports
http-rest -> tcp/4200
disco -> tcp/4300
pg -> tcp/5432

I left this here, to better _transport_ the issue with: IP:Port inside the docker container, and IP:Port on the host side. Where both of the Ports are   **D Y N A M I C** .

```shell
 env | grep -i NOMAD

NOMAD_HOST_ADDR_http-rest=95.217.186.98:20557
NOMAD_ADDR_http_rest=95.217.186.98:20557
NOMAD_HOST_IP_http-rest=95.217.186.98
NOMAD_IP_http_rest=95.217.186.98
NOMAD_ALLOC_PORT_http-rest=4200
NOMAD_PORT_http_rest=4200

---

NOMAD_ADDR_pg=95.217.186.98:28279
NOMAD_ALLOC_PORT_disco=4300
NOMAD_ALLOC_PORT_pg=5432
NOMAD_ALLOC_INDEX=1
NOMAD_HOST_ADDR_pg=95.217.186.98:28279
NOMAD_PORT_disco=4300
NOMAD_HOST_ADDR_disco=95.217.186.98:27632
NOMAD_SHORT_ALLOC_ID=e9a4d6cb
NOMAD_ALLOC_NAME=crate.crate[1]
NOMAD_HOST_PORT_disco=27632
NOMAD_IP_pg=95.217.186.98
NOMAD_HOST_IP_pg=95.217.186.98
NOMAD_HOST_PORT_pg=28279
NOMAD_ADDR_disco=95.217.186.98:27632
NOMAD_HOST_IP_disco=95.217.186.98
NOMAD_MEMORY_LIMIT=2048
NOMAD_PORT_pg=5432
NOMAD_ALLOC_ID=e9a4d6cb-b6a9-55e4-13e1-1281c922cc2a
NOMAD_HOST_PORT_http_rest=20557
NOMAD_IP_disco=95.217.186.98

```

----


---

# Appendix A: Useful stuff

#### Commands to start services manually
```
/usr/bin/consul agent -config-dir=/etc/consul.d/ &
nomad agent --config /etc/nomad.d/ &
/roo/coredns -conf core.cfg &
systemctl restart haproxy

```

#### Spread out Allocation to separate Nodes

`job.hcl` on `Group Level`
```
  constraint {
  operator  = "distinct_hosts"
  value     = "true"
}

```

#### Enable trace for service discovery
To modify the `log4j2.properties` you need to crate a docker mountable volume - on each host - and comment this part of the file:
```
#  Discovery
#  Crate will discover the other nodes within its own cluster.
#  If you want to log the discovery process, set the following:
logger.discovery.name: discovery
logger.discovery.level: TRACE
```

`nomad.hcl`
```
client {
  enabled = true

  host_volume "crate-config" {
    path      = "/opt/crate/config"
    read_only = false
  }
}


```

`job.hcl`
```
 group "crate" {

    count = 2

    volume "crate-config" {
      type = "host"
      read_only = false
      source = "crate-config"
    }
```

#### Networking
https://developer.hashicorp.com/nomad/docs/networking#bridge-networking
NETREAP: Running Cillium on nomad https://github.com/cosmonic/netreap

#### HAPROXY

HAPROXY Documentation Dataplane API: https://www.haproxy.com/documentation/hapee/latest/configuration/config-sections/frontend/
Frontend configuration: https://www.haproxy.com/documentation/hapee/latest/configuration/config-sections/frontend/

```
sudo add-apt-repository -y ppa:vbernat/haproxy-2.4
apt update
apt install haproxy

wget https://github.com/haproxytech/dataplaneapi/releases/download/v2.7.1/dataplaneapi_2.7.1_Linux_x86_64.tar.gz
```
