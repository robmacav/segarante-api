#!/bin/bash
set -e

rm -f /app/tmp/pids/server.pid

bundle exec rails db:create db:migrate

exec "$@"