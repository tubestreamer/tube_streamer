defmodule TubeStreamerWeb.LayoutViewTest do
  use TubeStreamerWeb.ConnCase, async: true

  @stream %{stream: "http://some.link",
            cover: "http://some.link/cover.jpg",
            title: "Some Mixtape",
            duration: 42}
  @broken_stream_1 Map.delete(@stream, :cover)
  @broken_stream_2 Map.delete(@broken_stream_1, :title)

  test "stream_loaded?" do
    assert TubeStreamerWeb.LayoutView.stream_loaded?(build_conn()) == false

    conn = build_conn()
           |> Map.put(:assigns, @stream)
    assert TubeStreamerWeb.LayoutView.stream_loaded?(conn) == true

    conn = build_conn()
           |> Map.put(:assigns, @broken_stream_1)
    assert TubeStreamerWeb.LayoutView.stream_loaded?(conn) == false

    conn = build_conn()
           |> Map.put(:assigns, @broken_stream_2)
    assert TubeStreamerWeb.LayoutView.stream_loaded?(conn) == false
  end
end
