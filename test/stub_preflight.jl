struct DummyTestRunnerTag <: CTBase.AbstractTestRunnerTag end

const STUB_PREFLIGHT = let
    test_runner_extension_before = Base.get_extension(CTBase, :TestRunner)

    run_tests_error = nothing
    try
        CTBase.run_tests(DummyTestRunnerTag())
    catch e
        run_tests_error = e
    end

    (
        test_runner_extension_before=test_runner_extension_before,
        run_tests_error=run_tests_error,
    )
end
