FROM gitpod/workspace-full
RUN npm install -g serve
USER gitpod
ENV GIT_EDITOR=/usr/bin/vi
RUN bash -c ". /home/gitpod/.sdkman/bin/sdkman-init.sh \
             && sdk install java 15.0.2.7.1-amzn && sdk install gradle 6.8.3"
ENV TEST_HARI="hari"