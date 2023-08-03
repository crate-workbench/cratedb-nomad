job "sysctl" {
  datacenters = ["*"]

  type = "sysbatch"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  group "max_map_count" {

    task "sysctl" {
      driver = "raw_exec"
      config {
        command = "sysctl"
        args    = ["-w", "vm.max_map_count=262144"]
      }
    }
  }
}
