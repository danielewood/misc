CERT_COMMON_NAME='intranet.contoso.org'
CERTBOT_SSL_DIR="/home/certbot/letsencrypt/dehydrated/certs/$CERT_COMMON_NAME"
APACHE_SSL_DIR="/srv/certs/$CERT_COMMON_NAME"
REMOTE_COMPUTER='certbot.contoso.org'

mkdir -p $APACHE_SSL_DIR

if [ ! -f $APACHE_SSL_DIR/fullchain.pem ]; then
        echo "No Certs Found, copying all certs..."
        scp certbot@$REMOTE_COMPUTER:$CERTBOT_SSL_DIR/fullchain.pem $APACHE_SSL_DIR/fullchain.pem
        scp certbot@$REMOTE_COMPUTER:$CERTBOT_SSL_DIR/privkey.pem $APACHE_SSL_DIR/privkey.pem
        scp certbot@$REMOTE_COMPUTER:$CERTBOT_SSL_DIR/cert.pem $APACHE_SSL_DIR/cert.pem
        scp certbot@$REMOTE_COMPUTER:$CERTBOT_SSL_DIR/fullchain.pem.MD5 $APACHE_SSL_DIR/fullchain.pem.MD5
        echo "Restarting Apache..."
        service apache2 restart
        exit 0
fi

scp certbot@$REMOTE_COMPUTER:$CERTBOT_SSL_DIR/fullchain.pem.MD5 $APACHE_SSL_DIR/fullchain.pem.MD5

if [ $(md5sum $APACHE_SSL_DIR/fullchain.pem | awk '{print $1}') != $(cat $APACHE_SSL_DIR/fullchain.pem.MD5) ]
  then
        echo "MD5 Hash has changed, overwriting existing certs and reloading Apache"
        scp certbot@$REMOTE_COMPUTER:$CERTBOT_SSL_DIR/fullchain.pem $APACHE_SSL_DIR/fullchain.pem
        scp certbot@$REMOTE_COMPUTER:$CERTBOT_SSL_DIR/privkey.pem $APACHE_SSL_DIR/privkey.pem
        scp certbot@$REMOTE_COMPUTER:$CERTBOT_SSL_DIR/cert.pem $APACHE_SSL_DIR/cert.pem
        echo "Restarting Apache..."
        service apache2 restart

  else
        echo "MD5 Hash is unchanged, exiting..."

fi

