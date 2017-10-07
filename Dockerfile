FROM        bitwalker/alpine-erlang:20.1


RUN         apk update && \
            apk add ca-certificates wget python bash && \
            update-ca-certificates && \
            wget https://yt-dl.org/downloads/latest/youtube-dl -O /usr/local/bin/youtube-dl && \
            chmod a+rx /usr/local/bin/youtube-dl

ENV         PORT=4000 \
            REPLACE_OS_VARS=true \
            SECRET_KEY_BASE="some_secret_key_base" \
            INFLUXDB_USERNAME="root" \
            INFLUXDB_PASSWORD="root_password" 

EXPOSE      4000
WORKDIR     /opt/tube_streamer

ENTRYPOINT  ./bin/tube_streamer foreground

ADD         "_build/prod/rel/tube_streamer/releases/*/tube_streamer.tar.gz" \
            "/opt/tube_streamer/"
