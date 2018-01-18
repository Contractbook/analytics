defmodule Analytics.Mixpanel.TestClient do
  def send_batch(endpoint_url, data) do
    send(self(), {:mixpanel_request, endpoint_url, data})
    :ok
  end
end
