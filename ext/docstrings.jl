"""
$(TYPEDSIGNATURES)

Extracts pairs of docstrings and code blocks from the given AI-generated text.

# Arguments

- `ai_text::String`: The full string response from the AI, possibly containing multiple docstring-code pairs.

# Returns

- `(pairs, reponse)::Tuple{Vector{Tuple{String,String}}, String}`: A tuple containing a vector of `(docstring, code)` pairs and a string reconstruction with triple-quoted docstrings prepended.

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

    reponse = ""
    for (doc, code) in pairs
        reponse *= "\n\"\"\"\n$doc\n\"\"\"\n$code\n"
    end

    # Retire tout ce qui est après le dernier bloc ```
    idx = findlast("```", reponse)
    if idx !== nothing
        reponse = reponse[1:(idx[1] - 1)]
    end
    return pairs, reponse
end

"""
$(TYPEDSIGNATURES)

Sends code and optional context to the Mistral API and extracts generated docstrings.

# Arguments

- `path::String`: Path to the Julia source file.
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
function CTBase.docstrings(path::String; tests=nothing, context=nothing, apikey="")

    # Read code file
    code_text = read(path, String)

    # Optionally read tests and doc files
    tests_text = tests !== nothing ? read(tests, String) : ""
    context_text = context !== nothing ? read(context, String) : ""
    url = "https://api.mistral.ai/v1/chat/completions"
    headers = ["Authorization" => "Bearer $apikey", "Content-Type" => "application/json"]

    # Build a precise prompt for the AI
    prompt = CTBase.generate_prompt(code_text, tests_text, context_text)

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

"""
$(TYPEDSIGNATURES)

Generates a new file with inserted docstrings and saves it to disk.

# Arguments

- `path`: Path to the source Julia file.
- `tests`: Optional path to test file (default `nothing`).
- `context`: Optional path to context file (default `nothing`).
- `apikey`: API key for Mistral (default empty string).

# Returns

- `outpath::String`: Path to the new file with `_docstrings` appended to the original filename.

# Example

```julia-repl
julia> docstrings_file("myfile.jl", apikey="sk-...")
"myfile_docstrings.jl"
```
"""
function docstrings_file(path; tests=nothing, context=nothing, apikey="")
    pairs, ai_text = docstrings(path; tests=tests, context=context, apikey=apikey)

    #code_unchanged_check
    original_code = read(path, String)
    code_unchanged_check(pairs, original_code)

    # Supprime toutes les lignes qui ne contiennent que ```
    dir, filename = splitdir(path)
    name, ext = splitext(filename)
    outpath = joinpath(dir, "$(name)_docstrings$(ext)")
    open(outpath, "w") do io
        write(io, ai_text)
    end

    return outpath
end

"""
$(TYPEDSIGNATURES)

Checks whether the generated docstring/code blocks altered the original code.

# Arguments

- `pairs`: A vector of `(docstring, code)` pairs.
- `original_code::String`: The original source code as a string.
- `display::Bool`: Whether to display line-by-line differences if any (default `true`).

# Returns

- `code_changed::Int`: Returns `1` if the code was changed, `0` otherwise.

# Example

```julia-repl
julia> code_unchanged_check([("doc", "function f() end")], "function f() end")
0
```
"""
function code_unchanged_check(pairs, original_code::String; display=true)

    # Reconstruit le code à partir des couples (docstring, code)
    reconstructed = join([code for (doc, code) in pairs], "\n\n")

    # Normalise : retire les espaces et retours à la ligne superflus
    norm = s -> join(split(strip(s)))
    orig_norm = norm(original_code)
    recon_norm = norm(reconstructed)
    if orig_norm != recon_norm
        display &&
            println("Le code a changé (différences ignorées : espaces/retours à la ligne).")

        # Affiche les différences ligne à ligne pour aider à localiser
        orig_lines = split(strip(original_code), '\n')
        recon_lines = split(strip(reconstructed), '\n')
        maxlen = max(length(orig_lines), length(recon_lines))
        for i in 1:(maxlen - 1)
            orig_line = i <= length(orig_lines) ? orig_lines[i] : ""
            recon_line = i <= length(recon_lines) ? recon_lines[i] : ""
            if (strip(orig_line) != strip(recon_line)) && display
                println("Différence à la ligne $i :")
                println("  original   : ", orig_line)
                println("  généré     : ", recon_line)
            end
        end
        return 1
    else
        return 0
    end
end
