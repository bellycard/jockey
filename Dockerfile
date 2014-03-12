FROM ruby:2.0.0-p598

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

# Install dependencies
ADD Gemfile /usr/src/app/
ADD Gemfile.lock /usr/src/app/
RUN bundle install

# TODO handle asset pre-compilation in build

ADD . /usr/src/app

EXPOSE 8888
CMD ["unicorn", "-c", "./config/unicorn.rb"]
