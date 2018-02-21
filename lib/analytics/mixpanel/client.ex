defmodule Analytics.Mixpanel.Client do
  @base_url "http://api.mixpanel.com/"

  def send_batch(endpoint_url, data) do
    headers = [{"accept", "application/json"}, {"content-type", "application/x-www-form-urlencoded"}]
    data = encode_data!(data)

    case :hackney.request(:post, [@base_url, endpoint_url, "?ip=0"], headers, {:form, [{:data, data}]}, [:with_body]) do
      {:ok, status, _headers, "1"} when status in 200..299 ->
        :ok

      {:ok, status, _headers, body} when status in 400..499 ->
        {:error, {status, body}}

      {_ok_or_error, 503, _headers, _body} ->
        {:error, :retry_later}

      {_ok_or_error, status, _headers, _body} when status in 500..599 ->
        {:error, :server_down}

      {_ok_or_error, _status, _headers, "0"} ->
        {:error, :invalid_data}

      {:error, :timeout} ->
        {:error, :timeout}
    end
  end

  def format_error(:server_down), do: "Intercom had an server error"
  def format_error(:retry_later), do: "Intercom API service is temporarily unavailable"
  def format_error(atom) when is_atom(atom), do: Atom.to_string(atom)

  def format_error({status, body}),
    do: "The client received malformed error response `#{body}` with #{to_string(status)} HTTP code"

  defp encode_data!(data), do: data |> Jason.encode!() |> Base.encode64()
end
