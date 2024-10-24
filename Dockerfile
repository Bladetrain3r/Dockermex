FROM ubuntu:latest AS builder
WORKDIR /app
RUN apt update && apt install -y g++ cmake git libfltk1.3-dev libsdl2-dev libsdl2-mixer-dev libcurl4-openssl-dev libpng-dev libjsoncpp-dev zlib1g-dev libportmidi-dev libprotobuf-dev
RUN git clone https://github.com/odamex/odamex.git --recurse-submodules && mkdir build
WORKDIR /app/odamex/build
RUN cmake .. && make odasrv
# Runtime Stage

FROM ubuntu:latest AS server
WORKDIR /app
COPY --from=builder /app/odamex/build /app
# Provide your own WADS
COPY iwads /app/iwads
COPY pwads /app/pwads
COPY runserver.sh /app
USER ubuntu
# RUN mkdir /home/ubuntu/.odamex
# RUN cp odamex.wad /home/ubuntu/.odamex && cp DOOM2.WAD /home/ubuntu/.odamex
# ENTRYPOINT ["/bin/sh"]
ENTRYPOINT ["/usr/bin/bash", "/app/runserver.sh"]
# ENTRYPOINT ["/app/server/odasrv", "-iwad /app/DOOM2.WAD", "-file /app/odamex.wad", "-config /app/odamex.cfg", "-exec /app/odamex-server.cfg" ]
EXPOSE 10666/udp
