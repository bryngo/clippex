defmodule ClippexWeb.TwitchLive.Clips do
  use ClippexWeb, :live_view

  alias Clippex.Twitch

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Clippex.PubSub, "clips:stitch")
    end

    {:ok,
     assign(socket,
       clips: [],
       error: nil,
       loading: false,
       selected_clip: nil,
       username_value: "",
       stitched_url: nil,
       stitching: false
     )}
  end

  @impl true
  def handle_event("search", %{"username" => username}, socket) do
    if username == "" do
      {:noreply, put_flash(socket, :error, "Please enter a Twitch Username")}
    else
      socket =
        assign(socket, loading: true, error: nil, selected_clip: nil, username_value: username)

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
  def handle_event("stitch", %{"username" => username}, socket) do
    if username == "" do
      {:noreply, put_flash(socket, :error, "Please enter a Twitch Username")}
    else
      Phoenix.PubSub.broadcast(Clippex.PubSub, "clips:stitch", {:stitch, username})

      {:noreply,
       assign(socket, stitching: true) |> put_flash(:info, "Stitching started for #{username}...")}
    end
  end

  @impl true
  def handle_event("validate_search", %{"username" => username}, socket) do
    {:noreply, assign(socket, username_value: username)}
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
  def handle_info({:stitch_complete, _username, url}, socket) do
    {:noreply,
     assign(socket, stitching: false, stitched_url: url)
     |> put_flash(:info, "Stitching complete! Watch below.")}
  end

  def handle_info({:stitch_failed, _username, reason}, socket) do
    {:noreply,
     assign(socket, stitching: false)
     |> put_flash(:error, "Stitching failed: #{reason}")}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl">
      <h1 class="text-2xl font-bold mb-4">Twitch Clips</h1>

      <form phx-submit="search" phx-change="validate_search" class="mb-8 flex gap-4">
        <input
          type="text"
          name="username"
          value={@username_value}
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
        <button
          type="button"
          phx-click="stitch"
          phx-value-username={@username_value}
          class="rounded-md bg-green-600 px-4 py-2 text-white hover:bg-green-700"
        >
          Stitch Clips
        </button>
      </form>

      <%= if @stitching do %>
        <div class="mb-8 p-4 bg-blue-50 text-blue-700 rounded-md flex items-center gap-2">
          <svg
            class="animate-spin h-5 w-5 text-blue-700"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
          >
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
            </circle>
            <path
              class="opacity-75"
              fill="currentColor"
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
            >
            </path>
          </svg>
          Processing your video stitch... This may take a minute.
        </div>
      <% end %>

      <%= if @stitched_url do %>
        <div class="mb-8 p-6 bg-green-50 rounded-xl border border-green-100">
          <h2 class="text-xl font-bold text-green-900 mb-4">✨ Stitched Video Ready!</h2>
          <video controls class="w-full rounded-lg shadow-lg mb-4" src={@stitched_url}></video>
          <a
            href={@stitched_url}
            download
            class="inline-flex items-center px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
              class="w-5 h-5 mr-2"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3"
              />
            </svg>
            Download Video
          </a>
        </div>
      <% end %>

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
