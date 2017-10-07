defmodule TubeStreamerWeb.ErrorViewTest do
  use TubeStreamerWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 404.json" do
    assert render(TubeStreamerWeb.ErrorView, "404.json", []) ==
           %{errors: %{detail: "Page not found"}}
  end

  test "renders 429.json" do
    assert render(TubeStreamerWeb.ErrorView, "429.json", []) ==
           %{errors: %{detail: "Too much streams"}}
  end

  test "render 500.json" do
    assert render(TubeStreamerWeb.ErrorView, "500.json", []) ==
           %{errors: %{detail: "Internal server error"}}
  end

  test "renders 404.html" do
    assert render(TubeStreamerWeb.ErrorView, "404.html", []) == 
           "Page not found"
  end

  test "render any other" do
    assert render(TubeStreamerWeb.ErrorView, "505.json", []) ==
           %{errors: %{detail: "Internal server error"}}
  end
end
