
# Script to check if .cov files exist during execution
using Pkg
Pkg.activate(".")

println("Starting process with coverage...")
println("PID: $(getpid())")

# Define a function to generate coverage
function foo()
    x = 1
    y = 2
    return x + y
end

foo()

# Check for .cov files
cov_files = filter(f -> endswith(f, ".cov"), readdir("src"))
println("Cov files in src during execution: ", cov_files)

if isempty(cov_files)
    println("No .cov files found yet. Writing happens at exit?")
else
    println("Found .cov files!")
end
