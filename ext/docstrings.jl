function extract_docstring_code_pairs(ai_text::String)
    
    start_idx = findfirst("\"\"\"", ai_text)
    if start_idx !== nothing
        response = ai_text[start_idx[1]:end]
    end
    
    # Regex pour capturer chaque bloc docstring + code qui suit
    pattern = r"\"\"\"(.*?)\"\"\"\s*([\s\S]*?)(?=(\"\"\"|$))"
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

    return [pairs, response]
end


#générate an answer from an IA. 
function docstrings(path; tests=nothing, doc=nothing, apikey="")
    # Read code file
    code_text = read(path, String)
    # Optionally read tests and doc files
    tests_text = tests !== nothing ? read(tests, String) : ""
    doc_text = doc !== nothing ? read(doc, String) : ""
    url = "https://api.mistral.ai/v1/chat/completions"
    headers = [
        "Authorization" => "Bearer $apikey",
        "Content-Type" => "application/json"
    ]

    # Build a precise prompt for the AI
prompt = """
Pour chaque type, fonction ou exception Julia fourni dans le code ci-dessous, génère une docstring Julia complète au format Documenter.jl, en respectant les points suivants :

- La docstring doit être placée **juste au-dessus** de la déclaration correspondante (type, struct, fonction, exception).
- Pour les **types et exceptions**, commence la docstring par `\"\"\"` suivi de `\$(TYPEDEF)` sur la première ligne.
- Pour les **fonctions**, commence la docstring par `\"\"\"` suivi de `\$(TYPEDSIGNATURES)` sur la première ligne.
- Donne une **description claire et concise** du rôle du type, de la fonction ou de l’exception.
- Pour les structs et exceptions, ajoute une section `# Fields` listant chaque champ avec son type et une courte description.
- Pour les fonctions, ajoute une section `# Arguments` listant chaque argument, puis une section `# Returns` si pertinent.
- Ajoute une section `# Example` montrant un exemple d’utilisation dans un bloc ```julia-repl.
- **N’ajoute rien d’autre** que les docstrings et le code fourni : ne crée pas de nouveaux types, fonctions ou exemples non présents dans le code.

**Exemple attendu pour un type ou une exception** :

\"\"\"
\$(TYPEDEF)

Exception thrown when a function call is not authorized in the current context or with the given arguments.

# Fields

- `var::String`: A message explaining why the call is unauthorized.

# Example

```julia-repl
julia> throw(UnauthorizedCall("user does not have permission"))
ERROR: UnauthorizedCall: user does not have permission
```
\"\"\"
struct UnauthorizedCall <: CTException
    var::String
end

**Exemple attendu pour une fonction** :

\"\"\"
\$(TYPEDSIGNATURES)

Customizes the printed message of the exception.

# Arguments

- `io::IO`: The IO stream to print to.
- `e::UnauthorizedCall`: The exception instance.

# Example

```julia-repl
julia> showerror(stdout, UnauthorizedCall("user does not have permission"))
UnauthorizedCall: user does not have permission
```
\"\"\"
function Base.showerror(io::IO, e::UnauthorizedCall)
    printstyled(io, "UnauthorizedCall"; color=:red, bold=true)
    return print(io, ": ", e.var)
end

IMPORTANT :  
- Ne documente **que** le code fourni ci-dessous, sans ajouter, modifier ou inventer de nouveaux types, fonctions ou exemples.
- Place chaque docstring juste avant la déclaration correspondante, sans texte entre la docstring et le code.

Voici le code à documenter :
$code_text

$(tests !== nothing ? "\nVoici les tests associés :\n$tests_text" : "")
$(doc !== nothing ? "\nVoici la documentation existante :\n$doc_text" : "")

Respecte strictement ce format pour chaque type, fonction ou exception générée.
"""

    # Prepare the data for the API
    data = Dict(
        "model" => "mistral-tiny",
        "messages" => [
            Dict("role" => "user", "content" => prompt)
        ]
    )

    # Send the request
    response = HTTP.post(
        url,
        headers,
        JSON.json(data)
    )

    sol_str = String(response.body)
    # Parse the response
    result = JSON.parse(sol_str)
    # Extract the AI's answer (assuming Mistral API format)
    ai_text = result["choices"][1]["message"]["content"]
    
    # Ignore tout ce qui précède le premier bloc triple guillemets
    response = extract_docstring_code_pairs(ai_text)[2]
        
    #print(ai_text)
    #print(response)

    return response
end



# filepath: /root/ENSEEIHT/Stage/CTBase.jl/ext/docstrings.jl
function docstrings_file(path; tests=nothing, doc=nothing, apikey="")
    ai_text = docstrings(path, tests=tests, doc=doc, apikey=apikey)
    # Supprime toutes les lignes qui ne contiennent que ```
    ai_text = join(filter(line -> strip(line) != "```", split(ai_text, '\n')), "\n")
    dir, filename = splitdir(path)
    name, ext = splitext(filename)
    outpath = joinpath(dir, "$(name)_docstrings$(ext)")
    open(outpath, "w") do io
        write(io, ai_text)
    end
    return outpath
end