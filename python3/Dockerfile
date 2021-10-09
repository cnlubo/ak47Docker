############################################
# name : cnlubo/python3
############################################
FROM cnlubo/basedeb:v1.0
LABEL maintainer="bolu20080314@gmail.com" \
    provider="cnak47"
# add source
COPY debian.list /etc/apt/sources.list

COPY assets /assets

RUN chmod +x /assets/build/*.sh && \
    /assets/build/prepare.sh && \
    /assets/build/install.sh && \
    /assets/build/cleanup.sh

ENTRYPOINT ["entrypoint.sh"]
CMD ["/usr/local/bin/zsh"]
