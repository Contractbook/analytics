# Analytics

Universal analytics client, currently only supports Mixpanel.

## Installation

The package can be installed by adding `analytics` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:analytics, "~> 0.5.0"}
  ]
end
```

And set your Mixpanel token in `config.ex`:
```
config :analytics, :mixpanel,
  token: "my_mixpanel_token"
```

The docs can be found at [https://hexdocs.pm/analytics](https://hexdocs.pm/analytics).

## License

See [LICENSE.md](LICENSE.md).
