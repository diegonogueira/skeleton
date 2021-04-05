defmodule SkeletonLegacy.Resolver do
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
    permission: %{
      ids: [],
      checks: []
    }

  defmacro __using__(opts) do
    quote do
      import SkeletonLegacy.Resolver

      def build(module, action, args, info) do
        %SkeletonLegacy.Resolver{
          helper: unquote(opts[:helper]),
          module: module,
          action: action,
          args: args,
          context: info.context,
          definition: info.definition,
          resource: nil,
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

  # Put source and resource

  def put_source(resolver, func \\ nil)
  def put_source(%{halted: true} = resolver, _), do: resolver
  def put_source(resolver, nil), do: put_source(resolver, &resolver.module._source/1)
  def put_source(resolver, func), do: put_source_or_resource(resolver, :source, func.(resolver))

  def put_resource(resolver, func \\ nil)
  def put_resource(%{halted: true} = resolver, _), do: resolver
  def put_resource(resolver, nil), do: put_resource(resolver, &resolver.module._resource/1)
  def put_resource(resolver, func), do: put_source_or_resource(resolver, :resource, func.(resolver))

  def put_source_or_resource(resolver, name, nil) do
    put_error(resolver, "#{to_string(name)} not found")
  end
  def put_source_or_resource(resolver, name, data) do
    Map.put(resolver, name, data)
  end

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
    {:ok, resource} =
      resolver
      |> put_output(callback.(resolver))
      |> resolver.helper._after_resolve_mutation()

    key = get_module_name(resource)

    {:ok, %{key => resource}}
  end

  defp get_module_name(struct) do
    struct.__struct__
    |> Macro.underscore()
    |> String.split("/")
    |> List.last()
    |> String.to_atom()
  end

  # Permission

  def check_source_permission(%{halted: true} = resolver, _), do: resolver
  def check_source_permission(resolver, check) do
    ensure_permission(resolver, resolver.module._source_permission(resolver), check)
  end

  def check_resource_permission(%{halted: true} = resolver, _), do: resolver
  def check_resource_permission(resolver, check) do
    ensure_permission(resolver, resolver.module._resource_permission(resolver), check)
  end

  defp ensure_permission(resolver, permission_module, check) do
    ensure_permission(resolver, permission_module, check, nil)
  end
  defp ensure_permission(resolver, permission_module, check, id) do
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
      |> permission_module.preload()
      |> List.first()

    if permission_module.check(check, preloaded, resolver) do
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
