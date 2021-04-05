defmodule Mix.Tasks.SkeletonLegacy.Gen.Html do
  use Mix.Task

  def run(args) do
    {_opts, [lib_name, resource, plural_name | inputs], _} = OptionParser.parse(args, switches: [])

    # Create model
    Mix.Tasks.SkeletonLegacy.Gen.Model.run(args)

    # Create services (CRUD)
    Mix.Tasks.SkeletonLegacy.Gen.Service.run([lib_name, resource, plural_name, "create"] ++ inputs)
    Mix.Tasks.SkeletonLegacy.Gen.Service.run([lib_name, resource, plural_name, "update"] ++ inputs)
    Mix.Tasks.SkeletonLegacy.Gen.Service.run([lib_name, resource, plural_name, "delete"] ++ inputs)
    Mix.Tasks.SkeletonLegacy.Gen.Query.run(args)

    # Create context api
    Mix.Tasks.SkeletonLegacy.Gen.ContextAPI.run(args)

    # Create permission
    Mix.Tasks.SkeletonLegacy.Gen.Permission.run(args)

    # Create resolver
    Mix.Tasks.SkeletonLegacy.Gen.Controller.run(args)
  end
end
