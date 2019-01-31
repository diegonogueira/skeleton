defmodule Skeleton.Service do
  alias Ecto.Multi

  defmacro __using__(opts \\ []) do
    alias Skeleton.Service, as: Serv

    quote do
      alias Ecto.Multi

      @repo unquote(opts[:repo])
      @ecto_version unquote(opts[:ecto_version])

      def begin_transaction(service), do: Serv.begin_transaction(@ecto_version, service)

      def run(multi, name, fun), do: Serv.run(multi, name, fun)

      def commit_transaction(multi), do: Serv.commit_transaction(multi, @repo)

      def commit_transaction_and_return(multi, func) when is_function(func, 1),
        do: Serv.commit_transaction_and_return(multi, func, @repo)

      def commit_transaction_and_return(multi, resource_name),
        do: Serv.commit_transaction_and_return(multi, resource_name, @repo)
    end
  end

  # For Ecto 2
  def begin_transaction("2", service) do
    run(Multi.new(), :service, fn _changes -> {:ok, service} end)
  end

  # For latest Ecto
  def begin_transaction(_, service) do
    run(Multi.new(), :service, fn _repo, _changes -> {:ok, service} end)
  end

  def run(multi, name, fun) do
    Multi.run(multi, name, fun)
  end

  def commit_transaction(multi, repo) do
    repo.transaction(multi)
  end

  def commit_transaction_and_return(multi, func, repo) when is_function(func) do
    multi
    |> commit_transaction(repo)
    |> case do
      {:ok, _} -> {:ok, func.(multi)}
      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def commit_transaction_and_return(multi, resource_name, repo) do
    multi
    |> commit_transaction(repo)
    |> case do
      {:ok, %{^resource_name => resource}} -> {:ok, resource}
      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  # def init(_repo, _changes, service), do: {:ok, service}
end
