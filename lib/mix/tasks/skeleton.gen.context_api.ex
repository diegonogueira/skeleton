defmodule Mix.Tasks.Skeleton.Gen.ContextAPI do
  use Mix.Task
  import Macro, only: [camelize: 1, underscore: 1]
  import Mix.Generator

  def run(args) do
    {_opts, [lib_name, resource, plural_name | _inputs], _} = OptionParser.parse(args, switches: [])

    resource_list = String.split(resource, "/")
    [context, singular_name] = Enum.take(resource_list, -2)

    generate_context(lib_name, context, singular_name, plural_name)
  end

  defp generate_context(lib_name, context, singular_name, plural_name) do
    path = "lib/#{underscore(lib_name)}/#{context}/"
    base_name = "#{underscore(context)}.ex"
    file = Path.join(path, base_name)

    create_directory(path)

    contexts =
      [
        lib_name: camelize(lib_name),
        mod: camelize(singular_name),
        context: camelize(context),
        singular_name: underscore(singular_name),
        plural_name: underscore(plural_name)
      ]

    create_file(file, context_template(contexts))
  end

  # Templates

  embed_template(:context, """
  defmodule <%= @lib_name %>.<%= @context %> do
    import Ecto.Changeset
    alias App.<%= @context %>.{<%= @mod %>, <%= @mod %>Create, <%= @mod %>Update, <%= @mod %>Delete}

    def get_<%= @singular_name %>!(id) do
      <%= @lib_name %>.Repo.get!(<%= @mod %>, id)
    end

    def list_<%= @plural_name %>() do
      <%= @lib_name %>.Repo.all(<%= @mod %>)
    end

    def change_<%= @singular_name %>(%<%= @mod %>{} = <%= @singular_name %>) do
      change(<%= @singular_name %>, %{})
    end

    def create_<%= @singular_name %>(%{assigns: %{current_user: user}}, params) do
      struct = %<%= @mod %>Create{current_user: user, params: params}
      <%= @mod %>Create.perform(struct)
    end

    def update_<%= @singular_name %>(%{assigns: %{resource: <%= @singular_name %>, current_user: user}}, params) do
      struct = %<%= @mod %>Update{current_user: user, resource: <%= @singular_name %>, params: params}
      <%= @mod %>Update.perform(struct)
    end

    def delete_<%= @singular_name %>(<%= @singular_name %>) do
      struct = %<%= @mod %>Delete{resource: <%= @singular_name %>}
      <%= @mod %>Delete.perform(struct)
    end
  end
  """)
end
