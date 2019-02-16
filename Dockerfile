# Lets keep it small
FROM ubuntu:18.04

# Update package manager
RUN apt update
# Set timezone info (for non interactive installation of tzdata)
RUN printf 'tzdata tzdata/Areas select Europe\ntzdata tzdata/Zones/Europe select Amsterdam\n' | debconf-set-selections
# Needed for non interactive installation of tzdata
ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NONINTERACTIVE_SEEN=true
# Install default packages
RUN apt install -y apache2 software-properties-common tzdata
# Add additional repos for installing certbot
RUN add-apt-repository -y universe && add-apt-repository -y ppa:certbot/certbot && apt-get update
# Install certbot including apache plugin
RUN apt install -y certbot python-certbot-apache

# Copy in the apache2 config
COPY files/apache.conf /etc/apache2/sites-available/000-default.conf

# Copy in the script that issues a certificate using certbot and starts Apache2 in foreground
COPY startup.sh /var/run/docker-startup.sh

# Expose the default SSL/TLS port and default HTTP port
EXPOSE 80 443

CMD ["/var/run/docker-startup.sh"]