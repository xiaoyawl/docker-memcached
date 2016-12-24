FROM benyoo/alpine:3.4.20160812

MAINTAINER from www.dwhd.org by lookback (mondeolove@gmail.com)
ENV MEMCACHED_VERSION 1.4.33
ENV MEMCACHED_SHA1 e343530c55946ccbdd78c488355b02eaf90b3b46

RUN set -x && \
	LOCAL_MIRRORS=${LOCAL_MIRRORS:-http://mirrors.ds.com/alpine} && \
	NET_MIRRORS=${NET_MIRRORS:-http://dl-cdn.alpinelinux.org/alpine} && \
	LOCAL_MIRRORS_HTTP_CODE=$(curl -LI -m 10 -o /dev/null -sw %{http_code} ${LOCAL_MIRRORS}) && \
	if [ "${LOCAL_MIRRORS_HTTP_CODE}" == "200" ]; then \
		echo -e "${LOCAL_MIRRORS}/v3.4/main\n${LOCAL_MIRRORS}/v3.4/community" > /etc/apk/repositories; else \
		echo -e "${NET_MIRRORS}/v3.4/main\n${NET_MIRRORS}/v3.4/community" > /etc/apk/repositories; fi && \
	addgroup -g 490 -S memcache && \
	adduser -S -H -u 490 -G memcache memcache && \
	apk --update --no-cache upgrade && \
	apk add --no-cache --virtual .build-deps \
		gcc libc-dev libevent-dev linux-headers make perl tar && \
	mkdir -p /usr/src/memcached && \
	curl -Lk "http://memcached.org/files/memcached-$MEMCACHED_VERSION.tar.gz" | tar xz -C /usr/src/memcached --strip-components=1 && \
	cd /usr/src/memcached && \
	./configure && \
	make -j$(getconf _NPROCESSORS_ONLN) && \
	make install && \
	cd / && rm -rf /usr/src/memcached && \
	runDeps="$( \
		scanelf --needed --nobanner --recursive /usr/local \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| sort -u \
			| xargs -r apk info --installed \
			| sort -u \
	)" && \
	apk add --virtual .memcached-rundeps $runDeps && \
	apk del .build-deps

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

USER memcache
EXPOSE 11211
CMD ["memcached"]
