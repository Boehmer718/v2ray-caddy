FROM caddy:2-alpine

LABEL org.opencontainers.image.authors="admin@gmail.com"

ARG V2R_VERSION=v5.29.2
ARG DOMAIN
ARG EMAIL
ARG TARGETARCH

ENV TZ=Asia/Shanghai
ENV DOMAIN=${DOMAIN}
ENV EMAIL=${EMAIL}
ENV V2R_PATH_CONF=/etc/v2ray
ENV CADDY_PATH_CONF=/etc/caddy

ADD boot.sh /usr/bin

COPY conf/ /conf/
COPY html/ /var/www/v2ray/ 

RUN set -xe \
    && apk -U upgrade \
    && apk add --update --no-cache --virtual .build-deps \
    tzdata \
    curl \
    && mkdir -p \
    ${CADDY_PATH_CONF} \
    ${V2R_PATH_CONF} \
    /app \
    && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
    # 根据目标架构选择正确的下载URL
    && if [ "$TARGETARCH" = "arm64" ]; then \
         export V2R_URL=https://github.com/v2fly/v2ray-core/releases/download/${V2R_VERSION}/v2ray-linux-arm64-v8a.zip; \
       elif [ "$TARGETARCH" = "arm" ]; then \
         export V2R_URL=https://github.com/v2fly/v2ray-core/releases/download/${V2R_VERSION}/v2ray-linux-arm32-v7a.zip; \
       else \
         export V2R_URL=https://github.com/v2fly/v2ray-core/releases/download/${V2R_VERSION}/v2ray-linux-64.zip; \
       fi \
    && echo "Downloading from: $V2R_URL" \
    && curl -L -H "Cache-Control: no-cache" -o /tmp/v2ray.zip ${V2R_URL} \
    && unzip /tmp/v2ray.zip -d /tmp/v2ray \
    && mv /tmp/v2ray /app \
    && ln -s /app/v2ray/v2ray /usr/bin/v2ray \
    && chmod +x /app/v2ray/v2ray \
    && chmod +x /usr/bin/boot.sh \
    # 删除不必要的东西
    && apk del .build-deps \
    && rm -rf /tmp/* \
    && rm /etc/caddy/Caddyfile \
    && apk add uuidgen openrc

EXPOSE 80 443

ENTRYPOINT ["/usr/bin/boot.sh"]
