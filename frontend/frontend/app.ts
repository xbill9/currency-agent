import './style.css';

const createForm = document.getElementById('create-form') as HTMLFormElement;
const topicInput = document.getElementById('topic-input') as HTMLInputElement;
const createButton = document.getElementById('create-button') as HTMLButtonElement;
const progressContainer = document.getElementById('progress-container') as HTMLElement;
const statusText = document.getElementById('status-text') as HTMLElement;
const chatOutput = document.getElementById('chat-output') as HTMLElement;
const outputText = document.getElementById('output-text') as HTMLElement;

const agentUrlInput = document.getElementById('agent-url') as HTMLInputElement;
const mcpUrlInput = document.getElementById('mcp-url') as HTMLInputElement;
const targetServerRadios = document.getElementsByName('target-server') as NodeListOf<HTMLInputElement>;

// Generate a random session ID for this browser session
const sessionId = 'session-' + Math.random().toString(36).substring(2, 15);

// Fetch config on load
async function initConfig() {
    try {
        const response = await fetch('/api/config');
        if (response.ok) {
            const config = await response.json();
            if (config.agent_server_url) agentUrlInput.value = config.agent_server_url;
            if (config.mcp_server_url) mcpUrlInput.value = config.mcp_server_url;
        }
    } catch (e) {
        console.error('Failed to load config:', e);
    }
}
initConfig();

function showProgress() {
    topicInput.disabled = true;
    createButton.disabled = true;
    createButton.innerHTML = 'Querying...';
    progressContainer.classList.remove('hidden');
    chatOutput.style.display = 'block';
    outputText.textContent = '';
}

function updateStatus(text: string) {
    statusText.textContent = text;
}

function appendToOutput(text: string) {
    outputText.textContent += text;
    chatOutput.scrollTop = chatOutput.scrollHeight;
}

createForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const message = topicInput.value.trim();
    if (!message) return;

    let targetServer = 'agent';
    targetServerRadios.forEach(r => {
        if (r.checked) targetServer = r.value;
    });

    const serverUrl = targetServer === 'agent' ? agentUrlInput.value.trim() : mcpUrlInput.value.trim();

    showProgress();

    try {
        const response = await fetch('/api/chat_stream', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                message: message,
                session_id: sessionId,
                server_url: serverUrl || undefined
            })
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const reader = response.body?.getReader();
        if (!reader) throw new Error("No reader found");
        
        const decoder = new TextDecoder();
        let buffer = '';

        while (true) {
            const { value, done } = await reader.read();
            if (done) break;
            
            buffer += decoder.decode(value, { stream: true });
            const lines = buffer.split('\n');
            buffer = lines.pop() || '';

            for (const line of lines) {
                if (!line.trim()) continue;
                try {
                    const data = JSON.parse(line);
                    if (data.type === 'progress') {
                        updateStatus(data.text);
                    } else if (data.type === 'result') {
                        appendToOutput(data.text);
                        createButton.innerHTML = 'Send Message';
                        createButton.disabled = false;
                        topicInput.disabled = false;
                        return;
                    }
                } catch (e) {
                    console.error('Error parsing JSON:', e, line);
                }
            }
        }

    } catch (error) {
        console.error('Error:', error);
        statusText.textContent = 'Something went wrong. Please check your URLs and try again.';
        createButton.innerHTML = 'Send Message';
        createButton.disabled = false;
        topicInput.disabled = false;
    }
});
