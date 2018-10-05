# http-gate

Quite simple http port forwarder.

## Installation

Get x86_64 static binary from releases.

## Usage

For example, listen '0.0.0.0:8080' and forwards by those paths as follows.
```
0.0.0.0:8080
  /clickhouse/* => 127.0.0.1:8123/*
  /*            => 127.0.0.1:9001/*
```

- **config.toml**

```toml
[front]
host = "0.0.0.0"
port = 8080

[[back]]
path = "/clickhouse"
port = 8123
remove_path = true

[[back]]
path = "/"
port = 9001
```

```console
$ http-gate -c config.toml
I [08:42:33] Front Add [Back#0] '/clickhouse/'  => 127.0.0.1:8123
I [08:42:33] Front Add [Back#1] '/'             => 127.0.0.1:9001
I [08:42:33] Front Listening on http://0.0.0.0:8080
```

## Development

- needs crystal-0.26.1

```console
$ make
```

## Contributing

1. Fork it (<https://github.com/maiha/http-gate/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [maiha](https://github.com/maiha) maiha - creator, maintainer
