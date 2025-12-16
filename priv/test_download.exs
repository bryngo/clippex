# test_download.exs
alias Clippex.Twitch
require Logger

# 1. Get Shroud's ID
{:ok, %{"id" => broadcaster_id}} = Twitch.get_user_by_login("shroud")
IO.puts("Broadcaster ID: #{broadcaster_id}")

# 2. Get a clip
{:ok, [clip | _]} = Twitch.get_clips(broadcaster_id)
IO.puts("Clip ID: #{clip["id"]}")

# 3. New test: Try to call the new API with various param combos
config = Application.get_env(:clippex, :twitch)
client_id = config[:client_id]
access_token = config[:access_token]

IO.puts("Token: #{String.slice(access_token, 0, 5)}...")

req = Req.new(base_url: "https://api.twitch.tv/helix")
      |> Req.Request.put_header("Client-Id", client_id)
      |> Req.Request.put_header("Authorization", "Bearer #{access_token}")

# Helper to run test
run_test = fn label, p ->
  IO.puts("\n--- Test: #{label} ---")
  IO.inspect(p, label: "Params")
  case Req.get(req, url: "/clips/downloads", params: p) do
    {:ok, %{status: 200, body: body}} ->
      IO.puts("SUCCESS (200)")
      IO.inspect(body)
    {:ok, %{status: status, body: body}} ->
      IO.puts("FAILED (#{status})")
      IO.inspect(body)
    {:error, reason} ->
      IO.puts("ERROR: #{inspect(reason)}")
  end
end

# Test 1: As documented (id, broadcaster_id, editor_id)
# Note: documentation usually says "id" for clip ID.
run_test.("Standard params", [
  id: clip["id"],
  broadcaster_id: broadcaster_id
  # editor_id omitted (optional? or requires user context)
])

# Test 2: With editor_id (impersonating broadcaster)
run_test.("With editor_id", [
  id: clip["id"],
  broadcaster_id: broadcaster_id,
  editor_id: broadcaster_id
])

# Test 4: Using 'clip_id' + 'editor_id' (Testing hypothesis that id param maps poorly or is numeric-only legacy)
run_test.("With clip_id + editor_id", [
  clip_id: clip["id"],
  broadcaster_id: broadcaster_id,
  editor_id: broadcaster_id
])

IO.puts("\n--- Clip Object Inspection ---")
IO.inspect(clip)
