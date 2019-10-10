defmodule Skeleton.Resolver.Permission do
  defmacro __using__(_) do
    quote do
      import Skeleton.Resolver.Permission
    end
  end

  def include?(a, b) do
    length(a -- a -- b) > 0
  end
end
