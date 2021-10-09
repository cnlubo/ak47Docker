ARG from_img_name="cnlubo/basedeb"
ARG from_img_tag="v1.1"
ARG from_img_hash=""
FROM ${from_img_name}:${from_img_tag}${docker_img_hash}
ARG tomcat_version="9.0.38"
LABEL maintainer="bolu20080314@gmail.com" \
    provider="cnak47"


# add source
COPY debian.list /etc/apt/sources.list

COPY assets/ /
RUN chmod +x /build/*.sh && \
    /build/prepare.sh && \
    /build/install.sh && \
    /build/cleanup.sh

WORKDIR ${PG_HOME}

ENTRYPOINT ["entrypoint.sh"]

EXPOSE 5432/tcp
