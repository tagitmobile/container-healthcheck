# Podman Container Ops and Management

The sample workspace to demonstrate Podman health check feature and management of containers using Ansible.

# Pre-requisites

## RHEL 8.x

```
sudo dnf install podman
sudo dnf install ansible
ansible-galaxy collection install containers.podman
```


## RHEL 9.x

```
sudo dnf install podman
sudo dnf install ansible-core
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

# Integration with `systemd`

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


# Ansible Playbook

## Start a Container

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

## Stop a Container

1. Write the `nginx-podman-playbook-stop.yaml` playbook

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
ansible-playbook nginx-podman-playbook-stop.yaml
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