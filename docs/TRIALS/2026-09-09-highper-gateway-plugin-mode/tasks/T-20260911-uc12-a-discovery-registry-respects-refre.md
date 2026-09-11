---
id: T-20260911-uc12-a-discovery-registry-respects-refre
title: UC12.A discovery registry respects refresh TTL
tier: T2
lang: rust
paths: highper-gateway/src/discovery/registry.rs
state: created
---

## Intent

Roadmap item UC12.A (`docs/planning/ROADMAP.md:454-456`): "Fix `should_refresh = true` always
at `src/discovery/registry.rs:41` — cache last-update; respect TTL." Today
`ServiceRegistry::get_upstreams` refreshes from the discovery backend on every call; the
`last_update` map (`registry.rs:21`) is written by `refresh_service` (`:86-87`) and never read.

## Acceptance criteria

- [ ] `get_upstreams` calls the discovery backend only when the service has no `last_update`
      entry or that entry is at least `config.refresh_interval` seconds old; otherwise it
      answers from the `upstreams` cache.
- [ ] `refresh_interval == 0` keeps the old behaviour (refresh on every call).
- [ ] Behaviour on refresh error and on an empty instance list is unchanged
      (error propagates; empty list still ends in "Service not found").
- [ ] A unit test that fails on the pre-fix code: two calls inside the TTL reach the backend once.

## Notes

