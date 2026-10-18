---
name: code-review-standards
description: Universal code review methodology for any software project. Use this skill when reviewing pull requests, analyzing code changes, or evaluating code quality — especially when no project-specific review skill exists. Applies two-level analysis (standard merge-readiness vs deep technical debt identification) with SOLID/Clean Code/DDD principles. Trigger for "review this PR", "code review", "analyze these changes", "check this code", or whenever systematic code evaluation is needed.
---

# Code Review Standards

A universal methodology for conducting systematic, objective code reviews in any software project.

## Purpose

This skill provides a structured approach to code review that:
- Separates **merge-blocking issues** from **technical debt** for clear prioritization
- Applies universal principles (SOLID, Clean Code, DDD) across languages and frameworks
- Distinguishes between **problems introduced by the PR** and **pre-existing issues**
- Scales from quick merge validation to deep architectural analysis

## When to Use This Skill

Use this skill when:
- Reviewing a pull request for merge readiness
- Analyzing code quality systematically
- Identifying technical debt in context of changes
- No project-specific review skill is available (e.g., `<project>-pr-reviewer`)

**Do NOT use if**: A project-specific review skill exists that incorporates project conventions and CI validation logic.

## Core Principle

**A code review must answer two distinct questions**:
1. **Is this PR ready to merge?** (blocking issues only)
2. **What technical debt exists in the code this PR touches?** (for future planning)

Confusing these two questions produces reviews that block merges for pre-existing issues or ignore systemic problems revealed by the changes.

---

## Two-Level Analysis Approach

### Level 1: Standard Analysis (Focus: Merge Readiness)

**Goal**: Validate the PR is **ready to merge** into the codebase.

**Criteria**:
- **Change consistency**: Complete deletions, no orphaned references, coherent modifications
- **Convention compliance**: Code follows project style guides (linting, formatting, naming)
- **Test coverage**: New code is tested, existing tests still pass
- **CI validation**: All automated checks pass (build, tests, linting, security scans)

**Finding Severity** (only what **blocks merge**):
- **CRITICAL**: Breaks tests, violates linting rules, introduces functional regression, security vulnerability
- **IMPORTANT**: Incomplete change (orphaned code), convention violation, missing tests for new logic
- **MINOR**: Improvement suggestion for newly added code (optional optimization, clarity enhancement)

**Key Principle**: If existing code already has a problem and the PR **does not worsen it** → **no finding**.  
*Rationale*: Blocking a PR for pre-existing issues punishes contributors for touching legacy code and discourages refactoring.

**Example**:
- PR adds a new method to a 500-line God Class → Finding: "New method added to oversized class" (MINOR suggestion to extract in future)
- PR does NOT trigger a finding for the God Class itself (pre-existing issue)

---

### Level 2: Deep Analysis (Focus: Technical Debt Identification)

**Goal**: Identify **technical debt** and architectural weaknesses revealed by the PR for future refactoring planning.

**Criteria**:
- **SOLID violations**: Single Responsibility Principle, Open/Closed Principle, Liskov Substitution, Interface Segregation, Dependency Inversion
- **Anti-patterns**: God Class, Anemic Domain Model, Feature Envy, Primitive Obsession, Shotgun Surgery
- **Clean Code**: Long Methods (>50 lines), High Cyclomatic Complexity (>10), Magic Values, Duplicate Logic
- **Architecture**: Layering violations, tight coupling, missing abstractions, inadequate domain modeling (DDD)

**Finding Severity** (includes **existing code impacted by PR**):
- **CRITICAL**: God Class (>500 lines), Anemic Domain Model (systemic across domain), massive SRP violation (>10 responsibilities)
- **IMPORTANT**: Anti-DDD pattern, moderate SOLID violation, Feature Envy (method uses another class's data more than its own)
- **MINOR**: Magic Values, Long Methods (50-100 lines), Primitive Obsession (should be Value Object)

**Key Principle**: If the PR **touches** code with technical debt → **identify and document** for future work.  
*Rationale*: Changes to fragile code are opportunities to plan refactoring. Document the debt while context is fresh.

**Example**:
- PR modifies a method in a God Class → Finding: "Service class has 847 lines and 15 responsibilities (violations: SRP, God Class pattern)" (CRITICAL debt, recommend extraction plan)

---

## Separation of Findings

**CRITICAL**: Reviews must clearly **separate** two categories:

### 1. Findings on PR Changes (Section: "Findings on the Changes")

**What to include**:
- Problems **introduced** by this PR
- Inconsistencies in the **modifications** made
- New code **not respecting** project conventions
- Test coverage gaps **for new logic**

**Format**:
```markdown
## Findings on the Changes (X total)

### CRITICAL (Y findings)
1. [File:line] [Description of blocking issue introduced by PR]
   - Impact: [What breaks]
   - Fix: [Specific correction needed]

### IMPORTANT (Z findings)
[Same structure]

### MINOR (W findings)
[Same structure]
```

---

### 2. Findings on Existing Code (Section: "Technical Debt Identified")

**What to include**:
- Problems **pre-existing** in code touched by PR
- Architectural weaknesses **revealed** by the changes
- Refactoring opportunities **contextualized** by PR scope

**Format**:
```markdown
## Technical Debt Identified (Code Existing Before PR)

### CRITICAL (Y findings)
1. [File:line] [Description of systemic issue in existing code]
   - Pattern: [Anti-pattern or SOLID violation name]
   - Scope: [How widespread: single method, class, module, system]
   - Recommendation: [Refactoring strategy, e.g., "Extract 5 services from God Class"]
   - Effort: [Estimated: hours, days, weeks]

### IMPORTANT (Z findings)
[Same structure]

### MINOR (W findings)
[Same structure]
```

**Key Distinction**: Findings in "Technical Debt Identified" do **not block merge**. They inform future sprint planning and refactoring priorities.

---

## When to Use Each Level

### Standard Analysis (Default)

**Use when**:
- Reviewing a typical feature/bugfix PR
- Team asks for merge validation ("Can I merge this?")
- Time-constrained review (quick turnaround needed)
- Context: Tactical merge decision

**Output**: Focused findings list (typically 0-5 findings), clear merge decision (APPROVED / REQUEST CHANGES / COMMENT).

---

### Deep Analysis (On Request)

**Use when**:
- PR touches critical files (>500 lines) or high-risk modules
- Team explicitly requests architectural analysis
- Context: "Identify technical debt for planning" or "Deep review"
- User says: "be thorough", "analyze strictly", "find all issues"

**Output**: Comprehensive findings list (can be 10-30+ findings), technical debt report with effort estimates, refactoring roadmap suggestions.

**Trigger phrases**:
- "deep analysis"
- "identify technical debt"
- "thorough review"
- "sois plus tatillon" (French: "be more picky")
- "strict analysis"

---

## SOLID Principles Reference

### Single Responsibility Principle (SRP)
A class should have only one reason to change.

**Violation signals**:
- Class has >500 lines
- Class name contains "Manager", "Handler", "Util", "Helper" without specific domain context
- Class has >10 public methods with unrelated purposes
- Method has >50 lines or >10 parameters

**Example**:
```java
// VIOLATION: UserService handles auth, profile, notifications, billing
class UserService {
  void login() {}
  void updateProfile() {}
  void sendNotification() {}
  void processBilling() {}
}

// FIX: Extract to AuthService, ProfileService, NotificationService, BillingService
```

---

### Open/Closed Principle (OCP)
Classes should be open for extension, closed for modification.

**Violation signals**:
- Large switch/case or if-else chains on type codes
- Adding new behavior requires modifying existing class code
- No use of polymorphism or strategy pattern where variance exists

**Example**:
```java
// VIOLATION: Adding new discount type requires modifying this method
double calculateDiscount(String type, double amount) {
  if (type.equals("SEASONAL")) return amount * 0.1;
  if (type.equals("MEMBER")) return amount * 0.15;
  // Adding "BULK" discount requires modifying this method
}

// FIX: Use Strategy pattern with DiscountStrategy interface
```

---

### Liskov Substitution Principle (LSP)
Subtypes must be substitutable for their base types without altering correctness.

**Violation signals**:
- Subclass throws exceptions not thrown by parent
- Subclass weakens preconditions or strengthens postconditions
- Subclass returns null when parent guarantees non-null

---

### Interface Segregation Principle (ISP)
Clients should not depend on interfaces they don't use.

**Violation signals**:
- Interface has >10 methods
- Implementations throw UnsupportedOperationException for some methods
- Clients import interface but use only 1-2 methods

**Example**:
```java
// VIOLATION: Forcing all implementations to support print/scan/fax
interface MultiFunctionDevice {
  void print(); void scan(); void fax();
}

// FIX: Split into Printer, Scanner, Fax interfaces
```

---

### Dependency Inversion Principle (DIP)
High-level modules should not depend on low-level modules. Both should depend on abstractions.

**Violation signals**:
- Service directly instantiates concrete dependencies (no DI)
- Business logic depends on specific database/HTTP library classes
- No interfaces for external dependencies (hard to test)

**Example**:
```java
// VIOLATION: Service directly depends on MySQLUserRepository
class UserService {
  private MySQLUserRepository repo = new MySQLUserRepository();
}

// FIX: Depend on UserRepository interface, inject via constructor
```

---

## Anti-Patterns Reference

### God Class
A class that knows too much or does too much.

**Signals**: >500 lines, >15 methods, >10 fields, name ends in "Manager" or "Service" without specific context

**Impact**: High coupling, difficult testing, merge conflicts, hard to understand

**Fix**: Extract cohesive groups of methods into separate classes (by responsibility)

---

### Anemic Domain Model
Domain objects are data containers with no behavior; all logic lives in service classes.

**Signals**: Entities with only getters/setters, no business methods; service classes with >20 methods doing all domain logic

**Impact**: Poor encapsulation, OOP benefits lost, harder to reason about invariants

**Fix**: Move business logic into domain objects, make them rich models

---

### Feature Envy
A method uses data from another class more than its own class.

**Signals**: Method calls >5 getters on a collaborator object, method logic really belongs in the collaborator class

**Fix**: Move the method to the class it's envious of

---

### Primitive Obsession
Using primitive types (int, String) instead of small objects for domain concepts.

**Signals**: String fields for email/phone/ISBN, int for money amounts, String for enums

**Fix**: Create Value Objects (Email, PhoneNumber, Money, etc.)

---

### Long Method
A method that is too long (>50 lines) and does too much.

**Signals**: >50 lines, >3 levels of nesting, needs vertical scrolling, hard to name without "and"

**Fix**: Extract helper methods, apply SRP at method level

---

### Magic Values
Hard-coded literals whose meaning is not obvious.

**Signals**: Numeric literals (42, 0.15, 3600) or string literals ("ACTIVE", "admin") without context

**Fix**: Extract to named constants with clear names

---

## Workflow

### Step 1: Understand PR Scope

1. **Read PR description** (ticket, motivation, expected changes)
2. **Identify change types**: New feature / Bugfix / Refactoring / Test addition
3. **Note files modified**: Count lines added/deleted per file

**Output**: Context summary (1-2 sentences) of what the PR is trying to accomplish.

---

### Step 2: Run Automated Checks (if possible)

- Build passes?
- Tests pass?
- Linting clean?
- Coverage maintained or improved?

**If CI is available**: Check CI status before manual review. Do NOT report findings that CI already catches (linting errors, failing tests) — those are already visible to the author.

---

### Step 3: Analyze Changes (Standard or Deep)

For **each file modified**:

1. **New code**: Check conventions, test coverage, logic correctness
2. **Modified code**: Check change consistency (no orphaned references)
3. **Deleted code**: Confirm deletions are complete (no dangling imports, unused variables)
4. **Existing code touched**: Note any technical debt (God Class, SOLID violations) for "Technical Debt Identified" section (Deep Analysis only)

**Decision**: CRITICAL findings block merge. IMPORTANT findings are strong suggestions. MINOR findings are optional improvements.

---

### Step 4: Generate Report

**Template**:

```markdown
# Code Review: [PR Title]

## Summary
- **PR Scope**: [1-2 sentence summary]
- **Change Type**: [Feature / Bugfix / Refactoring / etc.]
- **Files Modified**: X files (+Y / -Z lines)
- **CI Status**: [Passing / Failing / Not run]

---

## Findings on the Changes (X total)

### CRITICAL (Y findings)
[List blocking issues introduced by PR]

### IMPORTANT (Z findings)
[List significant issues in PR changes]

### MINOR (W findings)
[List optional improvements for new code]

---

## Technical Debt Identified (Code Existing Before PR) [Deep Analysis only]

### CRITICAL (Y findings)
[List systemic architectural issues]

### IMPORTANT (Z findings)
[List moderate technical debt]

### MINOR (W findings)
[List minor code smells]

---

## Recommendation

**Merge Decision**: [APPROVED / REQUEST CHANGES / COMMENT]

**Rationale**: [1-2 sentences explaining decision based on CRITICAL/IMPORTANT findings]

**Next Steps** [if REQUEST CHANGES]:
1. [Specific action required]
2. [Specific action required]

**Refactoring Priorities** [if Deep Analysis]:
1. [Highest-impact technical debt to address]
2. [Next priority]
```

---

## Calibration Guidelines

### What is CRITICAL?

- Breaks tests
- Introduces security vulnerability
- Violates linting rules (if enforced by CI)
- Creates functional regression
- God Class (>500 lines) in touched code (Deep Analysis)
- Systemic Anemic Domain Model (Deep Analysis)

### What is IMPORTANT?

- Incomplete change (orphaned code, missing cleanup)
- Convention violation not caught by linters
- Missing tests for new logic
- Anti-DDD pattern in touched code (Deep Analysis)
- Feature Envy or moderate SOLID violation (Deep Analysis)

### What is MINOR?

- Improvement suggestion for new code (better naming, extracted constant)
- Magic Values
- Long Methods (50-100 lines)
- Primitive Obsession (Deep Analysis)

### What is NOT a finding?

- Pre-existing issues that the PR does not touch or worsen (Standard Analysis)
- Subjective style preferences already passing linters
- Theoretical optimizations with no measurable impact

---

## Examples

### Example 1: Standard Analysis

**PR**: Add pagination to user list endpoint

**Findings on Changes**: 1 IMPORTANT (missing test for edge case: empty page)

**Recommendation**: REQUEST CHANGES (add test for empty page, then merge)

---

### Example 2: Deep Analysis

**PR**: Add new field to UserService.updateProfile()

**Findings on Changes**: 0 (change is clean)

**Technical Debt Identified**:
- CRITICAL: UserService is a God Class (847 lines, 23 methods, handles auth/profile/notifications/billing)
- IMPORTANT: updateProfile() is 78 lines (Long Method), has 8 parameters (Primitive Obsession)
- MINOR: Magic value "ACTIVE" hard-coded in 3 places

**Recommendation**: APPROVED for merge. Separately, plan refactoring sprint to extract AuthService, ProfileService, NotificationService, BillingService from UserService.

---

## Notes

- **Language-agnostic**: Principles apply to Java, TypeScript, Python, C#, Go, etc.
- **Framework-agnostic**: SOLID and Clean Code transcend Spring Boot, Angular, Django, etc.
- **Adapt to project context**: If project has TESTING.md or specific conventions, reference those for test standards
- **Avoid false positives**: When in doubt, classify as MINOR or omit — better to under-report than block merges for noise

---

## When NOT to Use This Skill

- **Project has a dedicated review skill** (e.g., `<project>-pr-reviewer` with project-specific CI validation and conventions)
- **Trivial PR** (single-line typo fix, dependency version bump) — use judgment, not full methodology
- **Documentation-only PR** (no code changes) — focus on clarity and accuracy, not SOLID principles
