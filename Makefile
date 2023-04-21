protobuf_generate:
	cp ../blinkenleds/schema.proto protobuf/
	protoc \
		-Iprotobuf \
		--elixir_out=./lib/pixel_generator/protobuf \
		--plugin=/Users/reimerei/.mix/escripts/protoc-gen-elixir \
		--elixir_opt=package_prefix=pixel_generator.protobuf \
		schema.proto

run:
	iex -S mix

