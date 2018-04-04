defmodule Analytics.SegmentTest do
  use ExUnit.Case
  import Analytics.Segment

  describe "alias_identity/2" do
    test "creates alias for distinct id" do
      assert :ok == alias_identity("foo_id", "email@example.com")

      event_payload = %{"previousId" => "foo_id", "userId" => "email@example.com"}
      assert_receive {:segment_request, "alias", ^event_payload, _opts}
    end
  end

  describe "group/3" do
    test "creates or updates group with traits" do
      assert :ok == group("foo_id", "group_id", %{"type" => "bastards"})

      event_payload = %{"groupId" => "group_id", "traits" => %{"type" => "bastards"}, "userId" => "foo_id"}
      assert_receive {:segment_request, "group", ^event_payload, _opts}
    end
  end

  describe "track/3" do
    test "tracks event with parameters" do
      assert :ok == track("foo_id", "event_name", %{"did_something_good" => false})

      event_payload = %{"event" => "event_name", "properties" => %{"did_something_good" => false}, "userId" => "foo_id"}
      assert_receive {:segment_request, "track", ^event_payload, _opts}
    end
  end

  describe "identify/2" do
    test "creates or updates customer with traits" do
      assert :ok == identify("foo_id", %{"did_something_good" => false})

      event_payload = %{"traits" => %{"did_something_good" => false}, "userId" => "foo_id"}
      assert_receive {:segment_request, "identify", ^event_payload, _opts}
    end
  end
end
