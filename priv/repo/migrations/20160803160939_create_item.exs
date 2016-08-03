defmodule HelloPhoenix.Repo.Migrations.CreateItem do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :name, :string

      timestamps()
    end

  end
end
