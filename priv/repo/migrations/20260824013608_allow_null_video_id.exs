defmodule Clippex.Repo.Migrations.AllowNullVideoId do
  use Ecto.Migration

  def change do
    alter table(:clips) do
      modify :video_id, :string, null: true
    end
  end
end
