defmodule SkeletonLegacy.Resolver.Permission do
  defmacro __using__(_) do
    quote do
      import SkeletonLegacy.Resolver.Permission

      def get_source_name(_resource), do: nil

      defoverridable get_source_name: 1
    end
  end

  def include?(a, b) do
    length(a -- a -- b) > 0
  end
end
