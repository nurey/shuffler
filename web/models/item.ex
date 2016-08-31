defmodule HelloPhoenix.Item do
  use HelloPhoenix.Web, :model

  schema "items" do
    field :name, :string
    field :photo, :binary
    field :photo_type, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :photo, :photo_type])
    |> validate_required([:name])
  end
end
