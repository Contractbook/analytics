defmodule Analytics.Mixpanel.TestClient do
  @moduledoc """
  Test client that sends tracked data to the test process.
  """
  def send_batch(endpoint_url, data) do
    send(self(), {:mixpanel_request, endpoint_url, data})
    :ok
  end
end
