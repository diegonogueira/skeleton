defmodule SkeletonLegacyTest do
  use ExUnit.Case
  doctest SkeletonLegacy

  test "greets the world" do
    assert SkeletonLegacy.hello() == :world
  end
end
