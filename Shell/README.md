# Shell

## Generate-NetApp-PublicCA-SSL.sh
- Takes Let's Encrypt SSL certificates and generates a script to paste in to your NetApp CLI to automatically install the certificate.
- Paths assume you use acme.sh, adjust variables at top of file as needed.


## Set-IPAUserPassword.sh
- enforce NTP time sync between IPA servers
- reset a user's password
- allow immediate use of network shares without user having to change their password again
- reset their password expiration to 2037
- verify NIS and IPA password replication between all three directory servers

## Gists:
  - [auto-netapp-public-ssl.sh](https://gist.github.com/danielewood/7891aef986f892d94e70af2ea695da97)
  - [auto-netapp-public-ssl-transcript](https://gist.github.com/danielewood/059e6ed7990435da5a90c43002da331e)
