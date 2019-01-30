FROM hszhaox/alpine:3.8

ENV JAVA_VERSION_MAJOR=8 \
    JAVA_VERSION_MINOR=202 \
    JAVA_VERSION_BUILD=08 \
    JAVA_PACKAGE=server-jre \
    JAVA_JCE=unlimited \
    JAVA_HOME=/opt/jdk \
    PATH=${PATH}:/opt/jdk/bin \
    GLIBC_REPO=https://github.com/sgerrand/alpine-pkg-glibc \
    GLIBC_VERSION=2.28-r0 \
    LANG=en_US.UTF-8

RUN set -ex \
    && [[ ${JAVA_VERSION_MAJOR} != 7 ]] || ( echo >&2 'Oracle no longer publishes JAVA7 packages' && exit 1 ) \
    && apk -U upgrade \
    && apk --no-cache add libstdc++ curl ca-certificates bash java-cacerts \
    && for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION} glibc-i18n-${GLIBC_VERSION}; do curl -sSL ${GLIBC_REPO}/releases/download/${GLIBC_VERSION}/${pkg}.apk -o /tmp/${pkg}.apk; done \
    && apk add --allow-untrusted /tmp/*.apk \
    && rm -v /tmp/*.apk \
    # && (echo "en_US" | xargs -i /usr/glibc-compat/bin/localedef --force --inputfile {} --charmap UTF-8 {}.UTF-8) \
    && ( /usr/glibc-compat/bin/localedef --force --inputfile en_US --charmap UTF-8 en_US.UTF-8 || true ) \
    && echo "export LANG=${LANG}" > /etc/profile.d/locale.sh \
    && /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib \
    && mkdir /opt \
    && curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" -o /tmp/java.tar.gz \
      https://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/1961070e4c9b4e26a04e7f5a083f551e/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz \
    && JAVA_PACKAGE_SHA256=$(curl -sSL https://www.oracle.com/webfolder/s/digest/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}checksum.html | grep -E "${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64\.tar\.gz" | grep -Eo '(sha256: )[^<]+' | cut -d: -f2 | xargs) \
    && echo "${JAVA_PACKAGE_SHA256}  /tmp/java.tar.gz" > /tmp/java.tar.gz.sha256 \
    && sha256sum -c /tmp/java.tar.gz.sha256 \
    && gunzip /tmp/java.tar.gz \
    && tar -C /opt -xf /tmp/java.tar \
    && ln -s /opt/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} /opt/jdk \
    && find /opt/jdk/ -maxdepth 1 -mindepth 1 | grep -v jre | xargs rm -rf \
    && cd /opt/jdk/ && ln -s ./jre/bin ./bin \
    && if [ "${JAVA_JCE}" == "unlimited" ]; then echo "Installing Unlimited JCE policy" \
         && curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" -o /tmp/jce_policy-${JAVA_VERSION_MAJOR}.zip \
              http://download.oracle.com/otn-pub/java/jce/${JAVA_VERSION_MAJOR}/jce_policy-${JAVA_VERSION_MAJOR}.zip \
         && cd /tmp && unzip /tmp/jce_policy-${JAVA_VERSION_MAJOR}.zip \
         && cp -v /tmp/UnlimitedJCEPolicyJDK8/*.jar /opt/jdk/jre/lib/security/; \
       fi \
    && sed -i s/#networkaddress.cache.ttl=-1/networkaddress.cache.ttl=10/ $JAVA_HOME/jre/lib/security/java.security \
    && apk del curl glibc-i18n \
    && rm -rf /opt/jdk/jre/plugin \
           /opt/jdk/jre/bin/javaws \
           /opt/jdk/jre/bin/jjs \
           /opt/jdk/jre/bin/orbd \
           /opt/jdk/jre/bin/pack200 \
           /opt/jdk/jre/bin/policytool \
           /opt/jdk/jre/bin/rmid \
           /opt/jdk/jre/bin/rmiregistry \
           /opt/jdk/jre/bin/servertool \
           /opt/jdk/jre/bin/tnameserv \
           /opt/jdk/jre/bin/unpack200 \
           /opt/jdk/jre/lib/javaws.jar \
           /opt/jdk/jre/lib/deploy* \
           /opt/jdk/jre/lib/desktop \
           /opt/jdk/jre/lib/*javafx* \
           /opt/jdk/jre/lib/*jfx* \
           /opt/jdk/jre/lib/amd64/libdecora_sse.so \
           /opt/jdk/jre/lib/amd64/libprism_*.so \
           /opt/jdk/jre/lib/amd64/libfxplugins.so \
           /opt/jdk/jre/lib/amd64/libglass.so \
           /opt/jdk/jre/lib/amd64/libgstreamer-lite.so \
           /opt/jdk/jre/lib/amd64/libjavafx*.so \
           /opt/jdk/jre/lib/amd64/libjfx*.so \
           /opt/jdk/jre/lib/ext/jfxrt.jar \
           /opt/jdk/jre/lib/ext/nashorn.jar \
           /opt/jdk/jre/lib/oblique-fonts \
           /opt/jdk/jre/lib/plugin.jar \
           /tmp/* /var/cache/apk/* /var/tmp/* \
    && ln -sf /etc/ssl/certs/java/cacerts $JAVA_HOME/jre/lib/security/cacerts \
    && echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

# EOF