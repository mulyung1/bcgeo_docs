# DeepSeek Harness (dsh) on a local GPU, reachable over the LAN

Runs `qwen3.6:27b-coding` on this machine's GPU through Ollama and serves the
dsh web UI so other machines on the network can use it.

## Requirements

- Ollama installed. It uses the GPU automatically (Metal on macOS, CUDA on NVIDIA/Linux).
- Node.js `>=24.9.0`. Check with `node -v`.
- dsh installed: `npx @deepseek-ai/dsh`

## 0. install Node.js and dsh

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
nvm install 22
nvm use 22
```

launch the webui
```bash
npx @deepseek-ai/dsh web
```

## 1. Pull the model on the GPU and start ollama server

```bash
ollama pull qwen3.6:27b-coding
ollama serve
```

by default, it will use port 11434

- using the `OLLAMA_HOST` env variable, we can specify a new port

- this will however require us to point to the model list

```bash
OLLAMA_HOST=172.28.x.x:3000 OLLAMA_MODELS=/usr/share/ollama/.ollama/models ollama serve
```

## 2. Get this machine's IP

```bash
ipconfig getifaddr en0    # macOS
hostname -I               # Linux
```

Example used below: `172.28.70.132`.

## 3. Start dsh bound to that IP

```bash
npx @deepseek-ai/dsh web --host your_host_ip --port 3080 --trusted-host your_host_ip:3080 --no-open
```

`--host` must be a real interface address. `0.0.0.0` is rejected.

dsh prints a URL like:

```
dsh web: http://172.28.70.132:3080/?token=XXXXXXXX
```

## 4. Open it from another machine

Open the printed URL, including `?token=...`, in a browser on any machine on
the same network. Without the token, access is denied.

## 5. Open the firewall if it does not connect

- macOS: System Settings > Network > Firewall > allow incoming connections for `node`.
- Linux (ufw): `sudo ufw allow 3080/tcp`

## Security

The token gives full control of the agent, which can run commands on this
machine. Share it only with trusted people. Keep it on a trusted LAN or VPN
(for example Tailscale). Do not port-forward 3080 to the internet.

## Troubleshooting

- `UNKNOWN_MODEL ... "8bdf0bc645c4"`: in `~/.dsh/profiles/web/cordis.patch.yml`,
  set `agent-default-model` > `model:` to `"qwen3.6:27b-coding"` (the name, not
  the ID from `ollama list`). Then restart dsh and start a new session.
- Repeated `[deepseek-account] ... 403` log lines: harmless when only Ollama is used.


## References

- [DSH setup tutorial]('https://github.com/47thtechcorner/RayCodes_DeepSeek_Harness')
- [Youtube Tutorial for local model setup]('https://www.youtube.com/watch?v=b7kk768JEws')