try:
    from test_driver.machine import QemuMachine
    machine: QemuMachine = machine
except:
    pass



machine.start()
machine.wait_for_unit("multi-user.target")
machine.succeed("uname -a")

machine.wait_for_unit("opensearch-dashboards")
machine.succeed("systemctl status opensearch-dashboards")
machine.succeed("echo penpot-exporter is up")
machine.wait_for_open_port(5601)
machine.succeed("curl --fail http://localhost:5601")

# machine.wait_for_unit("penpot-backend")
# machine.succeed("systemctl status penpot-backend")
# machine.succeed("echo penpot-backend is up")
# machine.wait_for_open_port(6060)
# machine.succeed("curl --fail http://localhost:6060/readyz")
