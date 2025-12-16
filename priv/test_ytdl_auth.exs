# Test youtube-dl with headers
alias Clippex.Twitch
require Logger

# 1. Get Config
config = Application.get_env(:clippex, :twitch)
client_id = config[:client_id]
access_token = config[:access_token]

# 2. Get a clip URL to test
{:ok, %{"id" => broadcaster_id}} = Twitch.get_user_by_login("shroud")
{:ok, [clip | _]} = Twitch.get_clips(broadcaster_id)
url = clip["url"]

IO.puts("Testing download for: #{url}")
IO.puts("Client-ID: #{client_id}")

# 3. Try youtube-dl with headers
args = [
  "--no-playlist",
  "--add-header", "Client-ID: #{client_id}",
  "--add-header", "Authorization: Bearer #{access_token}",
  url
]

IO.puts("Running youtube-dl with headers...")
case System.cmd("youtube-dl", args) do
  {output, 0} -> IO.puts("SUCCESS:\n#{output}")
  {output, code} -> IO.puts("FAILED (Code #{code}):\n#{output}")
end
