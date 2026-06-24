module TestCodeQuality

using Test: Test
using Aqua: Aqua
using CTBase: CTBase

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_code_quality()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Code quality" begin
        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Aqua" begin
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

        # Test.@testset "JET" begin
        #     JET.test_package(CTBase; target_defined_modules=true)
        # end

        # Test.@testset "JuliaFormatter" begin
        #     Test.@test JuliaFormatter.format(CTBase; verbose=true, overwrite=false)
        # end

        # Test.@testset "Doctests" begin
        #     Documenter.doctest(CTBase)
        # end
    end

    return nothing
end

end # module TestCodeQuality

# CRITICAL: redefine in outer scope so the test runner can call it
test_code_quality() = TestCodeQuality.test_code_quality()
