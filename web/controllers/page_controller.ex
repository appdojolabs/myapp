defmodule Myapp.PageController do
  use Myapp.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
