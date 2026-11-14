# ci-runner-image

A self-hosted GitHub Actions runner image for
[Actions Runner Controller](https://github.com/actions/actions-runner-controller).
It is the upstream `ghcr.io/actions/actions-runner` image plus:

| Added | Why |
| --- | --- |
| Go in the tool cache (`/opt/hostedtoolcache`) | `actions/setup-go` finds it instead of downloading |
| `build-essential` | `make` and cgo |
| `python3`, `python3-venv` | Python job steps |
| Docker Compose plugin | parity with the previous runner hosts |
| `tzdata`, `TZ=America/Chicago` | the jobs' tests expect the hosts' time zone |

`RUNNER_TOOL_CACHE` moves to `/opt/hostedtoolcache` because ARC mounts an
emptyDir over `_work`, which would hide a cache in `_work/_tool`.

No secrets. Every download is pinned by version and SHA-256, and the base
image by digest.

## Use

```
ghcr.io/kevin-wiskow/ci-runner-image@sha256:<digest>
```

Pin a digest, not a tag. Each build's digest is in its workflow run summary,
and its provenance can be checked with:

```sh
gh attestation verify oci://ghcr.io/kevin-wiskow/ci-runner-image@sha256:<digest> \
  --repo kevin-wiskow/ci-runner-image
```

## Builds

[`build.yml`](.github/workflows/build.yml) builds on GitHub-hosted runners,
smoke-tests the image, and publishes it with `GITHUB_TOKEN` (no stored
credentials): on every push to `main`, monthly (Ubuntu package updates), and
on demand. Pull requests build and test without publishing. Tags are
`runner-<runner version>-<date>` and `latest`.

Dependabot opens pull requests for the base image (weekly; runners must be
updated within about 30 days of a new release) and for the actions. Go and
Compose are bumped by hand: update the `ARG`s and their checksums (Go from
`https://go.dev/dl/?mode=json&include=all`, Compose from the release's
`.sha256` asset).

GitHub disables scheduled workflows in a public repository after 60 days
without activity; merging Dependabot's pull requests counts as activity.
