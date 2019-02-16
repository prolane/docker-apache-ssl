#!/usr/bin/env bash

# Check if domain is set
# If set, set ServerName in the apache.conf
if [[ -z "${LE_DOMAIN}" ]]; then
  echo "ServerName is not set in apache conf."
else
  sed -i '/ServerName/c\ServerName '"$LE_DOMAIN" /etc/apache2/sites-available/000-default.conf
fi

# Check if required env vars for certbot are both set
# If both set, run certbot
if [[ -z "${LE_EMAIL}" ]] ||  [[ -z "${LE_DOMAIN}" ]]; then
  echo "Apache will not run with ssl/tls endpoint."
else
  certbot -n --apache --agree-tos --email ${LE_EMAIL} --domains ${LE_DOMAIN}
  # Start cron (so the certs can be automatically renewed)
  service cron start
fi

# Check if apache2 was already started by certbot.
# We don't want it to start as a service. We want to start apache in foreground
service apache2 status
if test $? -eq 0
then
  echo "Apache2 service is running. Service will now be stopped."
  service apache2 stop
fi

# Start apache in foreground
echo "Will now start apache2 in foreground."
apachectl -DFOREGROUND