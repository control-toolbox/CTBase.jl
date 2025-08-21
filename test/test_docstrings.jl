function test_docstrings()
    @testset "extract_docstring_code_pairs" begin
        ai_text = """
\"\"\"
Adds two numbers.
\"\"\"
function add(x, y)
    return x + y
end

\"\"\"
Subtracts two numbers.
\"\"\"
function subtract(x, y)
    return x - y
end
"""

        expected_pairs = [
            ("Adds two numbers.", "function add(x, y)\n    return x + y\nend"),
            ("Subtracts two numbers.", "function subtract(x, y)\n    return x - y\nend"),
        ]

        pairs, _ = CTBaseDocstrings.extract_docstring_code_pairs(ai_text)

        @test pairs == expected_pairs

        false_pair = []

        @test pairs != false_pair
    end
end
