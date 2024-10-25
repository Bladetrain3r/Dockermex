# Odamex Build Stage

FROM ubuntu:latest AS builder-base
WORKDIR /app
RUN apt update && apt install -y g++ cmake git libfltk1.3-dev libsdl2-dev libsdl2-mixer-dev libcurl4-openssl-dev libpng-dev libjsoncpp-dev zlib1g-dev libportmidi-dev libprotobuf-dev
RUN git clone https://github.com/odamex/odamex.git --recurse-submodules

FROM builder-base AS srv
WORKDIR /app/odamex/build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release && make odasrv

FROM builder-base AS wad
RUN apt update && apt install -y git make gcc autoconf autoconf-archive automake pkg-config
RUN git clone https://github.com/Doom-Utils/deutex
WORKDIR /app/deutex
RUN ./bootstrap && ./configure && make && make install
ENV DEUTEX=/usr/local/bin/deutex
WORKDIR /app/odamex/build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release && make odawad

# Runtime Stage

FROM ubuntu:latest AS server
WORKDIR /app 
COPY --from=srv --chown=ubuntu /app/odamex/build/server/odasrv /app/server/odasrv
COPY --from=WAD --chown=ubuntu /app/odamex/build/wad/odamex.wad /app
COPY --chown=ubuntu configs /app/config
COPY --chown=ubuntu iwads /app/iwads
COPY --chown=ubuntu pwads /app/pwads
COPY --chown=ubuntu runserver.sh /app
USER ubuntu
# ENTRYPOINT ["/bin/sh"]
ENTRYPOINT ["/usr/bin/bash", "/app/runserver.sh"]
EXPOSE 10666/udp
