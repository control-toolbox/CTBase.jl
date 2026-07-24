"""
Regression guard for the struct-vs-abstract-parent bound-dropping pitfall (see
`.reports/2026-07-12_alias-where-bounds-audit.md` and the Handbook rule in
`philosophy/types-traits-interfaces.md#aliases-and-where`).

A `struct Child{T} <: Parent{T}` where `Parent{T<:Bound}` does not
automatically bound `T` on `Child` itself — Julia only enforces the bound
*indirectly*, at instantiation (`Parent{SomeType}` must be valid). Formally,
`Child <: Parent` stays `false` unless `Child`'s own declaration repeats the
bound. Six `Data` structs (`Hamiltonian`, `PseudoHamiltonian`, `ControlLaw`,
`PathConstraint`, `Multiplier`, `ControlledVectorField`) had exactly this gap
and were fixed.

This test asserts the subtype relation directly for every trait-parametrized
`Data` struct, so a future edit that drops the bound again fails loudly here
instead of surfacing as a mysterious dispatch bug elsewhere.
"""

module TestDataSubtyping

using Test: Test
import CTBase.Data

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_data_subtyping()
    Test.@testset "Struct <: AbstractParent (bound-dropping regression guard)" verbose =
        VERBOSE showtiming = SHOWTIMING begin
        Test.@testset "Fixed in this pass" begin
            Test.@test Data.Hamiltonian <: Data.AbstractHamiltonian
            Test.@test Data.PseudoHamiltonian <: Data.AbstractPseudoHamiltonian
            Test.@test Data.ControlLaw <: Data.AbstractControlLaw
            Test.@test Data.PathConstraint <: Data.AbstractPathConstraint
            Test.@test Data.Multiplier <: Data.AbstractMultiplier
            Test.@test Data.ControlledVectorField <: Data.AbstractControlledVectorField
        end

        Test.@testset "Already correct — guarded against future regressions" begin
            Test.@test Data.VectorField <: Data.AbstractVectorField
            Test.@test Data.HamiltonianVectorField <: Data.AbstractHamiltonianVectorField
            Test.@test Data.ComposedVectorField <: Data.AbstractVectorField
            Test.@test Data.ComposedHamiltonian <: Data.AbstractHamiltonian
            Test.@test Data.PseudoHamiltonianVectorField <:
                Data.AbstractPseudoHamiltonianVectorField
            Test.@test Data.AbstractPseudoHamiltonianVectorField <: Data.AbstractVectorField
        end
    end
end

end # module

test_data_subtyping() = TestDataSubtyping.test_data_subtyping()
