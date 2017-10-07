.PHONY: release image publish

all: release image

release:
	cd assets/ && ./node_modules/brunch/bin/brunch build --production
	mix phx.digest
	MIX_ENV=prod mix do deps.get --only prod, compile
	MIX_ENV=prod mix release

image: release
	docker build -t surik/tube_streamer .

publish: image
	docker push surik/tube_streamer
