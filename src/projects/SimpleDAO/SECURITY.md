# SECURITY.md – SimpleDAO + SimpleTimelock

> This document describes _known risks, assumptions, and limitations_ of the SimpleDAO + SimpleTimelock system in this repository.
>
> This project is an educational skeleton and **must not be deployed to mainnet or used to control real funds.**

---

## Scope

This document covers the following contracts:

- `SimpleDAO.sol`
- `SimpleTimelock.sol`

Out of scope:

- Any other example contracts in this repo
- Frontends, scripts, or off-chain tooling
- Token contracts, if later wired into this system

---

## Assumptions

The current design makes several simplifying assumptions:

- **1-address-1-vote model**: every address has equal voting power (weight = 1).
- **No identity / Sybil protection**: nothing prevents a single entity from controlling many addresses.
- **Anyone can propose**: there is no proposer role or stake requirement.
- **No execution payloads**: proposals do _not_ encode actual on-chain actions (targets + calldata); execution only changes internal DAO state.
- **Static configuration**: quorum, voting period, and timelock delay are immutable after deployment.
- **No upgrades**: there is no upgrade mechanism or governance-controlled implementation change.

These choices are acceptable for a learning project but are not safe for production governance.

---

## Threat Model (High-Level)

The main governance-related risks fall into four buckets:

1. Proposal hijacking
2. Quorum manipulation
3. Timelock bypass or griefing
4. Misconfigured roles / deployment

Each is described below with “What it is”, “Why this system is vulnerable”, and “What a real system would need”.

---

## 1. Proposal Hijacking

### What it is

“Proposal hijacking” occurs when an attacker (or untrusted party) creates proposals that:

- Do not reflect the community’s intent
- Are malicious, confusing, or spammy
- Are structured in a way that abuses the rules (e.g., tightly timed votes, misleading descriptions)

In real systems, this often combines with token distribution, delegation, or off-chain coordination failures.

### How this system behaves

- **Anyone can call `propose()`**:
  - There is no role check, no minimum stake, and no cooldown.
  - An attacker can create many proposals cheaply.
- **No “payload” yet**:
  - In this skeleton, proposals only change internal DAO state; they do not execute arbitrary calls.
  - This significantly limits damage, but teaches a pattern that would be dangerous once execution is added.
- **Description is free-form text**:
  - Users might rely on description for intent, while the actual on-chain effect (in a real system) could differ.

### Why this is acceptable here

- This system is **educational only** and does not execute external calls.
- The main goal is to learn proposal lifecycle mechanics, not enforce proposer quality.

### What a production system would need

- Proposer requirements (e.g., minimum token holdings or delegated votes).
- Proposal throttling (rate-limits, deposits, or costs).
- Clear off-chain review and communication channels.
- Possibly allowlists / guarded launch phases.

---

## 2. Quorum Manipulation

### What it is

Quorum manipulation happens when:

- Quorum is set too low, so a small minority can pass proposals.
- Quorum is set too high, so no proposal can realistically pass.
- Attackers concentrate votes in one block / period to surprise other participants.

In systems with token voting, this also includes manipulating token supply, borrowing power, or vote delegation.

### How this system behaves

- **Quorum is a raw integer** (`i_quorum`) over addresses, not stake.
- **No Sybil resistance**:
  - An attacker can create many addresses to meet quorum.
- **Voting model is simple**:
  - Every address has weight = 1.
  - This is good for learning but does not map to real token economics.

### Risk Summary

- A single entity controlling many EOAs can:
  - Meet quorum on their own.
  - Pass or block proposals at will.
- The contract does not enforce any upper bounds or dynamic quorum.

### Why this is acceptable here

- The system is **not wired to assets or upgradeability**.
- The objective is to explore quorum logic, not robust voting-power design.

### What a production system would need

- Token-based voting with well-understood supply and distribution.
- Resistance to flash-loaned voting power (snapshots, time-weighting).
- Carefully calibrated quorum (possibly dynamic quorum or participation-based rules).
- Formal governance parameters review before deployment.

---

## 3. Timelock Bypass / Griefing

### What it is

Timelock risks fall into two categories:

1. **Bypass**: executing changes before the intended delay or without proper governance.
2. **Griefing**: preventing execution or abusing who can execute to cause disruption.

### How this system behaves

- Only the DAO may call `SimpleTimelock.queue(proposalId)`.
- Anyone may call `SimpleTimelock.execute(proposalId)`, but:
  - Execution requires the operation to be queued.
  - Execution requires `block.timestamp >= eta`.
  - On execute, timelock calls `SimpleDAO.markExecuted(proposalId)`.

There is currently **no payload execution**, only state changes in the DAO.

### Potential issues (in a real system)

If this pattern were extended to execute arbitrary calls:

- Misconfigured `i_minDelay` (e.g., set to zero) would effectively remove delay.
- If timelock or DAO addresses are miswired:
  - Governance could be unable to execute proposals.
  - A malicious or incorrect DAO instance might gain control.
- Anyone-can-execute patterns can be abused for:
  - “Race to execute” dynamics (not always bad, but can surprise users).
  - Front-running of execution if timing matters (e.g., for markets, auctions).

### Why this is acceptable here

- There is **no arbitrary calldata execution**.
- The only state change on execute is `proposal.executed = true`.

### What a production system would need

- Careful review and enforcement of `minDelay`.
- Clear governance over who can update timelock parameters, if any.
- Strong invariants regarding:
  - who can queue
  - what can be queued
  - which contracts the timelock is allowed to call
- Possibly an execution role or mechanism for controlled execution actors.

---

## 4. Misconfigured Roles / Deployment

### What it is

Even with correct code, many governance failures come from:

- Incorrectly set constructor parameters.
- Wrong addresses passed to DAO/timelock.
- Using test or placeholder values in production.
- Setting parameters that make governance unusable (e.g., impossible quorums).

### How this system behaves

- `SimpleDAO` receives:
  - `timelock` address (cast to `ISimpleTimelock`)
  - `quorum`
  - `votingPeriod`
- `SimpleTimelock` receives:
  - `minDelay`
  - `dao` address

The contracts assume:

- The DAO and timelock addresses are correct.
- The delay and quorum settings are sane and final.

There is no on-chain guardrail against:

- Passing the wrong DAO address into the timelock.
- Passing an incorrect timelock address into the DAO.
- Setting quorum higher than any realistic participation.
- Using obviously unsafe values for `minDelay` in production.

### Risks

If this pattern were reused in a real deployment:

- Timelock could be bound to the wrong DAO (broken governance).
- DAO could trust the wrong timelock (bypass of intended controls).
- Quorum / delay could make the system ungovernable or trivially exploitable.

### What a production system would need

- Deployment scripts with strong assertions.
- On-chain sanity checks and possibly one-time configuration functions with stricter rules.
- A deployment review process and independent validation of addresses and parameters.
- Clear, public documentation of governance parameters.

---

## Non-Goals (What This System Does Not Attempt to Solve)

This system is **not** designed to address:

- Economic attacks involving token borrowing, manipulation, or bribery.
- Long-range governance attacks (e.g., buying up old keys, social engineering).
- Front-running or MEV around governance decisions.
- Legal or organizational governance processes.

All of these are _out of scope_ for this educational project.

---

## Summary

This SimpleDAO + SimpleTimelock system is intentionally minimal and **not suitable for mainnet**.

It is designed to:

- Teach core governance and timelock architecture.
- Demonstrate correct use of modifiers, state transitions, and events.
- Serve as a foundation for more advanced, production-grade designs.

If you intend to adapt this pattern for real-world use, you must:

- Introduce robust voting-power and proposer models.
- Carefully design governance parameters and upgradeability.
- Conduct thorough reviews and independent security audits.
