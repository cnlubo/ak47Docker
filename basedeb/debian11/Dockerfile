############################################
# name : cnlubo/basedeb
############################################
ARG from_img_name="debian"
ARG from_img_tag="11.4-slim"
ARG from_img_hash=""
FROM ${from_img_name}:${from_img_tag}${docker_img_hash}
ARG debian_version="11.4"
LABEL maintainer="bolu20080314@gmail.com" \
    provider="cnak47" \
    version=${debian_version}
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
CMD ["/bin/bash"]
