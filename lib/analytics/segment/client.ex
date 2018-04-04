defmodule Analytics.Segment.Client do
  @base_url "https://api.segment.io/v1/"

  def send(endpoint_url, data, opts) do
    write_key = Keyword.fetch!(opts, :write_key)
    headers = [{"accept", "application/json"}, {"content-type", "application/json"}]
    body = Jason.encode!(data)
    opts = [:with_body, {:basic_auth, {write_key, ""}}]

    case :hackney.request(:post, [@base_url, endpoint_url], headers, body, opts) do
      {:ok, status, _headers, _body} when status in 200..299 ->
        :ok

      {:ok, status, _headers, body} when status in 400..499 ->
        {:error, {status, body}}

      {_ok_or_error, status, _headers, _body} when status in 500..599 ->
        {:error, :server_down}

      {:error, :timeout} ->
        {:error, :timeout}
    end
  end

  def format_error(:server_down), do: "Segment had an server error"
  def format_error(:retry_later), do: "Segment API service is temporarily unavailable"
  def format_error({status, body}), do: "The client received error response `#{body}` with #{to_string(status)} status"
  def format_error(atom) when is_atom(atom), do: Atom.to_string(atom)
end
