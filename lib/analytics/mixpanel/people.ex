defmodule Analytics.Mixpanel.People do
  @moduledoc """
  This module is responsible for building a struct which is later can be used
  to send all changes via batch request to the Mixpanel.

  Whenever batch request is submitted it's validated as whole, so that if one of entries
  is invalid there would be no changes applied to a user.
  """
  alias Analytics.Mixpanel.People

  @engage_endpoint "engage"

  defstruct client: Analytics.Mixpanel.Client, operations: [], distinct_id: nil, ip: nil, token: nil

  @doc """
  Creates a new `People` struct that updates person with a `distinct_id`.
  """
  def new(distinct_id), do: %People{distinct_id: distinct_id, token: Analytics.Mixpanel.Client.token()}

  @doc """
  The IP address associated with a given profile, which Mixpanel
  uses to guess user geographic location. Ignored if not set.
  """
  def set_ip(%People{} = batch_request, ip), do: %{batch_request | ip: ip_to_string(ip)}

  defp ip_to_string({a, b, c, d}), do: "#{a}.#{b}.#{c}.#{d}"
  defp ip_to_string(ip), do: ip

  @doc """
  Updates the profile attribute.
  If the profile does not exist, it creates it with these properties.
  If it does exist, it sets the properties to these values, overwriting existing values.

  For more details see `submit/2`.
  """
  def set(%People{} = batch_request, key, value) do
    %{batch_request | operations: [{"$set", key, value} | batch_request.operations]}
  end

  @doc """
  Removes the profile attribute.

  For more details see `submit/2`.
  """
  def unset(%People{} = batch_request, key) do
    %{batch_request | operations: [{"$unset", key} | batch_request.operations]}
  end

  @doc """
  Works just like `set/2`, except it will not overwrite existing property values.
  This is useful for properties like "First login date".

  For more details see `submit/2`.
  """
  def set_once(%People{} = batch_request, key, value) do
    %{batch_request | operations: [{"$set_once", key, value} | batch_request.operations]}
  end

  @doc """
  When processed, the property values are added to the existing values of the properties on the profile.
  If the property is not present on the profile, the value will be added to 0.
  It is possible to decrement by calling "$add" with negative values.
  This is useful for maintaining the values of properties like "Number of Logins" or "Files Uploaded".

  For more details see `submit/2`.
  """
  def increment(%People{} = batch_request, key, value \\ 1) do
    %{batch_request | operations: [{"$add", key, value} | batch_request.operations]}
  end

  @doc """
  Appends each to a list associated with the corresponding property name.
  Appending to a property that doesn't exist will result in assigning a list with one element to that property.

  For more details see `submit/2`.
  """
  def append(%People{} = batch_request, key, value) do
    %{batch_request | operations: [{"$append", key, value} | batch_request.operations]}
  end

  @doc """
  The list values in the request are merged with the existing list on the user profile, ignoring duplicates.

  For more details see `submit/2`.
  """
  def union(%People{} = batch_request, key, list) when is_list(list) do
    %{batch_request | operations: [{"$union", key, list} | batch_request.operations]}
  end

  @doc """
  Adds a transactions to the individual user profile, which will also be reflected in the Mixpanel Revenue report.

  For more details see `submit/2`.
  """
  def track_charge(%People{} = batch_request, amount, metadata \\ %{}) do
    transaction =
      metadata
      |> Map.put("$amount", amount)
      |> Map.put_new("$time", DateTime.utc_now() |> DateTime.to_iso8601())

    append(batch_request, "$transactions", transaction)
  end

  @doc """
  Creates or updates user profile with operations from `People` struct.

  ## Options
    * `:update_last_seen` - If the `:update_last_seen` property is `true`, automatically updates the \
    "Last Seen" property of the profile. Otherwise, Mixpanel will add a "Last Seen" property associated \
    with the current time for all $set, $append, and $add operations. Default: `false`.
  """
  def submit(%People{} = batch_request, opts \\ []) do
    payload = build_payload(batch_request, opts)
    batch_request.client.send_batch(@engage_endpoint, payload)
  end

  defp build_payload(batch_request, opts) do
    %{operations: operations, distinct_id: distinct_id, ip: ip, token: token} = batch_request

    event_template =
      Map.new()
      |> Map.put("$distinct_id", distinct_id)
      |> Map.put("$token", token)
      |> maybe_put("$ip", ip)
      |> maybe_put_last_seen_update(Keyword.get(opts, :update_last_seen, false))

    operations
    |> Enum.reverse()
    |> Enum.group_by(&elem(&1, 0), &Tuple.delete_at(&1, 0))
    |> maybe_merge_set()
    |> maybe_merge_unset()
    |> maybe_merge_set_once()
    |> maybe_merge_add()
    |> maybe_merge_union()
    |> maybe_merge_append()
    |> Enum.flat_map(fn
      {operation, values} when is_map(values) ->
        [Map.put(event_template, operation, values)]

      {"$unset" = operation, values} ->
        [Map.put(event_template, operation, values)]

      {operation, values} when is_list(values) ->
        Enum.map(values, fn value ->
          Map.put(event_template, operation, value)
        end)
    end)
  end

  defp maybe_merge_set(%{"$set" => updates} = operations) do
    set = Enum.reduce(updates, %{}, fn {key, value}, acc -> Map.put(acc, key, value) end)
    Map.put(operations, "$set", set)
  end

  defp maybe_merge_set(operations) do
    operations
  end

  defp maybe_merge_unset(%{"$unset" => updates} = operations) do
    unset = Enum.reduce(updates, [], fn {key}, acc -> [key] ++ acc end)
    Map.put(operations, "$unset", unset)
  end

  defp maybe_merge_unset(operations) do
    operations
  end

  defp maybe_merge_set_once(%{"$set_once" => updates} = operations) do
    set_once = Enum.reduce(updates, %{}, fn {key, value}, acc -> Map.put_new(acc, key, value) end)
    Map.put(operations, "$set_once", set_once)
  end

  defp maybe_merge_set_once(operations) do
    operations
  end

  defp maybe_merge_add(%{"$add" => updates} = operations) do
    increment =
      Enum.reduce(updates, %{}, fn {key, value}, acc ->
        if current_value = Map.get(acc, key) do
          Map.put(acc, key, current_value + value)
        else
          Map.put(acc, key, value)
        end
      end)

    Map.put(operations, "$add", increment)
  end

  defp maybe_merge_add(operations) do
    operations
  end

  defp maybe_merge_union(%{"$union" => updates} = operations) do
    union =
      Enum.reduce(updates, %{}, fn {key, value}, acc ->
        if current_value = Map.get(acc, key) do
          Map.put(acc, key, current_value ++ value)
        else
          Map.put(acc, key, value)
        end
      end)

    Map.put(operations, "$union", union)
  end

  defp maybe_merge_union(operations) do
    operations
  end

  defp maybe_merge_append(%{"$append" => updates} = operations) do
    {_keys, append} =
      Enum.reduce(updates, {MapSet.new(), []}, fn
        {key, value}, {keys, []} ->
          {MapSet.put(keys, key), [Map.new([{key, value}])]}

        {key, value}, {keys, [h | t] = acc} ->
          if MapSet.member?(keys, key) do
            {keys, acc ++ [Map.new([{key, value}])]}
          else
            {MapSet.put(keys, key), [Map.put(h, key, value)] ++ t}
          end
      end)

    Map.put(operations, "$append", append)
  end

  defp maybe_merge_append(operations) do
    operations
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_put_last_seen_update(event, true), do: event
  defp maybe_put_last_seen_update(event, _), do: Map.put(event, "$ignore_time", "true")
end
