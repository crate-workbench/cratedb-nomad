job "crate-multi-node" {
  datacenters = ["dc1"]

  group "crate" {

    count = 3

    constraint {
     operator  = "distinct_hosts"
     value     = "true"
    }

    volume "crate-config" {
      type = "host"
      read_only = false
      source = "crate-config"
    }

    network {
      mode = "bridge"
      port "http-rest" {
      to     = 4200
      }
      port "pg" {
      to     = 5432
      }
      port "disco" {
      to     = 4300
      }

    }

    task "crate1" {
      driver = "docker"

      artifact {
        source = "https://repo1.maven.org/maven2/io/crate/crate-jmx-exporter/1.0.0/crate-jmx-exporter-1.0.0.jar"
        destination = "local/crate-jmx-exporter-1.0.0.jar"
        mode = "file"
      }

      env {
        CRATE_HEAP_SIZE = "512M"
        CRATE_JAVA_OPTS = <<EOF
-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/local/heapdump -Dlog4j2.formatMsgNoLookups=true -Dcom.sun.management.jmxremote.port=6666 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.rmi.port=6666 -Djava.rmi.server.hostname=127.0.0.1 -javaagent:/local/crate-jmx-exporter-1.0.0.jar=7071
EOF
      }

      kill_signal = "SIGTERM"
      kill_timeout = "180s"

      config {
        image = "crate/crate:5.4.0"
        args = [
              "-Ccluster.name=${NOMAD_GROUP_NAME}",
              "-Cstats.enabled=true",
              "-Cnode.name=${NOMAD_GROUP_NAME}-${NOMAD_ALLOC_INDEX}",
              "-Cdiscovery.type=zen",
              "-Cdiscovery.seed_providers=srv",
              "-Cdiscovery.srv.query=disco-${NOMAD_GROUP_NAME}.service.${NOMAD_DC}.consul.",
              "-Ccluster.initial_master_nodes=${NOMAD_GROUP_NAME}-0",
              "-Cnode.master=true",
              "-Cnode.data=true",
              "-Ctransport.publish_port=${NOMAD_HOST_PORT_disco}",
              "-Ctransport.tcp.port=${NOMAD_PORT_disco}",
              "-Cnetwork.publish_host=${NOMAD_IP_http_rest}",
              "-Chttp.port=${NOMAD_PORT_http_rest}",
              "-Chttp.publish_port=${NOMAD_HOST_PORT_http_rest}",
              "-Cprocessors=2",
            ]
      }

	  volume_mount {
	    volume = "crate-config"
	    destination = "/crate/config"
	    read_only = false
	  }

      resources {
        cpu    = 2000
        memory = 2048
      }

    }
        service {
        provider = "consul"
        name = "disco-${NOMAD_GROUP_NAME}"
        port = "disco"
      }
        service {
        provider = "consul"
        name = "http-rest-${NOMAD_GROUP_NAME}"
        port = "http-rest"
      }
        service {
        provider = "consul"
        name = "pg-${NOMAD_GROUP_NAME}"
        port = "pg"
      }

  }
}
