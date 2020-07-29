############################################
# version : cnlubo/nginx
# desc : 扩展版本
############################################
FROM cnlubo/python3:3.7.4
LABEL maintainer="bolu20080314@gmail.com" \
    provider="cnak47"

COPY debian.list /etc/apt/sources.list

ENV NGINX_HOME="/usr/local/software/nginx" \
    NGINX_USER="www"

ENV NGINX_LOG_DIR=$NGINX_HOME/logs \
    NGINX_SITECONF_DIR="/etc/nginx/sites-enabled" 

ENV PATH $NGINX_HOME/sbin:$PATH
COPY assets /assets
RUN chmod +x /assets/build/*.sh && \
    /assets/build/prepare.sh && \
    /assets/build/install.sh && \
    /assets/build/cleanup.sh

EXPOSE 80/tcp 443/tcp 1935/tcp

ENTRYPOINT ["entrypoint.sh"]
# CMD ["/usr/local/bin/zsh"]

# CMD ["/usr/local/software/nginx/sbin/nginx"]
