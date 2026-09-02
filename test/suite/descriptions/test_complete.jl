module TestComplete

using Test: Test
using CTBase: Descriptions
using CTBase: Exceptions

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_complete()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Complete Descriptions" begin

        # ====================================================================
        # UNIT TESTS - Complete Function Core Logic
        # ====================================================================

        algorithms = ()
        algorithms = Descriptions.add(algorithms, (:descent, :bfgs, :bisection))
        algorithms = Descriptions.add(algorithms, (:descent, :bfgs, :backtracking))
        algorithms = Descriptions.add(algorithms, (:descent, :bfgs, :fixedstep))
        algorithms = Descriptions.add(algorithms, (:descent, :gradient, :bisection))
        algorithms = Descriptions.add(algorithms, (:descent, :gradient, :backtracking))
        algorithms = Descriptions.add(algorithms, (:descent, :gradient, :fixedstep))

        Test.@testset "Successful completions" begin
            Test.@test Descriptions.complete((:descent,); descriptions=algorithms) ==
                (:descent, :bfgs, :bisection)
            Test.@test Descriptions.complete((:bfgs,); descriptions=algorithms) ==
                (:descent, :bfgs, :bisection)
            # Tuple overload check
            Test.@test Descriptions.complete(:descent; descriptions=algorithms) ==
                (:descent, :bfgs, :bisection)
        end

        Test.@testset "Completion with Variable Sized Descriptions" begin
            algorithms = ()
            algorithms = Descriptions.add(algorithms, (:a, :b, :c))
            algorithms = Descriptions.add(algorithms, (:a, :b, :c, :d))
            Test.@test Descriptions.complete((:a, :b); descriptions=algorithms) ==
                (:a, :b, :c)
            Test.@test Descriptions.complete((:a, :b, :c, :d); descriptions=algorithms) ==
                (:a, :b, :c, :d)
        end

        Test.@testset "Priority handling" begin
            # Test priority when ordering of descriptions switched
            algos_swapped = ()
            algos_swapped = Descriptions.add(algos_swapped, (:a, :b, :c, :d))
            algos_swapped = Descriptions.add(algos_swapped, (:a, :b, :c))
            Test.@test Descriptions.complete((:a, :b); descriptions=algos_swapped) ==
                (:a, :b, :c, :d)

            algos_ordered = ()
            algos_ordered = Descriptions.add(algos_ordered, (:a, :b, :c))
            algos_ordered = Descriptions.add(algos_ordered, (:a, :b, :c, :d))
            Test.@test Descriptions.complete((:a, :b); descriptions=algos_ordered) ==
                (:a, :b, :c)
        end

        Test.@testset "Successful completion with exact and partial matches" begin
            descriptions = ((:a, :b), (:a, :b, :c), (:b, :c))

            # Test exact match
            result = Descriptions.complete(:a, :b; descriptions=descriptions)
            Test.@test result == (:a, :b)

            # Test partial match
            result2 = Descriptions.complete(:a; descriptions=descriptions)
            Test.@test result2 in [(:a, :b), (:a, :b, :c)]
        end

        Test.@testset "Tie-breaking behavior" begin
            # When multiple descriptions have same intersection size, first wins
            descriptions = ((:a, :b, :c), (:a, :b, :d), (:a, :b, :e))
            result = Descriptions.complete(:a, :b; descriptions=descriptions)
            Test.@test result == (:a, :b, :c)  # First one wins

            # Different order
            descriptions2 = ((:x, :y, :z), (:x, :y, :w), (:x, :y, :v))
            result2 = Descriptions.complete(:x, :y; descriptions=descriptions2)
            Test.@test result2 == (:x, :y, :z)  # First one wins

            # Single symbol query with equal matches
            descriptions3 = ((:a, :b), (:a, :c), (:a, :d))
            result3 = Descriptions.complete(:a; descriptions=descriptions3)
            Test.@test result3 == (:a, :b)  # First one wins
        end

        Test.@testset "Exact match with multiple candidates" begin
            # Exact match exists among multiple partial matches
            descriptions = ((:a, :b, :c), (:a, :b), (:a, :c))
            result = Descriptions.complete(:a, :b; descriptions=descriptions)
            # Should prefer exact match or first with max intersection
            Test.@test result in [(:a, :b, :c), (:a, :b)]

            # Multiple exact matches - first wins
            descriptions2 = ((:x, :y), (:x, :y), (:x, :y, :z))
            result2 = Descriptions.complete(:x, :y; descriptions=descriptions2)
            Test.@test result2 == (:x, :y)  # First exact match
        end

        Test.@testset "Single vs multi-symbol input" begin
            descriptions = ((:a, :b, :c), (:a, :d), (:b, :c))

            # Single symbol
            result1 = Descriptions.complete(:a; descriptions=descriptions)
            Test.@test result1 in [(:a, :b, :c), (:a, :d)]

            # Two symbols
            result2 = Descriptions.complete(:a, :b; descriptions=descriptions)
            Test.@test result2 == (:a, :b, :c)

            # Three symbols
            result3 = Descriptions.complete(:a, :b, :c; descriptions=descriptions)
            Test.@test result3 == (:a, :b, :c)
        end

        Test.@testset "Tuple overload delegation" begin
            descriptions = ((:a, :b), (:c, :d))

            # Test that tuple overload works correctly
            result1 = Descriptions.complete((:a,); descriptions=descriptions)
            result2 = Descriptions.complete(:a; descriptions=descriptions)
            Test.@test result1 == result2

            # Multi-element tuple
            result3 = Descriptions.complete((:a, :b); descriptions=descriptions)
            result4 = Descriptions.complete(:a, :b; descriptions=descriptions)
            Test.@test result3 == result4
        end

        # ====================================================================
        # TYPE STABILITY TESTS
        # ====================================================================

        Test.@testset "Type stability - complete function" begin
            descriptions = ((:a, :b), (:a, :c), (:b, :c))

            # Varargs overload
            Test.@test (Test.@inferred Descriptions.complete(
                :a; descriptions=descriptions
            )) isa Descriptions.Description
            Test.@test (Test.@inferred Descriptions.complete(
                :a, :b; descriptions=descriptions
            )) isa Descriptions.Description

            # Tuple overload
            Test.@test (Test.@inferred Descriptions.complete(
                (:a,); descriptions=descriptions
            )) isa Descriptions.Description
            Test.@test (Test.@inferred Descriptions.complete(
                (:a, :b); descriptions=descriptions
            )) isa Descriptions.Description

            # Verify return type consistency
            result = Descriptions.complete(:a; descriptions=descriptions)
            Test.@test result isa Tuple{Vararg{Symbol}}
        end

        # ====================================================================
        # ERROR TESTS - AmbiguousDescription Quality
        # ====================================================================

        Test.@testset "Ambiguous/Invalid completions" begin
            # Basic error check
            Test.@test_throws Exceptions.AmbiguousDescription Descriptions.complete(
                (:ttt,); descriptions=algorithms
            )

            # Empty catalog
            Test.@test_throws Exceptions.AmbiguousDescription Descriptions.complete(
                :a; descriptions=()
            )

            # Enriched error checks - rigorous

            # 1. Empty descriptions check
            try
                Descriptions.complete(:a; descriptions=())
            catch e
                Test.@test e isa Exceptions.AmbiguousDescription
                Test.@test isempty(e.candidates)
                Test.@test occursin("No descriptions available", e.suggestion)
                Test.@test e.context == "description completion"
            end

            # 2. Description not found with suggestions (subset of existing)
            descriptions = ((:a, :b), (:c, :d), (:e, :f))
            try
                Descriptions.complete(:x; descriptions=descriptions)
            catch e
                Test.@test e isa Exceptions.AmbiguousDescription
                Test.@test e.description == (:x,)
                Test.@test !isempty(e.candidates)
                Test.@test length(e.candidates) == 3
                Test.@test "(:a, :b)" in e.candidates
                Test.@test occursin(
                    "Choose from the available descriptions listed above", e.suggestion
                )
            end

            # 3. Description not found with similar suggestions
            descriptions_sim = ((:a, :b, :c), (:a, :d, :e), (:x, :y, :z))
            try
                Descriptions.complete(:b, :f; descriptions=descriptions_sim)
            catch e
                Test.@test e isa Exceptions.AmbiguousDescription
                Test.@test !isempty(e.candidates)
                Test.@test occursin("closest matches", e.suggestion)
                # The similar descriptions are listed by the hint itself; the
                # candidate list stays the full catalog (issue #557).
                Test.@test occursin("(:a, :b, :c)", e.suggestion)
                Test.@test length(e.candidates) == 3
            end
        end

        Test.@testset "issue 553 - truncation marker and closest matches" begin
            # ================================================================
            # NON-REGRESSION: issue #553
            # 1) candidate list must not be silently truncated - a
            #    "… and N more" marker is appended when > max_show.
            # 2) the "closest matches" hint must actually list the similar
            #    descriptions (previously discarded, leaving the hint empty).
            # ================================================================

            # --- Build a catalog of 12, the last two GPU ones (issue scenario) ---
            descs = ()
            for i in 1:10
                descs = Descriptions.add(descs, (:ipopt, Symbol(:cpu_, i)))
            end
            descs = Descriptions.add(descs, (:gpu, :exact))
            descs = Descriptions.add(descs, (:gpu, :krylov))
            Test.@test length(descs) == 12

            # 1a. Marker appended by the formatter when > max_show
            formatted = Descriptions._format_description_candidates(descs; max_show=10)
            Test.@test length(formatted) == 11            # 10 shown + marker
            Test.@test formatted[end] == "… and 2 more"

            # 1b. max_show raised to 20 in complete: catalog of 22 must still
            #     surface the marker line in the raised exception.
            descs22 = ()
            for i in 1:22
                descs22 = Descriptions.add(descs22, (:ipopt, Symbol(:cpu_, i)))
            end
            err22 = try
                Descriptions.complete(:zzz; descriptions=descs22)
            catch e
                e
            end
            Test.@test err22 isa Exceptions.AmbiguousDescription
            Test.@test length(err22.candidates) == 21       # 20 shown + marker
            Test.@test err22.candidates[end] == "… and 2 more"

            # 2. Closest matches are not discarded. They are carried by the
            #    *hint*, not by `candidates` -- see the issue 557 testset below
            #    for why that distinction matters.
            err = try
                Descriptions.complete(:adnlp, :gpu; descriptions=descs)
            catch e
                e
            end
            Test.@test err isa Exceptions.AmbiguousDescription
            Test.@test occursin("closest matches", err.suggestion)
            Test.@test occursin("(:gpu, :exact)", err.suggestion)
            Test.@test occursin("(:gpu, :krylov)", err.suggestion)
            Test.@test !isempty(err.candidates)
        end

        Test.@testset "issue 557 - Available stays exhaustive, hint carries its list" begin
            # ================================================================
            # NON-REGRESSION: issue #557, follow-up to #553.
            #
            # #553's fix put the similarity-filtered matches into `candidates`.
            # The display layer labels that field "Available", so the message
            # claimed a 12-entry catalog held 5 descriptions, while the hint
            # ("Try one of the closest matches:") printed nothing after its
            # colon. Two invariants, one per field:
            #
            # 1) `candidates` describes the CATALOG -- exhaustive, or truncated
            #    with a marker -- on every path, similar matches or not. The
            #    marker added by #553 was unreachable in practice: it lived on
            #    the branch taken only when nothing resembles the request.
            # 2) `suggestion` carries the closest matches itself, so the hint
            #    is readable on its own line block.
            # ================================================================

            # --- 1. The branch #553 could not reach: > max_show AND a request
            #        that DOES resemble the catalog, so similar_descs != [].
            big = ()
            for i in 1:22
                big = Descriptions.add(big, (:ipopt, Symbol(:cpu_, i)))
            end
            err_big = try
                Descriptions.complete(:ipopt, :nowhere; descriptions=big)
            catch e
                e
            end
            Test.@test err_big isa Exceptions.AmbiguousDescription
            # similar matches exist (every entry shares :ipopt) ...
            Test.@test occursin("closest matches", err_big.suggestion)
            # ... and `candidates` is still the catalog, marker included.
            Test.@test length(err_big.candidates) == 21      # 20 shown + marker
            Test.@test err_big.candidates[end] == "… and 2 more"

            # --- 2. Small catalog: `candidates` is exhaustive, not filtered.
            descs = ()
            for i in 1:10
                descs = Descriptions.add(descs, (:ipopt, Symbol(:cpu_, i)))
            end
            descs = Descriptions.add(descs, (:gpu, :exact))
            descs = Descriptions.add(descs, (:gpu, :krylov))

            err = try
                Descriptions.complete(:adnlp, :gpu; descriptions=descs)
            catch e
                e
            end
            Test.@test err isa Exceptions.AmbiguousDescription
            Test.@test length(err.candidates) == 12
            Test.@test "(:gpu, :exact)" in err.candidates
            # the entries that do NOT resemble the request are listed too --
            # that is what "Available" means
            Test.@test "(:ipopt, :cpu_1)" in err.candidates
            Test.@test !any(occursin("more", c) for c in err.candidates)

            # --- 3. The hint is self-contained: header line, then one line per
            #        closest match.
            lines = split(err.suggestion, '\n')
            Test.@test length(lines) > 1
            Test.@test lines[1] == "Try one of the closest matches:"
            Test.@test Set(lines[2:end]) == Set(["(:gpu, :exact)", "(:gpu, :krylov)"])

            # --- 4. End to end: the rendered message shows them under Hint,
            #        not only in the struct.
            msg = sprint(showerror, err)
            hint_at = findfirst("Hint", msg)
            Test.@test !isnothing(hint_at)
            tail = msg[last(hint_at):end]
            Test.@test occursin("(:gpu, :exact)", tail)
            Test.@test occursin("(:gpu, :krylov)", tail)

            # --- 5. The no-similarity path is untouched: nothing resembles the
            #        request, so the hint stays a single sentence.
            err_none = try
                Descriptions.complete(:zzz; descriptions=descs)
            catch e
                e
            end
            Test.@test err_none isa Exceptions.AmbiguousDescription
            Test.@test !occursin("closest matches", err_none.suggestion)
            Test.@test !occursin('\n', err_none.suggestion)
            Test.@test length(err_none.candidates) == 12
        end

        Test.@testset "Diagnostic field verification" begin
            # Empty catalog - should have diagnostic
            try
                Descriptions.complete(:a; descriptions=())
            catch e
                Test.@test e isa Exceptions.AmbiguousDescription
                Test.@test e.diagnostic == "empty catalog"
            end

            # Unknown symbols - should have diagnostic
            descriptions = ((:a, :b), (:c, :d))
            try
                Descriptions.complete(:x, :y; descriptions=descriptions)
            catch e
                Test.@test e isa Exceptions.AmbiguousDescription
                Test.@test e.diagnostic in ["unknown symbols", "no complete match"]
            end

            # Partial match but not complete - should have diagnostic
            descriptions2 = ((:a, :b, :c), (:d, :e, :f))
            try
                Descriptions.complete(:a, :x; descriptions=descriptions2)
            catch e
                Test.@test e isa Exceptions.AmbiguousDescription
                Test.@test e.diagnostic == "no complete match"
            end
        end
    end
end

end # module

test_complete() = TestComplete.test_complete()
