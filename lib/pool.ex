defmodule HarfbuzzEx.Pool do
  @moduledoc """
  A NimblePool for concurrent Harfbuzz text shaping.
  """
  @behaviour NimblePool

  # --- Public API ---

  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :name, __MODULE__),
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    pool_size = Keyword.get(opts, :pool_size, System.schedulers_online())

    NimblePool.start_link(
      worker: {__MODULE__, opts},
      pool_size: pool_size,
      name: name
    )
  end

  @doc """
  Check out a Shaper resource to shape text, executing in the calling process.
  """
  def shape(pool_name, text) do
    NimblePool.checkout!(pool_name, :checkout, fn _pool_pid, resource ->
      result = HarfbuzzEx.Native.shaper_shape(resource, text)
      # NimblePool expects {return_value, state_to_checkin}
      {{:ok, result}, resource}
    end)
  end

  def shape!(pool_name, text) do
    {:ok, results} = shape(pool_name, text)
    results
  end

  def shape!(pool_name, text, data) when data in [:name, :x_advance, :y_advance, :x_offset, :y_offset] do
    shape!(pool_name, text)
    |> Enum.map(&Map.get(&1, data))
  end

  def shape(pool_name, text, data) when data in [:name, :x_advance, :y_advance, :x_offset, :y_offset] do
    {:ok, shape!(pool_name, text, data)}
  end

  # --- NimblePool Callbacks ---

  @impl NimblePool
  def init_worker(pool_state) do
    font_path = Keyword.fetch!(pool_state, :font_path)

    case HarfbuzzEx.Native.shaper_new(font_path) do
      {:error, reason} -> {:error, reason}
      # Returns {:ok, worker_state, pool_state}
      resource -> {:ok, resource, pool_state}
    end
  end

  @impl NimblePool
  def handle_checkout(:checkout, _from, resource, pool_state) do
    # Returns {:ok, client_state, worker_state, pool_state}
    {:ok, resource, resource, pool_state}
  end

  @impl NimblePool
  def handle_checkin(_client_state, _from, resource, pool_state) do
    {:ok, resource, pool_state}
  end

  @impl NimblePool
  def terminate_worker(_reason, _resource, _pool_state) do
    :ok
  end
end
