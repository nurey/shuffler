defmodule Mix.Tasks.AddPhotoToItems do
  use Mix.Task
  import Mix.Ecto

  @shortdoc "Adds a photo to each Item"

  @moduledoc """
    This is where we would put any long form documentation or doctests.
  """

  @google_api_key System.get_env("GOOGLE_PLACES_API_KEY")

  @params [
    {"key", @google_api_key},
    {"location", "43.6537704,-79.36694419999999"},
    {"type", "food"},
    {"radius", "500"}
  ]

  alias HelloPhoenix.Item

  def run(args) do
    Mix.Task.run "app.start", []

    repos = parse_repo(args)
    Enum.each repos, fn repo ->
      ensure_repo(repo, args)
      ensure_started(repo, args)

      items = repo.all(Item)
      photos = Enum.map(items, &lookup_google_place/1)
        |> Enum.map(&lookup_photo/1)
        |> Enum.map(&download_photo/1)

      # isolate the side effects around the Enum.each
      # Enum.each should be one line!
      # replace debugging (Mix.shell.info) with tests. Inline tests.
      # look into Elixir Awesome for Macros, to handle pipelines for tuples
      Enum.zip(items, photos)
        |> Enum.map(fn({item, {photo, content_type}}) ->
          Mix.shell.info("content_type is #{content_type}")
          Item.changeset(item, %{photo: photo, photo_type: content_type})
        end)
        |> Enum.each(fn(changeset) ->
          case repo.update(changeset) do
            {:ok, _item} ->
              Mix.shell.info("Item updated successfully.")
            {:error, _changeset} ->
              Mix.shell.info("Item update failed.")
          end
        end)
    end
  end

  def lookup_google_place(item) do
    params = @params ++ [{"name", item.name}]
    Mix.shell.info(inspect params)
    photos = GooglePlace.get!("/nearbysearch/json", [], params: params).body
      |> Poison.decode!
      |> Map.take(["results"])
      |> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
      |> Keyword.get(:results)
      |> List.first
      |> Map.get("photos")

    if photos do
      photos
        |> List.first
        |> Map.take(["photo_reference", "height"])
        |> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
    else
      [height: nil, photo_reference: nil]
    end
  end

  def lookup_photo([height: height, photo_reference: photo_reference]) when height == nil or photo_reference == nil do
    nil
  end

  def lookup_photo([height: height, photo_reference: photo_reference]) do
    params = [
      {"key", @google_api_key},
      {"photoreference", photo_reference},
      {"maxheight", height}
    ]

    case GooglePlace.get("/photo", [], [params: params]) do
      {:ok, %HTTPoison.Response{body: body, headers: headers}} ->
        Mix.shell.info(inspect headers)
        headers
          |> Enum.find(fn(header_tuple) -> elem(header_tuple, 0) == "Location" end)
          |> elem(1)
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        nil
      {:error, %HTTPoison.Error{reason: _reason}} ->
        nil
    end
  end

  def download_photo(url) when url == nil do
    {nil, nil}
  end

  def download_photo(url) do
    # HTTPoison has trouble with certain https urls.
    # See https://github.com/edgurgel/httpoison/issues/160
    insecure_url = Regex.replace(~r/^https/, url, "http")
    case HTTPoison.get(insecure_url, []) do
      {:ok, %HTTPoison.Response{body: body, headers: headers}} ->
        Mix.shell.info(inspect headers)
        content_type = headers
          |> Enum.find(fn(header_tuple) -> elem(header_tuple, 0) == "Content-Type" end)
          |> elem(1)
        {body, content_type}
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {nil, nil}
      {:error, %HTTPoison.Error{reason: reason}} ->
        Mix.shell.info(reason)
        {nil, nil}
    end
  end
end
