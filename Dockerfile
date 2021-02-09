FROM ruby:2.7
RUN apt-get update -qq && apt-get install -y gcc build-essential
WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN gem install bundler
RUN bundle install
COPY . /app

EXPOSE 3000
CMD ["bundle", "exec", "thin", "-R", "config.ru", "start"]
