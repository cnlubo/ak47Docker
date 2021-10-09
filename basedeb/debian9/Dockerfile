############################################
# name : cnlubo/basedeb
############################################
FROM debian:9.11-slim
LABEL maintainer="bolu20080314@gmail.com" \
    provider="cnak47"
# add source
COPY debian.list /etc/apt/sources.list


ENV PATH /usr/local/bin:$PATH

COPY assets /assets

RUN chmod +x /assets/build/*.sh && \
    /assets/build/prepare.sh && \
    /assets/build/utilities.sh && \
    /assets/build/install.sh && \
    /assets/build/cleanup.sh

ENV ENV LD_LIBRARY_PATH=/usr/local/software/sharelib/lib:/usr/local/software/ssl/lib:$LD_LIBRARY_PATH

ENTRYPOINT ["entrypoint.sh"]
CMD ["/usr/local/bin/zsh"]
