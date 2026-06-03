# Cleo Feature Installation Protocol

The **eventbridge (EB) is the spine** of the Cleo system. All agents communicate through it. Features are collections of event IDs that agents publish and subscribe to. The allowlist controls which agents receive which events.

Feature lifecycle events are **standardised** — not per-feature. The same event names work for every feature; `feature_id` in the payload identifies which feature.

Installing a feature is a two-phase process:
- **Part 1 — Server install:** feature services and infra land on the server
- **Part 2 — User subscribe:** a user's PA subscribes them to the feature

---

## Part 1 — Server Install

### Step 1 — Clone from the marketplace

```bash
git clone https://github.com/CKSoupen/cleo-{feature}.git \
  /opt/cleo/infra/agent-features/{feature}/
```

After the clone: source code and scripts are on disk. Nothing is running. The substrate is untouched.

### Step 2 — Run install.sh

```bash
bash /opt/cleo/infra/agent-features/{feature}/install.sh
```

`install.sh` is idempotent. It:
1. Deploys systemd unit files from `infra/` to `/etc/systemd/system/` and starts services
2. Registers the feature entry in `infra/agent-features/feature-catalog.json`

Part 1 is complete. The feature is live on the server. Any user can now subscribe.

---

## Part 2 — User Subscribe

### Step 1 — All agents discover available features

At cold-start, every agent (PA, PM, Dev) reads:

```
/opt/cleo/infra/agent-features/feature-catalog.json
```

This is the shared feature surface for the whole household — what's installed, what event IDs each feature exposes, and what allowlist entries are needed to use it.

### Step 2 — PA fires `feature.subscribe.requested`

When subscribing a user, PA publishes to the EB using the routing key `feature.subscribe.requested`:

```json
{
  "feature_id": "feat-{{feature_slug}}",
  "user": "{{username}}",
  "reply_event_id": "{{username}}.feature.subscribe.completed",
  "priority": "high"
}
```

The `reply_event_id` is **user-namespaced** (`{{username}}.feature.subscribe.completed`) so only this user's PA receives the completion signal. PA reads the exact payload schema from `subscribe_event_payload` in the feature catalog.

### Step 3 — subscribe.sh runs

A handler receives `feature.subscribe.requested` and executes:

```bash
bash /opt/cleo/infra/agent-features/{{feature_name}}/subscribe.sh \
  --user {{username}} \
  --reply-event-id {{username}}.feature.subscribe.completed \
  --priority high
```

`subscribe.sh`:
1. Sets up user-specific config (state dirs, service config, env files)
2. Adds `{{username}}` to `feature-catalog.json` subscribers list
3. Fires `{{username}}.feature.subscribe.completed` at high priority

> **Today:** triggered manually. **Future:** a daemon listening for `feature.subscribe.requested` runs this automatically.

### Step 4 — PA handles vault setup

Because `{{username}}.feature.subscribe.completed` is in PA's EB allowlist, the event lands in her inbox at high priority. PA handles it herself in her CC session (no daemon):

1. Read `feature_id` from event payload
2. Resolve `feature_name` from `infra/agent-features/feature-catalog.json`
3. Copy `infra/agent-features/{{feature_name}}/README.md` → `vault/4-Automation/my-agent-features/{{feature_name}}.md`
4. Upsert `vault/4-Automation/my-agent-features/my-feature-catalog.json` with the subscribed feature entry
5. Commit vault changes

PA is the sole vault writer throughout. No other process touches the vault.

### Step 5 — PA notifies the user

PA confirms subscription is complete with a summary to the user:
- Feature subscribed
- README available at `vault/4-Automation/my-agent-features/{{feature_name}}.md`
- Event IDs now available (from `my-feature-catalog.json`)
- Any post-subscription setup steps from the feature README (if applicable)

---

## Part 3 — User Setup

After Part 2 Step 4, the feature README is in the user's vault at `vault/4-Automation/my-agent-features/{{feature_name}}.md`. Part 3 is the user's PA following the README's **Installation section** to complete vault and state setup.

### Step 1 — PA reads the feature README

```
vault/4-Automation/my-agent-features/{{feature_name}}.md
```

PA reads the **Installation** section (marked `<!-- PA start here -->`). This lists the vault/state steps specific to this feature and this user.

### Step 2 — PA executes the installation steps

PA follows the steps in order. Typical examples:
- Create required vault directories (`2-Areas/self/calendar/`, `7-Sharing/manifest.json`, etc.)
- Seed any initial state files
- Verify the feature is working for this user

Each feature's README defines exactly what Part 3 looks like. The infra subscribe (Part 2) and the vault setup (Part 3) are deliberately separate — subscribe.sh handles the system layer; the README handles the user layer.

---

## Unsubscribe

```bash
bash /opt/cleo/infra/agent-features/{{feature_name}}/unsubscribe.sh --user {{username}}
```

Reverses Step 3. Fires `{{username}}.feature.unsubscribe.completed`. PA handles vault teardown on receipt.

## Uninstall (server-wide)

All users must be unsubscribed first, then:

```bash
bash /opt/cleo/infra/agent-features/{{feature_name}}/uninstall.sh
```

Stops services, removes systemd units, removes entry from `feature-catalog.json`.

## Upgrade

Upgrade is an explicit ceremony — never automatic:

```bash
bash /opt/cleo/infra/agent-features/{{feature_name}}/upgrade.sh
```

Runs uninstall + reinstall. All subscribers re-subscribe after. The `upgrade_available: true` flag in `feature-catalog.json` signals a new version is ready; the upgrade itself is always deliberately triggered.
