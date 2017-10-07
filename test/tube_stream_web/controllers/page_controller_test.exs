defmodule TubeStreamerWeb.PageControllerTest do
  use TubeStreamerWeb.ConnCase, async: true

  @url "https://www.youtube.com/watch?v=ZPfNgIj2eNU"
  @id  @url |> Base.encode32()

  describe "index/2" do
    test "responds with 200" do
      response = build_conn()
                 |> get(page_path(build_conn(), :index))
      assert 200 == response.status
    end
  end

  describe "stream/2" do
    setup do
      on_exit fn -> TubeStreamer.Stream.MetaCache.delete_all() end
    end

    test "responds with 200 and no meta" do
      # no meta
      response = build_conn()
                 |> get(page_path(build_conn(), :stream, @id))
      assert 200 == response.status
      assert not (response.resp_body =~ "<meta property=\"og:title\" content=\"")
      assert response.resp_body =~ "Loader.run("
    end

    test "responds with 200 and meta" do
      # run cache
      TubeStreamer.Stream.MetaCache.get(@url)

      # meta
      response = build_conn()
                 |> get(page_path(build_conn(), :stream, @id))
      assert 200 == response.status
      assert response.resp_body =~ "<meta property=\"og:title\" content=\"" 
    end
  end
end
