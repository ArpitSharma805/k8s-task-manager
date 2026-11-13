# GitOps Repository

This repository contains the GitOps manifests for the AI-Powered GitOps Platform.

## Structure

- `apps/` - ArgoCD Application manifests
- `charts/` - Helm charts for platform workloads
- `values/` - Environment-specific values files

## Usage

ArgoCD syncs from this repository to deploy workloads to the Kind cluster.
