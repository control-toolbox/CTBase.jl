"""
$(TYPEDSIGNATURES)

Extracts pairs of docstrings and code blocks from the given AI-generated text.

# Arguments

- `ai_text::String`: The full string response from the AI, possibly containing multiple docstring-code pairs.

# Returns

- `(pairs, response)::Tuple{Vector{Tuple{String,String}}, String}`: A tuple containing a vector of `(docstring, code)` pairs and a string reconstruction with triple-quoted docstrings prepended.

# Example

```julia-repl
julia> text = "\"\"\"Docstring\"\"\"\nfunction f(x)\n  x + 1\nend\n";
julia> extract_docstring_code_pairs(text)
(("Docstring", "function f(x)\n  x + 1\nend"), ...)
```
"""
function extract_docstring_code_pairs(ai_text::String)
    response = ai_text  # Toujours initialiser avec tout le texte
    start_idx = findfirst("\"\"\"", ai_text)
    if start_idx !== nothing
        response = ai_text[start_idx[1]:end]
    end

    # Regex pour capturer chaque bloc docstring + code qui suit
    pattern = r"\"\"\"\s*(.*?)\s*\"\"\"\s*([\s\S]*?)(?=(\"\"\"|$))"s
    pairs = []
    for m in eachmatch(pattern, response)
        doc = strip(m.captures[1])
        code = strip(m.captures[2])
        push!(pairs, (doc, code))
    end

    response = ""
    for (doc, code) in pairs
        response *= "\n\"\"\"\n$doc\n\"\"\"\n$code\n"
    end

    # Retire tout ce qui est après le dernier bloc ```
    idx = findlast("```", response)
    if idx !== nothing
        response = response[1:(idx[1] - 1)]
    end
    return pairs, response
end

"""
$(TYPEDSIGNATURES)

Sends code and optional context to the Mistral API and extracts generated docstrings.

# Arguments

- `path::String`: Path to the Julia source file.
- `complement`: Optional path to a complement file (default `nothing`).
- `tests`: Optional path to a test file (default `nothing`).
- `context`: Optional path to a context file for better generation (default `nothing`).
- `apikey::String`: Mistral API key (default empty).

# Returns

- `(pairs, response)::Tuple{Vector{Tuple{String, String}}, String}`: A tuple containing extracted docstring-code pairs and a reconstructed version of the code with inserted docstrings.

# Example

```julia-repl
julia> CTBase.docstrings("example.jl", apikey="sk-...")
([("Docstring", "function f(x) ... end")], "...full reconstructed text...")
```
"""
function CTBase.docstrings(
    path::String; complement=nothing, tests=nothing, context=nothing, apikey=""
)

    # Read code file
    code_text = read(path, String)

    # Optionally read tests and doc files
    complement_text = complement !== nothing ? read(complement, String) : ""
    tests_text = tests !== nothing ? read(tests, String) : ""
    context_text = context !== nothing ? read(context, String) : ""
    url = "https://api.mistral.ai/v1/chat/completions"
    headers = ["Authorization" => "Bearer $apikey", "Content-Type" => "application/json"]

    # Build a precise prompt for the AI
    prompt = CTBase.generate_prompt(code_text, complement_text, tests_text, context_text)

    # Prepare the data for the API
    data = Dict(
        "model" => "mistral-tiny",
        "messages" => [Dict("role" => "user", "content" => prompt)],
    )

    # Send the request
    response = HTTP.post(url, headers, JSON.json(data))
    sol_str = String(response.body)

    # Parse the response
    result = JSON.parse(sol_str)

    # Extract the AI's answer (assuming Mistral API format)
    ai_text = result["choices"][1]["message"]["content"]

    # Ignore tout ce qui précède le premier bloc triple guillemets
    response = extract_docstring_code_pairs(ai_text)

    return response
end
