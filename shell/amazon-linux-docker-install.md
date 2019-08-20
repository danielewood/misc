## amazon-linux-docker-install.md
Applies to Yum based Distros:
  - [Amazon Linux 2](https://aws.amazon.com/amazon-linux-2/release-notes/)

## Docker CE Install

```sh
# install docker and other tools
yum -y install docker git gcc-c++ make

# add ec2-user to docker group
usermod -aG docker ec2-user

# enable service
systemctl enable docker
systemctl start docker
```

## docker-compose install

```sh
# get latest "docker-compose" version
compose_latest=$(curl -I https://github.com/docker/compose/releases/latest 2>/dev/null | grep "^Location" | awk -F'/' '{print $NF}' | tr -d "\r")

# install with docker-compose installer script
curl -L "https://github.com/docker/compose/releases/download/${compose_latest}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# make executable
chmod +x /usr/local/bin/docker-compose

# link to /usr/bin for AmazonLinux2 $PATH compatibility
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# validate install
docker-compose --version
```
