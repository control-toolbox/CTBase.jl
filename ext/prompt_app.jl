"""
$(TYPEDSIGNATURES)

Returns the HTML source code for the Julia Docstrings Generator web application.

# Returns

- `html::String`: A string containing the full HTML document used to render the web interface.

# Example

```julia-repl
julia> html = html_code_docstrings_app();
```
"""
function html_code_promt_app()
html = """
<!DOCTYPE html>
<html lang='en'>
<head>
    <meta charset='UTF-8'>
    <title>Julia Docstrings Prompt Generator</title>
    <!-- Prism CSS: light and dark themes -->
    <link id="prism-theme" rel="stylesheet" href="https://cdn.jsdelivr.net/npm/prismjs@1.29.0/themes/prism-tomorrow.css" />
    <style>
        :root {
            --bg-dark: #23272f;
            --bg-container-dark: #2d333b;
            --text-dark: #ececf1;
            --border-dark: #444950;
            --bg-output-dark: #1f242b;
            --scrollbar-thumb-dark: #10a37f;

            --bg-light: #fafafa;
            --bg-container-light: #ffffff;
            --text-light: #222222;
            --border-light: #ccc;
            --bg-output-light: #f5f5f5;
            --scrollbar-thumb-light: #10a37f;
        }

        body {
            background: var(--bg-dark);
            color: var(--text-dark);
            font-family: 'Segoe UI', Arial, sans-serif;
            margin: 0;
            padding: 0;
            transition: background 0.3s, color 0.3s;
        }
        body.light {
            background: var(--bg-light);
            color: var(--text-light);
        }
        .container {
            max-width: 900px;
            margin: 40px auto;
            background: var(--bg-container-dark);
            border-radius: 12px;
            box-shadow: 0 4px 24px #0006;
            padding: 2em 2.5em 3em 2.5em; /* extra bottom padding for copy button */
            transition: background 0.3s;
            position: relative;
        }
        body.light .container {
            background: var(--bg-container-light);
            box-shadow: 0 4px 24px #aaa;
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
            color: inherit;
        }
        .tabs {
            display: flex;
            gap: 0.5em;
            margin-bottom: 1em;
            border-bottom: 2px solid var(--border-dark);
        }
        body.light .tabs {
            border-color: var(--border-light);
        }
        .tab {
            flex: 1;
            text-align: center;
            padding: 0.5em 0;
            cursor: pointer;
            background: var(--bg-container-dark);
            color: var(--text-dark);
            border: 1px solid var(--border-dark);
            border-bottom: none;
            border-radius: 6px 6px 0 0;
            user-select: none;
            transition: background 0.3s, color 0.3s, border-color 0.3s;
        }
        body.light .tab {
            background: var(--bg-container-light);
            color: var(--text-light);
            border-color: var(--border-light);
        }
        .tab.active {
            background: var(--bg-output-dark);
            color: #10a37f;
            font-weight: 600;
            border-color: #10a37f;
            border-bottom: 2px solid var(--bg-output-dark);
        }
        body.light .tab.active {
            background: var(--bg-output-light);
            border-color: #10a37f;
            color: #10a37f;
            border-bottom: 2px solid var(--bg-output-light);
        }
        textarea {
            width: 100%;
            background: var(--bg-dark);
            color: var(--text-dark);
            border: 1px solid var(--border-dark);
            border-radius: 6px;
            padding: 0.7em;
            font-size: 1em;
            resize: none;
            transition: background 0.3s, color 0.3s, border 0.3s;
            min-height: 150px;
            max-height: 600px;
            overflow-y: auto;
            box-sizing: border-box;
            /* HIDE all textareas by default */
            display: none;
        }
        textarea.active {
            /* SHOW only the active textarea */
            display: block;
        }
        body.light textarea {
            background: var(--bg-light);
            color: var(--text-light);
            border: 1px solid var(--border-light);
        }
        textarea:focus {
            border: 1.5px solid #10a37f;
            outline: none;
        }
        .flex-row {
            display: flex;
            gap: 1em;
            flex-wrap: wrap;
            margin-top: 0.5em;
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
            transition: background 0.2s, box-shadow 0.2s;
            margin-top: 0.5em;
        }
        button:hover, button:focus {
            background: #13c08a;
            outline: none;
            box-shadow: 0 0 5px #13c08a;
        }
        .output {
            margin-top: 1.5em;
            background: var(--bg-output-dark);
            border: 1px solid var(--border-dark);
            border-radius: 8px;
            padding: 1.5em;
            font-family: 'Fira Mono', 'Consolas', monospace;
            font-size: 1.1em;
            line-height: 1.5;
            color: var(--text-dark);
            min-height: 150px;
            max-height: 800px;
            overflow-y: auto;
            box-sizing: border-box;
            user-select: text;
            white-space: pre-wrap;
            word-wrap: break-word;
            transition: background 0.3s, color 0.3s, border 0.3s;
            position: relative;
        }
        body.light .output {
            background: var(--bg-output-light);
            border: 1px solid var(--border-light);
            color: var(--text-light);
            box-shadow: 0 0 10px #ccc inset;
        }
        .output.generating {
            font-style: italic;
            color: #a0a0a0;
        }
        hr {
            border: 0;
            border-top: 1px solid #444;
            margin: 2em 0;
            transition: border-color 0.3s;
        }
        body.light hr {
            border-top-color: #ccc;
        }
        @media (max-width: 900px) {
            .flex-row { flex-direction: column; }
        }
        /* Scrollbar styling */
        .output::-webkit-scrollbar {
            width: 10px;
        }
        .output::-webkit-scrollbar-track {
            background: var(--bg-output-dark);
            border-radius: 8px;
        }
        body.light .output::-webkit-scrollbar-track {
            background: var(--bg-output-light);
        }
        .output::-webkit-scrollbar-thumb {
            background: var(--scrollbar-thumb-dark);
            border-radius: 8px;
        }
        body.light .output::-webkit-scrollbar-thumb {
            background: var(--scrollbar-thumb-light);
        }
        /* Firefox */
        .output {
            scrollbar-width: thin;
            scrollbar-color: var(--scrollbar-thumb-dark) var(--bg-output-dark);
        }
        body.light .output {
            scrollbar-color: var(--scrollbar-thumb-light) var(--bg-output-light);
        }

        /* Copy button at bottom right of output */
        #copy {
            position: absolute;
            right: 1em;
            bottom: 1em;
            padding: 0.4em 0.9em;
            font-size: 0.9em;
            margin-top: 0;
        }
        #copy-check {
            margin-left: 0.5em;
            font-weight: bold;
            color: #10a37f;
        }

        /* Toggle theme button top right inside container */
        #toggle-theme {
            position: absolute;
            top: 1em;
            right: 1em;
            padding: 0.4em 1em;
            font-size: 0.9em;
            margin-top: 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h2>Julia Docstrings Prompt Generator</h2>

        <div class="tabs" role="tablist" aria-label="Input Tabs">
            <div class="tab active" role="tab" tabindex="0" aria-selected="true" aria-controls="code-tab" id="code-tab-btn">Code</div>
            <div class="tab" role="tab" tabindex="-1" aria-selected="false" aria-controls="test-tab" id="test-tab-btn">Tests (optional)</div>
            <div class="tab" role="tab" tabindex="-1" aria-selected="false" aria-controls="context-tab" id="context-tab-btn">Context (optional)</div>
        </div>

        <form id="form" novalidate>
            <textarea id="code" placeholder="Paste your Julia code here" spellcheck="false" role="tabpanel" aria-labelledby="code-tab-btn" rows="7"></textarea>

            <textarea id="test" placeholder="Paste your Julia tests here" spellcheck="false" role="tabpanel" aria-labelledby="test-tab-btn" rows="7"></textarea>

            <textarea id="context" placeholder="Add optional context to improve doc quality..." spellcheck="false" role="tabpanel" aria-labelledby="context-tab-btn" rows="7"></textarea>

            <div class="flex-row">
                <button type="submit">Generate Prompt</button>
                <button type="button" id="example">Load Example</button>
                <button type="button" id="quit">Quit the app</button>
            </div>
        </form>

        <hr>

        <pre class="output language-julia" id="output" tabindex="0" aria-live="polite"></pre>
        <button type="button" id="copy" aria-label="Copy prompt output">
            Copy Prompt <span id="copy-check" style="display:none;">✓</span>
        </button>
        <button type="button" id="toggle-theme" aria-label="Toggle dark/light mode">Toggle Dark/Light Mode</button>
    </div>

    <!-- Prism.js core + Julia language -->
    <script src="https://cdn.jsdelivr.net/npm/prismjs@1.29.0/prism.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/prismjs@1.29.0/components/prism-julia.min.js"></script>

    <script>
        function autoResizeTextarea(el) {
            // Ensure no inline display style to not conflict with CSS classes
            el.style.removeProperty('display');
            el.style.height = 'auto';
            el.style.height = el.scrollHeight + 'px';
        }

        // Apply resizing to all textareas on input
        document.querySelectorAll('textarea').forEach(function(textarea) {
            textarea.addEventListener('input', function() {
                autoResizeTextarea(this);
            });
            // Adjust on load if text is already present
            autoResizeTextarea(textarea);
        });

        const tabs = document.querySelectorAll('.tab');
        const textareas = {
            code: document.getElementById('code'),
            test: document.getElementById('test'),
            context: document.getElementById('context')
        };

        function activateTab(name) {
            tabs.forEach(tab => {
                const isActive = tab.id === name + '-tab-btn';
                tab.classList.toggle('active', isActive);
                tab.setAttribute('aria-selected', isActive ? 'true' : 'false');
                tab.tabIndex = isActive ? 0 : -1;
            });
            Object.entries(textareas).forEach(([key, ta]) => {
                if (key === name) {
                    ta.classList.add('active');
                    setTimeout(() => ta.focus(), 0);
                } else {
                    ta.classList.remove('active');
                }
            });
        }

        document.addEventListener('DOMContentLoaded', () => {
            // Show only the first textarea on load
            activateTab('code');

            // Auto resize all textareas once for initial size
            Object.values(textareas).forEach(el => autoResizeTextarea(el));
        });

        tabs.forEach(tab => {
            tab.addEventListener('click', () => {
                activateTab(tab.id.replace('-tab-btn','')); // fix: match '-tab-btn'
            });
            tab.addEventListener('keydown', e => {
                let index = Array.from(tabs).indexOf(e.target);
                if (e.key === "ArrowRight" || e.key === "ArrowDown") {
                    e.preventDefault();
                    let nextIndex = (index + 1) % tabs.length;
                    tabs[nextIndex].focus();
                    activateTab(tabs[nextIndex].id.replace('-tab-btn',''));
                } else if (e.key === "ArrowLeft" || e.key === "ArrowUp") {
                    e.preventDefault();
                    let prevIndex = (index - 1 + tabs.length) % tabs.length;
                    tabs[prevIndex].focus();
                    activateTab(tabs[prevIndex].id.replace('-tab-btn',''));
                }
            });
        });

        async function generatePrompt() {
            const code = textareas.code.value;
            const test = textareas.test.value;
            const context = textareas.context.value;
            const outputEl = document.getElementById('output');

            outputEl.textContent = "Generating...";
            outputEl.classList.add("generating");
            Prism.highlightElement(outputEl);

            try {
                const resp = await fetch('/run', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({ code: code, test: test, context: context })
                });
                const text = await resp.text();
                outputEl.textContent = text;
                Prism.highlightElement(outputEl);
            } catch (err) {
                outputEl.textContent = "Error during request: " + err;
            } finally {
                outputEl.classList.remove("generating");
            }
        }

        document.getElementById('form').onsubmit = function(e) {
            e.preventDefault();
            generatePrompt();
        };

        document.getElementById('quit').onclick = function () {
            Object.values(textareas).forEach(ta => ta.value = "");
            const outputEl = document.getElementById('output');
            outputEl.textContent = "Session cleared. Closing...";
            outputEl.classList.remove("generating");
            fetch('/quit').then(() => {
                setTimeout(() => window.close(), 700);
            });
        };

        const copyButton = document.getElementById('copy');
        const copyCheck = document.getElementById('copy-check');
        const outputEl = document.getElementById('output');

        // Handle copy logic
        copyButton.onclick = function () {
            const text = outputEl.textContent;
            if (text.trim().length === 0) {
                return; // Do nothing if there's nothing to copy
            }
            navigator.clipboard.writeText(text).then(() => {
                copyCheck.style.display = "inline";
                copyButton.disabled = true;
                // Reset after 1.5 seconds if no content change
                setTimeout(() => {
                    copyCheck.style.display = "none";
                    copyButton.disabled = false;
                }, 1500);
            });
        };

        // Reset checkmark on prompt change
        const observer = new MutationObserver(() => {
            copyCheck.style.display = "none";
            copyButton.disabled = false;
        });
        observer.observe(outputEl, { childList: true, subtree: true });

        document.getElementById('example').onclick = function () {
            textareas.code.value = "function square(x)\\n    x^2\\nend";
            textareas.test.value = "using Test\\n@test square(3) == 9";
            textareas.context.value = "";
            Object.values(textareas).forEach(el => autoResizeTextarea(el));
            activateTab('code');
        };

        // Dark/light mode toggle
        const toggleThemeBtn = document.getElementById('toggle-theme');
        toggleThemeBtn.onclick = () => {
            document.body.classList.toggle('light');
            // Swap Prism theme css
            const prismLink = document.getElementById('prism-theme');
            if(document.body.classList.contains('light')) {
                prismLink.href = "https://cdn.jsdelivr.net/npm/prismjs@1.29.0/themes/prism.css";
            } else {
                prismLink.href = "https://cdn.jsdelivr.net/npm/prismjs@1.29.0/themes/prism-tomorrow.css";
            }
        };
    </script>
</body>

</html>
"""
    return html
end

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

julia> handle_docstrings_app(req)
HTTP.Response(404, ["Content-Type" => "text/plain"], "Not found")
```
"""
function handle_prompt_app(req)
    if req.target == "/"
        return HTTP.Response(200, ["Content-Type" => "text/html"], html_code_promt_app())

    elseif req.target == "/run" && req.method == "POST"
        data = JSON.parse(String(req.body))
        user_code = data["code"]
        user_test = get(data, "test", "")
        user_context = get(data, "context", "")
        prompt = ""
        try
            prompt = CTBase.generate_prompt(user_code, user_test, user_context)
        catch err
            prompt = "Error during generation: $(err)"
        end
        return HTTP.Response(200, ["Content-Type" => "text/plain"], prompt)

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

Starts the local documentation server for the `CTBase` application.

# Arguments

- `::CTBase.DocstringsAppTag`: A dispatch tag used to identify the application.

# Returns

- `nothing`: This function does not return a meaningful value.

# Example

```julia-repl
julia> CTBase.docstrings_app(CTBase.DocstringsAppTag())
Open http://localhost:8080 in your browser.
```
"""
function CTBase.prompt_app(::CTBase.DocstringsAppTag)
    println("Open http://localhost:8081 in your browser.")
    HTTP.serve(handle_prompt_app, "127.0.0.1", 8081)
    return nothing
end