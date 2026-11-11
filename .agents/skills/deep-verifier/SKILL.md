---
name: deep-verifier
description: >-
  Use this skill whenever executing complex code changes, media processing pipelines, system automations,
  or multi-step research. Enforces rigorous multi-pass verification, sanity checks, test execution, and
  adversarial self-critique before finalizing results.
---

# Deep Verifier & Self-Correction Skill

This skill enforces strict empirical verification and multi-stage quality control to eliminate hallucinations, syntax errors, and runtime failures.

## Verification Checklist

When this skill is engaged, execute the following 4-phase verification pipeline:

### 1. Specification & Invariants Check
- [ ] Are all requirements explicitly listed with acceptance criteria?
- [ ] Are platform-specific constraints accounted for? (Windows paths, PowerShell escaping, Python 3.12 compatibility).
- [ ] Are required external tools and libraries verified as installed before running?

### 2. Empirical Execution (Zero Guessing)
- [ ] Never assume a command or script will work without running it.
- [ ] Execute commands and inspect:
  - Exit code (`0`)
  - Standard output (`stdout`) for expected results
  - Standard error (`stderr`) for hidden warnings or tracebacks
  - Generated files (existence, non-zero size, schema validity)

### 3. Adversarial Edge-Case Stress Testing
- [ ] Test boundaries: What happens with empty inputs, large files, special characters, spaces in filenames, non-ASCII (Cyrillic) characters?
- [ ] Confirm proper character encoding (`UTF-8` handling).
- [ ] Confirm proper error trapping (no unhandled exceptions crashing the workflow).

### 4. Final Sanity & Deliverable Review
- [ ] Read back modified sections of code or output files.
- [ ] Ensure all file paths and symbols are provided as clickable markdown links (`[text](file:///path)`).
- [ ] Provide clear, transparent summaries of what was verified and the concrete results observed.
