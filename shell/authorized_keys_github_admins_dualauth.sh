#!/bin/bash
# If a Public SSH Key (ed25519) of an Organization Admin appears in multiple Admin accounts, publish to /root/.ssh/authorized_keys_github_admins_dualauth
# Run periodically as a cron job, frequency of cron job will determine how long a key is live for.

# GITHUB_USERNAME GitHubAPI-READMEMBERS-SSHAutomation personal access token
#   Permissions: read:gpg_key, read:org, read:public_key
github_api_username='GITHUB_USERNAME'
github_api_key='GITHUB_TOKEN'

# Use grep + awk instead of jq to allow use on FreeBSD/FreeNAS
github_users=$(curl -u $github_api_username:$github_api_key https://api.github.com/orgs/ORGANIZATION_NAME/members?role=admin 2>/dev/null | grep '"login":' | awk -F'"' '{print $4}')

for github_user in $github_users; do
  authorized_keys+="$(curl https://github.com/"$github_user".keys 2>/dev/null | grep -E '^ssh-ed25519' )"
  # var=$'' injects excape sequences into variables
  authorized_keys+=$'\r\n'
done

authorized_keys=$(grep -E '^ssh-ed25519' <<<"$authorized_keys" | sort | uniq -d)

echo "$authorized_keys" > /root/.ssh/authorized_keys_github_admins_dualauth
chmod 700 /root/.ssh/authorized_keys_github_admins_dualauth