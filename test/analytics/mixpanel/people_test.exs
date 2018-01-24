defmodule Analytics.Mixpanel.PeopleTest do
  use ExUnit.Case
  import Analytics.Mixpanel.People
  alias Analytics.Mixpanel.People

  @distinct_id "my_distinct_id"

  describe "new/1" do
    test "creates a struct with distinct_id, token and client" do
      assert new(@distinct_id) ==
               %People{
                 client: Analytics.Mixpanel.Client,
                 operations: [],
                 distinct_id: @distinct_id,
                 ip: nil,
                 token: "test_token"
               }
    end
  end

  describe "set_ip/1" do
    test "tracks user IP address as a binary" do
      changeset = %{new(@distinct_id) | client: Analytics.Mixpanel.TestClient}
      changeset = set_ip(changeset, "127.0.0.1")
      assert changeset.ip == "127.0.0.1"
      assert submit(changeset) == :ok
      assert_receive {:mixpanel_request, "engage", []}, 500

      changeset = set(changeset, "foo", "bar")
      assert submit(changeset) == :ok
      assert_receive {:mixpanel_request, "engage", [event]}, 500
      assert event["$ip"] == "127.0.0.1"
    end

    test "tracks user IP address as a tuple" do
      changeset = %{new(@distinct_id) | client: Analytics.Mixpanel.TestClient}
      changeset = set_ip(changeset, {127, 0, 0, 2})
      assert changeset.ip == "127.0.0.2"
      assert submit(changeset) == :ok
      assert_receive {:mixpanel_request, "engage", []}, 500

      changeset = set(changeset, "foo", "bar")
      assert submit(changeset) == :ok
      assert_receive {:mixpanel_request, "engage", [event]}, 500
      assert event["$ip"] == "127.0.0.2"
    end

    test "removes user IP with nil" do
      changeset = %{new(@distinct_id) | client: Analytics.Mixpanel.TestClient, ip: "127.0.0.1"}
      changeset = set_ip(changeset, nil)
      assert changeset.ip == nil
    end
  end

  test "track_charge/3 appends charge event" do
    changeset = track_charge(%{new(@distinct_id) | client: Analytics.Mixpanel.TestClient}, 5, %{"$time" => "NOW"})
    assert submit(changeset) == :ok
    assert_receive {:mixpanel_request, "engage", changes}, 500

    assert changes == [
             %{
               "$append" => %{
                 "$transactions" => %{"$amount" => 5, "$time" => "NOW"}
               },
               "$distinct_id" => @distinct_id,
               "$ignore_time" => "true",
               "$token" => "test_token"
             }
           ]
  end

  test "submits profile changes" do
    changeset =
      %{new(@distinct_id) | client: Analytics.Mixpanel.TestClient}
      |> set("foo", "bar")
      |> set("fiz", "buz")
      |> unset("liz", "cuz")
      |> set_once("nix", "lix")
      |> set_once("nix", "tax")
      |> increment("i")
      |> increment("i", 2)
      |> append("l", 1)
      |> append("l", 2)
      |> append("l", 3)
      |> append("l2", 1)
      |> union("lx", [1, 2, 3])
      |> union("lx", [2, 3, 4])

    assert submit(changeset) == :ok
    assert_receive {:mixpanel_request, "engage", changes}, 500

    assert [
             %{"$add" => %{"i" => 3}},
             %{"$append" => %{"l" => 1, "l2" => 1}},
             %{"$append" => %{"l" => 2}},
             %{"$append" => %{"l" => 3}},
             %{"$set" => %{"fiz" => "buz", "foo" => "bar"}},
             %{"$set_once" => %{"nix" => "lix"}},
             %{"$union" => %{"lx" => [1, 2, 3, 2, 3, 4]}},
             %{"$unset" => %{"liz" => "cuz"}},
           ] = changes
  end
end
