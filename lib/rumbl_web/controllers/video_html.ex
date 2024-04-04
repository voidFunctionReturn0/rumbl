defmodule RumblWeb.VideoHTML do
  use RumblWeb, :html

  embed_templates "video_html/*"

  @doc """
  Renders a video form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :categories, :list

  def video_form(assigns)

  def category_select_options(categories) do
    for category <- categories, do: {category.name, category.id}
  end

  def category_ids(categories) do
    for category <- categories, do: category.id
  end
end
