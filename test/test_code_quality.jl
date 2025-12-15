function test_code_quality()
    @testset verbose = VERBOSE showtiming = SHOWTIMING "Code quality" begin
        @testset verbose = VERBOSE showtiming = SHOWTIMING "Aqua" begin
            Aqua.test_all(
                CTBase;
                ambiguities=false,
                #stale_deps=(; ignore=[:SomePackage],),
                deps_compat=(; ignore=[:LinearAlgebra, :Unicode],),
                piracies=true,
            )
            # do not warn about ambiguities in dependencies
            Aqua.test_ambiguities(CTBase)
        end

        # @testset "JET" begin
        #     JET.test_package(CTBase; target_defined_modules=true)
        # end

        # @testset "JuliaFormatter" begin
        #     @test JuliaFormatter.format(CTBase; verbose=true, overwrite=false)
        # end

        # @testset "Doctests" begin
        #     Documenter.doctest(CTBase)
        # end
    end

    return nothing
end
