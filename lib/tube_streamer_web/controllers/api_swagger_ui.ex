defmodule TubeStreamerWeb.ApiSwaggerUi.Controller do
  use Plug.Builder

  plug PhoenixSwagger.Plug.SwaggerUI, otp_app: :tube_streamer, 
                                      swagger_file: "api_specs_v1.json"
end
