FROM ruby:3.4.2-slim

RUN apt update -qq && apt install -y build-essential libpq-dev nodejs libyaml-dev

WORKDIR /app

COPY Gemfile Gemfile.lock .

RUN bundle config set without 'development test'

RUN bundle install --jobs `getconf _NPROCESSORS_ONLN` --retry 3

COPY entrypoint.sh /usr/bin/

RUN chmod +x /usr/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]

EXPOSE 3000

ENV RAILS_ENV=production

CMD ["rails", "server", "-b", "0.0.0.0"]