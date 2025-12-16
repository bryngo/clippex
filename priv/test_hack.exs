# Test Download Hack
alias Clippex.Twitch
require Logger

{:ok, %{"id" => broadcaster_id}} = Twitch.get_user_by_login("shroud")
{:ok, [clip | _]} = Twitch.get_clips(broadcaster_id)
IO.inspect(clip, label: "Full Clip Object")

thumbnail = clip["thumbnail_url"]
IO.puts("Thumbnail: #{thumbnail}")

# Extract parts
regex = ~r/twitch-clips-thumbnails-prod\/(?<slug>[^\/]+)\/(?<media_id>[^\/]+)\/preview/
case Regex.named_captures(regex, thumbnail) do
  %{"slug" => slug, "media_id" => media_id} ->
    candidates = [
      "https://production.assets.clips.twitchcdn.net/#{media_id}.mp4",
      "https://production.assets.clips.twitchcdn.net/AT-cm%7C#{media_id}.mp4",
      "https://production.assets.clips.twitchcdn.net/#{slug}.mp4",
    ]

    Enum.each(candidates, fn url ->
      IO.write("Checking #{url}... ")
      case Req.head(url) do
        {:ok, %{status: 200}} -> IO.puts("FOUND! (200)")
        {:ok, %{status: s}} -> IO.puts("Status #{s}")
        {:error, _} -> IO.puts("Error")
      end
    end)
  _ ->
    IO.puts("Could not parse thumbnail structure.")
end
