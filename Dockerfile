# Odamex Build Stage

FROM ubuntu:latest AS builder-base
WORKDIR /app
RUN apt update && \
    apt install -y g++ \
    cmake \
    git \
    libfltk1.3-dev \
    libsdl2-dev \
    libsdl2-mixer-dev \
    libcurl4-openssl-dev \
    libpng-dev \
    libjsoncpp-dev \
    zlib1g-dev \
    libportmidi-dev \
    libprotobuf-dev
    
RUN git clone --depth 1 https://github.com/odamex/odamex.git --recurse-submodules

# FLTK workaround
WORKDIR /app/odamex/libraries
# RUN git clone https://github.com/fltk/fltk.git

FROM builder-base AS srv
WORKDIR /app/odamex/build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release && make odasrv

FROM builder-base AS wad
RUN apt update && apt install -y git make gcc autoconf autoconf-archive automake pkg-config
RUN git clone https://github.com/Doom-Utils/deutex /app/deutex
WORKDIR /app/deutex
RUN ./bootstrap && ./configure && make && make install
ENV DEUTEX=/usr/local/bin/deutex
WORKDIR /app/odamex/build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release && make odawad

# Runtime Stage

FROM ubuntu:latest AS server
# Use ARG for build-time port configuration with default value
ARG ODAPORT=10666
# Set ENV from ARG for runtime
ENV ODAPORT=${ODAPORT}
WORKDIR /app 
RUN useradd -m odamex && chown -R odamex:odamex /app
RUN apt update && apt install -y dos2unix
COPY --chown=odamex configs /app/config
COPY --chown=odamex iwads /app/iwads
COPY --chown=odamex pwads /app/pwads
COPY --chown=odamex shell/runserver.sh /app
COPY --from=srv --chown=odamex /app/odamex/build/server/odasrv /app/server/odasrv
COPY --from=WAD --chown=odamex /app/odamex/build/wad/odamex.wad /app/iwads
RUN dos2unix /app/runserver.sh
USER odamex
# ENTRYPOINT ["/bin/sh"]
ENTRYPOINT ["/usr/bin/bash", "/app/runserver.sh"]
EXPOSE ${ODAPORT}/udp
