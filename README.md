# Snyk Integration with Bamboo CI/CD — Reference Implementation

> **Warning — This repository contains intentional security vulnerabilities.**
> The application code, dependencies, and container image include deliberate weaknesses designed to produce Snyk findings for demonstration purposes. **Do not deploy this to production or use it as a foundation for production applications** without first removing or remediating all introduced weaknesses.

## Purpose

This repository is a working reference implementation demonstrating how to integrate [Snyk](https://snyk.io) security scanning into a [Bamboo](https://www.atlassian.com/software/bamboo) CI/CD pipeline. It is designed as a customer-facing example — something a team can walk through, adapt, and use as a foundation for introducing developer-first security practices into their own delivery pipeline.

The core thesis is simple: **security scanning belongs in the pipeline, not after it.** Snyk's model is to surface vulnerabilities at the point a developer can act on them — during the build — rather than as a downstream audit finding. This example makes that concrete.

---

## What This Demonstrates

Snyk covers three distinct attack surfaces in modern application delivery, and this implementation exercises all three:

| Snyk Product | What It Scans | Signal in This Repo |
|---|---|---|
| **Snyk Open Source** | Third-party dependencies (npm, Maven, pip, etc.) | Intentionally vulnerable packages in `package.json` |
| **Snyk Code** | First-party application code (SAST) | Deliberate security weaknesses in TypeScript source |
| **Snyk Container** | Container images and their base OS layers | A base image chosen for known vulnerabilities |

Running all three within the same pipeline illustrates how Snyk provides layered coverage — not just "did I pull a bad library" but "is my own code safe" and "is the runtime environment I'm shipping into hardened."

---

## Repository Structure

```
/
├── app/                    # TypeScript application (the thing being built)
│   ├── src/                # Source with intentional code-level weaknesses
│   ├── package.json        # Dependencies with intentional vulnerable packages
│   └── Dockerfile          # Container definition with a deliberately weak base image
│
├── infra/                  # GCP infrastructure (Terraform or gcloud scripts)
│   ├── gce/                # Bamboo CI server on Compute Engine
│   └── cloudrun/           # Application hosting behind a load balancer
│
└── ci/                     # Bamboo pipeline definition
    └── bamboo-specs/       # Pipeline-as-code (YAML specs)
```

---

## Application

The sample application is a minimal **TypeScript REST API** — intentionally without a UI — designed to be exercised through standard HTTP verbs (`GET`, `POST`, `PUT`, `DELETE`). The goal is a deployable, testable surface that doesn't require front-end complexity to demonstrate the security scanning.

It is not a realistic production application. It is a vehicle for introducing detectable vulnerabilities across all three Snyk scan types. Think of it as a controlled specimen.

The application is containerized and deployed on **Google Cloud Platform**, exposed through a load balancer. Infrastructure is provisioned as code so the environment is reproducible.

---

## CI/CD Infrastructure

The pipeline runs on **Bamboo**, deployed as a Docker container on a **GCE instance**. The Bamboo Docker image includes a 30-day trial license, which is sufficient for demonstration purposes.

Bamboo is exposed through a GCP load balancer. The GitHub repository connection is configured manually by the user — this is a deliberate design choice. Keeping the SCM integration outside of automation makes the example more portable: the pipeline definitions and infrastructure scripts remain reusable across different GitHub repositories and organisations without hard-coded credentials or repository-specific assumptions.

The pipeline itself is defined as **Bamboo Specs** (YAML), committed alongside the application code. Pipeline stages:

1. **Build** — Compile and package the TypeScript application
2. **Snyk Open Source** — Scan `package.json` and the dependency tree
3. **Snyk Code** — Static analysis of the TypeScript source
4. **Snyk Container** — Scan the built Docker image
5. **Deploy** — Push to GCP (conditional on scan results, configurable)

---

## Getting Started

### Prerequisites

- A **GCP project** with billing enabled
- [`gcloud` CLI](https://cloud.google.com/sdk/docs/install) installed and authenticated (`gcloud auth login`)
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5 (if using the Terraform-based infra scripts)
- [Node.js](https://nodejs.org/) >= 18 and npm
- [Docker](https://docs.docker.com/get-docker/) installed locally
- A [Snyk account](https://app.snyk.io/signup) (free tier is sufficient) and the Snyk CLI (`npm install -g snyk && snyk auth`)
- A GitHub account

### Steps

1. **Fork or clone this repository** into your own GitHub account
2. **Provision the GCP infrastructure** — see the README in `/infra` for detailed instructions. In short:
   ```bash
   cd infra/gce && terraform init && terraform apply
   cd ../cloudrun && terraform init && terraform apply
   ```
3. **Access the Bamboo UI** via the load balancer IP output from the previous step and complete the initial setup wizard
4. **Connect Bamboo to your GitHub repository** through the Bamboo UI (manual step — see [Bamboo GitHub integration docs](https://confluence.atlassian.com/bamboo/linking-bamboo-with-bitbucket-or-github-289277347.html))
5. **Add your Snyk token** as a Bamboo global variable: *Bamboo administration > Global variables > Add* with the name `SNYK_TOKEN` and your token value (find it at [app.snyk.io/account](https://app.snyk.io/account))
6. **Trigger a build** and observe findings across all three scan types

### Optional: Local Validation

Before pushing to Bamboo, you can run Snyk scans locally to verify everything is wired up:

```bash
cd app
snyk test              # Open Source scan
snyk code test         # Code (SAST) scan
docker build -t bamboo-example .
snyk container test bamboo-example  # Container scan
```

---

## Design Decisions

**Why Bamboo?**
This example specifically targets teams already invested in the Atlassian ecosystem, where Bamboo is the incumbent CI server. The patterns demonstrated here — pipeline stage sequencing, environment variable handling, artifact management — translate directly to Bamboo deployments in enterprise environments.

**Why GCP?**
Infrastructure portability was a secondary concern. The example uses GCP primitives (GCE, Cloud Load Balancing) that have direct analogues in AWS and Azure. Teams on other clouds can adapt the `/infra` layer without touching the application or pipeline definitions.

**Why intentional vulnerabilities?**
The weaknesses introduced in this codebase are deliberate and documented. The purpose is to produce meaningful Snyk findings that can be discussed, triaged, and remediated — not to ship insecure software. This repository should not be used as a foundation for production applications without removing or addressing the introduced weaknesses.

**Why a manual GitHub connection?**
Automating the Bamboo–GitHub integration would require embedding credentials or tokens into infrastructure scripts, which creates a portability and security problem for a public reference implementation. The manual step is a one-time configuration that takes under five minutes and keeps the rest of the example clean.

---

## Cleanup / Teardown

GCP resources provisioned by this example incur costs. To tear down the infrastructure when you're done:

```bash
cd infra/cloudrun && terraform destroy
cd ../gce && terraform destroy
```

Verify in the [GCP Console](https://console.cloud.google.com/) that all resources (instances, load balancers, firewall rules) have been removed.

---

## Extending This Example

This repository is intended as a starting point. Likely extensions include:

- Swapping in a different application (different language, different framework) while reusing the pipeline and infrastructure
- Adding Snyk IaC scanning for the Terraform/gcloud infrastructure definitions
- Introducing Snyk's PR check integration for shift-left feedback at the pull request stage
- Replacing GCP with AWS or Azure infrastructure
- Hardening the pipeline to fail builds on high-severity findings (configurable via `--severity-threshold`)

---

## Related Resources

- [Snyk Documentation](https://docs.snyk.io)
- [Bamboo Documentation](https://confluence.atlassian.com/bamboo)
- [Snyk CLI Reference](https://docs.snyk.io/snyk-cli/cli-commands-and-options-summary)
- [Bamboo Specs Reference](https://docs.atlassian.com/bamboo-specs-docs/latest/)

---

## License

This project is licensed under the [MIT License](LICENSE).
