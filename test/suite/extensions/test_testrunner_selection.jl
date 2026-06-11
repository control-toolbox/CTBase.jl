module TestTestRunnerSelection

import Test
import CTBase

const TestRunner = Base.get_extension(CTBase, :TestRunner)

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_testrunner_selection()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_select_tests" begin
        select_tests = TestRunner._select_tests

        # Mock filename builder for testing
        test_builder_sym = name -> Symbol(:test_, name)
        test_builder_str = name -> "test_" * String(name)

        # Mocking readdir requires a temporary directory or we mock the fs behavior? 
        # Easier: we test the filtering logic with a custom test_dir.
        # Let's create a temporary directory structure for testing.

        mktempdir() do temp_dir
            # Create some dummy test files
            touch(joinpath(temp_dir, "test_utils.jl"))
            touch(joinpath(temp_dir, "test_core.jl"))
            touch(joinpath(temp_dir, "runtests.jl")) # Should be ignored
            touch(joinpath(temp_dir, "readme.md"))   # Should be ignored

            # ==========================================================
            # Scenario 1: Auto-discovery (available_tests empty)
            # ==========================================================
            Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Auto-discovery (empty available_tests)" begin
                # Empty args -> run all .jl files (excluding runtests.jl)
                # Names derived as basenames
                sel = select_tests(String[], Symbol[], false, identity; test_dir=temp_dir)
                Test.@test sort(sel) == ["test_core.jl", "test_utils.jl"]

                # Run all (-a) -> same result
                sel = select_tests(String[], Symbol[], true, identity; test_dir=temp_dir)
                Test.@test sort(sel) == ["test_core.jl", "test_utils.jl"]

                # Globbing: select only utils
                sel = select_tests(
                    ["test_utils"], Symbol[], false, identity; test_dir=temp_dir
                )
                Test.@test sel == ["test_utils.jl"]

                # Globbing: pattern matching
                sel = select_tests(
                    ["test_c*"], Symbol[], false, identity; test_dir=temp_dir
                )
                Test.@test sel == ["test_core.jl"]

                # Globbing: match filename?
                sel = select_tests(
                    ["test_core_jl"], Symbol[], false, identity; test_dir=temp_dir
                )
                # "^test_core_jl$" doesn't match "test_core.jl" or "test_core"
                Test.@test isempty(sel)

                sel = select_tests(
                    ["test_core.jl"], Symbol[], false, identity; test_dir=temp_dir
                )
                Test.@test sel == ["test_core.jl"]
            end

            # ==========================================================
            # Scenario 2: With available_tests
            # ==========================================================
            Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "With available_tests" begin
                available = [:utils, :core]

                # Note: TestRunner checks if file exists via builder
                # test_utils.jl exists -> :utils is valid
                # test_core.jl exists -> :core is valid

                # Empty args -> run all valid available tests
                sel = select_tests(
                    String[], available, false, test_builder_sym; test_dir=temp_dir
                )
                Test.@test sort(sel) == [:core, :utils]

                # Selection
                sel = select_tests(
                    ["utils"], available, false, test_builder_sym; test_dir=temp_dir
                )
                Test.@test sel == [:utils]

                # Globbing over available names
                # available test :core, file: test_core.jl
                sel = select_tests(
                    ["c*"], available, false, test_builder_sym; test_dir=temp_dir
                )
                Test.@test sel == [:core]

                # Globbing over filename without extension
                # available test :core, file: test_core.jl
                sel = select_tests(
                    ["test_core"], available, false, test_builder_sym; test_dir=temp_dir
                )
                Test.@test sel == [:core]

                # Builder may return String
                sel = select_tests(
                    ["core"], available, false, test_builder_str; test_dir=temp_dir
                )
                Test.@test sel == [:core]
            end

            Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "symbol in subdirectory" begin
                mkpath(joinpath(temp_dir, "suite_src"))
                touch(joinpath(temp_dir, "suite_src", "test_utils.jl"))

                available = [:utils]

                sel = select_tests(
                    String[], available, false, test_builder_sym; test_dir=temp_dir
                )
                Test.@test sel == [:utils]
            end

            Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "available_tests may be directories" begin
                mkpath(joinpath(temp_dir, "suite"))
                touch(joinpath(temp_dir, "suite", "test_a.jl"))
                touch(joinpath(temp_dir, "suite", "test_b.jl"))

                available = TestRunner.TestSpec["suite"]
                sel = select_tests(String[], available, false, identity; test_dir=temp_dir)
                Test.@test sel == ["suite/test_a.jl", "suite/test_b.jl"]

                sel = select_tests(
                    ["suite/test_a"], available, false, identity; test_dir=temp_dir
                )
                Test.@test sel == ["suite/test_a.jl"]
            end

            Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "glob: match basename without test_ prefix" begin
                mkpath(joinpath(temp_dir, "suite_src"))
                touch(joinpath(temp_dir, "suite_src", "test_utils.jl"))

                available = TestRunner.TestSpec["suite_src/*"]

                sel = select_tests(["utils"], available, false, identity; test_dir=temp_dir)
                Test.@test sel == ["suite_src/test_utils.jl"]
            end

            Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "bare directory selection" begin
                mkpath(joinpath(temp_dir, "suite_norm"))
                touch(joinpath(temp_dir, "suite_norm", "test_x.jl"))
                touch(joinpath(temp_dir, "suite_norm", "test_y.jl"))

                available = TestRunner.TestSpec["suite_norm/*"]

                # "suite_norm" (no wildcard) should behave like "suite_norm/*"
                sel = select_tests(
                    ["suite_norm"], available, false, identity; test_dir=temp_dir
                )
                Test.@test sort(sel) == ["suite_norm/test_x.jl", "suite_norm/test_y.jl"]

                # Trailing slash should also work
                sel = select_tests(
                    ["suite_norm/"], available, false, identity; test_dir=temp_dir
                )
                Test.@test sort(sel) == ["suite_norm/test_x.jl", "suite_norm/test_y.jl"]

                # Explicit wildcard still works
                sel = select_tests(
                    ["suite_norm/*"], available, false, identity; test_dir=temp_dir
                )
                Test.@test sort(sel) == ["suite_norm/test_x.jl", "suite_norm/test_y.jl"]
            end

            Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "bare nested directory selection" begin
                mkpath(joinpath(temp_dir, "suite_deep", "sub"))
                touch(joinpath(temp_dir, "suite_deep", "sub", "test_z.jl"))

                available = TestRunner.TestSpec["suite_deep/sub/*"]

                # "suite_deep/sub" should match "suite_deep/sub/*"
                sel = select_tests(
                    ["suite_deep/sub"], available, false, identity; test_dir=temp_dir
                )
                Test.@test sel == ["suite_deep/sub/test_z.jl"]
            end
        end
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_find_symbol_test_file_rel" begin
        find_symbol_file = TestRunner._find_symbol_test_file_rel

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "symbol resolution: shallowest match" begin
            mktempdir() do temp_dir
                mkpath(joinpath(temp_dir, "a"))
                mkpath(joinpath(temp_dir, "a", "b"))
                touch(joinpath(temp_dir, "a", "test_x.jl"))
                touch(joinpath(temp_dir, "a", "b", "test_x.jl"))

                rel = find_symbol_file(:x, n -> "test_" * String(n); test_dir=temp_dir)
                Test.@test rel == joinpath("a", "test_x.jl")
            end
        end
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "order preservation" begin
        parse_args = TestRunner._parse_test_args
        select_tests = TestRunner._select_tests

        # Selections should preserve order in ARGS parsing
        (sel, _, _) = parse_args(["z", "a", "m"])
        Test.@test sel == ["z", "a", "m"]

        # Using custom select_tests to verify preservation behavior
        mktempdir() do temp_dir
            touch(joinpath(temp_dir, "z.jl"))
            touch(joinpath(temp_dir, "a.jl"))
            touch(joinpath(temp_dir, "m.jl"))
            touch(joinpath(temp_dir, "b.jl"))

            # Case 1: Available list order determines output order if provided
            sel = select_tests(
                ["z", "a"], [:a, :b, :z], false, identity; test_dir=temp_dir
            )
            Test.@test sel == [:a, :z] # candidates order candidate list order

            # Case 2: Auto-discovery order (filesystem order, filtered)
            # We can't guarantee FS order, so checking set equality
            sel = select_tests(["z", "a"], Symbol[], false, identity; test_dir=temp_dir)
            Test.@test Set(sel) == Set(["a.jl", "z.jl"])
        end
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "duplicate selections preserved" begin
        parse_args = TestRunner._parse_test_args
        # Duplicates are not filtered (caller's responsibility)
        (sel, _, _) = parse_args(["utils", "utils"])
        Test.@test sel == ["utils", "utils"]
    end

    return nothing
end

end # module

test_testrunner_selection() = TestTestRunnerSelection.test_testrunner_selection()
