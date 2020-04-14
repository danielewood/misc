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
