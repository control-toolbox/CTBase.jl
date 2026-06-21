"""
Test runner backend for CTBase.

This extension implements `CTBase.DevTools.run_tests`, allowing test selection
via command-line arguments (globs) and configurable filename/function-name builders.

Most functions in this module have side effects (including file inclusion and
running testsets).
"""
module TestRunner

using CTBase: CTBase
import CTBase.DevTools
import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES
using Test: Test, @testset

include("types.jl")
include("arg_parsing.jl")
include("test_selection.jl")
include("test_execution.jl")
include("progress.jl")
include("entry_point.jl")

end
