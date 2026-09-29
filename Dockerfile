FROM ubuntu:22.04 AS base

ARG DEBIAN_FRONTEND=noninteractive
ARG NODE_VERSION=22.11.0

ENV TZ=Etc/UTC

# Install required packages and dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    expect \
    git \
    unzip \
    wget \
    xz-utils \
    default-jre \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js (Angular 19 needs >= 20.11 / 22)
RUN wget -nv -O /tmp/node.tar.xz "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
    && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
    && rm /tmp/node.tar.xz

# Create a non-root user and set up the working directory
RUN useradd -m -s /bin/bash mario
USER mario
WORKDIR /home/mario

# Install Tizen Studio CLI and configure the toolchain path
RUN wget -nv -O web-cli_Tizen_Studio_6.1_ubuntu-64.bin 'https://download.tizen.org/sdk/Installer/tizen-studio_6.1/web-cli_Tizen_Studio_6.1_ubuntu-64.bin'
RUN chmod a+x web-cli_Tizen_Studio_6.1_ubuntu-64.bin
RUN ./web-cli_Tizen_Studio_6.1_ubuntu-64.bin --accept-license --no-java-check /home/mario/tizen-studio

ENV PATH=/home/mario/tizen-studio/tools/ide/bin:/home/mario/tizen-studio/tools:${PATH}

# Prepare the Tizen certificate and security profiles for signing the application package
RUN tizen certificate \
    -a mario \
    -f mario \
    -p 1234

RUN tizen security-profiles add \
    -n mario \
    -a /home/mario/tizen-studio-data/keystore/author/mario.p12 \
    -p 1234

# Workaround to package applications without gnome-keyring
RUN sed -i 's|/home/mario/tizen-studio-data/keystore/author/mario.pwd||' /home/mario/tizen-studio-data/profile/profiles.xml
RUN sed -i 's|/home/mario/tizen-studio-data/tools/certificate-generator/certificates/distributor/tizen-distributor-signer.pwd|tizenpkcs12passfordsigner|' /home/mario/tizen-studio-data/profile/profiles.xml

# Install npm dependencies first (layer cache)
# NOTE: build this Dockerfile from the root of your local mario checkout
WORKDIR /home/mario/mario
COPY --chown=mario package.json package-lock.json ./
RUN npm ci

# Copy the rest of the source and build the Angular app.
# --base-href ./ is required because the widget is served from the local file system.
COPY --chown=mario . .
RUN npx ng build --configuration production --base-href ./

# ngMario ships no Tizen widget wrapper; config.xml and icon.png live in res/
# Angular's output dir (dist/<project>/browser) is detected via its index.html
WORKDIR /home/mario
RUN mkdir -p widget \
    && OUT="$(dirname "$(find mario/dist -name index.html | head -1)")" \
    && echo "Angular output: $OUT" \
    && cp -r "$OUT"/. widget/
RUN cp mario/res/config.xml widget/config.xml
RUN cp mario/res/icon.png widget/icon.png

# Sign and package the application into a WGT file
RUN echo \
    'set timeout -1\n' \
    'spawn tizen package -t wgt -- widget\n' \
    'expect "Author password:"\n' \
    'send -- "1234\\r"\n' \
    'expect "Yes: (Y), No: (N) ?"\n' \
    'send -- "N\\r"\n' \
    'expect eof\n' \
    | expect

RUN mv widget/NgMario.wgt .

# Clean up unnecessary files to reduce image size
RUN rm -rf \
    widget \
    mario \
    web-cli_Tizen_Studio_6.1_ubuntu-64.bin \
    tizen-package-expect.sh \
    .package-manager \
    .npm \
    .wget-hsts

# Use a multi-stage build to reclaim space from deleted files
FROM ubuntu:22.04

COPY --from=base /home/mario/NgMario.wgt /home/mario/NgMario.wgt
COPY --from=base /home/mario/tizen-studio /home/mario/tizen-studio
COPY --from=base /home/mario/tizen-studio-data /home/mario/tizen-studio-data

RUN useradd -m -s /bin/bash mario
RUN chown -R mario:mario /home/mario
USER mario
WORKDIR /home/mario

# Add Tizen Studio tools to PATH environment variable
ENV PATH=/home/mario/tizen-studio/tools/ide/bin:/home/mario/tizen-studio/tools:${PATH}