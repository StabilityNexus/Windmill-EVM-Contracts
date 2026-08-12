# Audit Directory — Windmill EVM Contracts

This directory contains audit reports, static analysis summaries (Slither/Foundry), and peer code review evaluation records for the **Windmill Exchange** smart contracts and sub-modules.

## Documents

- [`AuditReport.md`](file:///c:/Users/Hp/Windmill-EVM-Contracts/audit/AuditReport.md) — Peer review and automated security audit report summary.

## Automated Security Auditing
Continuous static security analysis is performed automatically via GitHub Actions on every PR using:
- **Slither** (`.github/workflows/security-slither.yml`)
- **Foundry Nightly Fuzzing** (`.github/workflows/nightly-fuzz.yml`)
