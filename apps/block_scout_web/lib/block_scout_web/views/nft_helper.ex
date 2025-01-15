defmodule BlockScoutWeb.NFTHelper do
  @moduledoc """
    Module with functions for NFT view
  """
  alias Explorer.Token.MetadataRetriever

  def get_media_src(nil, _), do: nil

  # credo:disable-for-next-line /Complexity/
  def get_media_src(metadata, high_quality_media?) do
    result =
      cond do
        metadata["animation_url"] && high_quality_media? ->
          retrieve_image(metadata["animation_url"])

        metadata["image_url"] ->
          retrieve_image(metadata["image_url"])

        metadata["image"] ->
          retrieve_image(metadata["image"])

        image = metadata["properties"]["image"] ->
          if is_map(image), do: image["description"], else: image

        true ->
          nil
      end

    if result && String.trim(result) == "", do: nil, else: result
  end

  def external_url(nil), do: nil

  def external_url(instance) do
    result =
      if instance.metadata && instance.metadata["external_url"] do
        instance.metadata["external_url"]
      else
        external_url(nil)
      end

    if !result || (result && String.trim(result)) == "", do: external_url(nil), else: result
  end

  def retrieve_image(image) when is_nil(image), do: nil

  def retrieve_image(image) when is_map(image) do
    image["description"]
  end

  def retrieve_image(image) when is_list(image) do
    image_url = image |> Enum.at(0)
    retrieve_image(image_url)
  end

  def retrieve_image(image_url) do
    image_url
    |> URI.decode()
    |> URI.encode()
    |> compose_ipfs_url()
  end

  def compose_ipfs_url(nil), do: nil

  def compose_ipfs_url(image_url) do
    image_url_downcase =
      image_url
      |> String.downcase()

    cond do
      image_url_downcase =~ ~r/^ipfs:\/\/ipfs/ ->
        # take resource id after "ipfs://ipfs/" prefix
        resource_id = image_url |> String.slice(12..-1//1)
        MetadataRetriever.ipfs_link(resource_id)

      image_url_downcase =~ ~r/^ipfs:\/\// ->
        # take resource id after "ipfs://" prefix
        resource_id = image_url |> String.slice(7..-1//1)
        MetadataRetriever.ipfs_link(resource_id)

      image_url_downcase =~ ~r/^ar:\/\// ->
        # take resource id after "ar://" prefix
        resource_id = image_url |> String.slice(5..-1//1)
        MetadataRetriever.arweave_link(resource_id)

      true ->
        image_url
    end
  end
end
