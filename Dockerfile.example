FROM alpine

USER root

# Enable HTTPS support in wget.
RUN apk add --update openssl ca-certificates && \
    rm -r /var/cache/apk/*

ARG NIX_VERSION="2.1.1"
ARG NIX_SHA256="ad10b4da69035a585fe89d7330037c4a5d867a372bb0e52a1542ab95aec67999"

# Set up user
ARG NB_USER
ARG NB_UID
ENV USER kernel
ENV HOME /home/kernel

RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid 1000 \
    kernel
WORKDIR /home/kernel

EXPOSE 8888

# Copy and chown stuff. This doubles the size of the repo, because
# you can't actually copy as USER, only as root! Thanks, Docker!
COPY default.nix /home/$USER
RUN mkdir -m 0755 /nix && \
    chown -R $USER:$USER /home/$USER && \
    chown -R $USER:$USER /nix

# convert command a b c -> nix-shell --command "command a b c"
# becuase nix-shell expects commands to be quoted
RUN printf "#!/bin/sh\necho \"\$*\"\nnix-shell default.nix --command \"\$*\"\n" > /usr/bin/nixshell && \
    chmod +x /usr/bin/nixshell

USER kernel

# Download Nix and install it into the system.
RUN wget https://nixos.org/releases/nix/nix-$NIX_VERSION/nix-$NIX_VERSION-x86_64-linux.tar.bz2 && \
    echo "$NIX_SHA256  nix-2.1.1-x86_64-linux.tar.bz2" | sha256sum -c && \
    tar xjf nix-*-x86_64-linux.tar.bz2 && \
    sh nix-*-x86_64-linux/install && \
    rm -r nix-*-x86_64-linux* && \
    echo ". /home/kernel/.nix-profile/etc/profile.d/nix.sh" > $HOME/.profile

ENV \
    NIX_PATH="nixpkgs=/home/kernel/.nix-defexpr/channels/nixpkgs" \
    PATH=/home/kernel/.nix-profile/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

RUN nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs && \
    nix-channel --update && \
    nix-shell default.nix --command "command -v jupyter"

ENTRYPOINT ["/usr/bin/nixshell"]
CMD ["jupyter", "notebook", "--ip", "0.0.0.0", "--port", "8888", "--NotebookApp.custom_display_url=http://localhost:8888"]
