defmodule Mix.Tasks.Skeleton.Gen.Query do
  use Mix.Task
  import Macro, only: [camelize: 1, underscore: 1]
  import Mix.Generator

  def run(args) do
    {_opts, [lib_name, resource, plural_name | _inputs], _} = OptionParser.parse(args, switches: [])

    [context, singular_name] = String.split(resource, "/")

    generate_query(lib_name, context, singular_name, plural_name)
    generate_query_test(lib_name, context, singular_name)
  end

  defp generate_query(lib_name, context, singular_name, plural_name) do
    path = "lib/#{underscore(lib_name)}/#{context}/#{singular_name}"
    base_name = "#{underscore(singular_name)}_query.ex"
    file = Path.join(path, base_name)

    create_directory(path)

    contexts = [
      lib_name: camelize(lib_name),
      context: camelize(context),
      mod: camelize(singular_name),
      singular_name: underscore(singular_name),
      plural_name: underscore(plural_name)
    ]

    create_file(file, query_template(contexts))
  end

  defp generate_query_test(lib_name, context, singular_name) do
    path = "test/#{underscore(lib_name)}/#{context}/#{singular_name}"
    base_name = "#{underscore(singular_name)}_query_test.exs"
    file = Path.join(path, base_name)

    create_directory(path)

    contexts = [
      lib_name: camelize(lib_name),
      context: camelize(context),
      mod: camelize(singular_name),
      singular_name: underscore(singular_name)
    ]
    create_file(file, query_test_template(contexts))
  end

  # Templates

  embed_template(:query, """
  defmodule <%= @lib_name %>.<%= @context %>.<%= @mod %>Query do
    use <%= @lib_name %>.Query, struct: <%= @lib_name %>.<%= @context %>.<%= @mod %>, assoc: :<%= @plural_name %>

    # Filters

    def filter_by(query, {:id, id}, _args) do
      where(query, id: ^id)
    end

    def filter_by(query, {:ids, ids}, _args) do
      where(query, [<%= String.first(@singular_name) %>], <%= String.first(@singular_name) %>.id in ^ids)
    end

    def filter_by(query, {:user_id, user_id}, _args) do
      where(query, user_id: ^user_id)
    end

    def filter_by(query, _, _args), do: query

    # Sort

    def sort_by(query, _, _args), do: query
  end
  """)

  embed_template(:query_test, """
  defmodule <%= @lib_name %>.<%= @context %>.<%= @mod %>QueryTest do
    use <%= @lib_name %>.ModelCase
    alias <%= @lib_name %>.Query
    alias <%= @lib_name %>.<%= @context %>.<%= @mod %>Query

    setup context do
      <%= @singular_name %> = insert(:<%= @singular_name %>)
      user = insert(:user)

      context
      |> Map.put(:<%= @singular_name %>, <%= @singular_name %>)
      |> Map.put(:user, user)
    end

    # Filters

    test "search filtering by id", context do
      [<%= @singular_name %>] = %Query{params: %{id: context.<%= @singular_name %>.id}} |> <%= @mod %>Query.all
      assert <%= @singular_name %>.id == context.<%= @singular_name %>.id
    end

    test "search filtering by ids", context do
      [<%= @singular_name %>] = %Query{params: %{ids: [context.<%= @singular_name %>.id]}} |> <%= @mod %>Query.all
      assert <%= @singular_name %>.id == context.<%= @singular_name %>.id
    end

    test "search filtering by user_id", context do
      [<%= @singular_name %>] = %Query{current_user: context.user} |> <%= @mod %>Query.all
      assert <%= @singular_name %>.id == context.<%= @singular_name %>.id
    end
  end
  """)
end
