#!/usr/bin/env bash

set -eux

INIT_FILE=/mastodon/public/system/.init_done

if [ -e $INIT_FILE ] && [ "${FORCE_INIT:-false}" != "true" ]; then
  exit 0
fi

bundle exec rake db:migrate

sleep 1

#echo "user = User.new(email: '${MASTODON_ADMIN_EMAIL:-admin@"$LOCAL_DOMAIN"}', password: '${MASTODON_ADMIN_PASSWORD:-password}', confirmed_at: Time.now.utc, bypass_invite_request_check: true)
#user.save(validate: false)
#user.approve!
#user.reset_password!
#user.reset_password('${MASTODON_ADMIN_PASSWORD:-password}', '${MASTODON_ADMIN_PASSWORD:-password}')" | rails c

tootctl accounts create "${MASTODON_ADMIN_ACCOUNT:-castle_mastodon}" \
  --email "${MASTODON_ADMIN_EMAIL:-admin@$HOSTNAME}" \
  --confirmed \
  --role=Owner \
#tootctl accounts modify "${MASTODON_ADMIN_ACCOUNT:-admin}" \
#  --role Owner

#echo "user = User.find(1)
#user.reset_password!
#user.reset_password('${MASTODON_ADMIN_PASSWORD:-password}', '${MASTODON_ADMIN_PASSWORD:-password}')" | rails c
  
#tootctl accounts create hippo --email hippo@mastodon.castle --confirmed 
#tootctl accounts approve hippo
      
#echo "insert into oauth_access_tokens (token, scopes, resource_owner_id, created_at) values ('token', 'read write follow', 1, current_timestamp);" \
#  | PGPASSWORD="$DB_PASS" psql  --host="$DB_HOST" --user "$DB_USER"

touch $INIT_FILE
