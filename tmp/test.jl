using Pkg
Pkg.activate("tmp")

using HTTP
using JSON

api_key = "AhjfYFU8uDyigVgJTL07hC95GUsOqnaw"
url = "https://api.mistral.ai/v1/chat/completions"

headers = Dict(
    "Authorization" => "Bearer $api_key",
    "Content-Type" => "application/json"
)

data = Dict(
    "model" => "mistral-tiny",
    "messages" => [
        Dict("role" => "user", "content" => "écrit une blague")
    ]
)

response = HTTP.post(
    url,
    headers,
    JSON.json(data)
)



u = String(response.body)
println(u)

result = JSON.parse(u)

print(result["choices"][1]["message"]["content"])



#body_str = String(response.body)
#result = JSON.parse(body_str)
#content = result["choices"][1]["message"]["content"]


file = "./tmp/exemple.jl"

include("../ext/docstrings.jl")
docstrings_file(file, apikey=api_key)