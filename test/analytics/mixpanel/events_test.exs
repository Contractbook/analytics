defmodule Analytics.Mixpanel.EventsTest do
  use ExUnit.Case
  import Analytics.Mixpanel.Events
  alias Analytics.Mixpanel.Events

  @distinct_id "my_distinct_id"

  describe "new/1" do
    test "creates a struct with distinct_id, token and client" do
      assert new(@distinct_id) ==
               %Events{
                 client: Analytics.Mixpanel.Client,
                 events: [],
                 distinct_id: @distinct_id,
                 ip: nil,
                 token: "test_token"
               }
    end
  end

  describe "new/0" do
    test "creates a struct with token and client" do
      assert new() ==
               %Events{
                 client: Analytics.Mixpanel.Client,
                 events: [],
                 distinct_id: nil,
                 ip: nil,
                 token: "test_token"
               }
    end
  end

  describe "set_ip/1" do
    test "tracks user IP address as a binary" do
      events = %{new(@distinct_id) | client: Analytics.Mixpanel.TestClient}
      events = set_ip(events, "127.0.0.1")
      assert events.ip == "127.0.0.1"
      assert submit(events) == :ok
      assert_receive {:mixpanel_request, "track", []}, 500

      events = track(events, "test_event")
      assert submit(events) == :ok
      assert_receive {:mixpanel_request, "track", [event]}, 500
      assert event.properties["ip"] == "127.0.0.1"
    end

    test "tracks user IP address as a tuple" do
      events = %{new(@distinct_id) | client: Analytics.Mixpanel.TestClient}
      events = set_ip(events, {127, 0, 0, 2})
      assert events.ip == "127.0.0.2"
      assert submit(events) == :ok
      assert_receive {:mixpanel_request, "track", []}, 500

      events = track(events, "test_event")
      assert submit(events) == :ok
      assert_receive {:mixpanel_request, "track", [event]}, 500
      assert event.properties["ip"] == "127.0.0.2"
    end

    test "removes user IP with nil" do
      events = %{new(@distinct_id) | client: Analytics.Mixpanel.TestClient, ip: "127.0.0.1"}
      events = set_ip(events, nil)
      assert events.ip == nil
    end
  end

  test "submits tracked events with distinct_id in struct" do
    events =
      %{new(@distinct_id) | client: Analytics.Mixpanel.TestClient}
      |> track("test_eventA")
      |> track("test_eventB", %{"foo" => "bar"})
      |> track("test_eventc", %{fiz: "buz"})

    assert submit(events) == :ok
    assert_receive {:mixpanel_request, "track", events}, 500

    assert events == [
             %{event: "test_eventA", properties: %{"distinct_id" => @distinct_id, "token" => "test_token"}},
             %{
               event: "test_eventB",
               properties: %{"distinct_id" => @distinct_id, "foo" => "bar", "token" => "test_token"}
             },
             %{
               event: "test_eventc",
               properties: %{:fiz => "buz", "distinct_id" => @distinct_id, "token" => "test_token"}
             }
           ]
  end

  test "submits tracked events with distinct_id in track/4" do
    events =
      %{new() | client: Analytics.Mixpanel.TestClient}
      |> track_for_user("userA", "test_eventA")
      |> track_for_user("userA", "test_eventB", %{"foo" => "bar"})
      |> track_for_user("userB", "test_eventc", %{fiz: "buz"})

    assert submit(events) == :ok
    assert_receive {:mixpanel_request, "track", events}, 500

    assert events == [
             %{event: "test_eventA", properties: %{"distinct_id" => "userA", "token" => "test_token"}},
             %{
               event: "test_eventB",
               properties: %{"distinct_id" => "userA", "foo" => "bar", "token" => "test_token"}
             },
             %{
               event: "test_eventc",
               properties: %{:fiz => "buz", "distinct_id" => "userB", "token" => "test_token"}
             }
           ]
  end
end
