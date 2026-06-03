# Cleo Feature Installation Protocol

The **eventbridge (EB) is the spine** of the Cleo system. All agents communicate through it. Features are collections of event IDs that agents publish and subscribe to. The allowlist controls which agents receive which events.

Installing a feature is a two-phase process:
- **Part 1 — Server install:** the feature's services and infra land on the server, available for any user to subscribe
- **Part 2 — User subscribe:** a user's agent subscribes to the feature's event surface; vault and state are configured for that user

---

## Part 1 — Server Install

### Step 1 — Clone from the marketplace

A feature lives as a GitHub repo. Clone it into the canonical install location:

```bash
git clone https://github.com/CKSoupen/cleo-{feature}.git \
  /opt/cleo/infra/agent-features/{feature}/
```

**After the clone, nothing is installed.** You have:
- Source code (`src/`)
- Scripts: `install.sh`, `subscribe.sh`, `unsubscribe.sh`, `upgrade.sh`, `uninstall.sh`
- Feature doc (`README.md`)
- Infra templates (`infra/` — systemd unit files, EB config)

The substrate is untouched. No services running. No EB config registered.

### Step 2 — Run install.sh

```bash
bash /opt/cleo/infra/agent-features/{feature}/install.sh
```

`install.sh` is idempotent. It:
1. Deploys systemd unit files from `infra/` to `/etc/systemd/system/`
2. Enables and starts the services
3. Registers the feature in `infra/agent-features/feature-catalog.json` (creates the file if it's the first feature)

**After install.sh, the feature is live on the server.** Catalog status: `available` → `installed`.

### Step 3 — Verify

```bash
systemctl status cleo-{feature}.service
cat /opt/cleo/infra/agent-features/feature-catalog.json | jq '.features[] | select(.feature_id == "feat-{slug}")'
```

---

## Part 2 — User Subscribe

A user's PA subscribes them to a feature. Each user subscribes independently.

### Step 4 — PA discovers available features

At cold-start, PA reads the server catalog:

```
/opt/cleo/infra/agent-features/feature-catalog.json
```

This tells PA what features are installed on this server and available to subscribe to.

### Step 5 — PA fires subscribe.requested

PA publishes to the eventbridge:

```json
{
  "event_id": "feature.subscribe.requested",
  "payload": {
    "feature_id": "feat-{slug}",
    "user": "{username}",
    "reply_event_id": "{username}.feature.subscribe.completed",
    "priority": "high"
  }
}
```

The `reply_event_id` is **user-namespaced** — `{username}.feature.subscribe.completed` — so only this user's PA receives the completion signal. Generic event IDs would reach all PAs.

### Step 6 — subscribe.sh runs

A handler (manual today; daemon in future) executes:

```bash
bash /opt/cleo/infra/agent-features/{feature}/subscribe.sh \
  --user {username} \
  --reply-event-id {username}.feature.subscribe.completed \
  --priority high
```

`subscribe.sh`:
1. Sets up user-specific config (state dirs, service config entries)
2. Adds the user to `feature-catalog.json` subscribers
3. Fires `{username}.feature.subscribe.completed` at the specified priority

### Step 7 — PA receives the completion event

Because PA's allowlist includes `{username}.feature.subscribe.completed`, the event lands in her EB inbox and is pushed at high priority. Only this user's PA receives it.

### Step 8 — PA handles vault setup

On receipt of `{username}.feature.subscribe.completed`, PA:
1. Reads `feature_id` from event payload
2. Resolves feature name from `feature-catalog.json`
3. Copies `infra/agent-features/{feature}/README.md` → `vault/4-Automation/my-agent-features/{feature}.md`
4. Upserts `vault/4-Automation/my-agent-features/my-feature-catalog.json` with the feature entry
5. Commits vault changes + notifies user

### Step 9 — Cold-start awareness

At next cold-start, PA reads `vault/4-Automation/my-agent-features/my-feature-catalog.json` and has full awareness of:
- Which features are installed for this user
- All event IDs the feature exposes (without needing to read the full README)

---

## Unsubscribe

```bash
bash /opt/cleo/infra/agent-features/{feature}/unsubscribe.sh --user {username}
```

Reverses Step 6. Fires `{username}.feature.unsubscribe.completed`. PA handles vault teardown on receipt.

## Uninstall (server-wide)

All users must be unsubscribed first.

```bash
bash /opt/cleo/infra/agent-features/{feature}/uninstall.sh
```

Stops services, removes systemd units, removes entry from `feature-catalog.json`.

## Upgrade

Upgrade is an explicit ceremony — not automatic.

```bash
bash /opt/cleo/infra/agent-features/{feature}/upgrade.sh
```

Runs uninstall + reinstall. All subscribers re-subscribe after. The `status: upgrade-available` flag in `feature-catalog.json` signals a new version is ready; the upgrade itself is always deliberately triggered.
