defmodule Clippex.Repo.Migrations.CreateClips do
  use Ecto.Migration

  def change do
    create table(:clips) do
      add :clip_id, :string
      add :broadcaster_id, :string
      add :video_id, :integer
      add :game_id, :integer
      add :title, :string
      add :clip_created_at, :utc_datetime
      add :thumbnail_url, :string
      add :duration, :integer
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:clips, [:user_id])
  end
end
