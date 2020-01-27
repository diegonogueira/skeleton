defmodule Skeleton.Resolver do
  defstruct helper: nil,
    module: nil,
    action: nil,
    args: %{},
    context: nil,
    definition: nil,
    source: nil,
    resource: nil,
    output: nil,
    halted: false,
    error: nil,
    request_datetime: nil,
    permission: %{
      ids: [],
      checks: []
    }

  defmacro __using__(opts) do
    quote do
      import Skeleton.Resolver

      def build(module, action, args, info) do
        %Skeleton.Resolver{
          helper: unquote(opts[:helper]),
          module: module,
          action: action,
          args: args,
          context: info.context,
          source: info.source,
          definition: info.definition,
          request_datetime: NaiveDateTime.utc_now,
          permission: %{
            ids: [],
            checks: []
          }
        }
      end

      def perform(action, args, info) do
        resolver =
          __MODULE__
          |> build(action, args, info)
          |> unquote(opts[:helper])._before_perform()

        apply(__MODULE__, action, [resolver])
      end
    end
  end

  # Ensure authenticated

  def ensure_authenticated(%{halted: true} = resolver), do: resolver
  def ensure_authenticated(resolver), do: resolver.helper._ensure_authenticated(resolver)

  # Ensure unauthenticated

  def ensure_not_authenticated(%{halted: true} = resolver), do: resolver
  def ensure_not_authenticated(resolver), do: resolver.helper._ensure_not_authenticated(resolver)

  # Resolve query

  def resolve_query(%{halted: true} = resolver, _), do: {:error, resolver.error}
  def resolve_query(resolver, callback) do
    output =
      resolver
      |> put_output(callback.(resolver))
      |> resolver.helper._after_resolve_query()

    {:ok, output}
  end

  # Resolve mutation

  def resolve_mutation(%{halted: true} = resolver, _), do: {:error, resolver.error}
  def resolve_mutation(resolver, callback) do
    resolver
    |> put_output(callback.(resolver))
    |> resolver.helper._after_resolve_mutation()
  end

  # Permission

  def check_permission(%{halted: true} = resolver, _, _), do: resolver
  def check_permission(resolver, permission, check) do
    ensure_permission(resolver, permission, check)
  end

  defp ensure_permission(resolver, permission, check) do
    ensure_permission(resolver, permission, check, nil)
  end
  defp ensure_permission(resolver, permission, check, id) do
    data = resolver.resource || resolver.source || %{}

    # TODO: Tratar para esses casos
    # def preload_data(resolver) do
    #   case resolver.permission.ids do
    #     nil -> []
    #     [nil] -> []
    #     _ -> do_preload(resolver)
    #   end
    # end

    resolver = put_in(resolver.permission.checks, [check])
    resolver = put_in(resolver.permission.ids, [id || Map.get(data, :id)])

    preloaded =
      resolver
      |> permission.preload()
      |> List.first()

    if permission.check(check, preloaded, resolver) do
      resolver
    else
      put_error(resolver, "not authorized")
    end
  end

  # Helpers

  def put_error(resolver, error) do
    resolver
    |> Map.put(:halted, true)
    |> Map.put(:error, error)
  end

  def put_output(resolver, output) do
    Map.put(resolver, :output, output)
  end
end
