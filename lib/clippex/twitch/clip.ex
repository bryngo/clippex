defmodule Clippex.Twitch.Clip do
  use Ecto.Schema
  import Ecto.Changeset
  require Logger

  schema "clips" do
    field :clip_id, :string
    field :broadcaster_id, :string
    field :video_id, :string
    field :game_id, :string
    field :title, :string
    field :clip_created_at, :utc_datetime
    field :thumbnail_url, :string
    field :duration, :integer
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(clip, attrs) do
    clip
    |> cast(attrs, [
      :clip_id,
      :broadcaster_id,
      :video_id,
      :game_id,
      :title,
      :clip_created_at,
      :thumbnail_url,
      :duration
    ])
    |> validate_required([
      :clip_id,
      :broadcaster_id,
      :video_id,
      :game_id,
      :title,
      :clip_created_at,
      :thumbnail_url,
      :duration
    ])
  end

  @doc false
  def save_new_clips(clips) do
    clip_ids = Enum.map(clips, & &1["id"])
    saved_clips = get_clips_by_clip_ids(clip_ids)
    saved_clip_ids = Enum.map(saved_clips, & &1.clip_id)

    clips_to_save = Enum.filter(clips, fn clip -> clip["id"] not in saved_clip_ids end)

    save_clips(clips_to_save)
  end

  @doc false
  def save_clips(clips) do
    Logger.info("Saving #{length(clips)} clips")

    Enum.map(clips, fn raw_clip ->
      attrs = map_raw_clip(raw_clip)

      %__MODULE__{}
      |> changeset(attrs)
      |> Clippex.Repo.insert()
      |> case do
        {:ok, _clip} ->
          :ok

        {:error, changeset} ->
          Logger.error("Failed to save clip #{raw_clip["id"]}: #{inspect(changeset.errors)}")
          {:error, changeset}
      end
    end)
  end

  def get_clips_by_clip_ids(clip_ids) do
    import Ecto.Query

    from(c in __MODULE__, where: c.clip_id in ^clip_ids)
    |> Clippex.Repo.all()
  end

  defp map_raw_clip(raw) do
    %{
      clip_id: raw["id"],
      broadcaster_id: raw["broadcaster_id"],
      video_id: raw["video_id"],
      game_id: raw["game_id"],
      title: raw["title"],
      clip_created_at: raw["created_at"],
      thumbnail_url: raw["thumbnail_url"],
      duration: round(raw["duration"] || 0)
    }
  end
end
