#!/usr/bin/env bash

# If PROXY_HOST and PROXY_PORT env vars are set, 
# then make sure proxy.conf file is created
if [[ -z "${PROXY_HOST}" ]] ||  [[ -z "${PROXY_PORT}" ]]; then
  echo "Apache will not run as ReverseProxy."
  # Set the 'Proxy' command line parameter for apachectl
  APACHE_PROXY=NoProxy
else
  echo -e "<Location \"/\">\n\
  RequestHeader set X-Forwarded-Proto "https"
  ProxyPass http://$PROXY_HOST:$PROXY_PORT/\n\
  ProxyPassReverse http://$PROXY_HOST:$PROXY_PORT/\n\
  </Location>" > /etc/apache2/conf-include/proxy.conf
  # Set the 'Proxy' command line parameter for apachectl
  APACHE_PROXY=Proxy
fi

# Check if required env vars for certbot are set
if [[ -z "${LE_EMAIL}" ]] ||  [[ -z "${LE_DOMAIN}" ]]; then
  echo "Apache will not run with ssl/tls endpoint."
else
  # Set the right ServerName and use https scheme
  # Sed explained: Ignore everything from start to first occurrence of 'ServerName'
  # Then do a regular substitution
  sed -i "0,/ServerName/! s/.*ServerName.*/\tServerName https:\/\/$LE_DOMAIN/" /etc/apache2/sites-available/000-default.conf
  # Run certbot
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
apachectl -DFOREGROUND -D$APACHE_PROXY