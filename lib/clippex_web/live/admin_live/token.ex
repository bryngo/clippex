defmodule ClippexWeb.AdminLive.Token do
  use ClippexWeb, :live_view

  alias Clippex.Twitch

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, token: nil, error: nil, loading: false)}
  end

  @impl true
  def handle_event("generate_token", _params, socket) do
    socket = assign(socket, loading: true, error: nil)

    case Twitch.get_app_access_token() do
      {:ok, token} ->
        {:noreply, assign(socket, token: token, loading: false)}

      {:error, :missing_credentials} ->
        {:noreply,
         assign(socket, loading: false, error: "Twitch Client Secret is not configured.")}

      {:error, _} ->
        {:noreply, assign(socket, loading: false, error: "Failed to generate token.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl">
      <h1 class="text-2xl font-bold mb-6">Admin: Generate Twitch Token</h1>

      <div class="bg-white shadow sm:rounded-lg p-6">
        <p class="text-gray-600 mb-4">
          Click the button below to generate a new App Access Token using the Client Credentials Flow.
        </p>

        <button
          phx-click="generate_token"
          class="rounded-md bg-indigo-600 px-4 py-2 text-white hover:bg-indigo-700 disabled:opacity-50 mb-6"
          disabled={@loading}
        >
          {if @loading, do: "Generating...", else: "Generate Token"}
        </button>

        <%= if @error do %>
          <div class="rounded-md bg-red-50 p-4 text-red-700 mb-4">
            {@error}
          </div>
        <% end %>

        <%= if @token do %>
          <div class="rounded-md bg-green-50 p-4">
            <h3 class="text-lg font-medium text-green-800 mb-2">Access Token Generated</h3>
            <div class="bg-gray-800 text-gray-100 p-3 rounded font-mono break-all">
              {@token}
            </div>
            <p class="text-sm text-green-700 mt-2">
              Copy this token and update your <code>TWITCH_ACCESS_TOKEN</code> environment variable.
            </p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
