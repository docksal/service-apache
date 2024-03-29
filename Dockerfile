ARG UPSTREAM_IMAGE
FROM ${UPSTREAM_IMAGE}

# TODO: Drop this? HTTPS termination should happen at the reverse proxy and this is not used anyway.
# Generate a self-signed cert
RUN set -xe; \
	apk add --update --no-cache \
		bash \
		openssl \
	; \
	openssl req -batch -x509 -newkey rsa:4096 -days 3650 -nodes -sha256 -subj "/" \
		-keyout /usr/local/apache2/conf/server.key -out /usr/local/apache2/conf/server.crt; \
	apk del openssl; \
	rm -rf /var/cache/apk/*

# Configure Apache environment variables
ENV \
	APACHE_DOCUMENTROOT=/var/www/docroot \
	APACHE_FCGI_HOST_PORT="cli:9000"

RUN set -xe; \
	# Enabled extra modules
	sed -i '/^#.* deflate_module /s/^#//' /usr/local/apache2/conf/httpd.conf; \
	sed -i '/^#.* proxy_module /s/^#//' /usr/local/apache2/conf/httpd.conf; \
	sed -i '/^#.* proxy_http_module /s/^#//' /usr/local/apache2/conf/httpd.conf; \
	sed -i '/^#.* proxy_fcgi_module /s/^#//' /usr/local/apache2/conf/httpd.conf; \
	sed -i '/^#.* proxy_connect_module /s/^#//' /usr/local/apache2/conf/httpd.conf; \
	sed -i '/^#.* ssl_module /s/^#//' /usr/local/apache2/conf/httpd.conf; \
	sed -i '/^#.* socache_shmcb_module /s/^#//' /usr/local/apache2/conf/httpd.conf; \
	sed -i '/^#.* rewrite_module /s/^#//' /usr/local/apache2/conf/httpd.conf; \
	# Enable extra config files
	sed -i '/^#.* conf\/extra\/httpd-vhosts.conf/s/^#//' /usr/local/apache2/conf/httpd.conf; \
	# Used for runtime config overrides
	mkdir -p /usr/local/apache2/conf/custom; \
	# Link out custom docroot location to the default htdocs folder by default
	mkdir -p /var/www; \
	ln -s /usr/local/apache2/htdocs $APACHE_DOCUMENTROOT

COPY httpd-foreground /usr/local/bin/
COPY conf /usr/local/apache2/conf
COPY healthcheck.sh /opt/healthcheck.sh

WORKDIR /var/www

EXPOSE 80 443

CMD ["httpd-foreground"]

# Health check script
HEALTHCHECK --interval=5s --timeout=1s --retries=12 CMD ["/opt/healthcheck.sh"]
