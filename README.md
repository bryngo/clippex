# Clippex

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

- Run `sudo service postgresql start` to start the postgresql service.

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

- To get the `TWITCH_ACCESS_TOKEN` value, you have to hit another API

```
curl --location 'https://id.twitch.tv/oauth2/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'client_id={{TWITCH_CLIENT_ID}}' \
--data-urlencode 'client_secret={{TWITCH_CLIENT_SECRET}}' \
--data-urlencode 'grant_type=client_credentials'
```

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
