# Human-play API container

This image runs the Python `weiss_rl.human_play.web_server` service. It is the
stateful simulator/model API for the static web client.

Build from the repository root:

```bash
docker build -t weiss-play-api .
```

Run locally with a curated artifact root mounted at `/data/weiss-demo`:

```bash
docker run --rm -p 8765:8765 \
  -e WEISS_HUMAN_PLAY_ALLOWED_ORIGINS=http://127.0.0.1:5174,https://your-ui.vercel.app \
  -e WEISS_HUMAN_PLAY_REPO_ROOT=/data/weiss-demo \
  -v /absolute/path/to/demo-bundle:/data/weiss-demo:ro \
  weiss-play-api
```

The mounted demo bundle should look like the repository surfaces the API already
expects:

```text
demo-bundle/
  configs/                       # empty marker dir; required so config_canonical.json resolves a repo root
  runs/
    selected_demo_run/
      config_canonical.json
      manifest.json or spec_hash256.txt
      training/snapshots/registry.json
      training/snapshots/.../weights.pt
```

The `configs/` marker directory must exist at the bundle root: the stack-config
loader walks up from `config_canonical.json` looking for a parent that contains a
`configs/` directory and treats that as the repo root. An empty `configs/` is
enough.

The run's `spec_hash256.txt` must match the simulator baked into the image
(`weiss-sim` `export_spec_bundle()` hash). A bundle exported against a different
simulator spec will fail contract verification at session start.

The image intentionally does not copy local `runs/` by default. Export a small,
public-safe model bundle from the training repo and mount it into the container
instead of publishing every experiment artifact. The bundle is mounted read-only;
session transcripts are written to `WEISS_HUMAN_PLAY_TRANSCRIPT_ROOT` (a separate
writable volume) instead of into the model bundle.

## OVH/VPS deployment

The repo includes a small Compose stack for a public HTTPS API:

- `api`: builds this Dockerfile and serves the human-play API on port `8765`.
- `caddy`: terminates HTTPS and proxies to the API container.

Default hostname:

```text
https://weiss-api.146.59.126.179.sslip.io
```

`sslip.io` resolves that hostname to the OVH IPv4 address, so no separate DNS
record is required for the first public smoke deployment.

Server bootstrap sketch:

```bash
apt-get update
apt-get install -y ca-certificates curl git
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
. /etc/os-release
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian ${VERSION_CODENAME} stable" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

git clone https://github.com/victorwp288/weiss-human-play-api.git /opt/weiss-human-play-api
cd /opt/weiss-human-play-api
mkdir -p demo-bundle
docker compose up -d --build
```

After the API is healthy, set the frontend's `VITE_API_BASE` to the HTTPS API
URL and redeploy the Vercel frontend.
