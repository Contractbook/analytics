defmodule Analytics.Mixpanel do
  alias Analytics.Mixpanel.{Events, People}

  @doc """
  Tracks an event.
  """
  def track(distinct_id, event, properties \\ %{}) do
    distinct_id
    |> Events.new()
    |> Events.track(event, properties)
    |> Events.submit()
  end

  @doc """
  Updates the profile attribute.
  If the profile does not exist, it creates it with these properties.
  If it does exist, it sets the properties to these values, overwriting existing values.
  """
  def set(distinct_id, key, value) do
    distinct_id
    |> People.new()
    |> People.set(key, value)
    |> People.submit()
  end

  @doc """
  Works just like `set/2`, except it will not overwrite existing property values.
  This is useful for properties like "First login date".
  """
  def set_once(distinct_id, key, value) do
    distinct_id
    |> People.new()
    |> People.set_once(key, value)
    |> People.submit()
  end

  @doc """
  When processed, the property values are added to the existing values of the properties on the profile.
  If the property is not present on the profile, the value will be added to 0.
  It is possible to decrement by calling "$add" with negative values.
  This is useful for maintaining the values of properties like "Number of Logins" or "Files Uploaded".
  """
  def increment(distinct_id, key, value \\ 1) when is_integer(value) do
    distinct_id
    |> People.new()
    |> People.increment(key, value)
    |> People.submit()
  end

  @doc """
  Appends each to a list associated with the corresponding property name.
  Appending to a property that doesn't exist will result in assigning a list with one element to that property.
  """
  def append(distinct_id, key, value) do
    distinct_id
    |> People.new()
    |> People.append(key, value)
    |> People.submit()
  end

  @doc """
  The list values in the request are merged with the existing list on the user profile, ignoring duplicates.
  """
  def union(distinct_id, key, list) when is_list(list) do
    distinct_id
    |> People.new()
    |> People.union(key, list)
    |> People.submit()
  end

  @doc """
  Adds a transactions to the individual user profile, which will also be reflected in the Mixpanel Revenue report.
  """
  def track_charge(distinct_id, amount, metadata \\ %{}) do
    distinct_id
    |> People.new()
    |> People.track_charge(amount, metadata)
    |> People.submit()
  end
end
