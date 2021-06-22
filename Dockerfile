FROM crystallang/crystal:1.0.0
WORKDIR /app
COPY shard.yml .
COPY shard.lock .
COPY src src
RUN shards build --production --release
CMD ["/app/bin/app"]
