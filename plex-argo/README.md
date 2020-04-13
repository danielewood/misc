# Create a free CloudFlare Argo tunnel to your Plex Media Server
This enables fast remote access to your Plex Media Server, even behind a Carrier Grade NAT or VPN with no port-forwarding ability.

## CloudFlare Argo
Read the [CloudFlare blog post on Free Argo tunnels](https://blog.cloudflare.com/a-free-argo-tunnel-for-your-next-project/).

TL;DR: TryCloudFlare Argo Tunnels:
 - Have Unique URL per session
 - Are free to use and have no bandwidth charges associated with them
 - Require No Account or Authentication
 - Operate much like a Reverse SSH tunnel + nginx on a remote VPS, except you dont need to do any setup.
 
## Plex Custom Connection URLs
When you specity a Custom Connection URL in your Plex Media Server, it will publish that URL in the PlexAPI, allowing all your clients to discover alternative paths to your server. This Published information can be seen for your server by going to `https://plex.tv/api/resources?X-Plex-Token=YOUR_API_TOKEN`
This API token is refreshed every time your Plex Media Server restarts.

You can obtain your current API Token and see your current customConnections URL in the Plex API with the following powershell snippet:
    
```powershell
    $RegistryPath='Registry::HKEY_CURRENT_USER\SOFTWARE\Plex, Inc.\Plex Media Server'
    $PlexOnlineToken=(Get-ItemProperty -Path $RegistryPath -Name PlexOnlineToken).PlexOnlineToken
    $PlexOnlineToken='https://plex.tv/api/resources?X-Plex-Token=' + $PlexOnlineToken
    Write-Host 'Plex API URL:' ${PlexOnlineToken}
    (Invoke-WebRequest -UseBasicParsing -Uri ${PlexOnlineToken}).Content
```
# Plex Setup

## Linux Users

The following bash script will update a docker container running Plex with the current Argo URLs.
You will need to adjust `$PreferencesPath` to match your setup. If you are running Plex as a systemd service, just change docker to systemctl.

I suggest you run this as a cron job every few minutes, or use a systemd timer.

You will need [cloudflared](https://developers.cloudflare.com/argo-tunnel/downloads/) installed and running. You should probably write a systemd service file for it.

### Plex-Argo-DirectoryUpdate.bash

```bash
#!/bin/bash
# Assumes the cloudflared is running with metrics server
# Example: cloudflared tunnel --url 'http://localhost:32400' --metrics 'localhost:33400'

PreferencesPath='/home/ubuntu/plex/config/Library/Application Support/Plex Media Server/Preferences.xml'
PlexOnlineToken='https://plex.tv/api/resources?X-Plex-Token='$(grep -oP 'PlexOnlineToken="\K[^"]*' "${PreferencesPath}")

PlexAPIcustomConnections=$(curl -s $PlexOnlineToken | grep -oP 'address="\K[^"]*\.trycloudflare\.com' | head -n1)
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

## Windows Users
The following powershell snippet will Configure your Plex Media Server for Remote Access through CloudFlare.
We are making sure that Plex Remote Access is disabled as we do not want to proxy anything through the Plex Servers and want it all done through CloudFlare.

```powershell
    $RegistryPath='Registry::HKEY_CURRENT_USER\SOFTWARE\Plex, Inc.\Plex Media Server'
    # Disable "Settings/Remote Access"
    Set-ItemProperty -Path ${RegistryPath} -Name PublishServerOnPlexOnlineKey -Value 0
    # Disable "Settings/Network/Enable Relay"
    Set-ItemProperty -Path ${RegistryPath} -Name RelayEnabled -Value 0 
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

The following powershell script is embedded within the Scheduled Task, it will attempt to update the Plex API URLs every five minutes if there are any changes. It hides the powershell window on launch, so you should only see it momentarily and then never again:

```powershell
  Start-Sleep 10
  While ($true) {
    $RegistryPath='Registry::HKEY_CURRENT_USER\SOFTWARE\Plex, Inc.\Plex Media Server'
    $PlexOnlineToken=(Get-ItemProperty -Path $RegistryPath -Name PlexOnlineToken).PlexOnlineToken
    $PlexOnlineToken='https://plex.tv/api/resources?X-Plex-Token=' + $PlexOnlineToken

    $regex = '([\w-]+\.)+trycloudflare\.com'

    $ArgoURL=$null
    $PlexAPIcustomConnections=$null
    $RestError=$null

    Try {
      $ArgoURL=(Invoke-WebRequest -UseBasicParsing -Uri 'http://localhost:33400/metrics').Content | Select-String -Pattern $regex -AllMatches | % { $_.Matches } | % { $_.Value } | Select-Object -First 1
      $PlexAPIcustomConnections=(Invoke-WebRequest -UseBasicParsing -Uri ${PlexOnlineToken}).Content | Select-String -Pattern $regex -AllMatches | % { $_.Matches } | % { $_.Value } | Select-Object -First 1
    } Catch {
      $RestError = $_
      Start-Sleep 60
    }
    if ((!$ArgoURL) -or (!$PlexAPIcustomConnections)){continue}
    if ($ArgoURL -ne $PlexAPIcustomConnections){
      $RegistryValue='https://' + ${ArgoURL} + ':443,http://' + ${ArgoURL} + ':80'
      Set-ItemProperty -Path ${RegistryPath} -Name customConnections -Value ${RegistryValue}
      $PlexEXE = 'C:\Program Files (x86)\Plex\Plex Media Server\Plex Media Server.exe'
      Get-Process | ? {$_.path -eq $PlexEXE} | Stop-Process
      Start-Process $PlexEXE
    }
    Start-Sleep 300
  }
```
