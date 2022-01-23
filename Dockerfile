FROM docker.io/library/ruby:3.1.0-alpine3.15 AS build

RUN bundle config --global frozen 1
RUN apk add --no-cache git ruby-dev make g++

WORKDIR /usr/src/app
COPY . .
RUN bundle install --binstubs=/usr/local/bundle/bin


# Runtime image
FROM docker.io/library/ruby:3.1.0-alpine3.15

RUN apk add --no-cache git openssh-client

WORKDIR /usr/src/app
COPY --from=build /usr/src/app .
COPY --from=build /usr/local/bundle /usr/local/bundle

ENTRYPOINT ["/usr/local/bin/bundle", "exec", "repupdate"]
