defmodule RumblWeb.UserJSON do
  alias Rumbl.Accounts

  def show(%Accounts.User{} = user) do
    %{
      id: user.id,
      username: user.username
    }
  end
end
