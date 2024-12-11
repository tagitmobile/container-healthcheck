# container-healthcheck

The sample workspace to demonstrate Docker or Podman health check feature.

# Commands

## Podman

### Run the `container-healthcheck` Container

```
podman run --replace -d --name container-healthcheck --health-cmd /healthcheck --health-on-failure=kill --healthcheck-interval=0 --health-retries=1 docker.io/tagitmobile/container-healthcheck
```

### Manually Execute  `container-healthcheck` Container Health Check

```
podman healthcheck run container-healthcheck
```

### Trigger Unhealthy Container 

```
podman exec container-healthcheck touch /uh-oh
```

# Reference

## Docker

- https://docs.docker.com/reference/dockerfile/#healthcheck

## Podman

- https://developers.redhat.com/blog/2019/04/18/monitoring-container-vitality-and-availability-with-podman
- https://www.redhat.com/en/blog/podman-edge-healthcheck