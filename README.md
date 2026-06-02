---
feature_id: "feat-{{feature_slug}}"
name: "{{feature_name}}"
version: "0.1.0"
repo: "https://github.com/CKSoupen/cleo-{{feature_name}}"
subscribe_event_id: "feature.{{feature_slug}}.subscribe"
unsubscribe_event_id: "feature.{{feature_slug}}.unsubscribe"
install_event_id: "feature.{{feature_slug}}.install"
uninstall_event_id: "feature.{{feature_slug}}.uninstall"
deps: []
contact: "soupencameron@gmail.com"
sub_features:
  - id: "{{subfeature_id}}"
    description: "{{subfeature_description}}"
feature_event_ids:
  - event_id: "feature.{{feature_slug}}.bug-report"
    description: "Log a bug or improvement request"
  - event_id: "feature.{{feature_slug}}.unsubscribe"
    description: "Unsubscribe this user from the feature"
---

# Cleo Feature: {{feature_name}}

## Prerequisites
What must be installed first — other features, EB protocol version, substrate deps.

## Installation
<!-- PA start here — follow steps in order -->
1. {{step_1}}
2. {{step_2}}

## Usage
Directory structure, commands to run, how to generate subfeature schemas.

## Events

| Event | Description |
|---|---|
| `feature.{{feature_slug}}.bug-report` | Log a bug or improvement request |
| `feature.{{feature_slug}}.unsubscribe` | Unsubscribe this user |

## Architecture
How it works — components, data flow, systemd units, EB subscriptions.

## Health Check
`systemctl status cleo-{{feature_name}}.service`

## Opt-out / Teardown
Steps to unsubscribe and clean up.

## FAQs
