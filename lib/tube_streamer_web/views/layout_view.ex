defmodule TubeStreamerWeb.LayoutView do
  use TubeStreamerWeb, :view

  def stream_loaded?(%Plug.Conn{assigns: assigns}) do
    keys = Map.keys(assigns) 
    Enum.all?([:stream, :cover, :title, :duration], fn(x) -> x in keys end)
  end

  def stream_loaded?(_), do: false
end
