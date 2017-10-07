defmodule TubeStreamerWeb.Api.V1.StreamControllerTest do
  use TubeStreamerWeb.ConnCase, async: true

  @url1 "https://www.youtube.com/watch?t=4&v=BaW_jenozKc"
        |> Base.encode32()
  @url2 "https://vimeo.com/233130406"
        |> Base.encode32()

  describe "index/2" do
    test "responds with redirect" do
      response = build_conn()
                 |> get(stream_path(build_conn(), :index, @url1))
      assert 302 == response.status
    end

    test "responds with stream" do
      response = build_conn()
                 |> get(stream_path(build_conn(), :index, @url2))
      assert 200 == response.status
    end

    test "responds with 404 when url is not correct" do
      response = build_conn()
                 |> get(stream_path(build_conn(), :index, "aaa"))
      assert 404 == response.status
    end

    test "responds with 429 when has to much parallel streams" do
      Application.put_env(:tube_streamer, :streams_limit, 0)
      response = build_conn()
                 |> get(stream_path(build_conn(), :index, @url2))
      assert 429 == response.status
      Application.put_env(:tube_streamer, :streams_limit, 10)
    end
  end

  describe "info/2" do
    test "responds with proper data from youtube" do
      response = build_conn()
                 |> get(stream_path(build_conn(), :info, @url1))
      assert 200 == response.status
      assert 10 == (response.resp_body |> Poison.decode!())["duration"] 
      assert 0 < TubeStreamer.Stream.MetaCache.size()
    end

    test "responds with proper data from vimeo" do
      response = build_conn()
                 |> get(stream_path(build_conn(), :info, @url2))
      assert 200 == response.status
      assert 67 == (response.resp_body |> Poison.decode!())["duration"] 
      assert 0 < TubeStreamer.Stream.MetaCache.size()
    end
  end
end
