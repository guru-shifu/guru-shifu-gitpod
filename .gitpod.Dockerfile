FROM gitpod/workspace-full
RUN npm install -g serve
USER gitpod
RUN bash -c ". /home/gitpod/.sdkman/bin/sdkman-init.sh \
             && sdk install java && sdk install gradle"