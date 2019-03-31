FROM alpine:latest as build

LABEL description="Build container - libcoap"

RUN apk update && apk add --no-cache \
    autoconf automake build-base binutils gcc g++ git libtool make openssl-dev openssl pkgconfig

RUN cd /tmp \
    && git clone https://github.com/obgm/libcoap.git \
    && cd libcoap \
    && ./autogen.sh \
    && ./configure --with-openssl --disable-tests --enable-shared --disable-documentation \
    && make \
    && make install

FROM alpine:latest as runtime

LABEL description="Run container - libcoap minimal server"

RUN apk update && apk add --no-cache \
    build-base pkgconfig

COPY [ "common.cc", "common.hh", "Makefile", "server.cc", "/tmp/" ] 

COPY --from=build /usr/local/include/coap2/* /usr/local/include/coap2/
COPY --from=build /usr/local/lib/* /usr/local/lib/
COPY --from=build [ "/usr/local/bin/coap-client", "/usr/local/bin/coap-server", "/bin/" ]
COPY --from=build /usr/local/lib/pkgconfig/* /usr/local/lib/pkgconfig/

RUN cd /tmp \
    && make server \
    && cp ./server /bin/

EXPOSE 5683/udp

CMD  [ "server", "&" ]