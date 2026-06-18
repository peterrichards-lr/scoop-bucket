# Peter's Rust Tools Scoop Bucket

This is a custom [Scoop](https://scoop.sh/) bucket for distributing Rust tools on Windows. It's designed for a low-maintenance, fully automated release-and-update workflow.

## 🚀 How to Use

If you haven't already, [install Scoop](https://scoop.sh/#install).

### 1. Add this Bucket
```powershell
scoop bucket add peterrichards-lr https://github.com/peterrichards-lr/scoop-bucket
```

### 2. Install a Tool
```powershell
# Replace 'tool-name' with one of the available tools below
scoop install <tool-name>
```

---

## 🛠️ How it Works (Automations)

This bucket is designed to be self-updating and reliable using GitHub Actions.

1.  **JSON Linting (`scripts/lint.sh`)**: All changes are automatically checked locally before you commit. This ensures all JSON manifests are valid and contain the required fields (`version`, `description`, `homepage`). To set this up, run `./scripts/setup-hooks.sh`.
2.  **Auto-Update (`auto-update.yml`)**: Every 2 hours, a GitHub Action checks all manifests in the `bucket/` directory. If it finds a new release in a tool's GitHub repository, it automatically:
    - Downloads the new binary.
    - Calculates the new SHA256 hashes.
    - Updates the manifest version and URLs.
    - Commits the changes back to this repository.

---

## ➕ Adding a New Tool

To add a new Rust tool to this bucket, follow these steps:

### 1. Set up Release Automation in your Tool's Repo
In the repository of your Rust tool, add a `.github/workflows/release.yml` file. You can find a template in [templates/rust-release.yml](./templates/rust-release.yml). This ensures that every time you push a tag (e.g., `v1.0.0`), a Windows binary is built and released.

### 2. Create the Manifest here
1.  Copy [bucket/my-rust-tool.json.example](./bucket/my-rust-tool.json.example) to `bucket/<tool-name>.json`.
2.  Update the `homepage`, `description`, and `architecture` URLs to point to your new tool's repository.
3.  Calculate the initial SHA256 hash for your first release and put it in the manifest.
    - On Windows: `certutil -hashfile your-tool.zip SHA256`
    - On macOS/Linux: `shasum -a 256 your-tool.zip`

### 3. Push the Manifest
Once you push the new `.json` file to this repository, the **Auto-Update** action will take over for all future releases.

---

## 📜 Available Tools

The following tools are available in this bucket:

- **[lcp-db-reset](https://github.com/peterrichards-lr/lcp-db-reset)**: A Liferay Cloud utility to reset the database schema.
- **[lcp-sql-fetch](https://github.com/peterrichards-lr/lcp-sql-fetch)**: A tool to execute local SQL scripts on Liferay Cloud via lcp shell.
- **[lwu (Liferay Workspace Updater)](https://github.com/peterrichards-lr/liferay-workspace-updater)**: A CLI tool to automatically update Liferay Workspace components to their latest versions.

---

## ⚖️ License
This project is licensed under the [MIT License](./LICENSE).
