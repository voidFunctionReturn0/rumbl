defmodule RumblWeb.VideoControllerTest do
  use RumblWeb.ConnCase, async: true

  @create_attrs %{
    url: "http://youtu.be",
    title: "vid",
    description: "a vid"}
  @invalid_attrs %{title: "invalid"}

  test "requires user authentication on all actions", %{conn: conn} do
    Enum.each([
      get(conn, ~p"/manage/videos/new"),
      get(conn, ~p"/manage/videos"),
      get(conn, ~p"/manage/videos/123"),
      get(conn, ~p"/manage/videos/123/edit"),
      put(conn, ~p"/manage/videos/123", video: %{}),
      post(conn, ~p"/manage/videos", video: %{}),
      delete(conn, ~p"/manage/videos/123")
    ], fn conn ->
      assert html_response(conn, 302)
      assert conn.halted
    end)
  end

  describe "with a logged-in user" do
    alias Rumbl.Multimedia

    defp video_count(user), do: Enum.count(Multimedia.list_user_videos(user))

    setup %{conn: conn, login_as: username} do
      user = user_fixture(username: username)
      conn = assign(conn, :current_user, user)

      {:ok, conn: conn, user: user}
    end

    @tag login_as: "max"
    test "lists all user's video on index", %{conn: conn, user: user} do
      user_video = video_fixture(user, title: "funny cats")
      other_video = video_fixture(
        user_fixture(username: "other"),
        title: "another video")

      conn = get conn, ~p"/manage/videos"
      assert html_response(conn, 200) =~ ~r/Listing Videos/
      assert String.contains?(conn.resp_body, user_video.title)
      refute String.contains?(conn.resp_body, other_video.title)
    end

    @tag login_as: "max"
    test "creates user video and redirects", %{conn: conn, user: user} do
      create_conn = post conn, ~p"/manage/videos", video: @create_attrs
      assert %{id: id} = redirected_params(create_conn)
      assert redirected_to(create_conn) == ~p"/manage/videos/#{id}"

      conn = get conn, ~p"/manage/videos/#{id}"
      assert html_response(conn, 200) =~ "Video"
      assert Multimedia.get_user_video!(user, id).user_id == user.id
    end

    @tag login_as: "max"
    test "does not create vid, renders errors when invalid", %{conn: conn, user: user} do
      count_before = video_count(user)
      conn = post conn, ~p"/manage/videos", video: @invalid_attrs
      assert html_response(conn, 200) =~ "check the errors"
      assert video_count(user) == count_before
    end
  end

  test "authorizes actions against access by other users", %{conn: conn} do
    owner = user_fixture(username: "owner")
    video = video_fixture(owner, @create_attrs)
    non_owner = user_fixture(username: "sneaky")
    conn = assign(conn, :current_user, non_owner)

    assert_error_sent :not_found, fn -> get conn, ~p"/manage/videos/#{video.id}" end
    assert_error_sent :not_found, fn -> get conn, ~p"/manage/videos/#{video.id}/edit" end
    assert_error_sent :not_found, fn -> put conn, ~p"/manage/videos/#{video.id}", video: @create_attrs end
    assert_error_sent :not_found, fn -> delete conn, ~p"/manage/videos/#{video.id}" end
  end

  # @create_attrs %{description: "some description", title: "some title", url: "some url"}
  # @update_attrs %{description: "some updated description", title: "some updated title", url: "some updated url"}
  # @invalid_attrs %{description: nil, title: nil, url: nil}

  # describe "index" do
  #   test "lists all videos", %{conn: conn} do
  #     conn = get(conn, ~p"/videos")
  #     assert html_response(conn, 200) =~ "Listing Videos"
  #   end
  # end

  # describe "new video" do
  #   test "renders form", %{conn: conn} do
  #     conn = get(conn, ~p"/videos/new")
  #     assert html_response(conn, 200) =~ "New Video"
  #   end
  # end

  # describe "create video" do
  #   test "redirects to show when data is valid", %{conn: conn} do
  #     conn = post(conn, ~p"/videos", video: @create_attrs)

  #     assert %{id: id} = redirected_params(conn)
  #     assert redirected_to(conn) == ~p"/videos/#{id}"

  #     conn = get(conn, ~p"/videos/#{id}")
  #     assert html_response(conn, 200) =~ "Video #{id}"
  #   end

  #   test "renders errors when data is invalid", %{conn: conn} do
  #     conn = post(conn, ~p"/videos", video: @invalid_attrs)
  #     assert html_response(conn, 200) =~ "New Video"
  #   end
  # end

  # describe "edit video" do
  #   setup [:create_video]

  #   test "renders form for editing chosen video", %{conn: conn, video: video} do
  #     conn = get(conn, ~p"/videos/#{video}/edit")
  #     assert html_response(conn, 200) =~ "Edit Video"
  #   end
  # end

  # describe "update video" do
  #   setup [:create_video]

  #   test "redirects when data is valid", %{conn: conn, video: video} do
  #     conn = put(conn, ~p"/videos/#{video}", video: @update_attrs)
  #     assert redirected_to(conn) == ~p"/videos/#{video}"

  #     conn = get(conn, ~p"/videos/#{video}")
  #     assert html_response(conn, 200) =~ "some updated description"
  #   end

  #   test "renders errors when data is invalid", %{conn: conn, video: video} do
  #     conn = put(conn, ~p"/videos/#{video}", video: @invalid_attrs)
  #     assert html_response(conn, 200) =~ "Edit Video"
  #   end
  # end

  # describe "delete video" do
  #   setup [:create_video]

  #   test "deletes chosen video", %{conn: conn, video: video} do
  #     conn = delete(conn, ~p"/videos/#{video}")
  #     assert redirected_to(conn) == ~p"/videos"

  #     assert_error_sent 404, fn ->
  #       get(conn, ~p"/videos/#{video}")
  #     end
  #   end
  # end

  # defp create_video(_) do
  #   video = video_fixture()
  #   %{video: video}
  # end
end
