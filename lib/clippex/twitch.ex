defmodule Clippex.Twitch do
  @moduledoc """
  Context module for interacting with the Twitch API.
  """

  require Logger

  @base_url "https://api.twitch.tv/helix"

  def get_clips(broadcaster_id) do
    config = Application.get_env(:clippex, :twitch)
    client_id = config[:client_id]
    access_token = config[:access_token]

    if is_nil(client_id) or is_nil(access_token) do
      {:error, :missing_credentials}
    else
      req =
        Req.new(base_url: @base_url)
        |> Req.Request.put_header("Client-Id", client_id)
        |> Req.Request.put_header("Authorization", "Bearer #{access_token}")

      ended_at = DateTime.utc_now()
      started_at = DateTime.add(ended_at, -30, :day)

      params = [
        broadcaster_id: broadcaster_id,
        started_at: DateTime.to_iso8601(started_at),
        ended_at: DateTime.to_iso8601(ended_at)
      ]

      case Req.get(req, url: "/clips", params: params) do
        {:ok, %Req.Response{status: 200, body: %{"data" => data}}} ->
          {:ok, data}

        {:ok, %Req.Response{status: status, body: body}} ->
          Logger.error("Twitch API error: #{status} - #{inspect(body)}")
          {:error, :api_error}

        {:error, reason} ->
          Logger.error("Twitch API request failed: #{inspect(reason)}")
          {:error, :request_failed}
      end
    end
  end

  def get_user_by_login(login_name) do
    config = Application.get_env(:clippex, :twitch)
    client_id = config[:client_id]
    access_token = config[:access_token]

    if is_nil(client_id) or is_nil(access_token) do
      {:error, :missing_credentials}
    else
      req =
        Req.new(base_url: @base_url)
        |> Req.Request.put_header("Client-Id", client_id)
        |> Req.Request.put_header("Authorization", "Bearer #{access_token}")

      case Req.get(req, url: "/users", params: [login: login_name]) do
        {:ok, %Req.Response{status: 200, body: %{"data" => [user | _]}}} ->
          {:ok, user}

        {:ok, %Req.Response{status: 200, body: %{"data" => []}}} ->
          {:error, :not_found}

        {:ok, %Req.Response{status: status, body: body}} ->
          Logger.error("Twitch API error: #{status} - #{inspect(body)}")
          {:error, :api_error}

        {:error, reason} ->
          Logger.error("Twitch API request failed: #{inspect(reason)}")
          {:error, :request_failed}
      end
    end
  end

  def get_clips_by_username(username) do
    case get_user_by_login(username) do
      {:ok, %{"id" => user_id}} ->
        get_clips(user_id)

      error ->
        error
    end
  end

  def get_download_url(clip_id, broadcaster_id, editor_id) do
    config = Application.get_env(:clippex, :twitch)
    client_id = config[:client_id]
    access_token = config[:access_token]

    if is_nil(client_id) or is_nil(access_token) do
      {:error, :missing_credentials}
    else
      req =
        Req.new(base_url: @base_url)
        |> Req.Request.put_header("Client-Id", client_id)
        |> Req.Request.put_header("Authorization", "Bearer #{access_token}")

      params = [
        clip_id: clip_id,
        broadcaster_id: broadcaster_id,
        editor_id: editor_id
      ]

      case Req.get(req, url: "/clips/downloads", params: params) do
        {:ok, %Req.Response{status: 200, body: %{"data" => [data | _]}}} ->
          {:ok, data["download_url"]}

        {:ok, %Req.Response{status: status, body: body}} ->
          Logger.error("Twitch Download API error: #{status} - #{inspect(body)}")
          {:error, :api_error}

        {:error, reason} ->
          Logger.error("Twitch Download API request failed: #{inspect(reason)}")
          {:error, :request_failed}
      end
    end
  end

  def get_app_access_token do
    config = Application.get_env(:clippex, :twitch)
    client_id = config[:client_id]
    client_secret = config[:client_secret]

    if is_nil(client_id) or is_nil(client_secret) do
      {:error, :missing_credentials}
    else
      params = [
        client_id: client_id,
        client_secret: client_secret,
        grant_type: "client_credentials"
      ]

      case Req.post("https://id.twitch.tv/oauth2/token", form: params) do
        {:ok,
         %Req.Response{
           status: 200,
           body: %{"access_token" => token, "token_type" => "bearer", "expires_in" => expires_in}
         }} ->
          Logger.info("Twitch Auth success: #{token} expires in #{expires_in}")
          {:ok, token}

        {:ok, %Req.Response{status: status, body: body}} ->
          Logger.error("Twitch Auth error: #{status} - #{inspect(body)}")
          {:error, :auth_failed}

        {:error, reason} ->
          Logger.error("Twitch Auth request failed: #{inspect(reason)}")
          {:error, :request_failed}
      end
    end
  end
end
