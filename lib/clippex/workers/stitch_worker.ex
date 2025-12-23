defmodule Clippex.Workers.StitchWorker do
  use GenServer
  require Logger
  alias Clippex.Twitch

  @topic "clips:stitch"

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    Phoenix.PubSub.subscribe(Clippex.PubSub, @topic)
    Logger.info("StitchWorker started and subscribed to #{@topic}")
    {:ok, nil}
  end

  @impl true
  def handle_info({:stitch, username}, state) do
    Logger.info("StitchWorker received request for user: #{username}")

    Task.start(fn -> process_stitch(username) end)

    {:noreply, state}
  end

  @impl true
  def handle_info({:stitch_complete, _username, _url}, state) do
    # Ignore our own broadcast
    {:noreply, state}
  end

  @impl true
  def handle_info({:stitch_failed, _username, _reason}, state) do
    # Ignore our own broadcast
    {:noreply, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.debug("StitchWorker received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  defp process_stitch(username) do
    case Twitch.get_clips_by_username(username) do
      {:ok, clips} ->
        # Take top 10 clips
        top_clips = Enum.take(clips, 10)
        Logger.info("Found #{length(top_clips)} clips for #{username}. Starting process...")

        # Create a unique directory for this job
        clips_output_dir =
          Path.join(:code.priv_dir(:clippex), "static/downloads/clips/#{username}")

        File.mkdir_p!(clips_output_dir)

        # Download clips
        clip_paths =
          top_clips
          |> Enum.with_index()
          |> Enum.map(fn {clip, index} ->
            download_clip(clip, clips_output_dir, index)
          end)
          |> Enum.filter(&(&1 != nil))

        if length(clip_paths) > 0 do
          # Stitch using ffmpeg
          output_filename = "stitched.mp4"

          stitched_output_dir =
            Path.join(:code.priv_dir(:clippex), "static/downloads/stitched/#{username}")

          File.mkdir_p!(stitched_output_dir)
          output_path = Path.join(stitched_output_dir, output_filename)

          # Construct inputs
          inputs =
            clip_paths
            |> Enum.flat_map(fn path -> ["-i", path] end)

          num_clips = length(clip_paths)

          filter_complex =
            0..(num_clips - 1)
            |> Enum.map(fn i -> "[#{i}:v][#{i}:a]" end)
            |> Enum.join("")
            |> Kernel.<>("concat=n=#{num_clips}:v=1:a=1[v][a]")

          # ffmpeg -i clip1 -i clip2 ... -filter_complex ... -map [v] -map [a] output.mp4
          args =
            inputs ++
              [
                "-filter_complex",
                filter_complex,
                "-map",
                "[v]",
                "-map",
                "[a]",
                "-c:v",
                "libx264",
                "-c:a",
                "aac",
                output_path
              ]

          case System.cmd("ffmpeg", args) do
            {_, 0} ->
              Logger.info("Stitching complete for #{username}")
              # URL relative to static
              public_url = "/downloads/stitched/#{username}/#{output_filename}"

              Phoenix.PubSub.broadcast(
                Clippex.PubSub,
                @topic,
                {:stitch_complete, username, public_url}
              )

            {output, code} ->
              Logger.error("FFmpeg failed with code #{code}: #{output}")

              Phoenix.PubSub.broadcast(
                Clippex.PubSub,
                @topic,
                {:stitch_failed, username, "Stitching process failed"}
              )
          end

          # Clean up
          File.rm_rf!(clips_output_dir)
        else
          Logger.error("No clips could be downloaded.")

          Phoenix.PubSub.broadcast(
            Clippex.PubSub,
            @topic,
            {:stitch_failed, username, "Could not download clips"}
          )
        end

      {:error, reason} ->
        Logger.error("Failed to fetch clips: #{inspect(reason)}")

        Phoenix.PubSub.broadcast(
          Clippex.PubSub,
          @topic,
          {:stitch_failed, username, "Failed to fetch clips"}
        )
    end
  end

  defp download_clip(%{"url" => clip_url, "id" => id} = _clip, output_dir, _index) do
    filename = "#{id}.mp4"
    path = Path.join(output_dir, filename)

    # Use yt-dlp to download
    # -f bestvideo+bestaudio/best: best quality merging video and audio if needed
    # --no-warnings: suppress warnings (like python version deprecation)
    # -o: output path
    # --no-playlist: ensure we only get the clip
    Logger.info("Downloading clip #{id} via yt-dlp...")

    case System.cmd(
           "yt-dlp",
           [
             "-f",
             "bestvideo+bestaudio/best",
             "--no-warnings",
             "--no-playlist",
             "-o",
             path,
             clip_url
           ],
           stderr_to_stdout: true
         ) do
      {_, 0} ->
        if File.exists?(path) do
          Logger.info("Downloaded #{id} to #{path}")
          path
        else
          Logger.error("yt-dlp reported success but file missing: #{path}")
          nil
        end

      {output, code} ->
        Logger.warning("yt-dlp failed for #{id} (code #{code}): #{output}")
        nil
    end
  end
end
