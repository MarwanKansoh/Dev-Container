# Engineering Development Container

A shared development container for engineering teams. This image packages the common tools developers can pull from GitHub Container Registry and use consistently across local development, CI, and ephemeral environments.

## Included tools

### Source control and GitHub
- Git
- GitHub CLI

### Cloud and infrastructure
- AWS CLI v2
- AWS Session Manager plugin
- Terraform
- OpenTofu
- kubectl
- Helm

### AI-assisted development
- Claude Code

### Languages and runtimes
- Python runtime
- Node.js runtime
- Go toolchain

### Linters
- Ruff (Python)
- ESLint (Node.js)
- golangci-lint (Go)

### Package managers
- pip
- npm

### Shell and build utilities
- bash
- curl
- jq
- yq
- make
- unzip
- zip
- tar
- vim
- less

## Repository structure

```text
.
├── .devcontainer/
│   └── devcontainer.json
├── .github/
│   └── workflows/
│       └── build-and-publish.yml
├── scripts/
│   └── verify-tools.sh
├── .gitignore
├── Dockerfile
└── README.md
```

## Build locally

```bash
docker build -t engineering-dev-base:local .
```

## Run locally

```bash
docker run --rm -it engineering-dev-base:local
```

To mount your current repository into the container:

```bash
docker run --rm -it -v "$PWD:/workspace" engineering-dev-base:local
```

## Verify installed tools

After starting the container:

```bash
verify-tools
```

## Publish to GitHub Container Registry

The included GitHub Actions workflow builds and publishes a multi-architecture image to GHCR on pushes to `main`, tags starting with `v`, and manual workflow runs.

The published image path will be:

```text
ghcr.io/<owner>/<repo>:latest
```

## Example usage from GHCR

```bash
docker pull ghcr.io/<owner>/<repo>:latest
docker run --rm -it ghcr.io/<owner>/<repo>:latest
```

## Suggested image tags

You can keep the automated tags from the workflow and optionally add a manual versioning convention such as:

```text
latest
2026.03
python3.12-node22
```

## Using Claude Code

Claude Code is pre-installed in the container. To use it, set your Anthropic API key:

```bash
export ANTHROPIC_API_KEY=your-api-key
claude
```

You can also pass the API key at container start:

```bash
docker run --rm -it -e ANTHROPIC_API_KEY=your-api-key engineering-dev-base:local
```

## Customising versions

Several tool versions are set as Docker build arguments in the `Dockerfile`.

```dockerfile
ARG NODE_MAJOR=22
ARG NPM_VERSION=10.9.2
ARG GO_VERSION=1.24.1
ARG TERRAFORM_VERSION=1.11.1
ARG OPENTOFU_VERSION=1.9.0
ARG KUBECTL_VERSION=v1.32.3
ARG HELM_VERSION=v3.17.1
ARG YQ_VERSION=v4.44.6
ARG GOLANGCI_LINT_VERSION=v1.64.5
ARG ESLINT_VERSION=9.22.0
ARG RUFF_VERSION=0.11.0
```

You can override them at build time:

```bash
docker build \
  --build-arg NODE_MAJOR=22 \
  --build-arg GO_VERSION=1.24.1 \
  --build-arg TERRAFORM_VERSION=1.11.1 \
  -t engineering-dev-base:custom .
```

## Design choices

This repository intentionally uses:
- Ubuntu 24.04 as a broadly compatible base image
- a non-root runtime user called `devuser`
- multi-architecture publishing for `linux/amd64` and `linux/arm64`
- a lightweight verification script to validate the installed toolchain
- a `.devcontainer` definition so teams can open the image directly in VS Code Dev Containers or GitHub Codespaces

## Common next enhancements

Depending on your team, you may later want to add:
- Docker client
- Kustomize
- internal CA certificates
- organisation bootstrap scripts
