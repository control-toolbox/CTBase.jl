"""
Unit, contract and error tests of `Differentiation.check_backend` and of the availability
check performed by every gradient method of the `CTBaseDifferentiationInterface` extension:
an AD backend whose package is not loaded gives an `ExtensionError` naming the package
instead of a raw `MethodError` from DifferentiationInterface.jl.

The unavailable backend is a fake (`AutoFakeBackend`, unknown to every DifferentiationInterface
extension) so that the tests do not depend on which backend packages other test files loaded.
"""

module TestBackendAvailable

using Test: Test
using CTBase: Data
using CTBase: Differentiation
using CTBase: Exceptions
using CTBase: Strategies
using ADTypes: ADTypes
using ForwardDiff: ForwardDiff
using DifferentiationInterface: DifferentiationInterface

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ==============================================================================
# Fakes (module top-level)
# ==============================================================================

"""An ADTypes backend that no DifferentiationInterface extension knows: never available."""
struct AutoFakeBackend <: ADTypes.AbstractADType end

"""A backend strategy that does not wrap anything: the core stub of `check_backend` applies."""
struct FakeADBackend <: Differentiation.AbstractADBackend
    options::Strategies.StrategyOptions
end
FakeADBackend() = FakeADBackend(Strategies.StrategyOptions())

const EXT = Base.get_extension(
    Base.parentmodule(Differentiation), :CTBaseDifferentiationInterface
)

_di(ad) = Differentiation.DifferentiationInterface(; ad_backend=ad)

# the error thrown by `f()`, or `nothing` if it does not throw
_error_of(f) =
    try
        f()
        nothing
    catch err
        err
    end

function test_backend_available()
    Test.@testset "Backend availability" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ======================================================================
        # UNIT — package name of a backend
        # ======================================================================
        Test.@testset "Unit: _backend_package strips the Auto prefix" begin
            Test.@test EXT._backend_package(ADTypes.AutoMooncake()) === :Mooncake
            Test.@test EXT._backend_package(ADTypes.AutoForwardDiff()) === :ForwardDiff
            Test.@test EXT._backend_package(ADTypes.AutoZygote()) === :Zygote
            Test.@test EXT._backend_package(ADTypes.AutoPolyesterForwardDiff()) ===
                :PolyesterForwardDiff
            Test.@test EXT._backend_package(AutoFakeBackend()) === :FakeBackend
        end

        # ======================================================================
        # UNIT — which leaf backend is unavailable
        # ======================================================================
        Test.@testset "Unit: _unavailable" begin
            fake, fd = AutoFakeBackend(), ADTypes.AutoForwardDiff()
            Test.@test EXT._unavailable(fd) === nothing
            Test.@test EXT._unavailable(fake) === fake
            # a sparse backend is checked through its dense backend
            Test.@test EXT._unavailable(ADTypes.AutoSparse(fd)) === nothing
            Test.@test EXT._unavailable(ADTypes.AutoSparse(fake)) === fake
            # a second-order backend: outer first, then inner
            Test.@test EXT._unavailable(DifferentiationInterface.SecondOrder(fd, fd)) ===
                nothing
            Test.@test EXT._unavailable(DifferentiationInterface.SecondOrder(fake, fd)) ===
                fake
            Test.@test EXT._unavailable(DifferentiationInterface.SecondOrder(fd, fake)) ===
                fake
        end

        # ======================================================================
        # CONTRACT — core stub and available backend
        # ======================================================================
        Test.@testset "Contract: the core method does nothing" begin
            Test.@test Differentiation.check_backend(FakeADBackend()) === nothing
        end

        Test.@testset "Contract: an available backend passes and is returned" begin
            b = _di(ADTypes.AutoForwardDiff())
            Test.@test Differentiation.check_backend(b) === nothing
            Test.@test EXT._checked_backend(b) === ADTypes.AutoForwardDiff()
            Test.@test Differentiation.hamiltonian_gradient(
                b,
                Data.Hamiltonian((x, p) -> sum(x .* p)),
                0.0,
                [1.0, 2.0],
                [3.0, 4.0],
                nothing,
            )[1] ≈ [3.0, 4.0]
        end

        # ======================================================================
        # ERROR — an unavailable backend names its package
        # ======================================================================
        Test.@testset "Error: check_backend throws an ExtensionError naming the package" begin
            err = _error_of(() -> Differentiation.check_backend(_di(AutoFakeBackend())))
            Test.@test err isa Exceptions.ExtensionError
            Test.@test err.weakdeps == (:FakeBackend,)
            Test.@test occursin("FakeBackend", sprint(showerror, err))
            Test.@test err.context == "CTBase.Differentiation"
        end

        Test.@testset "Error: the leaf backend of a composite is the one reported" begin
            b = _di(
                DifferentiationInterface.SecondOrder(
                    ADTypes.AutoForwardDiff(), AutoFakeBackend()
                ),
            )
            err = _error_of(() -> Differentiation.check_backend(b))
            Test.@test err isa Exceptions.ExtensionError
            Test.@test err.weakdeps == (:FakeBackend,)
        end

        # ======================================================================
        # ERROR — every gradient method of the extension checks the backend
        # ======================================================================
        Test.@testset "Error: $name throws ExtensionError, not MethodError" for (
            name, call
        ) in (
            (
                "hamiltonian_gradient",
                b -> Differentiation.hamiltonian_gradient(
                    b,
                    Data.Hamiltonian((x, p) -> sum(x .* p)),
                    0.0,
                    [1.0],
                    [2.0],
                    nothing,
                ),
            ),
            (
                "variable_gradient",
                b -> Differentiation.variable_gradient(
                    b,
                    Data.Hamiltonian((x, p, v) -> sum(x .* p) * v; is_variable=true),
                    0.0,
                    [1.0],
                    [2.0],
                    3.0,
                ),
            ),
            (
                "pseudo_hamiltonian_gradient",
                b -> Differentiation.pseudo_hamiltonian_gradient(
                    b,
                    Data.PseudoHamiltonian((x, p, u) -> sum(x .* p) + sum(u .^ 2)),
                    0.0,
                    [1.0],
                    [2.0],
                    [3.0],
                    nothing,
                ),
            ),
            (
                "pseudo_hamiltonian_control_gradient",
                b -> Differentiation.pseudo_hamiltonian_control_gradient(
                    b,
                    Data.PseudoHamiltonian((x, p, u) -> sum(x .* p) + sum(u .^ 2)),
                    0.0,
                    [1.0],
                    [2.0],
                    [3.0],
                    nothing,
                ),
            ),
            (
                "pseudo_variable_gradient",
                b -> Differentiation.pseudo_variable_gradient(
                    b,
                    Data.PseudoHamiltonian(
                        (x, p, u, v) -> sum(x .* p) * v; is_variable=true
                    ),
                    0.0,
                    [1.0],
                    [2.0],
                    [3.0],
                    4.0,
                ),
            ),
            (
                "gradient (array)",
                b -> Differentiation.gradient(b, x -> sum(abs2, x), [1.0, 2.0]),
            ),
            ("gradient (scalar)", b -> Differentiation.gradient(b, x -> x^2, 2.0)),
            ("derivative", b -> Differentiation.derivative(b, t -> t^2, 2.0)),
            (
                "differentiate",
                b -> Differentiation.differentiate(b, (a, c) -> a * c, Val(1), 2.0, 3.0),
            ),
            (
                "pushforward",
                b -> Differentiation.pushforward(b, (a, c) -> a * c, Val(1), 2.0, 1.0, 3.0),
            ),
        )
            b = _di(AutoFakeBackend())
            err = _error_of(() -> call(b))
            Test.@test err isa Exceptions.ExtensionError
            Test.@test err.weakdeps == (:FakeBackend,)
        end

        # ======================================================================
        # HOT PATH — the check is free for a concrete backend
        # ======================================================================
        Test.@testset "Type stability of _checked_backend" begin
            b = _di(ADTypes.AutoForwardDiff())
            Test.@test_nowarn Test.@inferred EXT._checked_backend(b)
            Test.@test_nowarn Test.@inferred Differentiation.check_backend(b)
        end
    end
end

end # module

test_backend_available() = TestBackendAvailable.test_backend_available()
