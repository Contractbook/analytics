Application.put_env(:analytics, :mixpanel, token: "test_token")
Application.put_env(:analytics, :segment, write_key: "test_write_key", client: Analytics.Segment.TestClient)
ExUnit.start()
