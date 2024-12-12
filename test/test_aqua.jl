function test_aqua()
    @testset "Aqua.jl" begin
        Aqua.test_all(
            CTBase;
            ambiguities=false,
            #stale_deps=(ignore=[:SomePackage],),
            deps_compat=(ignore=[:LinearAlgebra, :Unicode],),
            piracies=true,
        )
        # do not warn about ambiguities in dependencies
        Aqua.test_ambiguities(CTBase)
    end
end
