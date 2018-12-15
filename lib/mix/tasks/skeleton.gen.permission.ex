defmodule Mix.Tasks.Skeleton.Gen.Permission do
  use Mix.Task
  import Macro, only: [camelize: 1, underscore: 1]
  import Mix.Generator

  def run(args) do
    {_opts, [lib_name, resource, plural_name | _inputs], _} = OptionParser.parse(args, switches: [])

    [context, singular_name] = String.split(resource, "/")

    generate_permission(lib_name, context, singular_name, plural_name)
    generate_permission_test(lib_name, context, singular_name)
  end

  defp generate_permission(lib_name, context, singular_name, plural_name) do
    path = "lib/#{underscore(lib_name)}_web/permissions/#{context}"
    base_name = "#{underscore(singular_name)}_permission.ex"
    file = Path.join(path, base_name)

    create_directory(path)

    contexts = [
      lib_name: camelize(lib_name),
      context: camelize(context),
      mod: camelize(singular_name),
      singular_name: underscore(singular_name),
      plural_name: underscore(plural_name)
    ]

    create_file(file, permission_template(contexts))
  end

  defp generate_permission_test(lib_name, context, singular_name) do
    path = "test/#{underscore(lib_name)}_web/permissions/#{context}"
    base_name = "#{underscore(singular_name)}_permission_test.exs"
    file = Path.join(path, base_name)

    create_directory(path)

    contexts = [
      lib_name: camelize(lib_name),
      context: camelize(context),
      mod: camelize(singular_name),
      singular_name: underscore(singular_name)
    ]

    create_file(file, permission_test_template(contexts))
  end

  # Templates

  embed_template(:permission, """
  defmodule <%= @lib_name %>Web.<%= @mod %>Permission do
    use <%= @lib_name %>Web.Permission
    alias Campainha.{Repo, <%= @context %>.<%= @mod %>}

    def check(_, _<%= @singular_name %>, permission) do
      true
    end
  end
  """)

  embed_template(:permission_test, """
  defmodule <%= @lib_name %>Web.<%= @mod %>PermissionTest do
    use <%= @lib_name %>Web.ConnCase
  end
  """)
end
