# VMWare-ESXi-ssh-pubkey

Commands to disable ssh password authentication, enable ed25519 pubkey authentication, and make the sshd start at boot.

## Disable password auth, add ed25519 as an allowed key type
    cat<<'EOF'>>/etc/ssh/sshd_config
    PermitRootLogin without-password
    UsePAM no
    ChallengeResponseAuthentication no
    PasswordAuthentication no
    PubkeyAcceptedKeyTypes=+ssh-ed25519
    
    EOF

## Add your ssh keys to authorized_keys
    mkdir -p /etc/ssh/keys-root/
    
    cat<<'EOF'>>/etc/ssh/keys-root/authorized_keys
    ssh-ed25519 keyhere
    ssh-rsa keyhere
    
    EOF
    
## Set authorized_keys file permissions
    chmod 700 -R /etc/ssh/keys-root
    chmod 600 -R /etc/ssh/keys-root/authorized_keys

## Restart SSHd to use new config.
    /etc/init.d/SSH restart
    
## Enable SSHd on boot and suppress SSH warning on WebUI
    vim-cmd hostsvc/enable_ssh
    esxcfg-advcfg -s 1 /UserVars/SuppressShellWarning
