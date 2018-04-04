defmodule Analytics.Segment.TestClient do
  @moduledoc """
  Test client that sends tracked data to the test process.
  """
  def send(endpoint_url, data, opts) do
    send(self(), {:segment_request, endpoint_url, data, opts})
    :ok
  end
end
