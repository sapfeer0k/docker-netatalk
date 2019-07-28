#######################
# Usual avahi/dbus image
#######################
FROM arm32v6/alpine
MAINTAINER sergei@lomakov.net

WORKDIR /dubo-dubon-duponey
RUN apk add --update dbus avahi bash shadow \
    && rm -rf /var/cache/apk/*
RUN mkdir -p /var/run/dbus
COPY avahi-daemon.conf /etc/avahi/avahi-daemon.conf
COPY afpd.service /etc/avahi/services/afpd.service
#######################
# Netatalk section
#######################
RUN apk add --update netatalk \
    && rm -rf /var/cache/apk/*

COPY afp.conf /etc/afp.conf
# XXX per-user connections require this?
RUN chmod a+r /etc/afp.conf

ENV USERS=""
ENV PASSWORDS=""
EXPOSE 548
VOLUME "/media/home"
VOLUME "/media/share"
VOLUME "/media/timemachine"

#######################
# Entrypoint
#######################
COPY entrypoint.sh .
ENTRYPOINT ["./entrypoint.sh"]
