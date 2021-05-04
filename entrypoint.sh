#!/bin/bash

set -e

DEBUG="${DEBUG:-}"
[ "$DEBUG" == 'true' ] && set -x

LOGDIR="/var/log"
[ ! -d "${LOGDIR}" ] && mkdir -p $LOGDIR
LOGFILE="${LOGDIR}/dovecot.log"
if [ ! -f $LOGFILE ]; then
  touch $LOGFILE
fi
chmod 666 $LOGFILE

if [ ! -f /etc/dovecot/fullchain.pem ]; then
  cp /etc/ssl/dovecot/server.pem /etc/dovecot/fullchain.pem
  cp /etc/ssl/dovecot/server.key /etc/dovecot/privkey.pem 
fi

COMMONDIR="/etc/dovecot"
if [ ! -f "${COMMONDIR}/dh-dovecot.pem" ]; then
  openssl dhparam 2048 > "${COMMONDIR}/dh-dovecot.pem"
fi


sed -i "s/PASSWDCHANGEME/$DBPASS/g" $COMMONDIR/dovecot-sql.conf.ext
sed -i "s/SCHEMACHANGEME/$SCHEMA/g" $COMMONDIR/dovecot-sql.conf.ext
sed -i "s/DBCHANGEME/$DBNAME/g" $COMMONDIR/dovecot-sql.conf.ext
sed -i "s/USERCHANGEME/$DBUSER/g" $COMMONDIR/dovecot-sql.conf.ext
sed -i "s/HOSTCHANGEME/$DBHOST/g" $COMMONDIR/dovecot-sql.conf.ext

exec tail -f "$LOGFILE" &
exec "$@"
