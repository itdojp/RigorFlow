# AI Chat-Driven Formal Specification Development Practice Guide

## Introduction

This guide provides practical guidance for selecting and applying formal methods optimal for projects through dialogue with generative AI (Claude, etc.), and proceeding with TDD implementation. Not all projects need formal methods; AI diagnoses and suggests necessary methods.

## Part 0: Project Diagnosis

### 0.1 Formal Methods Necessity Assessment

#### Diagnosis Request to AI

```markdown
## Project Diagnosis Request
"Please diagnose whether formal methods are needed for the following project:

Project overview: [description]
Risk level: [low/medium/high]
Complexity: [simple/normal/complex]
Important characteristics: [concurrency/cryptography/financial/life-critical]

Present as diagnosis results:
1. Necessity of formal methods
2. If needed, which level (Level 0-4)
3. Recommended implementation language
4. Staged introduction plan"
```

#### Branching Based on Diagnosis Results

**When formal methods not needed**:
- Proceed to regular design and development process
- Ensure quality with BDD and TDD
- Add later if necessary

**When formal methods needed**:
- Start with necessary minimum
- Apply only to high-risk parts
- Gradually expand

## Part 1: Requirements Analysis and Specification Generation (As Needed)

### 1.1 Requirements Specification Creation (Level 0-1)

#### Basic Requirements Description (All Projects)

```markdown
## Requirements Clarification
"Please organize requirements for the following system:

System overview: [describe overview]
Main functions: [describe in bullet points]

Output format:
- Level 0: Clear requirements description in natural language
- Level 1 addition: Also create BDD scenario format"
```

#### BDD Specification (When Level 1 Selected)

```gherkin
Feature: Feature name
  Scenario: Scenario name
    Given precondition
    When action
    Then expected result
```

### 1.2 Selective Application of Formal Specification

#### Which Parts to Apply Formal Methods

```markdown
"Please identify parts of this system where formal methods should be applied:

System function list: [list]

Analysis perspectives:
- Concurrency risk → Level 3 (TLA+, etc.)
- Computational accuracy → Level 4 (Dafny, etc.)
- Data consistency → Level 2 (type system)
- Normal processing → Level 0-1 sufficient

Please present recommendations by part"
```

### 1.3 Language-Independent Specification Creation

#### Level 3: When Model Checking is Needed

```markdown
"We will perform model checking due to concurrency issues:

Target: [session management, message ordering, etc.]
Tool selection: Choose from TLA+, Alloy, others

Elements to include in specification:
- Elements operating concurrently
- Synchronization/communication mechanisms
- Timing constraints
- Invariants

Implementation language will be decided later"
```

#### Level 4: When Proof is Needed

```markdown
"We need to prove correctness of cryptographic processing:

Target: [cryptographic functions, security protocols]
Tool selection: Choose from Dafny, Coq, F*

Elements to include in specification:
- Pre-conditions and post-conditions
- Invariants
- Mathematical properties

Implementation language chosen considering provability"
```

#### Basic Structure Template

```markdown
"Please create TLA+ specification including the following elements:

1. Constants (CONSTANTS)
   - Player set
   - Timeout values
   - Move types

2. Variables (VARIABLES)
   - Each player's state
   - Game session state
   - Message queue

3. Initial state (Init)
   - Initial values of all variables

4. Actions
   - Player joining
   - Move selection and commit
   - Result revelation
   - Timeout processing

5. Invariants
   - Type invariant (TypeInvariant)
   - Safety invariant (SafetyInvariant)

6. Liveness conditions
   - Eventually winner is determined
   - No deadlock"
```

#### TLA+ Specification Quality Check

**AI Verification Request**:

```markdown
"Please verify the created TLA+ specification from the following perspectives:

Syntax check:
- Is there MODULE declaration?
- Is EXTENDS clause appropriate?
- Is variable declaration format correct?

Semantic check:
- Does Init predicate initialize all variables?
- Does Next predicate include all actions?
- Are invariants meaningful?

Completeness check:
- Are all BDD specification scenarios covered?
- Are error cases considered?
- Are concurrent execution issues considered?"
```

### 1.4 Dafny Specification Creation

#### Contract Design Template

```markdown
"Please create the following Dafny specification:

1. Data type definitions
   - Move type (Rock, Scissors, Paper)
   - GameResult type (Win, Lose, Draw)
   - Commitment type (hash value)
   - Proof type (zero-knowledge proof)

2. Pure function contracts
   function CreateCommitment(move: Move, nonce: nat): Commitment
     ensures |result| == 64  // Hash length

   function JudgeGame(move1: Move, move2: Move): GameResult
     ensures move1 == move2 ==> result == Draw
     ensures (move1 == Rock && move2 == Scissors) ==> result == Win

3. Method contracts
   method VerifyProof(proof: Proof, commitment: Commitment) 
     returns (valid: bool)
     ensures valid ==> ProofMatchesCommitment(proof, commitment)

4. Invariants
   - Data structure consistency
   - Cryptographic properties"
```

#### Dafny Specification Verification

```markdown
"Please check the Dafny specification from the following perspectives:

Contract completeness:
- Do all functions have ensures clauses?
- Are necessary requires clauses defined?
- Do methods with side effects have modifies clauses?

Contract soundness:
- Are pre-conditions not too strong?
- Are post-conditions achievable?
- Can invariants be maintained?

Implementability:
- Are contracts implementable in Rust?
- Can performance requirements be met?"
```

## Part 2: Specification Verification and Improvement

### 2.1 Inter-Specification Consistency Check

#### Consistency Checklist

```markdown
"Please confirm consistency between TLA+ and Dafny specifications:

State correspondence:
□ Are there corresponding Dafny types for each TLA+ variable?
□ Do state transitions match in both specifications?

Operation correspondence:
□ Do TLA+ actions correspond to Dafny functions/methods?
□ Are argument and return value types consistent?

Error handling:
□ Are error cases handled the same way in both specifications?
□ Is handling of temporal elements like timeouts clear?

Please report inconsistencies in the following format:
- Inconsistency location: [specific location]
- Problem content: [details]
- Fix suggestion: [proposal]"
```

### 2.2 Requirements Coverage Check

```markdown
"Please analyze coverage between BDD requirements specification and formal specifications:

## Check Items
1. Where is each BDD scenario covered in specifications?
2. Are there any uncovered requirements?
3. Are there features in specifications but not in requirements?

## Reporting format
Scenario name: [scenario]
- TLA+ correspondence: [corresponding part]
- Dafny correspondence: [corresponding part]
- Coverage: [complete/partial/none]"
```

### 2.3 Implementability Check

```markdown
"Please evaluate implementability of formal specifications:

Technical feasibility:
- Can it be implemented with chosen technology stack?
- Can performance requirements be met?
- Are necessary libraries available?

Complexity assessment:
- Estimated implementation effort
- Technical difficulty
- Risk factors

Alternative suggestions:
- Are there easier implementation methods?
- Is specification simplification possible?"
```

## Part 3: Test-Driven Development

### 3.1 Test Generation Strategy

#### Test Derivation from Specifications

```markdown
"Please generate the following tests from formal specifications:

1. Unit tests from Dafny contracts
   - Normal cases: inputs satisfying contracts
   - Boundary values: contract boundary conditions
   - Abnormal cases: contract violation cases

2. Property tests from TLA+ invariants
   - State invariant maintenance
   - Safety property verification
   - Liveness property confirmation

3. Acceptance tests from BDD scenarios
   - Direct conversion of Given-When-Then
   - End-to-end flows

Please include for each test:
- Test name (name expressing intent)
- Test purpose
- Expected result"
```

### 3.2 TDD Cycle Practice

#### Cycle 1: First Test

```markdown
"Please create the first test case:

Target function: [function to implement]
Test type: [unit/integration]
Language: [Rust/Elixir]

In the following format:
1. Test code (assuming it will fail)
2. Explanation of test intent
3. Minimal implementation policy"
```

#### Cycle 2: Implementation

```markdown
"Please provide minimal implementation to pass this test:

Test: [previous test]

Requirements:
- Consider only passing the test
- Avoid excessive design
- Assume refactoring later"
```

#### Cycle 3: Refactoring

```markdown
"Please refactor the implementation:

Current implementation: [code]

Improvement points:
- Remove code duplication
- Improve readability
- Enhance performance
- Apply design patterns

But do not change tests"
```

#### Cycle 4: Next Test

```markdown
"Please suggest the next test to write:

Implemented functions: [list]
Unimplemented functions: [list]

Priority criteria:
- High-risk functions
- Dependencies to other functions
- Business value"
```

### 3.3 Test Quality Check

```markdown
"Please evaluate the created test suite:

Coverage:
- Line coverage
- Branch coverage
- Specification coverage

Quality indicators:
- Test independence
- Execution speed
- Maintainability
- Intent clarity

Improvement suggestions:
- Missing test cases
- Redundant tests
- Test structure improvements"
```

## Part 4: Integration and System Testing

### 4.1 Component Integration

#### Elixir-Rust Boundary Testing

```markdown
"Please design integration tests at boundaries:

Boundary interface:
- Function name: [Rust function called from Elixir]
- Input type: [data format]
- Output type: [return value format]

Test cases:
1. Normal data passing
2. Error propagation
3. Type conversion accuracy
4. Performance (latency)
5. Behavior during concurrent calls"
```

### 4.2 End-to-End Testing

```markdown
"Please create E2E tests based on BDD scenarios:

Scenario: [BDD scenario name]

Test environment:
- Required services
- Test data
- Mocks/stubs

Execution steps:
1. Environment preparation
2. Scenario execution
3. Result verification
4. Cleanup

Expected results:
- Functional confirmation items
- Non-functional confirmation items"
```

### 4.3 System Quality Check

```markdown
"Please evaluate overall system quality:

Functional requirements satisfaction:
□ Do all BDD scenarios work?
□ Are error cases handled appropriately?

Non-functional requirements satisfaction:
□ Does response time meet requirements?
□ Does concurrent connection count meet requirements?
□ Do security requirements meet standards?

Room for improvement:
- Performance bottlenecks
- Error handling improvements
- Usability issues"
```

## Part 5: Practical Approach

### 5.1 Time Allocation by Phase (Standard for 1 Feature)

| Phase | Work Content | Duration | Deliverables |
|-------|--------------|----------|--------------|
| **Requirements Definition** | BDD specification creation | 30-60 min | BDD scenarios |
| **Domain Analysis** | Technical division judgment | 20-30 min | Division design |
| **Specification Generation** | TLA+/Dafny creation | 60-90 min | Formal specifications |
| **Specification Verification** | Consistency & completeness check | 30-45 min | Verified specifications |
| **Test Generation** | Various test creation | 45-60 min | Test code |
| **TDD Implementation** | Implementation and refactoring | 2-4 hours | Implementation code |
| **Integration Testing** | E2E verification | 30-45 min | Verified working system |

### 5.2 Effective AI Dialogue Tips

#### Good Question Patterns

**Specific with Context**:
```
✅ Good example:
"For rock-paper-scissors win/loss judgment function, generate
Rust unit tests from Dafny contract.
I particularly want to comprehensively test draw cases."

❌ Bad example:
"Write tests"
```

**Proceed Step by Step**:
```
✅ Good example:
1. "First create one test for simplest case"
2. "Next add boundary value tests"
3. "Finally add error case tests"

❌ Bad example:
"Generate all tests at once"
```

**Include Feedback**:
```
✅ Good example:
"In the generated TLA+ specification, timeout processing is
unclear. Please define it in more detail."

❌ Bad example:
"Specification is wrong"
```

### 5.3 Troubleshooting

#### Common Problems and Solutions

| Problem | Symptom | AI Question Example |
|---------|---------|---------------------|
| **Specification Inconsistency** | TLA+ and Dafny have different states | "Please suggest ways to unify state representations in both specifications" |
| **Test Failure** | Different result from expected | "Please analyze the cause of this test failure: [error content]" |
| **Implementation Difficulty** | Specification too complex | "Is there a way to implement this specification more simply?" |
| **Performance** | Processing slow | "Please identify bottlenecks in this processing and suggest improvements" |

### 5.4 Quality Checklist

#### Completion Conditions for Each Phase

```markdown
□ BDD Specification
  □ All major functions are scenarioized
  □ Acceptance criteria are clear
  □ Specific and measurable

□ Formal Specification
  □ No syntax errors
  □ Covers BDD requirements
  □ Implementable content

□ Tests
  □ Coverage 90%+
  □ All tests executable
  □ Intent clear

□ Implementation
  □ All tests pass
  □ Refactoring complete
  □ Code review done

□ Integration
  □ E2E tests successful
  □ Non-functional requirements met
  □ Deployable
```

## Appendix A: Language-specific Templates

### Rust (Dafny Specification Implementation)

```rust
// Unit test template
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_function_name_normal_case() {
        // Arrange
        let input = setup();
        
        // Act
        let result = target_function(input);
        
        // Assert
        assert_eq!(result, expected_value);
    }

    #[test]
    #[should_panic(expected = "error message")]
    fn test_function_name_error_case() {
        // Error case test
    }
}
```

### Elixir (TLA+ Specification Implementation)

```elixir
# Property test template
defmodule GameTest do
  use ExUnit.Case
  use PropCheck

  property "invariant maintenance" do
    forall state <- game_state_generator() do
      # Property verification
      valid_state?(state)
    end
  end

  test "state transition accuracy" do
    # Given
    initial_state = %GameState{}
    
    # When  
    new_state = GameSession.apply_action(initial_state, action)
    
    # Then
    assert valid_transition?(initial_state, new_state)
  end
end
```

## Appendix B: Project Scale-based Adjustments

### Small Scale (About 1 week)
- BDD: 3-5 main scenarios
- Formal specification: Core functions only
- Testing: Unit test focused
- Simplification OK

### Medium Scale (About 1 month)
- BDD: Cover all functions
- Formal specification: Both TLA+ and Dafny
- Testing: Implement all levels
- Strictly observe quality standards

### Large Scale (3+ months)
- BDD: Detailed scenarios
- Formal specification: Complete specifications
- Testing: Comprehensive testing
- Emphasize performance and security

## Summary

Following this guide, through AI dialogue:

1. **Clarify requirements** (BDD)
2. **Formalize specifications** (TLA+/Dafny)
3. **Generate tests** (derive from specifications)
4. **Implement with TDD** (step by step)
5. **Integrate and verify** (E2E)

Utilize AI in all steps to build high-quality systems without script creation.

### Success Points

- **Proceed step by step**: Don't demand too much at once
- **Ask specifically**: Make context and intent clear
- **Emphasize feedback**: Confirm results and improve
- **Maintain quality standards**: Use checklists

This approach enables efficient development of systems that balance formal correctness with practicality.

---

**Created**: August 8, 2025  
**Version**: 1.0