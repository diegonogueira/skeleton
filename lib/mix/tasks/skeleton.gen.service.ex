defmodule Mix.Tasks.Skeleton.Gen.Service do
  use Mix.Task
  import Macro, only: [camelize: 1, underscore: 1]
  import Mix.Generator

  @switches [polymorphic: :boolean]

  def run(args) do
    {opts, [lib_name, resource, plural_name, action | inputs], _} = OptionParser.parse(args, switches: @switches)

    [context, singular_name] = String.split(resource, "/")

    inputs =
      inputs
      |> parse_inputs()
      |> generate_field_type()

    generate_service(lib_name, context, singular_name, plural_name, action, inputs, opts)
    generate_service_test(lib_name, context, singular_name, plural_name, action, inputs, opts)
  end

  defp generate_service(lib_name, context, singular_name, plural_name, action, inputs, opts) do
    path = "lib/#{underscore(lib_name)}/#{context}/#{singular_name}"
    base_name = "#{underscore(singular_name)}_#{underscore(action)}.ex"
    file = Path.join(path, base_name)

    create_directory(path)

    contexts = [
      lib_name: camelize(lib_name),
      context: camelize(context),
      mod: "#{camelize(singular_name)}#{camelize(action)}",
      singular_name: underscore(singular_name),
      plural_name: underscore(plural_name),
      action: underscore(action),
      inputs: inputs
    ]

    case action do
      "create" ->
        if opts[:polymorphic] do
          create_file(file, service_create_polymorphic_template(contexts))
        else
          create_file(file, service_create_template(contexts))
        end

      "update" ->
        create_file(file, service_update_template(contexts))

      "delete" ->
        create_file(file, service_delete_template(contexts))

      _ ->
        create_file(file, service_custom_template(contexts))
    end
  end

  defp generate_service_test(lib_name, context, singular_name, plural_name, action, inputs, opts) do
    path = "test/#{underscore(lib_name)}/#{context}/#{singular_name}"
    base_name = "#{underscore(singular_name)}_#{underscore(action)}_test.exs"
    file = Path.join(path, base_name)

    create_directory(path)

    contexts = [
      lib_name: camelize(lib_name),
      context: camelize(context),
      mod: "#{camelize(singular_name)}#{camelize(action)}",
      singular_name: underscore(singular_name),
      plural_name: underscore(plural_name),
      action: underscore(action),
      inputs: inputs
    ]

    case action do
      "create" ->
        if opts[:polymorphic] do
          create_file(file, service_create_polymorphic_test_template(contexts))
        else
          create_file(file, service_create_test_template(contexts))
        end

      "update" ->
        create_file(file, service_update_test_template(contexts))

      "delete" ->
        create_file(file, service_delete_test_template(contexts))

      _ ->
        create_file(file, service_custom_test_template(contexts))
    end
  end

  # Templates

  try do
    embed_template(:service_create, from_file: Path.expand("../../../../../lib/mix/tasks/skeleton_templates/service/service_create_template.eex", __DIR__))
  rescue
    _ ->

    embed_template(:service_create, """
    defmodule <%= @lib_name %>.<%= @context %>.<%= @mod %> do
      use <%= @lib_name %>.Service
      alias <%= @lib_name %>.<%= @context %>.<%= @mod %>
      alias <%= @lib_name %>.<%= @context %>.<%= camelize(@singular_name) %>

      @enforce_keys [:current_user, :params]
      defstruct current_user: nil, params: %{}

      def perform(%<%= @mod %>{} = service) do
        service
        |> begin_transaction()
        |> run(:<%= @singular_name %>, &create_<%= @singular_name %>/1)
        |> commit_transaction_and_return(:<%= @singular_name %>)
      end

      # Changeset

      defp changeset(struct, params) do
        struct
        |> cast(params, [<%= @inputs |> Map.keys() |> Enum.map(&(":"<>&1)) |> Enum.join(", ") %>])
        |> validate_required([<%= @inputs |> Map.keys() |> Enum.map(&(":"<>&1)) |> Enum.join(", ") %>])
      end

      # Create <%= @singular_name %>

      defp create_<%= @singular_name %>(%{service: service}) do
        %<%= camelize(@singular_name) %>{}
        |> Map.put(:user_id, service.current_user.id)
        |> changeset(service.params)
        |> Repo.insert()
      end
    end
    """)
  end

  try do
    embed_template(:service_create_polymorphic, from_file: Path.expand("../../../../../lib/mix/tasks/skeleton_templates/service/service_create_polymorphic_template.eex", __DIR__))
  rescue
    _ ->

    embed_template(:service_create_polymorphic, """
    defmodule <%= @lib_name %>.<%= @context %>.<%= @mod %> do
      use <%= @lib_name %>.Service
      alias <%= @lib_name %>.<%= @context %>.<%= @mod %>

      @enforce_keys [:current_user, :source, :params]
      defstruct current_user: nil, source: nil, params: %{}

      def perform(%<%= @mod %>{} = service) do
        service
        |> begin_transaction()
        |> run(:<%= @singular_name %>, &create_<%= @singular_name %>/1)
        |> commit_transaction_and_return(:<%= @singular_name %>)
      end

      # Changeset

      defp changeset(struct, params) do
        struct
        |> cast(params, [<%= @inputs |> Map.keys() |> Enum.map(&(":"<>&1)) |> Enum.join(", ") %>])
        |> validate_required([<%= @inputs |> Map.keys() |> Enum.map(&(":"<>&1)) |> Enum.join(", ") %>])
      end

      # Create <%= @singular_name %>

      defp create_<%= @singular_name %>(%{service: service}) do
        service.source
        |> Ecto.build_assoc(:<%= @plural_name %>)
        |> Map.put(:user_id, service.current_user.id)
        |> changeset(service.params)
        |> Repo.insert()
      end
    end
    """)
  end

  try do
    embed_template(:service_update, from_file: Path.expand("../../../../../lib/mix/tasks/skeleton_templates/service/service_update_template.eex", __DIR__))
  rescue
    _ ->

    embed_template(:service_update, """
    defmodule <%= @lib_name %>.<%= @context %>.<%= @mod %> do
      use <%= @lib_name %>.Service
      alias <%= @lib_name %>.<%= @context %>.<%= @mod %>

      @enforce_keys [:current_user, :resource, :params]
      defstruct current_user: nil, resource: nil, params: %{}

      def perform(%<%= @mod %>{} = service) do
        service
        |> begin_transaction()
        |> run(:<%= @singular_name %>, &update_<%= @singular_name %>/1)
        |> commit_transaction_and_return(:<%= @singular_name %>)
      end

      # Changeset

      defp changeset(struct, params) do
        struct
        |> cast(params, [<%= @inputs |> Map.keys() |> Enum.map(&(":"<>&1)) |> Enum.join(", ") %>])
        |> validate_required([<%= @inputs |> Map.keys() |> Enum.map(&(":"<>&1)) |> Enum.join(", ") %>])
      end

      # Update <%= @singular_name %>

      defp update_<%= @singular_name %>(%{service: service}) do
        service.resource
        |> changeset(service.params)
        |> Repo.update()
      end
    end
    """)
  end

  try do
    embed_template(:service_custom, from_file: Path.expand("../../../../../lib/mix/tasks/skeleton_templates/service/service_custom_template.eex", __DIR__))
  rescue
    _ ->

    embed_template(:service_custom, """
    defmodule <%= @lib_name %>.<%= @context %>.<%= @mod %> do
      use <%= @lib_name %>.Service
      alias <%= @lib_name %>.<%= @context %>.<%= @mod %>

      @enforce_keys [:current_user, :resource, :params]
      defstruct current_user: nil, resource: nil, params: %{}

      def perform(%<%= @mod %>{} = service) do
        service
        |> begin_transaction()
        |> run(:<%= @singular_name %>, &<%= @action %>_<%= @singular_name %>/1)
        |> commit_transaction_and_return(:<%= @singular_name %>)
      end

      # Changeset

      defp changeset(struct, params) do
        struct
        |> cast(params, [<%= @inputs |> Map.keys() |> Enum.map(&(":"<>&1)) |> Enum.join(", ") %>])
        |> validate_required([<%= @inputs |> Map.keys() |> Enum.map(&(":"<>&1)) |> Enum.join(", ") %>])
      end

      # <%= camelize(@action) %> <%= @singular_name %>

      defp <%= @action %>_<%= @singular_name %>(%{service: service}) do
        service.resource
        |> changeset(service.params)
        |> Repo.update()
      end
    end
    """)
  end

  try do
    embed_template(:service_delete, from_file: Path.expand("../../../../../lib/mix/tasks/skeleton_templates/service/service_delete_template.eex", __DIR__))
  rescue
    _ ->

    embed_template(:service_delete, """
    defmodule <%= @lib_name %>.<%= @context %>.<%= @mod %> do
      use <%= @lib_name %>.Service
      alias <%= @lib_name %>.<%= @context %>.<%= @mod %>

      @enforce_keys [:current_user, :resource]
      defstruct current_user: nil, resource: nil

      def perform(%<%= @mod %>{} = service) do
        service
        |> begin_transaction()
        |> run(:<%= @singular_name %>, &delete_<%= @singular_name %>/1)
        |> commit_transaction_and_return(:<%= @singular_name %>)
      end

      def perform_each(service) do
        service.resource
        |> Ecto.assoc(:<%= @plural_name %>)
        |> Repo.all
        |> Enum.each(fn <%= @singular_name %> ->
          %<%= @mod %>{
            current_company: service.current_company,
            current_profile: service.current_profile,
            resource: <%= @singular_name %>
          }
          |> perform
        end)

        {:ok, nil}
      end

      # Delete <%= @singular_name %>

      defp delete_<%= @singular_name %>(%{service: service}) do
        Repo.delete(service.resource)
      end
    end
    """)
  end

  try do
    embed_template(:service_create, from_file: Path.expand("../../../../../lib/mix/tasks/skeleton_templates/service/service_create_test_template.eex", __DIR__))
  rescue
    _ ->

    embed_template(:service_create_test, """
    defmodule <%= @lib_name %>.<%= @context %>.<%= @mod %>Test do
      use <%= @lib_name %>.ModelCase
      alias <%= @lib_name %>.<%= @context %>.<%= @mod %>

      setup context do
        service =
          %<%= @mod %>{
            current_company: context.company,
            current_profile: context.profile,
            params: %{<%= for field <- Map.keys(@inputs) do %>
              <%= field %>: nil<% end %>
            }
          }

        context
        |> Map.put(:service, service)
      end

      # Changeset

      <%= for field <- Map.keys(@inputs) do %>
      test "changeset does not accept blank <%= field %>", context do
        service = Map.put(context.service, :params, %{context.service.params | <%= field %>: ""})
        {:error, changeset} = <%= @mod %>.perform(service)
        assert changeset.errors == [{:<%= field %>, {"can't be blank", [validation: :required]}}]
      end
      <% end %>

      # Create <%= @singular_name %>

      test "creates <%= @singular_name %>", context do
        {:ok, <%= @singular_name %>} = <%= @mod %>.perform(context.service)
        assert <%= @singular_name %>.id
      end
    end
    """)
  end

  try do
    embed_template(:service_create_polymorphic_test, from_file: Path.expand("../../../../../lib/mix/tasks/skeleton_templates/service/service_create_polymorphic_test_template.eex", __DIR__))
  rescue
    _ ->

    embed_template(:service_create_polymorphic_test, """
    defmodule <%= @lib_name %>.<%= @context %>.<%= @mod %>Test do
      use <%= @lib_name %>.ModelCase
      alias <%= @lib_name %>.<%= @context %>.<%= @mod %>

      setup context do
        source = insert(:source)
        user = insert(:account)

        service =
          %<%= @mod %>{
            current_user: user,
            source: source,
            params: %{<%= for field <- Map.keys(@inputs) do %>
              <%= field %>: nil<% end %>
            }
          }

        context
        |> Map.put(:<%= @singular_name %>, <%= @singular_name %>)
        |> Map.put(:service, service)
      end

      # Changeset

      <%= for field <- Map.keys(@inputs) do %>
      test "changeset does not accept blank <%= field %>", context do
        service = Map.put(context.service, :params, %{context.service.params | <%= field %>: ""})
        {:error, changeset} = <%= @mod %>.perform(service)
        assert changeset.errors == [{:<%= field %>, {"can't be blank", [validation: :required]}}]
      end
      <% end %>

      # Create <%= @singular_name %>

      test "creates <%= @singular_name %>", context do
        {:ok, <%= @singular_name %>} = <%= @mod %>.perform(context.service)
        assert <%= @singular_name %>.id
      end

      test "returns error and changeset when create <%= @singular_name %> with invalid", context do
        service = Map.put(context.service, :params, %{FIELD: ""})
        assert {:error, _changeset} = <%= @mod %>.perform(service)
      end
    end
    """)
  end

  try do
    embed_template(:service_update_test, from_file: Path.expand("../../../../../lib/mix/tasks/skeleton_templates/service/service_update_test_template.eex", __DIR__))
  rescue
    _ ->

  embed_template(:service_update_test, """
    defmodule <%= @lib_name %>.<%= @context %>.<%= @mod %>Test do
      use <%= @lib_name %>.ModelCase
      alias <%= @lib_name %>.<%= @context %>.<%= @mod %>

      setup context do
        <%= @singular_name %> = insert(:<%= @singular_name %>)
        user = insert(:account)

        service =
          %<%= @mod %>{
            current_user: user,
              resource: <%= @singular_name %>,
            params: %{<%= for field <- Map.keys(@inputs) do %>
              <%= field %>: nil<% end %>
            }
          }

        context
        |> Map.put(:<%= @singular_name %>, <%= @singular_name %>)
        |> Map.put(:service, service)
      end

      # Changeset

      <%= for field <- Map.keys(@inputs) do %>
      test "changeset does not accept blank <%= field %>", context do
        service = Map.put(context.service, :params, %{context.service.params | <%= field %>: ""})
        {:error, changeset} = <%= @mod %>.perform(service)
        assert changeset.errors == [{:<%= field %>, {"can't be blank", [validation: :required]}}]
      end
      <% end %>

      # Update <%= @singular_name %>

      test "updates <%= @singular_name %>", context do
        {:ok, <%= @singular_name %>} = <%= @mod %>.perform(context.service)
        assert <%= @singular_name %>.id
      end

      test "returns error and changeset when updates <%= @singular_name %> with invalid", context do
        service = Map.put(context.service, :params, %{FIELD: ""})
        assert {:error, _changeset} = <%= @mod %>.perform(service)
      end
    end
    """)
  end

  try do
    embed_template(:service_custom_test, from_file: Path.expand("../../../../../lib/mix/tasks/skeleton_templates/service/service_custom_test_template.eex", __DIR__))
  rescue
    _ ->

  embed_template(:service_custom_test, """
    defmodule <%= @lib_name %>.<%= @context %>.<%= @mod %>Test do
      use <%= @lib_name %>.ModelCase
      alias <%= @lib_name %>.<%= @context %>.<%= @mod %>

      setup context do
        <%= @singular_name %> = insert(:<%= @singular_name %>)
        user = insert(:account)

        service =
          %<%= @mod %>{
              current_user: user,
            resource: <%= @singular_name %>,
            params: %{<%= for field <- Map.keys(@inputs) do %>
              <%= field %>: nil<% end %>
            }
          }

        context
        |> Map.put(:<%= @singular_name %>, <%= @singular_name %>)
        |> Map.put(:service, service)
      end

      # Changeset

      <%= for field <- Map.keys(@inputs) do %>
      test "changeset does not accept blank <%= field %>", context do
        service = Map.put(context.service, :params, %{context.service.params | <%= field %>: ""})
        {:error, changeset} = <%= @mod %>.perform(service)
        assert changeset.errors == [{:<%= field %>, {"can't be blank", [validation: :required]}}]
      end
      <% end %>

      # <%= camelize(@action) %> <%= @singular_name %>

      test "<%= @action %>s <%= @singular_name %>", context do
        {:ok, <%= @singular_name %>} = <%= @mod %>.perform(context.service)
        assert <%= @singular_name %>.id
      end

      test "returns error and changeset when <%= @action %> <%= @singular_name %> with invalid", context do
        service = Map.put(context.service, :params, %{FIELD: ""})
        assert {:error, _changeset} = <%= @mod %>.perform(service)
      end
    end
    """)
  end

  try do
    embed_template(:service_delete_test, from_file: Path.expand("../../../../../lib/mix/tasks/skeleton_templates/service/service_delete_test_template.eex", __DIR__))
  rescue
    _ ->

    embed_template(:service_delete_test, """
    defmodule <%= @lib_name %>.<%= @context %>.<%= @mod %>Test do
      use <%= @lib_name %>.ModelCase

      test "deletes the <%= @singular_name %>", context do
        <%= @singular_name %> = insert(:<%= @singular_name %>)
        user = insert(:account)

        {:ok, <%= @singular_name %>} =
          %<%= @lib_name %>.<%= @mod %>{
            current_user: user,
            resource: <%= @singular_name %>
          } |> <%= @lib_name %>.<%= @mod %>.perform

        refute <%= @lib_name %>.<%= @mod %> |> Repo.get(<%= @singular_name %>.id)

        {:ok, id} = Ecto.UUID.dump(<%= @singular_name %>.id)
        [row] = Ecto.Adapters.SQL.query!(Repo, "select deleted_at from <%= @plural_name %> where id = $1", [id]).rows
        assert List.first(row)
      end
    end
    """)
  end

  defp parse_inputs(raw_inputs) do
    raw_inputs
    |> Enum.filter(&(String.contains?(&1, ":")))
    |> Enum.map(fn raw_input ->
      case String.split(raw_input, ":") do
        [key, type] ->
          {key, String.to_atom(type)}
        [key, type, schema_or_type] ->
          {key, String.to_atom(type), String.to_atom(schema_or_type)}
        [key] ->
          {key, :string}
      end
    end)
  end

  defp generate_field_type(inputs) do
    Enum.reduce(inputs, %{}, fn
      {key, :references}, acc ->
        Map.put(acc, "#{key}_id", :references)
      {key, :array, type}, acc ->
        Map.put(acc, key, "{:array, :#{type}}")
      {key, type}, acc ->
        Map.put(acc, key, type)
    end)
  end
end
