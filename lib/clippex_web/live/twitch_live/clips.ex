defmodule ClippexWeb.TwitchLive.Clips do
  use ClippexWeb, :live_view

  alias Clippex.Twitch

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, clips: [], error: nil, loading: false, selected_clip: nil)}
  end

  @impl true
  def handle_event("search", %{"username" => username}, socket) do
    if username == "" do
      {:noreply, put_flash(socket, :error, "Please enter a Twitch Username")}
    else
      socket = assign(socket, loading: true, error: nil, selected_clip: nil)

      case Twitch.get_clips_by_username(username) do
        {:ok, clips} ->
          {:noreply, assign(socket, clips: clips, loading: false)}

        {:error, :not_found} ->
          {:noreply, assign(socket, loading: false, error: "User not found.")}

        {:error, :missing_credentials} ->
          {:noreply,
           assign(socket, loading: false, error: "Twitch credentials are not configured.")}

        {:error, _} ->
          {:noreply,
           assign(socket,
             loading: false,
             error: "Failed to fetch clips. Please check the ID and try again."
           )}
      end
    end
  end

  @impl true
  def handle_event("play", %{"url" => embed_url}, socket) do
    # Add parent=localhost to satisfy Twitch embed policy
    embed_url = "#{embed_url}&parent=localhost"
    {:noreply, assign(socket, selected_clip: embed_url)}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, assign(socket, selected_clip: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl">
      <h1 class="text-2xl font-bold mb-4">Twitch Clips</h1>

      <form phx-submit="search" class="mb-8 flex gap-4">
        <input
          type="text"
          name="username"
          placeholder="Enter Twitch Username (e.g. ninja)"
          class="flex-1 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
        />
        <button
          type="submit"
          class="rounded-md bg-indigo-600 px-4 py-2 text-white hover:bg-indigo-700 disabled:opacity-50"
          disabled={@loading}
        >
          {if @loading, do: "Loading...", else: "Get Clips"}
        </button>
      </form>

      <%= if @error do %>
        <div class="mb-4 rounded-md bg-red-50 p-4 text-red-700">
          {@error}
        </div>
      <% end %>

      <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
        <%= for clip <- @clips do %>
          <div
            class="overflow-hidden rounded-lg border shadow-sm cursor-pointer hover:shadow-md transition-shadow"
            phx-click="play"
            phx-value-url={clip["embed_url"]}
          >
            <div class="relative">
              <img
                src={clip["thumbnail_url"]}
                alt={clip["title"]}
                class="w-full object-cover aspect-video"
              />
              <div class="absolute inset-0 flex items-center justify-center bg-black/0 hover:bg-black/20 transition-all">
                <div class="bg-white bg-opacity-80 rounded-full p-2">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    class="w-8 h-8 text-indigo-600"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M4.5 5.653c0-1.426 1.529-2.33 2.779-1.643l11.54 6.348c1.295.712 1.295 2.573 0 3.285L7.28 19.991c-1.25.687-2.779-.217-2.779-1.643V5.653z"
                      clip-rule="evenodd"
                    />
                  </svg>
                </div>
              </div>
            </div>
            <div class="p-4">
              <h3 class="mb-1 font-semibold truncate" title={clip["title"]}>{clip["title"]}</h3>
              <p class="text-sm text-gray-500">
                {clip["broadcaster_name"]} • {clip["view_count"]} views
              </p>
              <p class="text-xs text-gray-400 mt-2">
                {Calendar.strftime(NaiveDateTime.from_iso8601!(clip["created_at"]), "%Y-%m-%d")}
              </p>
            </div>
          </div>
        <% end %>
      </div>

      <%= if @selected_clip do %>
        <div
          class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-75 p-4"
          phx-click="close_modal"
          phx-window-keydown="close_modal"
          phx-key="escape"
        >
          <div
            class="relative w-full max-w-4xl bg-black rounded-lg overflow-hidden shadow-xl aspect-video"
            phx-click-away="close_modal"
          >
            <button
              class="absolute top-2 right-2 text-white hover:text-gray-300 z-10"
              phx-click="close_modal"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                class="w-8 h-8"
              >
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
            <iframe
              src={@selected_clip}
              height="100%"
              width="100%"
              allowfullscreen
            >
            </iframe>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
