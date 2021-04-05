defmodule Mix.Tasks.SkeletonLegacy.Gen.Permission do
  use Mix.Task
  import Macro, only: [camelize: 1, underscore: 1]
  import Mix.Generator

  def run(args) do
    {_opts, [lib_name, resource, plural_name | _inputs], _} = OptionParser.parse(args, switches: [])

    resource_list = String.split(resource, "/")
    [context, singular_name] = Enum.take(resource_list, -2)

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

  try do
    embed_template(:permission, from_file: Path.expand("../../../../../lib/mix/tasks/skeleton_legacy_templates/permission/permission_template.eex", __DIR__))
  rescue
    _ ->

    embed_template(:permission, """
    defmodule <%= @lib_name %>Web.<%= @mod %>Permission do
      use <%= @lib_name %>Web.Permission
      alias Campainha.{Repo, <%= @context %>.<%= @mod %>}

      def check(_, _<%= @singular_name %>, permission) do
        true
      end
    end
    """)
  end

  try do
    embed_template(:permission_test, from_file: Path.expand("../../../../../lib/mix/tasks/skeleton_legacy_templates/permission/permission_test_template.eex", __DIR__))
  rescue
    _ ->

    embed_template(:permission_test, """
    defmodule <%= @lib_name %>Web.<%= @mod %>PermissionTest do
      use <%= @lib_name %>Web.ConnCase
    end
    """)
  end
end
