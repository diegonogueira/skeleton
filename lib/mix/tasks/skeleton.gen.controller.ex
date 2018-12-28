defmodule Mix.Tasks.Skeleton.Gen.Controller do
  use Mix.Task
  import Macro, only: [camelize: 1, underscore: 1]
  import Mix.Generator

  def run(args) do
    {_opts, [lib_name, resource, plural_name | inputs], _} = OptionParser.parse(args, switches: [])

    resource_list = String.split(resource, "/")
    path = resource_list |> List.delete_at(-1) |> Enum.join("/")
    [context, singular_name] = Enum.take(resource_list, -2)

    fields = parse_inputs(inputs)

    inputs =
      inputs
      |> parse_inputs()
      |> generate_html_components()

    [scope | others] = String.split(path, "/")
    scope = if others != [], do: "#{scope}_", else: nil

    generate_controller(lib_name, context, singular_name, plural_name, path, scope)
    generate_view(lib_name, context, singular_name, plural_name, path)
    generate_templates(lib_name, context, singular_name, plural_name, inputs, path, scope)
    generate_controller_test(lib_name, context, singular_name, plural_name, inputs, path, fields)

    if scope do
    IO.puts("""
    \n1: Add route on #{camelize(lib_name)}Web.Router

      scope "/#{String.downcase(camelize(scope))}", #{camelize(scope)}, as: :#{String.downcase(camelize(scope))} do
        resources "/#{plural_name}", #{camelize(singular_name)}Controller
      end
    """)
    else
    IO.puts("""
    \n1: Add route on camelize(lib_name)Web.Router

      resources "/#{plural_name}", #{camelize(singular_name)}Controller
    """)
    end
  end

  defp generate_controller(lib_name, context, singular_name, plural_name, path, scope) do
    path = "lib/#{underscore(lib_name)}_web/controllers/#{path}"
    base_singular_name = "#{underscore(singular_name)}_controller.ex"
    file = Path.join(path, base_singular_name)

    create_directory(path)

    contexts = [
      lib_name: camelize(lib_name),
      context: camelize(context),
      mod: camelize(singular_name),
      singular_name: underscore(singular_name),
      plural_name: underscore(plural_name),
      scope: scope
    ]

    create_file(file, controller_template(contexts))
  end

  defp generate_view(lib_name, context, singular_name, plural_name, path) do
    path = "lib/#{underscore(lib_name)}_web/views/#{underscore(singular_name)}"
    base_singular_name = "#{underscore(singular_name)}_view.ex"
    file = Path.join(path, base_singular_name)

    create_directory(path)

    contexts = [
      lib_name: camelize(lib_name),
      context: camelize(context),
      mod: camelize(singular_name),
      singular_name: underscore(singular_name),
      plural_name: underscore(plural_name)
    ]

    create_file(file, view_template(contexts))
  end

  defp generate_templates(lib_name, context, singular_name, plural_name, inputs, path, scope) do
    path = "lib/#{underscore(lib_name)}_web/templates/#{path}/#{underscore(singular_name)}"

    Enum.each([:index, :show, :new, :edit, :form], fn template ->
      base_singular_name = "#{template}.html.eex"
      file = Path.join(path, base_singular_name)

      create_directory(path)

      contexts = [
        lib_name: camelize(lib_name),
        context: camelize(context),
        mod: camelize(singular_name),
        singular_name: underscore(singular_name),
        plural_name: underscore(plural_name),
        inputs: inputs,
        scope: scope
      ]

      # Try to run dynamically, using apply did not work
      case template do
        :index -> create_file(file, index_template(contexts))
        :show -> create_file(file, show_template(contexts))
        :new -> create_file(file, new_template(contexts))
        :edit -> create_file(file, edit_template(contexts))
        :form -> create_file(file, form_template(contexts))
      end
    end)
  end

  defp generate_controller_test(lib_name, context, singular_name, plural_name, _inputs, path, fields) do
    path = "test/#{underscore(lib_name)}_web/controllers/#{path}"
    base_singular_name = "#{underscore(singular_name)}_controller_test.exs"
    file = Path.join(path, base_singular_name)

    create_directory(path)

    contexts = [
      lib_name: camelize(lib_name),
      context: camelize(context),
      mod: camelize(singular_name),
      singular_name: underscore(singular_name),
      plural_name: underscore(plural_name),
      fields: fields
    ]

    create_file(file, controller_test_template(contexts))
  end

  # Templates

  try do
    embed_template(:controller, from_file: Path.expand("../../../../../lib/mix/tasks/skeleton_templates/controller/controller_template.eex", __DIR__))
  rescue
    _ ->

    embed_template(:controller, """
    defmodule <%= @lib_name %>Web.<%= @mod %>Controller do
      use <%= @lib_name %>Web.Controller
      alias <%= @lib_name %>Web.<%= @mod %>Permission
      alias <%= @lib_name %>.<%= @context %>
      alias <%= @lib_name %>.<%= @context %>.<%= @mod %>

      def index(conn, _params) do
        conn
        |> ensure_authenticated()
        |> resolve(fn conn ->
          <%= @plural_name %> = <%= @context %>.list_<%= @plural_name %>()
          render(conn, "index.html", <%= @plural_name %>: <%= @plural_name %>)
        end)
      end

      def show(conn, %{"id" => id}) do
        conn
        |> ensure_authenticated()
        |> assign_resource()
        |> resolve(fn conn ->
          render(conn, "show.html", <%= @singular_name %>: conn.assigns.resource)
        end)
      end

      def new(conn, _params) do
        conn
        |> ensure_authenticated()
        |> check_permission(<%= @mod %>Permission, :can_create)
        |> resolve(fn conn ->
          changeset = <%= @context %>.change_<%= @singular_name %>(%<%= @mod %>{})
          render conn, "new.html", changeset: changeset
        end)
      end

      def create(conn, %{"<%= @singular_name %>" => <%= @singular_name %>}) do
        conn
        |> ensure_authenticated()
        |> check_permission(<%= @mod %>Permission, :can_create)
        |> resolve(fn conn ->
          with {:ok, _} <- <%= @context %>.create_<%= @singular_name %>(conn.assigns, ad) do
            conn
            |> put_flash(:success, gettext("Success!"))
            |> redirect(to: Routes.<%= @singular_name %>_path(conn, :show, conn.assigns.resource))
          end
        end)
      end

      def edit(conn, %{"id" => id}) do
        conn
        |> ensure_authenticated()
        |> assign_resource()
        |> check_permission(<%= @mod %>Permission, :can_update)
        |> resolve(fn conn ->
          changeset = <%= @context %>.change_<%= @singular_name %>(conn.assigns.resource)
          render(conn, "edit.html", <%= @singular_name %>: conn.assigns.resource, changeset: changeset)
        end)
      end

      def update(conn, %{"id" => _id, "<%= @singular_name %>" => <%= @singular_name %>_params}) do
        conn
        |> ensure_authenticated()
        |> assign_resource()
          |> check_permission(<%= @mod %>Permission, :can_update)
        |> resolve(fn conn ->
          with {:ok, _} <- <%= @context %>.update_<%= @singular_name %>(conn.assigns.resource, user_params) do
            conn
            |> put_flash(:success, "Updated!")
            |> redirect(to: Routes.<%= @singular_name %>_path(conn, :show, conn.assigns.resource))
          end
        end)
      end

      def delete(conn, %{"id" => _id}) do
        conn
        |> ensure_authenticated()
        |> assign_resource()
        |> check_permission(<%= @mod %>Permission, :can_delete)
        |> resolve(fn conn ->
          with {:ok, _} <- <%= @context %>.delete_<%= @singular_name %>(conn.assigns.resource) do
            conn
            |> put_flash(:success, "Deleted!")
            |> redirect(to: Routes.<%= @singular_name %>_path(conn, :index))
          end
        end)
      end

      # Helpers

      defp assign_resource(%{params: %{"id" => id}} = conn) do
        put_resource(conn, <%= @context %>.get_user!(id))
      end
    end
    """)
  end

  try do
    embed_template(:view, from_file: Path.expand("../../../../../lib/mix/tasks/skeleton_templates/controller/view_template.eex", __DIR__))
  rescue
    _ ->

    embed_template(:view, """
    defmodule <%= @lib_name %>Web.<%= @mod %>View do
      use <%= @lib_name %>Web, :view
    end
    """)
  end

  try do
    embed_template(:index, from_file: Path.expand("../../../../../lib/mix/tasks/skeleton_templates/controller/index_template.eex", __DIR__))
  rescue
    _ ->

    embed_template(:index, """
    <%%= for <%= @singular_name %> <- <%= @plural_name %> do %>
      <%%= for <%= @singular_name %> <- <%= @plural_name %> do %>
      <%= for {key, _label, _input, _error} <- @inputs do %>
      <%%= <%= @singular_name %>.<%= key  %> %>
      <% end %>

      <%%= link "Show", to: Routes.<%= @singular_name %>_path(@conn, :show, <%= @singular_name %>) %>
      <%%= link "Edit", to: Routes.<%= @singular_name %>_path(@conn, :edit, <%= @singular_name %>) %>
      <%%= link "Delete", to: Routes.<%= @singular_name %>_path(@conn, :delete, <%= @singular_name %>), method: :delete, data: [confirm: "Are you sure?"] %>
      <hr>
    <%% end %>
    """)
  end

  try do
    embed_template(:show, from_file: Path.expand("../../../../../lib/mix/tasks/skeleton_templates/controller/show_template.eex", __DIR__))
  rescue
    _ ->

    embed_template(:show, """
    <%= for {key, _label, _input, _error} <- @inputs do %>
    <%%= @<%= @singular_name %>.<%= key  %> %>
    <% end %>

    <%%= link "Edit", to: Routes.<%= @singular_name %>_path(@conn, :edit, @<%= @singular_name %>) %>
    <%%= link "Back", to: Routes.<%= @singular_name %>_path(@conn, :index) %>
    """)
  end

  try do
    embed_template(:edit, from_file: Path.expand("../../../../../lib/mix/tasks/skeleton_templates/controller/edit_template.eex", __DIR__))
  rescue
    _ ->

    embed_template(:edit, """
    <%%= render "form.html", Map.put(assigns, :action, Routes.<%= @singular_name %>_path(@conn, :update, @<%= @singular_name %>)) %>

    <%%= link "Back", to: Routes.<%= @singular_name %>_path(@conn, :index) %>
    """)
  end

  try do
    embed_template(:new, from_file: Path.expand("../../../../../lib/mix/tasks/skeleton_templates/controller/new_template.eex", __DIR__))
  rescue
    _ ->

    embed_template(:new, """
    <%%= render "form.html", Map.put(assigns, :action, Routes.<%= @singular_name %>_path(@conn, :create)) %>

    <%%= link "Back", to: Routes.<%= @singular_name %>_path(@conn, :index) %>
    """)
  end

  try do
    embed_template(:form, from_file: Path.expand("../../../../../lib/mix/tasks/skeleton_templates/controller/form_template.eex", __DIR__))
  rescue
    _ ->

    embed_template(:form, """
    <%%= form_for @changeset, @action, fn f -> %>
      <%%= if @changeset.action do %>
        <div class="alert alert-danger">
          <p>Oops, something went wrong! Please check the errors below.</p>
        </div>
      <%% end %>

      <%= for {_key, label, input, error} <- @inputs do %>
      <%= label %>
      <%= input %>
      <%= error %>
      <% end %>

      <%%= submit "Save" %>
    <%% end %>
    """)
  end

  try do
    embed_template(:controller_test, from_file: Path.expand("../../../../../lib/mix/tasks/skeleton_templates/controller/controller_test_template.eex", __DIR__))
  rescue
    _ ->

    embed_template(:controller_test, """
    defmodule <%= @lib_name %>.<%= @context %>.<%= @mod %>Test do
      use <%= @lib_name %>.ConnCase

      @tag login: false
      test "name of test", %{conn: conn} do
        # conn = get conn, Routes.route_path(conn, :action)
        # assert html_response(conn, 200) =~ ""
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

  defp generate_html_components(inputs) do
    Enum.map(inputs, fn
      {key, :integer} ->
        {key, label(key), ~s(<%= number_input f, #{key} %>), error(key)}
      {key, :float} ->
        {key, label(key), ~s(<%= number_input f, :#{key}, step: "any" %>), error(key)}
      {key, :decimal} ->
        {key, label(key), ~s(<%= number_input f, :#{key}, step: "any" %>), error(key)}
      {key, :boolean} ->
        {key, label(key), ~s(<%= checkbox f, :#{key} %>), error(key)}
      {key, :text} ->
        {key, label(key), ~s(<%= textarea f, :#{key} %>), error(key)}
      {key, :date} ->
        {key, label(key), ~s(<%= date_select f, :#{key} %>), error(key)}
      {key, :time} ->
        {key, label(key), ~s(<%= time_select f, :#{key} %>), error(key)}
      {key, :utc_datetime} ->
        {key, label(key), ~s(<%= datetime_select f, :#{key} %>), error(key)}
      {key, :naive_datetime} ->
        {key, label(key), ~s(<%= datetime_select f, :#{key} %>), error(key)}
      {key, :array, :integer} ->
        {key, label(key), ~s(<%= multiple_select f, :#{key}, ["1": 1, "2": 2] %>), error(key)}
      {key, :array, _} ->
        {key, label(key), ~s(<%= multiple_select f, :#{key}, ["Option 1": "option1", "Option 2": "option2"] %>), error(key)}
      {key, :references} ->
        {key, label(key), ~s(<%= text_input f, :#{key}_id %>), error(key)}
      {key, _} ->
        {key, label(key), ~s(<%= text_input f, :#{key} %>), error(key)}
    end)
  end

  defp label(key) do
    ~s(<%= label f, :#{key} %>)
  end

  defp error(field) do
    ~s(<%= error_tag f, :#{field} %>)
  end
end
