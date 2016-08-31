defmodule HelloPhoenix.Repo.Migrations.AddPhotoToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :photo, :bytea
      add :photo_type, :string
    end
  end
end
