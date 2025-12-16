# Verify Stitch Backend

alias Clippex.Workers.StitchWorker
require Logger

# Use a known user with clips (e.g. shroud or ninja)
username = "shroud"

IO.puts("Simulating stitch request for #{username}...")

# Subscribe to the topic to receive the result
Phoenix.PubSub.subscribe(Clippex.PubSub, "clips:stitch")

# Trigger the worker
send(StitchWorker, {:stitch, username})

# Wait for the result
receive do
  {:stitch_complete, ^username, url} ->
    IO.puts("\nSUCCESS: Stitch completed!")
    IO.puts("Generated URL: #{url}")

    # Verify file exists
    path = Path.join(:code.priv_dir(:clippex), "static#{url}")
    if File.exists?(path) do
      IO.puts("File Verified: #{path}")
      %{size: size} = File.stat!(path)
      IO.puts("File Size: #{size} bytes")
    else
      IO.puts("ERROR: File does not exist at #{path}")
    end

  {:stitch_failed, ^username, reason} ->
    IO.puts("\nFAILURE: Stitch failed - #{reason}")

after
  120_000 -> # Increased timeout for youtube-dl
    IO.puts("\nTIMEOUT: Worker took too long or failed silently.")
end
