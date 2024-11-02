FROM cm2network/steamcmd:root

# Install dependencies
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y \
    libtinfo5:i386 \
    libncurses5:i386 \
    libcurl3-gnutls:i386
USER steam

# Install TF2 server binary
WORKDIR ${STEAMCMDDIR}
RUN ./steamcmd.sh +force_install_dir ${HOMEDIR}/tf-dedicated +login anonymous +app_update 232250 +quit

# Symbolically link required library to server binaries (server won't start otherwise?)
RUN ln -s /usr/lib/amd64-linux-gnu/libcurl-gnutls.so.4 ${HOMEDIR}/tf-dedicated/bin/libcurl-gnutls.so.4

WORKDIR ${HOMEDIR}/tf-dedicated
