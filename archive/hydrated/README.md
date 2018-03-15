# Hydrated
Hydrated was originally written to solve a problem, Lync/Skype4B Edge requires a costly SAN certificate. This script adds a layer to `dehydrated` to make adding multiple sets of SSL certificate in an automated manner easier to manage.

## Installation

```
cd ~
git clone https://github.com/danielewood/hydrated
cd hydrated
git clone https://github.com/lukas2511/dehydrated
cd dehydrated
mkdir hooks
git clone https://github.com/kappataumu/letsencrypt-cloudflare-hook hooks/cloudflare
```

If you are using Python 3 on CentOS 7:
```
sudo yum install epel-release
sudo yum install python34-setuptools
sudo easy_install-3.4 pip
```

CloudFlare Hooks:
```
sudo pip install -r hooks/cloudflare/requirements.txt
```

GoDaddy Hooks:
```
sudo pip install -r hooks/cloudflare/requirements.txt
```



## hydrated.sh
- Hydrated generates said certificate using Let's Encrypt with DNS Hooks in a format that can then be imported to Lync/S4B.
- If you need another DNS provider's hooks, look here: https://github.com/lukas2511/dehydrated/wiki/Examples-for-DNS-01-hooks
- All you need to do is edit the .conf and put in your settings. You can pass any other config file as an argument. This makes for easy use of cron for generating multiple certificates using different conf files.
- A Powershell script will be added later, as well as a writeup, to allow automatic importation of certificates into Windows IIS and Lync servers.

## Install-LE-CsCertificate.ps1
- Description here...
## Install-LE-IISCertificate.ps1
- Description here...
## Send-NewCertificateNotification.ps1
- Description here...
## get-apache-certs.sh
- Description here...
## hydrated-defaults.conf
- Description here...
## hydrated-common.conf
- Description here...


## Configuration

Your account's CloudFlare email and API key are expected to be in the environment, so make sure to place these statements in `dehydrated/config`, which is automatically sourced by `dehydrated` on startup:

```
echo "export CF_EMAIL=user@example.com" >> config
echo "export CF_KEY=K9uX2HyUjeWg5AhAb" >> config
echo "export CF_DEBUG=true" >> config
echo "export CF_DNS_SERVERS='8.8.8.8 8.8.4.4' >> config
```
