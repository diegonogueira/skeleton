defmodule Skeleton.Controller do
  import Plug.Conn

  defmacro __using__(_) do
    alias Skeleton.Controller, as: Ctrl

    quote do
      def ensure_authenticated(%{halted: true} = conn), do: conn
      def ensure_authenticated(conn), do: Ctrl.ensure_authenticated(__MODULE__, conn)

      def ensure_not_authenticated(%{halted: true} = conn), do: conn
      def ensure_not_authenticated(conn), do: Ctrl.ensure_not_authenticated(__MODULE__, conn)

      def put_source(%{halted: true} = conn, _), do: conn
      def put_source(conn, source), do: Ctrl.put_source(conn, source)

      def put_resource(%{halted: true} = conn, _), do: conn
      def put_resource(conn, resource), do: Ctrl.put_resource(conn, resource)

      def check_permission(conn, module, permission, args \\ %{})
      def check_permission(%{halted: true} = conn, _, _, _), do: conn
      def check_permission(conn, module, permission, fun) when is_function(fun) do
        check_permission(conn, module, permission, fun.(conn))
      end
      def check_permission(conn, module, permission, args) do
        Ctrl.check_permission(conn, module, permission, args)
      end

      def resolve(%{halted: true} = conn, _), do: conn
      def resolve(conn, callback), do: callback.(conn)
    end
  end

  def ensure_authenticated(module, conn) do
    opts = module.authenticated.init([])
    module.authenticated.call(conn, opts)
  end

  def ensure_not_authenticated(module, conn) do
    opts = module.not_authenticated.init([])
    module.not_authenticated.call(conn, opts)
  end

  def check_permission(conn, module, permission, args) do
    args =
      Map.merge(%{
        resource: conn.assigns[:resource],
        source: conn.assigns[:source],
        current_user: conn.assigns[:current_user]
      }, Enum.into(args, %{}))

    if apply(module, :check, [conn, permission, args]) do
      conn
    else
      conn
      |> put_status(:unauthorized)
      |> halt()
    end
  end

  def put_source(conn, source) do
    assign(conn, :source, source)
  end

  def put_resource(conn, resource) do
    assign(conn, :resource, resource)
  end
end
