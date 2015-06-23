defprotocol Maru.Response do
  @fallback_to_any true

  def content_type(resp)
  def resp_body(resp)
end


defimpl Maru.Response, for: BitString do
  def content_type(_) do
    "text/plain"
  end

  def resp_body(resp) do
    resp
  end
end

defimpl Maru.Response, for: Any do
  def content_type(_) do
    "application/json"
  end

  def resp_body(resp) do
    resp |> Poison.encode!
  end
end
