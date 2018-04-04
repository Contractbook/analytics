defmodule Analytics.Mixpanel do
  alias Analytics.Mixpanel.{Events, People}

  @doc """
  Associates one identity with another, usually an anonymous user with an identified user once they sign up.

  This function MUST be called exactly once for each user when the used is signed up,
  otherwise user would be duplicated on Mixpanel side. You MUST not submit any People data
  before creating an alias, unless you work with legacy users that were signed up before
  Mixpanel was integrated.

  By default, DistinctID was automatically set by Mixpanel and you would want to alias it
  with a User email in your database. (Email is preferred over User ID because your code won't
  need to know the ID, which is useful for third-party integrations that don't have access to the
  production data.)

  Calling alias doesn't actually change Mixpanel distinct_id; instead, what it does do is add the ID to
  a lookup table on Mixpanel’s end and map it to the original Mixpanel distinct_id.

  You can receive a `disting_id` from your front-end or by reading a Mixpanel cookie set for your domain:

      def client_distinct_id(conn) do
        # Usually it's format is: "mp_\#{mixpanel_token}_mixpanel"
        cookie_name = "mp_sldasjdlasjiu39d8ds9hfn3l_mixpanel"

        with value when is_binary(value) <- get_mixpanel_cookie(conn, cookie_name),
             value = URI.decode(value),
             {:ok, %{"distinct_id" => distinct_id}} <- Jason.decode(value) do
          distinct_id
        else
          _ -> nil
        end
      end

      defp get_mixpanel_cookie(conn, cookie_name) do
        maybe_fetch_cookies(conn).cookies[cookie_name]
      end

      defp maybe_fetch_cookies(%{cookies: %Plug.Conn.Unfetched{}} = conn), do: Plug.Conn.fetch_cookies(conn)
      defp maybe_fetch_cookies(%{} = conn), do: conn

  Do not batch updates to people attributes with creating an alias, alias would not be available
  for other events and you would get duplicated in People.
  """
  def alias_identity(distinct_id, new_distinct_id_or_user_id) when is_binary(new_distinct_id_or_user_id) do
    distinct_id
    |> Events.new()
    |> Events.track("$create_alias", %{"alias" => new_distinct_id_or_user_id})
    |> Events.submit()
  end

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

  @doc false
  def config do
    config = Application.fetch_env!(:analytics, :mixpanel)
    client = Keyword.get(config, :client, Analytics.Mixpanel.Client)
    token = Keyword.fetch!(config, :token)
    [client: client, token: token]
  end
end
