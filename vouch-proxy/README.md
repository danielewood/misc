# Setup vouch-proxy on a VPS/VM:
1. Have Docker and nginx setup.
1. Copy nginx files from this folder to /etc/nginx
1. Edit configs to replace YOUR.DOMAIN and YOUR_DOMAIN
1. Edit `/etc/nginx/snippets/vouch.proxy_pass.map to reflect your environment`
1. `systemctl reload nginx`
1. Make vouch config folder (or clone from GitHub)
    ```bash
    mkdir -p ~/vouch-proxy/config/
    mkdir -p ~/vouch-proxy/data/
    ```
1. Place config files in the `~/vouch-proxy/config/` folder
    ```bash
    cp config-gmail.yml ~/vouch-proxy/config/config.yml
    ```
1. Pull and start a container with extra settings
    ```bash
    cd ~/vouch-proxy/
    docker run -d \ # Pull and start a vouch-proxy, background it after start
        -p 9090:9090 \ # Map ports Host:Container
        --name vouch-proxy \ # Set its running name be vouch-proxy
        -v ${PWD}/config:/config \ # map config/*:/config/*
        -v ${PWD}/data:/data \
        --restart unless-stopped \ # Make this container come back at reboot.
        voucher/vouch-proxy:alpine # Name of image to pull from docker hub, or run if its already local
    ```
