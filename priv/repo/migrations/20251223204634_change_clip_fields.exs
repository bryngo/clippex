defmodule Clippex.Repo.Migrations.ChangeClipFields do
  use Ecto.Migration

  def change do
    alter table(:clips) do
      modify :video_id, :string, null: false
      modify :game_id, :string, null: false
    end
  end
end
