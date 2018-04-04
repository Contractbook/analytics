defmodule Analytics.Segment do
  @doc """
  Associates one identity with another, usually an anonymous user with an identified user once they sign up.
  """
  def alias_identity(distinct_id, new_distinct_id_or_user_id) when is_binary(new_distinct_id_or_user_id) do
    config = config()
    data = %{
      "previousId" => distinct_id,
      "userId" => new_distinct_id_or_user_id
    }
    config[:client].send("alias", data, config)
  end

  @doc """
  Associates an identified user with a group and updates group object with traits.
  """
  def group(distinct_id, group_id, traits \\ %{}) do
    config = config()
    data = %{
      "userId" => distinct_id,
      "groupId" => group_id,
      "traits" => traits
    }
    config[:client].send("group", data, config)
  end

  @doc """
  Tracks an event for an identified user.
  """
  def track(distinct_id, event, properties \\ %{}) do
    config = config()
    data = %{
      "userId" => distinct_id,
      "event" => event,
      "properties" => properties
    }
    config[:client].send("track", data, config)
  end

  @doc """
  Ties a users to their actions and record traits about them.
  """
  def identify(distinct_id, traits \\ %{}) do
    config = config()
    data = %{
      "userId" => distinct_id,
      "traits" => traits
    }
    config[:client].send("identify", data, config)
  end

  @doc false
  def config do
    config = Application.fetch_env!(:analytics, :segment)
    client = Keyword.get(config, :client, Analytics.Segment.Client)
    write_key = Keyword.fetch!(config, :write_key)
    [client: client, write_key: write_key]
  end
end
