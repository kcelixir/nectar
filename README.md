# Nectar

> An HTTP server for Elixir.

Nectar is a simple HTTP server implemented in Elixir. It is intended to be a replacement for [Cowboy](https://github.com/ninenines/cowboy).

## Getting Started

### Prerequisites

What things you need to install the software and how to install them

* [Erlang](https://www.erlang.org/) 20.2.3 or later
* [Elixir](https://elixir-lang.org/) 1.6.1 or later

### Installation

The easiest way to add Nectar to your project is by [using Mix](http://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html).

Add `:nectar` as a dependency to `mix.exs`:

```elixir
defp deps do
  [
    {:nectar, "~> 0.1.0"}
  ]
end
```

Then run:

```shell
$ mix deps.get
```

### Running

```shell
$ mix nectar.server
```

## Contributing

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/nectar](https://hexdocs.pm/nectar).

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/kcelixir/nectar/tags).

## Authors

* [Craig S. Cottingham](https://github.com/CraigCottingham)
* [Jeffery Utter](https://github.com/jeffutter)
* [Johnny 5](https://github.com/djgoku)

## License

This project is licensed under the Apache 2.0 License. See [LICENSE.md](LICENSE.md) file for details.

## Acknowledgments

CSC: A big "thank you" to everyone in the [KC Elixir Users Group Slack](https://kcelixir.slack.com) who didn't look at me crazy when I suggested this project. (If you did, but kept it to yourself, that still counts. 😀)

If you're not already a member of the KC Elixir Users Group Slack, please feel free to [join us](http://kcelixir-slack.herokuapp.com/)!
