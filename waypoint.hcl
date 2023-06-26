# Waypoint configuration for running CrateDB on Nomad
# https://github.com/crate-workbench/cratedb-nomad
#
# Synopsis:
#
#   waypoint init
#   waypoint up


# Licensed to CRATE Technology GmbH ("Crate") under one or more contributor
# license agreements.  See the NOTICE file distributed with this work for
# additional information regarding copyright ownership.  Crate licenses
# this file to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.  You may
# obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations
# under the License.
#
# However, if you have executed another commercial license agreement
# with Crate these terms will supersede the license and you may use the
# software solely pursuant to the terms of the relevant commercial agreement.


project = "cratedb-nomad"

app "cratedb" {

  labels = {
    "service" = "database",
    "env" = "dev"
  }

  # https://developer.hashicorp.com/waypoint/integrations/hashicorp/docker-pull/latest/components/builder/docker-pull-builder
  build {
    use "docker-pull" {
      image = "crate"
      tag = "5.3"
    }
  }

  # https://developer.hashicorp.com/waypoint/integrations/hashicorp/docker
  # https://developer.hashicorp.com/waypoint/integrations/hashicorp/docker/latest/components/platform/docker-platform
  deploy {
    use "docker" {

      service_port = 4200
      extra_ports = [4200, 5432]
      command = [
        "crate",
        "-Cdiscovery.type=single-node",
        "-Ccluster.routing.allocation.disk.threshold_enabled=false",
      ]
      static_environment = {
        "CRATE_HEAP_SIZE" = "4g"
      }

    }
  }

}
