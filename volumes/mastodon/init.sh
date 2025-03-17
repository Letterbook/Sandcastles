#!/usr/bin/env bash

set -eux

INIT_FILE=/mastodon/public/system/.init_done

if [ -e $INIT_FILE ] && [ "${FORCE_INIT:-false}" != "true" ]; then
  exit 0
fi

# migrate the db
bundle exec rake db:migrate
sleep 1

# create the initial user account
tootctl accounts create "${MASTODON_ADMIN_ACCOUNT:=castle_mastodon}" \
  --email "${MASTODON_ADMIN_EMAIL:-castle@mastodon.castle}" \
  --confirmed \
  --role=Owner

tootctl accounts approve "${MASTODON_ADMIN_ACCOUNT}"

# set the user password to a known value
echo "user = User.find(1)
user.reset_password!
user.reset_password('${MASTODON_ADMIN_PASSWORD:-password}', '${MASTODON_ADMIN_PASSWORD:-password}')" | rails c

# mark initialization as complete, so it doesn't have to be repeated on the next startup
touch $INIT_FILE
