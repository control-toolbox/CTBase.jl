using Test
using CTBase
using Pkg

@testset "Package Version" begin
    # Verify the package version matches the version in Project.toml
    pkg_version = Pkg.TOML.parsefile(joinpath(dirname(@__DIR__), "Project.toml"))["version"]
    @test pkg_version == "0.16.1"
end