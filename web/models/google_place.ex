defmodule GooglePlace do
  use HTTPoison.Base

  def process_url(url) do
    "https://maps.googleapis.com/maps/api/place" <> url
  end

  # def process_response_body(body) do
  #   body
  #   |> Poison.decode!
  # end
end
