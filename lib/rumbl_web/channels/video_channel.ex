defmodule RumblWeb.VideoChannel do
  use RumblWeb, :channel
  alias Rumbl.{
    Accounts,
    Multimedia
  }
  alias RumblWeb.AnnotationJSON

  @impl true
  # def join("video:lobby", payload, socket) do
  #   if authorized?(payload) do
  #     {:ok, socket}
  #   else
  #     {:error, %{reason: "unauthorized"}}
  #   end
  # end
  def join("videos:" <> video_id, params, socket) do
    send(self(), :after_join)
    last_seen_id = params["last_seen_id"] || 0
    video_id = String.to_integer(video_id)
    video = Multimedia.get_video!(video_id)
    annotations =
      video
      |> Multimedia.list_annotations(last_seen_id)
      |> AnnotationJSON.annotations()

    {:ok, %{annotations: annotations}, assign(socket, :video_id, video_id)}
  end

  @impl true
  def handle_info(:after_join, socket) do
    push(socket, "presence_state", RumblWeb.Presence.list(socket))
    {:ok, _} = RumblWeb.Presence.track(
      socket,
      socket.assigns.user_id,
      %{device: "brower"})

    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in(event, params, socket) do
    user = Accounts.get_user!(socket.assigns.user_id)
    handle_in(event, params, user, socket)
  end

  def handle_in("new_annotation", params, user, socket) do
    case Multimedia.annotate_video(user, socket.assigns.video_id, params) do
      {:ok, annotation} ->
        broadcast!(socket, "new_annotation", %{
          id: annotation.id,
          user: RumblWeb.UserJSON.show(user),
          body: annotation.body,
          at: annotation.at
        })
        {:reply, :ok, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (video:lobby).
  # @impl true
  # def handle_in("shout", payload, socket) do
  #   broadcast(socket, "shout", payload)
  #   {:noreply, socket}
  # end

  # Add authorization logic here as required.
  # defp authorized?(_payload) do
  #   true
  # end
end
