html = """
<!DOCTYPE html>
<html lang='en'>
<head>
    <meta charset='UTF-8'>
    <title>Julia Docstring Generator</title>
    <style>
        body {
            background: #23272f;
            color: #ececf1;
            font-family: 'Segoe UI', Arial, sans-serif;
            margin: 0;
            padding: 0;
        }
        .container {
            max-width: 900px;
            margin: 40px auto;
            background: #2d333b;
            border-radius: 12px;
            box-shadow: 0 4px 24px #0006;
            padding: 2em 2.5em 2em 2.5em;
        }
        h2 {
            text-align: center;
            font-weight: 600;
            margin-bottom: 1.5em;
            color: #10a37f;
            letter-spacing: 1px;
        }
        label {
            font-weight: 500;
            color: #ececf1;
        }
        .api {
            margin-bottom: 1em;
        }
        .flex-row {
            display: flex;
            gap: 1em;
        }
        .flex-col {
            flex: 1;
            display: flex;
            flex-direction: column;
        }
        input[type="password"], textarea {
            width: 100%;
            background: #23272f;
            color: #ececf1;
            border: 1px solid #444950;
            border-radius: 6px;
            padding: 0.7em;
            margin-top: 0.3em;
            margin-bottom: 1em;
            font-size: 1em;
            resize: none;
            transition: border 0.2s;
            min-height: 60px;
            max-height: 600px;
            overflow-y: auto;
        }
        input[type="password"]:focus, textarea:focus {
            border: 1.5px solid #10a37f;
            outline: none;
        }
        button {
            background: #10a37f;
            color: #fff;
            border: none;
            border-radius: 6px;
            padding: 0.7em 1.5em;
            font-size: 1.1em;
            font-weight: 600;
            cursor: pointer;
            transition: background 0.2s;
            margin-top: 0.5em;
        }
        button:hover {
            background: #13c08a;
        }
        .output {
            margin-top: 1.5em;
            background: #23272f;
            border: 1px solid #444950;
            border-radius: 8px;
            padding: 1.2em;
            white-space: pre-wrap;
            font-family: 'Fira Mono', 'Consolas', monospace;
            font-size: 1em;
            color: #ececf1;
            min-height: 80px;
            max-height: 800px;
            overflow-y: auto;
        }
        @media (max-width: 900px) {
            .flex-row { flex-direction: column; }
        }
    </style>
</head>
<body>
    <div class="container">
        <h2>Julia Docstring Generator</h2>
        <div class="api">
            <label for="apikey">Mistral API Key:</label>
            <input type="password" id="apikey" placeholder="Enter your API key here" required>
        </div>
        <form id="form">
            <label for="input">Julia Code</label>
            <textarea id="input" placeholder="Paste your Julia code here"></textarea>
            <div class="flex-row">
                <div class="flex-col">
                    <label for="tests">Julia Tests (optional)</label>
                    <textarea id="tests" placeholder="Paste your Julia tests here"></textarea>
                </div>
                <div class="flex-col">
                    <label for="doc">Context of the code(optional)</label>
                    <textarea id="doc" placeholder="Paste any context here"></textarea>
                </div>
            </div>
            <button type="submit">Generate Documentation</button>
        </form>
        <div class="output" id="output"></div>
        <button type="button" id="quit">Quit the app</button>
    </div>
    <script>
        // Function to dynamically resize textareas
        function autoResizeTextarea(el) {
            el.style.height = 'auto';
            el.style.height = (el.scrollHeight) + 'px';
        }
        // Apply resizing to all textareas on input
        document.querySelectorAll('textarea').forEach(function(textarea) {
            textarea.addEventListener('input', function() {
                autoResizeTextarea(this);
            });
            // Adjust on load if text is already present
            autoResizeTextarea(textarea);
        });

        document.getElementById('form').onsubmit = async function(e) {
            e.preventDefault();
            const input = document.getElementById('input').value;
            const tests = document.getElementById('tests').value;
            const doc = document.getElementById('doc').value;
            const apikey = document.getElementById('apikey').value;
            if (!apikey) {
                document.getElementById('output').textContent = "Please provide your API key.";
                return;
            }
            document.getElementById('output').textContent = "Generating...";
            const resp = await fetch('/run', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ code: input, tests: tests, doc: doc, apikey: apikey })
            });
            const text = await resp.text();
            document.getElementById('output').textContent = text;
        };

        document.getElementById('quit').onclick = function () {
            document.getElementById('input').value = "";
            document.getElementById('tests').value = "";
            document.getElementById('doc').value = "";
            document.getElementById('output').textContent = "Session cleared. Closing...";
            fetch('/quit').then(() => {
                setTimeout(function() {
                    window.close();
                }, 700);
            });
        };

    </script>
</body>
</html>
"""


"""
$(TYPEDSIGNATURES)

Handle an incoming HTTP request and return a suitable response.

# Arguments

- `req::Request`: The request object containing the requested path, method, and body.

# Returns

- `HTTP.Response`: An HTTP response object containing the response status code, headers, and body.

# Example

```julia-repl
julia> req = Request("", HTTP.GET, IOBuffer(""))

julia> handle(req)
HTTP.Response(404, ["Content-Type" => "text/plain"], "Not found")
```
"""


function handle(req)
    if req.target == "/"
        return HTTP.Response(200, ["Content-Type" => "text/html"], html)
    elseif req.target == "/run" && req.method == "POST"
        data = JSON.parse(String(req.body))
        user_code = data["code"]
        user_tests = get(data, "tests", "")
        user_doc = get(data, "doc", "")
        user_apikey = data["apikey"]
        if isempty(user_apikey)
            return HTTP.Response(401, ["Content-Type" => "text/plain"], "Clé API requise.")
        end
        codefile = tempname() * ".jl"
        open(codefile, "w") do io
            write(io, user_code)
        end
        testsfile = nothing
        if !isempty(user_tests)
            testsfile = tempname() * ".jl"
            open(testsfile, "w") do io
                write(io, user_tests)
            end
        end
        docfile = nothing
        if !isempty(user_doc)
            docfile = tempname() * ".jl"
            open(docfile, "w") do io
                write(io, user_doc)
            end
        end
        commented = ""
        try
            commented = CTBase.docstrings(codefile; tests=testsfile, context=docfile, apikey=user_apikey)[2]
        catch err
            commented = "Erreur lors de la génération : $(err)"
        end
        return HTTP.Response(200, ["Content-Type" => "text/plain"], commented)
    
    elseif req.target == "/quit"
        @async begin
            sleep(0.5)
            exit() 
        end
        return HTTP.Response(200, ["Content-Type" => "text/plain"], "Server shutting down.")
    else
        return HTTP.Response(404, ["Content-Type" => "text/plain"], "Not found")
    end
end

"""
$(TYPEDSIGNATURES)

Start the simple API server and run it in the background.

# Example

```julia-repl
julia> CTBase.docstrings_app()
Open http://localhost:8080 in your browser.
```
"""

function CTBase.docstrings_app(::CTBase.DocstringsAppTag)
    println("Open http://localhost:8080 in your browser.")
    HTTP.serve(handle, "127.0.0.1", 8080)
    return nothing
end