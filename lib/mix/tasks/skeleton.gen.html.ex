defmodule Mix.Tasks.Skeleton.Gen.Html do
  use Mix.Task

  def run(args) do
    {_opts, [lib_name, resource, plural_name | inputs], _} = OptionParser.parse(args, switches: [])

    # Create model
    Mix.Tasks.Skeleton.Gen.Model.run(args)

    # Create services (CRUD)
    Mix.Tasks.Skeleton.Gen.Service.run([lib_name, resource, plural_name, "create"] ++ inputs)
    Mix.Tasks.Skeleton.Gen.Service.run([lib_name, resource, plural_name, "update"] ++ inputs)
    Mix.Tasks.Skeleton.Gen.Service.run([lib_name, resource, plural_name, "delete"] ++ inputs)
    Mix.Tasks.Skeleton.Gen.Query.run(args)

    # Create permission
    Mix.Tasks.Skeleton.Gen.Permission.run(args)

    # Create resolver
    Mix.Tasks.Skeleton.Gen.Controller.run(args)
  end
end
