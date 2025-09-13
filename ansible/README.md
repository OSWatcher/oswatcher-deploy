# GitHub Actions Runners

Deploys 20 self-hosted GitHub Actions runners to `ops.grapheos.cc` for the `OSWatcher/osw-builder` repository.

## Setup

1. Set GitHub token:
   ```bash
   export GITHUB_TOKEN="your_token"
   ```

2. Deploy runners:
   ```bash
   ansible-playbook -i inventory.yml site.yml
   ```

## Configuration

- **Target**: `OSWatcher/osw-builder`
- **Count**: 20 runners (`builder-1` to `builder-20`)
- **Location**: `/home/{user}/runners/`

Edit `roles/runner/vars/main.yml` to modify settings.

## Management

- **Stop**: Set `runner_state: "stopped"` and re-run playbook
- **Remove**: Set `runner_state: "absent"` and re-run playbook