module TestExtensionsQuality

using Test: Test
using Aqua: Aqua
using CTBase: CTBase

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

const CTBaseAqua = Base.get_extension(CTBase, :CTBaseAqua)

# Fakes: a package, one clean extension and one pirating, ambiguous extension.
module FakePkg
    struct Owned end
    const OwnedOrInt = Union{Owned,Int}
    const ForeignUnion = Union{Int,AbstractVector{<:Real}}
    f(::Int) = 1
end

module FakeCleanExt
    using ..FakePkg
    FakePkg.f(::Float64) = 2
    Base.show(::IO, ::FakePkg.Owned) = nothing
end

module FakePirateExt
    Base.sin(::Symbol) = 1
    Base.cos(::Symbol, ::Any) = 1
    Base.cos(::Any, ::Symbol) = 2
end

function test_extensions_quality()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Extensions quality" begin
        Test.@testset "Extension names" begin
            names = CTBaseAqua._extension_names(CTBase)
            Test.@test "CTBaseAqua" in names
            Test.@test issorted(names)
        end

        Test.@testset "Owned symbols" begin
            owned = CTBaseAqua._owned_symbols(FakePkg)
            Test.@test FakePkg.f in owned
            Test.@test FakePkg.Owned in owned
            Test.@test !(sin in owned)
            Test.@test !(FakePkg.OwnedOrInt in owned)
            Test.@test !(FakePkg.ForeignUnion in owned)
        end

        Test.@testset "Piracy detection" begin
            Test.@test isempty(CTBaseAqua._piracies(FakePkg, FakeCleanExt))
            pirates = CTBaseAqua._piracies(FakePkg, FakePirateExt)
            Test.@test length(pirates) == 3
            Test.@test all(m -> m.module === FakePirateExt, pirates)
            Test.@test CTBaseAqua._piracy_key(first(pirates)) isa String
        end

        Test.@testset "Ambiguity detection" begin
            Test.@test isempty(CTBaseAqua._ambiguities(FakeCleanExt))
            Test.@test !isempty(CTBaseAqua._ambiguities(FakePirateExt))
        end
    end
    return nothing
end

end # module

test_extensions_quality() = TestExtensionsQuality.test_extensions_quality()
