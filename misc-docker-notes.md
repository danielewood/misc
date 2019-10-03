# Working notes on docker containers

## Basic container creation/running

### Pull and start a docker container in the background
```bash
docker run -d maintainer/container:version
```

### Pull and start a container with extra settings
```bash
docker run -d \ # Pull and start a vouch-proxy, background it after start
    -p 9090:9090 \ # Map ports Host:Container
    --name vouch-proxy \ # Set its running name be vouch-proxy
    -v ${PWD}/config:/config \ # map config/*:/config/*
    -v ${PWD}/data:/data \
    --restart unless-stopped \ # Make this container come back at reboot.
    voucher/vouch-proxy:alpine # Name of image to pull from docker hub, or run if its already local
```

### filestash example from git repo
```bash
git clone https://github.com/mickael-kerjean/filestash
cd filestash/
docker build -t filestash ./docker/
cp config/config.json config/config.json.example
nano config/config.json
# enable write by all users so that the container can write to the config file on the host
chmod 666 config/config.json

docker run -d \
  -p 8334:8334 \
  --name filestash \
  -v ${PWD}/config/config.json:/app/data/state/config/config.json \
  --restart unless-stopped \
  filestash:latest
```

### monstaftp example dropping a folder into nginx+php for it to serve up
```bash
curl -L https://www.monstaftp.com/downloads/monsta_ftp_2.9.1_install.zip -O
unzip monsta_ftp_2.9.1_install.zip
nano mftp/settings/settings.json

docker run -d \
  --name monstaftp \
  -p 8080:8080 \
  -v ${PWD}/mftp:/var/www/html \
  --restart unless-stopped \
  trafex/alpine-nginx-php7
```

### vouch-proxy example building from git repo
```bash
git clone https://github.com/vouch/vouch-proxy
cd vouch-proxy
cp config/config.yml_example_google config/config.yml
nano config/config.yml

# -f to specify alternate Dockerfile in directory
# -t for container name to reference when running
docker build -t vouch-alpine -f Dockerfile.alpine .

# Run the build we just created
docker run -d \
    -p 9090:9090 \
    --name vouch-alpine \
    -v ${PWD}/config:/config \
    -v ${PWD}/data:/data \
    --restart unless-stopped \
    vouch-alpine
```

## Container maintenence/management

### See running containers
```bash
docker container ls
```

### See all containers
```bash
docker container ls -a
```

### Enter bash terminal within a container
```bash
docker exec -it vouch-proxy /bin/bash
```

### See logs for a container
```bash
docker logs vouch-proxy
```

### Stop, Remove container
```bash
docker container stop vouch-proxy
docker container rm vouch-proxy
```

### Clear all non-running docker assets
```bash
docker system prune
```

### Cleanup EVERYTHING not currently in use
```bash
docker system prune -a
```

### Show container mount points
```bash
docker inspect vouch-proxy | jq -c '.[0].Mounts'
```

### Show restart policy of a container
```bash
docker inspect vouch-proxy | jq -c '.[0].HostConfig.RestartPolicy.Name'
```

### Set/Update restart policy of a container
```bash
docker update --restart=unless-stopped vouch-proxy
```
