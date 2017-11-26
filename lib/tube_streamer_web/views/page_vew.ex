defmodule TubeStreamerWeb.PageView do
  use TubeStreamerWeb, :view

  import Plug.Conn

  def is_ru?(conn), do: get_session(conn, :locale) == "ru"

  def is_en?(conn), do: get_session(conn, :locale) == "en"

  def active?(true), do: "active"
  def active?(_), do: ""
end
