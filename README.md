# Ginko App — Temporary Repository

⚠️ **Important notice**

This repository is **temporary**.  
Once the access issues are resolved, the project will be **moved to the official repository**:

👉 https://github.com/CCGenetics/Ginko-app

---

## Development Workflow

- Active development is done on **separate feature branches**.
- Each new feature, fix, or experiment should be implemented in its own branch.
- Once ready, changes are **merged into the `main` branch** via a merge request / pull request.
- The `main` branch is considered **stable** and is used for deployment.

---

## Step Descriptions

Documentation and descriptions for individual processing steps are located in:

app/content/steps

Each step has its own Markdown file describing inputs, outputs, and expected behavior.

---

## Live Application

The application is currently available at:

👉 https://ginko.mrk.quest/

---

## Deployment & Builds

- Every **merge into the `main` branch** triggers an automatic deployment.
- The application is **rebuilt from scratch on the production server** after each merge.
- Deployment is handled automatically via CI/CD.

---

## Status

This setup is intended for **testing and development purposes** until the repository migration is completed.
