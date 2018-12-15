defmodule Skeleton.Service do
  alias Ecto.Multi

  defmacro __using__(opts \\ []) do
    alias Skeleton.Service, as: Serv

    quote do
      alias Ecto.Multi

      @repo unquote(opts[:repo])

      def begin_transaction(service), do: Serv.begin_transaction(service)

      def run(multi, name, fun), do: Serv.run(multi, name, fun)

      def commit_transaction(multi), do: Serv.commit_transaction(multi, @repo)

      def commit_transaction_and_return(multi, resource_name),
        do: Serv.commit_transaction_and_return(multi, resource_name, @repo)
    end
  end

  def begin_transaction(service) do
    run(Multi.new(), :service, &init(&1, &2, service))
  end

  def run(multi, name, fun) do
    Multi.run(multi, name, fun)
  end

  def commit_transaction(multi, repo) do
    repo.transaction(multi)
  end

  def commit_transaction_and_return(multi, resource_name, repo) do
    multi
    |> commit_transaction(repo)
    |> case do
      {:ok, %{^resource_name => resource}} -> {:ok, resource}
      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def init(_repo, _changes, service), do: {:ok, service}
end
