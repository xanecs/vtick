defmodule VtickWeb.AdminRedirector do
  def init(default), do: default

  def call(conn, _opts) do
    conn
    |> Phoenix.Controller.redirect(to: "/admin/matches")
    |> Plug.Conn.halt()
  end
end
