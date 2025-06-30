# Podman Container Ops and Management

The sample workspace to demonstrate Podman health check feature and management of containers using Ansible.

# Pre-requisites

## RHEL 8.x

```
sudo dnf install podman
sudo dnf install ansible
ansible-galaxy collection install containers.podman
```


## RHEL 9.x / 10

```
sudo dnf install podman
sudo dnf install ansible-core
ansible-galaxy collection install containers.podman
```

## Ubuntu 22.04+

```
sudo apt install podman
sudo apt install ansible
ansible-galaxy collection install containers.podman
```

# HealthCheck Commands

Demostrate the manual healthcheck feature.

## Podman

### Run the `container-healthcheck-sample` Container

```
podman run --replace -d --name container-healthcheck-sample --health-cmd /healthcheck --health-on-failure=kill --healthcheck-interval=0 --health-retries=1 docker.io/tagitmobile/container-healthcheck
```

### Manually Execute  `container-healthcheck-sample` Container Health Check

```
podman healthcheck run container-healthcheck-sample
```

### Trigger Unhealthy Container 

```
podman exec container-healthcheck-sample touch /uh-oh
```

### Check Container Status 

```
podman ps -a
```

# Integration with Root `systemd`

Demostrate self-healing capability. The healthcheck can be combined with `systemd` to allow for self-healing services. For this to work, make sure that the healthcheck parameter `--healthcheck-interval=2s` and `--health-on-failure=kill` are set.

1. sudo vi /etc/systemd/system/myapp-container.service

```
[Unit]
Description=Podman container container-healthcheck-sample
After=network.target

[Service]
# Restart settings
Restart=always                          
# Always restart the container if it stops or fails
RestartSec=5                             
# Delay (in seconds) before restarting the container

# Podman command to run the container
ExecStart=/usr/bin/podman run --replace --rm --name container-healthcheck-sample --health-cmd /healthcheck --health-on-failure=kill --healthcheck-interval=2s --health-retries=1 docker.io/tagitmobile/container-healthcheck

# Stop the container gracefully
ExecStop=/usr/bin/podman stop container-healthcheck-sample

# Restart the container if needed
ExecReload=/usr/bin/podman run --replace --rm --name container-healthcheck-sample --health-cmd /healthcheck --health-on-failure=kill --healthcheck-interval=2s --health-retries=1 docker.io/tagitmobile/container-healthcheck

# Healthcheck (optional)
#ExecStartPost=/bin/sh -c "curl -f http://localhost:{{ port }} || exit 1"

[Install]
WantedBy=multi-user.target
```

2. sudo systemctl daemon-reload
3. sudo systemctl enable myapp-container.service
4. sudo systemctl start myapp-container.service
5. sudo systemctl status myapp-container.service

```
[ec2-user@ip-172-31-24-243 ~]$ sudo systemctl status myapp-container.service
● myapp-container.service - Podman container container-healthcheck-sample
     Loaded: loaded (/etc/systemd/system/myapp-container.service; enabled; preset: disabled)
     Active: active (running) since Wed 2024-12-11 10:23:57 UTC; 17s ago
   Main PID: 4072 (podman)
      Tasks: 9 (limit: 4372)
     Memory: 258.7M
        CPU: 8.683s
     CGroup: /system.slice/myapp-container.service
             ├─4072 /usr/bin/podman run --replace --rm --name container-healthcheck-sample --health-cmd /healthcheck --health-on-failure=kill --healthcheck-interval=2s --health-retries=1 docker.io/tagitmobile/container-healthcheck
             └─4233 /usr/bin/conmon --api-version 1 -c 9805b60a43a708b4b3d9ecae975115a46548e6fff470155291a243183fc20f39 -u 9805b60a43a708b4b3d9ecae975115a46548e6fff470155291a243183fc20f39 -r /usr/bin/crun -b /var/lib/containers/storage/overlay-containers/9805b60>

Dec 11 10:23:59 ip-172-31-24-243.ap-southeast-1.compute.internal podman[4072]: Copying blob sha256:c92a95008f9d0407c6e4199511144bc9ffe77ed73efc9c8e8a98ca1268ddf3d7
Dec 11 10:24:10 ip-172-31-24-243.ap-southeast-1.compute.internal podman[4072]: Copying config sha256:09613225e445780da7685718abf6cf085a139c74dd1117b7236e16515421d217
Dec 11 10:24:10 ip-172-31-24-243.ap-southeast-1.compute.internal podman[4072]: Writing manifest to image destination
Dec 11 10:24:10 ip-172-31-24-243.ap-southeast-1.compute.internal podman[4072]: 2024-12-11 10:24:10.34516448 +0000 UTC m=+13.206968027 container create 9805b60a43a708b4b3d9ecae975115a46548e6fff470155291a243183fc20f39 (image=docker.io/tagitmobile/container-healthc>
Dec 11 10:24:10 ip-172-31-24-243.ap-southeast-1.compute.internal podman[4072]: 2024-12-11 10:24:10.320890274 +0000 UTC m=+13.182694066 image pull 09613225e445780da7685718abf6cf085a139c74dd1117b7236e16515421d217 docker.io/tagitmobile/container-healthcheck
Dec 11 10:24:11 ip-172-31-24-243.ap-southeast-1.compute.internal podman[4072]: 2024-12-11 10:24:11.111410278 +0000 UTC m=+13.973214054 container init 9805b60a43a708b4b3d9ecae975115a46548e6fff470155291a243183fc20f39 (image=docker.io/tagitmobile/container-healthch>
Dec 11 10:24:11 ip-172-31-24-243.ap-southeast-1.compute.internal container-healthcheck-sample[4233]: WAITING
Dec 11 10:24:11 ip-172-31-24-243.ap-southeast-1.compute.internal podman[4072]: 2024-12-11 10:24:11.141222115 +0000 UTC m=+14.003025699 container start 9805b60a43a708b4b3d9ecae975115a46548e6fff470155291a243183fc20f39 (image=docker.io/tagitmobile/container-healthc>
Dec 11 10:24:11 ip-172-31-24-243.ap-southeast-1.compute.internal podman[4072]: 2024-12-11 10:24:11.148944973 +0000 UTC m=+14.010748651 container attach 9805b60a43a708b4b3d9ecae975115a46548e6fff470155291a243183fc20f39 (image=docker.io/tagitmobile/container-health>
Dec 11 10:24:11 ip-172-31-24-243.ap-southeast-1.compute.internal podman[4072]: WAITING
```

> To test the self-healing feature, use `sudo podman exec container-healthcheck-sample touch /uh-oh`.  

6. sudo systemctl stop myapp-container.service

# Integration with Rootless User Service `systemd`

Demostrate self-healing capability. The healthcheck can be combined with `systemd` to allow for self-healing services. For this to work, make sure that the healthcheck parameter `--healthcheck-interval=2s` and `--health-on-failure=kill` are set.

1. Enable lingering once (so the service survives logout):

```bash
sudo loginctl enable-linger arj     # lets systemd start your user units at boot
```

2. Create the unit file under your user systemd tree

```bash
mkdir -p ~/.config/systemd/user
vi ~/.config/systemd/user/container-healthcheck.service
```

```
# ~/.config/systemd/user/container-healthcheck.service
[Unit]
Description=Podman container-healthcheck-sample (rootless)
Wants=network-online.target
After=network-online.target

[Service]
# Restart settings
Restart=always                          
# Always restart the container if it stops or fails
RestartSec=5                             
# Delay (in seconds) before restarting the container

# Podman command to run the container
ExecStart=/usr/bin/podman run --replace --rm --name container-healthcheck-sample --health-cmd /healthcheck --health-on-failure=kill --healthcheck-interval=2s --health-retries=1 docker.io/tagitmobile/container-healthcheck

# Stop the container gracefully
ExecStop=/usr/bin/podman stop container-healthcheck-sample

# Restart the container if needed
ExecReload=/usr/bin/podman run --replace --rm --name container-healthcheck-sample --health-cmd /healthcheck --health-on-failure=kill --healthcheck-interval=2s --health-retries=1 docker.io/tagitmobile/container-healthcheck

# Healthcheck (optional)
#ExecStartPost=/bin/sh -c "curl -f http://localhost:{{ port }} || exit 1"

[Install]
WantedBy=default.target
```

> Tip: `podman generate systemd --name container-healthcheck-sample --files --new` will build an almost-identical unit with all the little details pre-filled; you can drop that file straight into `~/.config/systemd/user/` instead of hand-crafting it.

3. systemctl --user daemon-reload
4. systemctl --user enable --now container-healthcheck.service
5. systemctl --user status container-healthcheck.service

```
[arj@ARJ-RYZEN7 ~]$ systemctl --user status container-healthcheck.service
● container-healthcheck.service - Podman container-healthcheck-sample (rootless)
     Loaded: loaded (/home/arj/.config/systemd/user/container-healthcheck.service; enabled; preset: disabled)
     Active: active (running) since Mon 2025-06-30 09:39:18 +08; 6s ago
 Invocation: 82bb7af7e6774969bb61327b1658f4e1
   Main PID: 5847 (podman)
      Tasks: 18 (limit: 26213)
     Memory: 31.8M (peak: 34.6M)
        CPU: 130ms
     CGroup: /user.slice/user-1001.slice/user@1001.service/app.slice/container-healthcheck.service
             ├─5847 /usr/bin/podman run --replace --rm --name container-healthcheck-sample --health-cmd /healthcheck --health-on-failure=kill --healthcheck-interval=2s --health-retries=1 docker.io/tagitmobile/container-healthcheck
             ├─5868 /usr/bin/pasta --config-net --dns-forward 169.254.1.1 -t none -u none -T none -U none --no-map-gw --quiet --netns /run/user/1001/netns/netns-8af36004-ea41-72f0-ca16-b392e5a757fb --map-guest-addr 169.254.1.2
             └─5875 /usr/bin/conmon --api-version 1 -c 8e604a193383755d3ca177cd75db16c38bfd5662f99b60863a3d4e02cfd4111d -u 8e604a193383755d3ca177cd75db16c38bfd5662f99b60863a3d4e02cfd4111d -r /usr/bin/crun -b /home/arj/.local/share/containers/storage/overlay-containers/8e604a193383755d3ca177cd75db16c38bfd5662f99b60863a3d4e02cfd4111d/userdata -p /run/user/1001/containers/overlay-containers/8e604a193383755d3ca177cd75db16c38bfd5662f99b60863a3d4e02cfd4111d/userdata/pidfile -n container-healthcheck-sample --exit-dir /run/user/1001/libpod/tmp/exits --persist-dir /run/user/1001/libpod/tmp/persist/8e604a193383755d3ca177cd75db16c38bfd5662f99b60863a3d4e02cfd4111d --full-attach -s -l journald --log-level warning --syslog --runtime-arg --log-format=json --runtime-arg --log --runtime-arg=/run/user/1001/containers/overlay-containers/8e604a193383755d3ca177cd75db16c38bfd5662f99b60863a3d4e02cfd4111d/userdata/oci-log --conmon-pidfile /run/user/1001/containers/overlay-containers/8e604a193383755d3ca177cd75db16c38bfd5662f99b60863a3d4e02cfd4111d/userdata/conmon.pid --exit-command /usr/bin/podman --exit-command-arg --root --exit-command-arg /home/arj/.local/share/containers/storage --exit-command-arg --runroot --exit-command-arg /run/user/1001/containers --exit-command-arg --log-level --exit-command-arg warning --exit-command-arg --cgroup-manager --exit-command-arg systemd --exit-command-arg --tmpdir --exit-command-arg /run/user/1001/libpod/tmp --exit-command-arg --network-config-dir --exit-command-arg "" --exit-command-arg --network-backend --exit-command-arg netavark --exit-command-arg --volumepath --exit-command-arg /home/arj/.local/share/containers/storage/volumes --exit-command-arg --db-backend --exit-command-arg sqlite --exit-command-arg --transient-store=false --exit-command-arg --runtime --exit-command-arg crun --exit-command-arg --storage-driver --exit-command-arg overlay --exit-command-arg --events-backend --exit-command-arg journald --exit-command-arg container --exit-command-arg cleanup --exit-command-arg --stopped-only --exit-command-arg --rm --exit-command-arg 8e604a193383755d3ca177cd75db16c38bfd5662f99b60863a3d4e02cfd4111d

Jun 30 09:39:18 ARJ-RYZEN7 systemd[175]: Started container-healthcheck.service - Podman container-healthcheck-sample (rootless).
```

> To test the self-healing feature, use `podman exec container-healthcheck-sample touch /uh-oh`.  

6. systemctl --user stop container-healthcheck.service

# Starting and Stopping a Container 

## Ansible Playbook
Podman and Ansible are very good tools individually for managing containers and automating all things respectively. They are even better together for enabling automation and orchestration of the container and pod lifecycles in simple scenarios. 

More information: https://www.redhat.com/en/blog/ansible-podman-container-deployment

### Start a Container

1. Write the `nginx-podman-playbook-start.yaml` playbook

```
---
- name: Podman container management example
  hosts: localhost
  become: true
  collections:
    - containers.podman

  tasks:
    - name: Pull the latest NGINX image
      podman_image:
        name: docker.io/library/nginx
        tag: latest
        state: present

    - name: Run the NGINX container
      podman_container:
        name: nginx_container
        image: docker.io/library/nginx:latest
        state: started
        ports:
          - "8080:80"
        restart_policy: always

    - name: Ensure the container is running
      podman_container:
        name: nginx_container
        state: started
```

2. Run the playbook

```
ansible-playbook nginx-podman-playbook-start.yaml
```

### Stop a Container

1. Write the `nginx-podman-playbook-stop.yaml` playbook

```
---
- name: Podman container management example
  hosts: localhost
  become: true
  collections:
    - containers.podman

  tasks:
    - name: Ensure the container is stopped
      podman_container:
        name: nginx_container
        state: stopped
```

2. Run the playbook

```
ansible-playbook nginx-podman-playbook-stop.yaml
```

## Shell Script 
With only Podman and the shell.

### Start a Container
Run the command as-is or write a script with the below command.

```
podman run --replace -d --name nginx -p 8080:80 docker.io/library/nginx:latest
```

### Stop a Container
Run the command as-is or write a script with the below command.

```
podman stop nginx
```

# Reference

## Docker

- https://docs.docker.com/reference/dockerfile/#healthcheck

## Podman

- https://developers.redhat.com/blog/2019/04/18/monitoring-container-vitality-and-availability-with-podman
- https://www.redhat.com/en/blog/podman-edge-healthcheck

## Ansible

- https://www.redhat.com/en/blog/ansible-podman-container-deployment
- https://docs.ansible.com/ansible/latest/collections/containers/podman/index.html

# Additional Linux Commands

## Listing the Processes

### All Processes with Full Command 
```bash
ps -eafww
```

### All Processes with Container CGroup Namespaces
```bash
ps -ea -o user,exe,ppid,pid,cgroupns,ipcns,mntns,netns,pidns,userns,utsns,cgname
podman ps --ns
```

## Listing the Network Ports
```bash
ss -ltnupr --cgroup
```

### Process Details 

```bash
ls /proc/<PID>/
cat /proc/<PID>/cmdline
cat /proc/<PID>/status
```
## Journal Events

### Listing All Events
```bash
journalctl -b
```

### Listing All Podman Events
```bash
journalctl -b SYSLOG_IDENTIFIER=podman PODMAN_NAME=run_image -o json-pretty
```

### Listing All Container Names
```bash
journalctl -F CONTAINER_NAME
```

### Listing Specific Container Events
```bash
journalctl CONTAINER_NAME=run_image
```


