defmodule Analytics.Mixpanel.Events do
  @moduledoc """
  This module provides a struct that accumulates user events and helper to submit data to Mixpanel.
  """
  alias Analytics.Mixpanel.Events

  @track_endpoint "track"

  defstruct client: Analytics.Mixpanel.Client, events: [], distinct_id: nil, ip: nil, token: nil

  @doc """
  Creates a new `Events` struct that is used to submit events for a client identified with `distinct_id`.
  """
  def new(distinct_id), do: %Events{distinct_id: distinct_id, token: Analytics.Mixpanel.Client.token()}
  def new, do: %Events{token: Analytics.Mixpanel.Client.token()}

  @doc """
  The IP address associated with a given profile, which Mixpanel
  uses to guess user geographic location. Ignored if not set.
  """
  def set_ip(%Events{} = batch_request, ip), do: %{batch_request | ip: ip_to_string(ip)}

  defp ip_to_string({a, b, c, d}), do: "#{a}.#{b}.#{c}.#{d}"
  defp ip_to_string(ip), do: ip

  @doc """
  Appends an event to a `Events` struct with a pre-defined `distinct_id`.

  Events struct must be created with `new/1` in order to use this function.

  ## Arguments
    * `event` - A name for the event;
    * `properties` - A collection of properties associated with this event. Where `:time` (timestamp) would update \
    event time (otherwise Mixpanel uses time when event is arrived to their back-end), \
    `distinct_id` can be used to identify user and `:token` can be used to override Mixpanel API key.
  """
  def track(%Events{distinct_id: distinct_id} = batch_request, event, properties \\ %{})
    when is_map(properties) and not is_nil(distinct_id) do
    %{batch_request | events: [{distinct_id, event, properties} | batch_request.events]}
  end

  @doc """
  Appends an event to a `Events` struct with a specific `distinct_id`. This is useful when you want
  to submit events to more than user per request.

  ## Arguments
    * `distinct_id` - Distinct ID that identifies user on Mixpanel;
    * `event` - A name for the event;
    * `properties` - A collection of properties associated with this event. Where `:time` (timestamp) would update \
    event time (otherwise Mixpanel uses time when event is arrived to their back-end), \
    `distinct_id` can be used to identify user and `:token` can be used to override Mixpanel API key.
  """
  def track_for_user(%Events{} = batch_request, distinct_id, event, properties \\ %{})
    when is_map(properties) do
    %{batch_request | events: [{distinct_id, event, properties} | batch_request.events]}
  end

  @doc """
  Submits events tracked for a user.
  """
  def submit(%Events{} = batch_request) do
    %{client: client, events: events, ip: ip, token: token} = batch_request

    event_template =
      Map.new()
      |> Map.put("token", token)
      |> maybe_put("ip", ip)

    payload =
      events
      |> Enum.reverse()
      |> Enum.map(fn {distinct_id, event, properties} ->
        properties =
          event_template
          |> maybe_put("distinct_id", distinct_id)
          |> Map.merge(properties)
          |> maybe_normalize_time()

        %{event: event, properties: properties}
      end)

    client.send_batch(@track_endpoint, payload)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_normalize_time(%{time: time} = properties), do: Map.put(properties, :time, normalize_time(time))
  defp maybe_normalize_time(%{"time" => time} = properties), do: Map.put(properties, "time", normalize_time(time))
  defp maybe_normalize_time(properties), do: properties

  defp normalize_time(nil), do: nil
  defp normalize_time(timestamp) when is_integer(timestamp), do: timestamp
  defp normalize_time(%DateTime{} = datetime), do: DateTime.to_unix(datetime)
end
