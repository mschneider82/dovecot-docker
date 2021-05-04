FROM ubuntu:20.04

ENV VERSION=20.04 \
    DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/Berlin \
    OS=ubuntu \
    LANG=de_DE.utf8

RUN echo $TZ > /etc/timezone && \
    apt-get update && apt-get -y dist-upgrade && \
    apt-get install --no-install-recommends -y tzdata locales inetutils-ping netcat curl

RUN apt install -y --no-install-recommends vim curl  gpg gpg-agent apt-transport-https ca-certificates ssl-cert && \
    curl https://repo.dovecot.org/DOVECOT-REPO-GPG | gpg --import && \
    gpg --export ED409DA1 > /etc/apt/trusted.gpg.d/dovecot.gpg && \
    echo "deb https://repo.dovecot.org/ce-2.3-latest/ubuntu/focal focal main" > /etc/apt/sources.list.d/dovecot.list && \
    apt update && \
    apt install -y --no-install-recommends dovecot-core dovecot-imapd dovecot-lmtpd \
            dovecot-mysql dovecot-pop3d dovecot-sieve dovecot-sqlite dovecot-submissiond && \
    groupadd -g 5000 vmail && useradd -u 5000 -g 5000 vmail -d /home/vmail && passwd -l vmail && \
    rm -rf /etc/dovecot && mkdir /home/vmail && chown vmail:vmail /home/vmail && \
    make-ssl-cert generate-default-snakeoil && \
    mkdir /etc/dovecot && ln -s /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/dovecot/fullchain.pem && \
    ln -s /etc/ssl/private/ssl-cert-snakeoil.key /etc/dovecot/privkey.pem && \
    rm -rf /var/lib/apt/lists/*

RUN curl -L https://github.com/krallin/tini/releases/download/v0.19.0/tini-amd64 -o /tini
RUN chmod +x /tini

COPY dovecot.conf /etc/dovecot/
COPY dovecot-sql.conf.ext /etc/dovecot/
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh /usr/local/sbin/*


#12345 auth listener for postfix
#smtpd_sasl_path = inet:dovecot.example.com:12345
#smtpd_sasl_type = dovecot
EXPOSE 110 143 993 995 12345

HEALTHCHECK --interval=10s --timeout=5s --start-period=90s --retries=5 CMD doveadm service status 1>/dev/null && echo 'At your service, sir' || exit 1

# change this:
ENV SCHEMA=PLAIN
ENV DBHOST=localhost
ENV DBNAME=postfixadmin
ENV DBUSER=postfixadmin
ENV DBPASS=postfixadmin

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/tini", "--", "dovecot","-F"]
