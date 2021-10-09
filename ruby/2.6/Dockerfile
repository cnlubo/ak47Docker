############################################
# version : cnlubo/ruby2.6
############################################
FROM cnlubo/basedeb:v1.0
LABEL maintainer="bolu20080314@gmail.com" \
    provider="cnak47"

# install things globally, for great justice
# and don't create ".bundle" in all our apps
ENV GEM_HOME /usr/local/bundle

ENV BUNDLE_PATH="$GEM_HOME" \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    BUNDLE_APP_CONFIG="$GEM_HOME"
# path recommendation:
# https://github.com/bundler/bundler/pull/6469#issuecomment-383235438
ENV PATH $GEM_HOME/bin:$BUNDLE_PATH/gems/bin:$PATH

COPY build /build

RUN chmod +x /build/*.sh && \
    /build/prepare.sh && \
    /build/install.sh && \
    /build/cleanup.sh

ENTRYPOINT ["entrypoint.sh"]
CMD ["/usr/local/bin/zsh"]
