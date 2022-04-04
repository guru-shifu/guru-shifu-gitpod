FROM gitpod/workspace-full

RUN docker pull gradle:jdk15
RUN docker pull flyway/flyway
RUN docker pull mysql