FROM ubuntu:latest AS builder
WORKDIR /app
RUN apt update && apt install -y g++ cmake git libfltk1.3-dev libsdl2-dev libsdl2-mixer-dev libcurl4-openssl-dev libpng-dev libjsoncpp-dev zlib1g-dev libportmidi-dev libprotobuf-dev
RUN git clone https://github.com/odamex/odamex.git --recurse-submodules && mkdir build
WORKDIR /app/odamex/build
RUN cmake .. && make odasrv
# Runtime Stage

FROM ubuntu:latest AS server
WORKDIR /app
# For 
COPY --from=builder --chown=ubuntu /app/odamex/build /app
# Provide your own WADS

COPY --chown=ubuntu configs /app/config
COPY --chown=ubuntu iwads /app/iwads
COPY --chown=ubuntu pwads /app/pwads
COPY --chown=ubuntu runserver.sh /app
USER ubuntu
# ENTRYPOINT ["/bin/sh"]
ENTRYPOINT ["/usr/bin/bash", "/app/runserver.sh"]
EXPOSE 10666/udp
