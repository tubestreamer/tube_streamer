defmodule TubeStreamerWeb.SiteControllerTest do
  use TubeStreamerWeb.ConnCase, async: true

  describe "index/2" do
    test "responds with 200" do
      response = build_conn()
                 |> get(sitemap_path(build_conn(), :index))
      assert 200 == response.status
      assert response.resp_body =~ "xml"
    end
  end
end
