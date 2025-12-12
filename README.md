# SimpleDAO + SimpleTimelock

**A minimal, educational DAO governance skeleton built for clarity and extendability.**

This project implements the core lifecycle of an on-chain governance system:

1. Proposal creation
2. Voting
3. Quorum + majority checks
4. Timelock queueing
5. Scheduled execution

It is intentionally simple and built to be **readable, testable, and easy to extend.**

---

## Features

### **SimpleDAO**

- Create proposals with human-readable metadata
- Fixed voting window
- 1-address-1-vote model
- Track `forVotes` & `againstVotes`
- Prevent double-voting
- Enforce voting window
- Enforce quorum
- Enforce “forVotes > againstVotes”
- Queue successful proposals into a timelock
- Timelock marks proposals executed
- Emits all relevant events

### **SimpleTimelock**

- Only DAO may queue
- Stores a per-proposal ETA
- Enforces `minDelay`
- Executes only after ETA
- Calls back into DAO (`markExecuted`)
- Clears ETA on execution
- Emits queue + execute events

---

## Project Structure

```
/src
  /projects
    SimpleDAO.sol
    SimpleTimelock.sol

/test
  /projects
    SimpleDAO.t.sol
    SimpleTimelock.t.sol
```

All tests use Foundry tools such as `prank`, `warp`, `roll`, and `expectRevert`.

---

## Test Coverage

### **DAO tests**

- Proposal creation
- Proposal struct correctness
- ProposalCreated event
- Invalid proposal IDs revert
- Voting window enforcement
- Double-voting prevention
- Correct vote accumulation
- Quorum failure reverts
- Majority failure reverts
- Queueing reverts (active voting / already queued / executed)
- Queueing success and event emission

### **Timelock tests**

- queue fails if caller ≠ DAO
- queue stores ETA correctly
- execute reverts if not queued
- execute reverts if ETA not reached
- execute calls DAO.markExecuted
- ETA clears on execution

---

## Architecture Overview

### Governance flow

```
propose()
    ↓
vote()
    ↓
queueProposal()
    ↓
timelock.queue()
    ↓ (wait minDelay)
timelock.execute()
    ↓
dao.markExecuted()
```

### High-level design notes

- DAO controls governance rules
- Timelock controls scheduling
- DAO never directly executes actions (simplified)
- Immutable configuration for safety
- Uses event-driven architecture similar to real DAOs (Compound-style)

---

## Status

**This is an educational minimal implementation.**  
It is _not_ a production governance system. Missing features include:

- calldata execution
- multisig or guardian roles
- ERC20 voting power
- delegation
- proposal cancellation
- vote snapshots
- dynamic quorum
- batching of actions
- upgradeability

Purpose: **learn core governance patterns** without complexity.

---

## Suggested Extensions (Recommended Learning Path)

### Governance Upgrades

- ERC20Votes for token-weighted voting
- Delegation (Compound-style)
- Snapshot voting
- Abstain vote option
- Dynamic quorum percentage

### Execution Extensions

- Add calldata execution
- Add batch action support
- Add grace period after queueing
- Allow proposal cancellation

### Security Hardening

- Invariant tests
- Guardian/veto role
- Reentrancy analysis
- Timelock upgrade mechanism

### Frontend / Off-chain

- Simple UI for proposals & voting
- Subgraph indexing
- Explorer for proposal lifecycle

---

## License

MIT License

---

## Credits

Developed as part of a structured Solidity learning roadmap, focusing on correctness, clarity, and complete Foundry test coverage.
