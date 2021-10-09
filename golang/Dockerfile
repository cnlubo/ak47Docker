ARG from_img_name="golang"
ARG from_img_tag="1.13.4-alpine3.10"
ARG from_img_hash=""
FROM ${from_img_name}:${from_img_tag}${docker_img_hash}
ARG golang_version="1.13.4"
LABEL maintainer="bolu20080314@gmail.com" \
    provider="cnak47" \
    version=${golang_version}

ENV TEST_ASSET_KUBECTL=/usr/local/bin/kubectl \
    TEST_ASSET_KUBE_APISERVER=/usr/local/bin/kube-apiserver \
    TEST_ASSET_ETCD=/usr/local/bin/etcd \
    PATH=/usr/local/bin:$PATH

# RUN apk add --no-cache --update \
#     alpine-sdk musl-dev openssl bash

# COPY bin/* /usr/local/bin/

# ARG commit_id
# ENV COMMIT_ID=${commit_id}
COPY assets /assets
# ARG version
# ENV VERSION=${version}
RUN chmod +x /assets/build/*.sh && \
    /assets/build/prepare.sh && \
    /assets/build/utilities.sh && \
    /assets/build/install.sh && \
    /assets/build/cleanup.sh

#ENTRYPOINT ["entrypoint.sh"]
CMD ["/bin/bash"]