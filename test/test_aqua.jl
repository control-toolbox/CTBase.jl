function test_aqua()

@testset "Aqua.jl" begin
  Aqua.test_all(
    CTBase;
    ambiguities=(
        exclude=[
            ForwardDiff.:(==),
            ForwardDiff.:(^),
            ForwardDiff.convert,
            ForwardDiff.Dual,
            ForwardDiff.log,
            ForwardDiff.promote_rule,
            StaticArrays.getindex
        ], broken=true),
    #stale_deps=(ignore=[:SomePackage],),
    deps_compat=(ignore=[:LinearAlgebra, :Unicode],),
    piracies=true,
  )
end

end