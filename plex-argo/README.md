# Create a **free** Cloudflare Argo Tunnel to your Plex Media Server

Enables fast remote access to your Plex Media Server, even behind a carrier grade NAT or VPN with no port-forwarding ability.

**NOTE:** Do not add `localhost, 127.0.0.1, or ::1` to the `Settings/Network/List of IP addresses and networks that are allowed without auth` box. That will allow anyone with your Plex Argo URL (anyone that is a member of your server) to access the Admin WebUI with no access controls.

## CloudFlare Argo

Read the [The Cloudflare Blog - A free Argo Tunnel for your next project](https://blog.cloudflare.com/a-free-argo-tunnel-for-your-next-project/).

TL;DR - **Free TryCloudFlare** Argo Tunnel features:
 - Operate much like a Reverse SSH tunnel + nginx on a remote VPS
 - Unique URLs per session (i.e. apple-bali-matters-local.trycloudflare.com)
 - Support for http:80 & https:443
 - Free to use and no bandwidth restrictions
 - No account or authentication requirements
 - Simplier setup with _much_ less overhead
 
## Plex Custom Connection URLs

When you specify a custom connection URL in your Plex Media Server, it will publish that URL in the PlexAPI. This allows all your clients to discover alternative paths to your server. 

This Published information can be seen for your server by going to `https://plex.tv/api/resources?X-Plex-Token=YOUR_API_TOKEN`

**NOTE:** This API token changes each time your Plex Media Server restarts.

You can obtain your current API Token and see your current customConnections URL in the Plex API with the following:

**Windows PowerShell** snippet:

```powershell
$PreferencesPath='Registry::HKEY_CURRENT_USER\SOFTWARE\Plex, Inc.\Plex Media Server'
$PlexOnlineToken='https://plex.tv/api/resources?X-Plex-Token=' + (Get-ItemProperty -Path $PreferencesPath -Name PlexOnlineToken).PlexOnlineToken
Write-Host 'Plex API URL:' ${PlexOnlineToken}
(Invoke-WebRequest -UseBasicParsing -Uri ${PlexOnlineToken}).Content
```

Bash snippet (**Docker**):

```bash
PreferencesPath='/home/ubuntu/plex/config/Library/Application Support/Plex Media Server/Preferences.xml'
PlexOnlineToken='https://plex.tv/api/resources?X-Plex-Token='$(grep -oP 'PlexOnlineToken="\K[^"]*' "${PreferencesPath}")
echo "Plex API URL: ${PlexOnlineToken}"
curl -s $PlexOnlineToken
```

Bash snippet (**systemd**):

```bash
PreferencesPath='/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Preferences.xml'
PlexOnlineToken='https://plex.tv/api/resources?X-Plex-Token='$(grep -oP 'PlexOnlineToken="\K[^"]*' "${PreferencesPath}")
echo "Plex API URL: ${PlexOnlineToken}"
curl -s $PlexOnlineToken
```

# Remote Access Tunnel Setup

## Linux Users

You will need [cloudflared](https://developers.cloudflare.com/argo-tunnel/downloads/) installed and running. I recommend installing it as a service.

```bash
sudo mkdir -p /etc/cloudflared
sudo bash -c "cat <<'EOF'>/etc/cloudflared/config.yml
url: http://localhost:32400
metrics: localhost:33400
EOF"
sudo cloudflared service install
```

The following bash script will update a docker container running Plex with the current Argo URLs.
You will need to adjust `$PreferencesPath` to match your setup. 

I suggest you run this as a cron job every few minutes, or use a systemd timer.

### Plex-Argo-DirectoryUpdate-docker.bash

```bash
#!/bin/bash
# Assumes cloudflared is running with metrics server on port 33400
# Example: cloudflared tunnel --url 'http://localhost:32400' --metrics 'localhost:33400'

PreferencesPath='/home/ubuntu/plex/config/Library/Application Support/Plex Media Server/Preferences.xml'
PlexOnlineToken='https://plex.tv/api/resources?X-Plex-Token='$(grep -oP 'PlexOnlineToken="\K[^"]*' "${PreferencesPath}")
clientIdentifier=$(grep -oP 'ProcessedMachineIdentifier="\K[^"]*' "${PreferencesPath}")

PlexAPIcustomConnections=$(curl -s $PlexOnlineToken | sed -n "/${clientIdentifier}/{n;p;n;p;}" | grep -oP 'address="\K[^"]*\.trycloudflare\.com' | head -n1)
ArgoURL=$(curl -s http://localhost:33400/metrics | grep -oP 'userHostname="https://\K[^"]*\.trycloudflare\.com' | head -n1)

[ -z $ArgoURL ] && exit
[ -z $PlexAPIcustomConnections ] && exit

if [[ $ArgoURL != $PlexAPIcustomConnections ]]; then
    docker container stop plex
    PreferencesValue="https://${ArgoURL}:443,http://${ArgoURL}:80"
    # Set new Argo URL
    sed -i "s|customConnections=\".*\"|customConnections\=\"${PreferencesValue}\"|" "${PreferencesPath}"
    # Disable Plex Relay Servers
    sed -i "s|RelayEnabled=\"1\"|RelayEnabled=\"0\"|" "${PreferencesPath}"
    # Disable Plex Remote Access Methods
    sed -i "s|PublishServerOnPlexOnlineKey=\"1\"|PublishServerOnPlexOnlineKey=\"0\"|" "${PreferencesPath}"
    docker container restart plex
fi
```

### Plex-Argo-DirectoryUpdate-systemd.bash

```bash
#!/bin/bash
# Assumes cloudflared is running with metrics server on port 33400
# Example: cloudflared tunnel --url 'http://localhost:32400' --metrics 'localhost:33400'

PreferencesPath='/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Preferences.xml'
PlexOnlineToken='https://plex.tv/api/resources?X-Plex-Token='$(grep -oP 'PlexOnlineToken="\K[^"]*' "${PreferencesPath}")
clientIdentifier=$(grep -oP 'ProcessedMachineIdentifier="\K[^"]*' "${PreferencesPath}")

PlexAPIcustomConnections=$(curl -s $PlexOnlineToken | sed -n "/${clientIdentifier}/{n;p;n;p;}" | grep -oP 'address="\K[^"]*\.trycloudflare\.com' | head -n1)
ArgoURL=$(curl -s http://localhost:33400/metrics | grep -oP 'userHostname="https://\K[^"]*\.trycloudflare\.com' | head -n1)

[ -z $ArgoURL ] && exit
[ -z $PlexAPIcustomConnections ] && exit

if [[ $ArgoURL != $PlexAPIcustomConnections ]]; then
    systemctl stop plexmediaserver.service
    PreferencesValue="https://${ArgoURL}:443,http://${ArgoURL}:80"
    # Set new Argo URL
    sed -i "s|customConnections=\".*\"|customConnections\=\"${PreferencesValue}\"|" "${PreferencesPath}"
    # Disable Plex Relay Servers
    sed -i "s|RelayEnabled=\"1\"|RelayEnabled=\"0\"|" "${PreferencesPath}"
    # Disable Plex Remote Access Methods
    sed -i "s|PublishServerOnPlexOnlineKey=\"1\"|PublishServerOnPlexOnlineKey=\"0\"|" "${PreferencesPath}"
    systemctl restart plexmediaserver.service
fi
```


## Windows Users

The following `PowerShell` snippet will Configure your Plex Media Server for Remote Access through CloudFlare.

We are making sure that Plex Remote Access is disabled as we do not want to proxy anything through the Plex Servers and want it all done through Cloudflare.

```powershell
$PreferencesPath='Registry::HKEY_CURRENT_USER\SOFTWARE\Plex, Inc.\Plex Media Server'
# Disable "Settings/Remote Access"
Set-ItemProperty -Path ${PreferencesPath} -Name PublishServerOnPlexOnlineKey -Value 0
# Disable "Settings/Network/Enable Relay"
Set-ItemProperty -Path ${PreferencesPath} -Name RelayEnabled -Value 0 
```

## Scheduled Tasks
Included in this are two Windows Scheduled Task XMLs that contain all the logic needed to automatically maintain an Argo Tunnel and keep the Plex Directory up to date with your current tunnel URLs.

### Plex-Argo-tunnel.xml
Starts cloudflared with a free trycloudflare.com Argo Tunnel (no CloudFlare Account needed)

You can replace localhost:32400 with your Computer_IP_Address:32400 so that Plex detects the traffic as "external" for bandwith monitoring purposes.

When you import this XML into Task Scheduler, you will need to change the AtLogon User to the account which Plex runs under.

Change `C:\PATH\TO\CLOUDFLARED\cloudflared.exe` to the path where you stored the [cloudflared.exe Application](https://developers.cloudflare.com/argo-tunnel/downloads/) prior to importing the XML.

This Scheduled Task launches cloudflared.exe and hides the powershell window on launch, so you should only see it momentarily and then never again.

### Plex-Argo-DirectoryUpdate.xml

Updates Plex customConnection URLs, if different from Argo Tunnel URL, and restarts Plex Media Server to push new URLs to the Plex API

When you import this XML into Task Scheduler, you will need to change the User under the Triggers Tab to the account which Plex runs under.

The following PowerShell script is embedded within the Scheduled Task, it will attempt to update the Plex API URLs every five minutes if there are any changes. It hides the powershell window on launch, so you should only see it momentarily and then never again:

```powershell
  Start-Sleep 10
  While ($true) {
    $PreferencesPath='Registry::HKEY_CURRENT_USER\SOFTWARE\Plex, Inc.\Plex Media Server'
    $PlexOnlineToken='https://plex.tv/api/resources?X-Plex-Token=' + (Get-ItemProperty -Path $PreferencesPath -Name PlexOnlineToken).PlexOnlineToken
    $clientIdentifier=(Get-ItemProperty -Path $PreferencesPath -Name ProcessedMachineIdentifier).ProcessedMachineIdentifier

    $regex = '([\w-]+\.)+trycloudflare\.com'

    $ArgoURL=$null
    $PlexAPIcustomConnections=$null
    $RestError=$null

    Try {
      $ArgoURL=(Invoke-WebRequest -UseBasicParsing -Uri 'http://localhost:33400/metrics').Content | Select-String -Pattern $regex -AllMatches | % { $_.Matches } | % { $_.Value } | Select-Object -First 1
      [xml]$doc = (New-Object System.Net.WebClient).DownloadString("${PlexOnlineToken}")
      $PlexAPIcustomConnections=($doc.MediaContainer.Device | 
      Where clientIdentifier -eq $clientIdentifier).Connection | 
      where address -Like '*trycloudflare.com' | Select-Object -ExpandProperty address -First 1
    } Catch {
      $RestError = $_
      Start-Sleep 60
    }
    if ((!$ArgoURL) -or (!$PlexAPIcustomConnections)){continue}
    if ($ArgoURL -ne $PlexAPIcustomConnections){
      $PreferencesValue='https://' + ${ArgoURL} + ':443,http://' + ${ArgoURL} + ':80'
      Set-ItemProperty -Path ${PreferencesPath} -Name customConnections -Value ${PreferencesValue}
      $PlexEXE = 'C:\Program Files (x86)\Plex\Plex Media Server\Plex Media Server.exe'
      Get-Process | Where-Object {$_.Path -eq $PlexEXE} | Stop-Process
      Start-Process $PlexEXE
    }
    Start-Sleep 300
  }
```
