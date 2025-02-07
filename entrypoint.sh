#!/usr/bin/env bash
########################################################################################################################
# Common helpers
########################################################################################################################
# Err on anything
set -e

helpers::avahi(){
  # On container restart, cleanup the crap
  rm -f /var/run/dbus.pid
  rm -f /run/avahi-daemon/pid

  # Not really useful, but then
  dbus-uuidgen --ensure

  # https://linux.die.net/man/1/dbus-daemon-1
  dbus-daemon --system

  until [ -e /var/run/dbus/system_bus_socket ]; do
    sleep 1s
  done

  # Set the hostname, if we have it
  sed -i'' -e "s,%AVAHI_NAME%,$AVAHI_NAME,g" /etc/avahi/avahi-daemon.conf

  # https://linux.die.net/man/8/avahi-daemon
  avahi-daemon --daemonize --no-chroot
}

########################################################################################################################
# Specific to this image
########################################################################################################################

# Constants definition
readonly HOME_ROOT=/media/home
readonly SHARE_ROOT=/media/share
readonly TIMEMACHINE_ROOT=/media/timemachine

# helper to create user accounts
helpers::createUser(){
  local login="$1"
  local password="$2"
  adduser --home "$HOME_ROOT/$login" --disabled-password --ingroup afp-share --gecos '' "$login"

  if [ "$password" ]; then
    printf "$login:$password" | chpasswd
  fi
}

# On first run
if [ ! -e ".first-run" ]; then

  echo "First run configuration"

  # Create a group
  echo "Group and permissions setup"
  groupadd afp-share

  [ -d "$HOME_ROOT" ]        || mkdir "$HOME_ROOT"
  [ -d "$SHARE_ROOT" ]       || mkdir "$SHARE_ROOT"
  [ -d "$TIMEMACHINE_ROOT" ] || mkdir "$TIMEMACHINE_ROOT"

  USERS=($USERS)
  PASSWORDS=($PASSWORDS)

  echo "Creating users"
  for ((index=0; index<${#USERS[@]}; index++)); do
    helpers::createUser "${USERS[$index]}" "${PASSWORDS[$index]}"
  done

  chown "${USERS[0]}:afp-share" "$SHARE_ROOT"
  chmod g+swrx "$SHARE_ROOT"
  chown "${USERS[0]}:afp-share" "$TIMEMACHINE_ROOT"
  chmod g+swrx "$TIMEMACHINE_ROOT"

  sed -i'' -e "s,%NAME%,$NAME,g" /etc/afp.conf

  sed -i'' -e "s,%HOME_ROOT%,$HOME_ROOT,g" /etc/afp.conf
  sed -i'' -e "s,%SHARE_ROOT%,$SHARE_ROOT,g" /etc/afp.conf
  sed -i'' -e "s,%TIMEMACHINE_ROOT%,$TIMEMACHINE_ROOT,g" /etc/afp.conf

  touch .first-run
  echo "Done with first run, all set"
fi

# If there is no AVAHI_NAME, use the AFP service name?
AVAHI_NAME=${AVAHI_NAME:-$NAME}

# Run with it
helpers::avahi
exec netatalk -d -F /etc/afp.conf "$@"
