# Project Diagnosis Interview Sheet

## How to Use
1. Fill out each item in this sheet (checkboxes: mark applicable items with ✓)
2. Paste completed sheet into AI chat
3. Request "Please diagnose based on this interview sheet"

---

## 1. Basic Project Information

### Project Name
```
[                                        ]
```

### Project Overview (1-3 sentences)
```
[                                        ]
[                                        ]
[                                        ]
```

### Project Type (mark with ✓)
- [ ] CLI tools/scripts
- [ ] API/backend services
- [ ] Web applications (full stack)
- [ ] Mobile applications
- [ ] Desktop applications
- [ ] Embedded systems
- [ ] Distributed systems/microservices
- [ ] Data processing/analytics systems
- [ ] AI/machine learning systems
- [ ] Blockchain/cryptographic systems
- [ ] Other: [                        ]

### Development Phase
- [ ] Idea validation (PoC)
- [ ] Prototype
- [ ] MVP (minimum viable product)
- [ ] Production development
- [ ] Existing system modification
- [ ] Existing system migration/replacement

---

## 2. Business Requirements

### System Importance
- [ ] Hobby/learning use
- [ ] Internal tools (limited impact)
- [ ] Business systems (business impact)
- [ ] Customer-facing services (revenue impact)
- [ ] Mission-critical (cannot stop)

### Impact of Failure (multiple selection allowed)
- [ ] No impact/limited
- [ ] Work delays
- [ ] Financial loss (small scale)
- [ ] Financial loss (large scale)
- [ ] Credit/reputation loss
- [ ] Legal liability
- [ ] Life/safety related

### Expected User Count
- [ ] Personal use
- [ ] Up to 10 people
- [ ] Up to 100 people
- [ ] Up to 1,000 people
- [ ] Up to 10,000 people
- [ ] 10,000+ people
- [ ] General public

### Development Period
- [ ] Within 1 week
- [ ] Within 1 month
- [ ] Within 3 months
- [ ] Within 6 months
- [ ] Within 1 year
- [ ] Over 1 year

---

## 3. Technical Characteristics

### System Complexity

#### Data Processing
- [ ] Simple CRUD operations
- [ ] Complex business logic
- [ ] Real-time data processing
- [ ] Big data processing
- [ ] Complex data transformation/aggregation

#### Concurrency/Distribution
- [ ] Single-threaded/synchronous processing only
- [ ] Multi-threaded/concurrent processing
- [ ] Distributed processing/multiple nodes
- [ ] Microservices architecture
- [ ] Real-time synchronization required

#### External Integration
- [ ] Standalone (no external integration)
- [ ] Few API integrations
- [ ] Many system integrations
- [ ] Legacy system integration
- [ ] Third-party service dependencies

### Security Requirements
- [ ] Public information only (no security needed)
- [ ] Basic authentication/authorization
- [ ] Handles personal information
- [ ] Handles financial information
- [ ] Handles medical information
- [ ] Encryption required
- [ ] Advanced cryptography (zero-knowledge proofs, etc.)

### Performance Requirements
- [ ] No particular requirements
- [ ] Response within 1 second
- [ ] Response within 100ms
- [ ] High throughput required
- [ ] Real-time performance required
- [ ] 24/7 operation required

---

## 4. Quality/Regulatory Requirements

### Quality Requirement Level
- [ ] Minimum functionality is OK
- [ ] General quality (bugs acceptable)
- [ ] High quality (minimal bugs)
- [ ] Very high quality (almost no bugs)
- [ ] Perfect quality (proof required)

### Regulations/Compliance (multiple selection allowed)
- [ ] None
- [ ] Internal company standards
- [ ] Industry standards compliance
- [ ] Personal data protection laws (GDPR, etc.)
- [ ] Financial regulations (PCI DSS, etc.)
- [ ] Medical regulations (HIPAA, etc.)
- [ ] Audit requirements
- [ ] Formal proof required

### Testing Requirements
- [ ] Minimal testing
- [ ] General testing (70% coverage)
- [ ] High coverage (90%+)
- [ ] Complete testing (including E2E)
- [ ] Formal verification required

---

## 5. Team/Environment Information

### Team Size
- [ ] 1 person (individual development)
- [ ] 2-3 people
- [ ] 4-10 people
- [ ] 11-30 people
- [ ] 30+ people

### Team Skill Level
- [ ] Beginner-centered
- [ ] Intermediate-centered
- [ ] Advanced-centered
- [ ] Mixed

### Formal Methods Experience
- [ ] No experience
- [ ] Heard of it
- [ ] Basic knowledge
- [ ] Practical experience
- [ ] Expert

### Planned/Preferred Technologies (multiple selection allowed)

#### Languages
- [ ] Python
- [ ] JavaScript/TypeScript
- [ ] Java
- [ ] Go
- [ ] Rust
- [ ] C/C++
- [ ] Ruby
- [ ] Elixir
- [ ] Other: [                        ]
- [ ] Undecided (want AI to suggest)

#### Infrastructure/Environment
- [ ] Local development only
- [ ] On-premises
- [ ] Cloud (AWS)
- [ ] Cloud (GCP)
- [ ] Cloud (Azure)
- [ ] Cloud (Other)
- [ ] Docker/containers
- [ ] Kubernetes
- [ ] Serverless

### Development Environment
- [ ] AI chat only (code generation)
- [ ] Local development environment
- [ ] Claude Code, etc. (workspace environment)
- [ ] GitHub Codespaces
- [ ] Other cloud IDEs

---

## 6. Constraints

### Budget Constraints
- [ ] No budget limit
- [ ] Strict budget constraints
- [ ] Standard budget
- [ ] Generous budget

### Technical Constraints (multiple selection allowed)
- [ ] Specific language required: [                ]
- [ ] Specific framework required: [        ]
- [ ] Compatibility with existing systems required
- [ ] Specific DB required: [              ]
- [ ] Specific cloud required: [            ]
- [ ] On-premises required
- [ ] None

### Other Constraints/Requirements
```
[                                        ]
[                                        ]
[                                        ]
```

---

## 7. Initial Diagnosis Summary (AI-friendly format)

### Risk Level Assessment (self-evaluation)
- [ ] Low risk (small impact if failed)
- [ ] Medium risk (moderate impact)
- [ ] High risk (significant impact)
- [ ] Highest risk (catastrophic impact)

### Complexity Assessment (self-evaluation)
- [ ] Simple (CRUD-centered)
- [ ] Standard (general business logic)
- [ ] Complex (concurrency/distribution)
- [ ] Very complex (all elements complex)

### Preferred Development Approach
- [ ] Want fastest working solution (simple version recommended)
- [ ] Balance-focused (partial formal methods OK)
- [ ] Quality priority (consider complete version)
- [ ] Leave to AI judgment

---

## 8. Questions for AI (if any)

```
[                                        ]
[                                        ]
[                                        ]
```

---

## Submission Template

Copy and paste the following to AI:

```markdown
# Project Diagnosis Request

Based on the following completed interview sheet,
please diagnose the appropriate development approach (simple/complete version)
and start development.

[Paste completed interview sheet here]

After diagnosis, I want to proceed with the recommended guide.
```

---

## Interview Sheet Examples

### Example 1: Simple Web App (for simple version)
```
Project Name: Internal attendance management system
Project Overview: Web application to manage employee attendance
Project Type: ✓ Web application
Development Phase: ✓ MVP
System Importance: ✓ Internal tools
Impact of Failure: ✓ Work delays
Expected User Count: ✓ Up to 100 people
Development Period: ✓ Within 1 month
(abbreviated)
```

### Example 2: Financial System (for complete version)
```
Project Name: Cryptocurrency trading system
Project Overview: System for cryptocurrency trading and asset management
Project Type: ✓ Blockchain/cryptographic systems
Development Phase: ✓ Production development
System Importance: ✓ Mission-critical
Impact of Failure: ✓ Financial loss (large scale) ✓ Credit/reputation loss
Expected User Count: ✓ 10,000+ people
Development Period: ✓ Within 6 months
(abbreviated)
```

---

## Benefits of Interview Sheet

1. **Structured Information Collection**
   - Collect necessary information without omission
   - Enable AI to make accurate diagnosis

2. **Time Savings**
   - Reduce dialogue back-and-forth
   - Appropriate judgment on first attempt

3. **Objective Assessment**
   - Objectify with checkboxes
   - Eliminate subjective judgment

4. **Documentation/Sharing**
   - Document project characteristics
   - Share understanding within team

5. **Continuous Use**
   - Re-evaluate during project
   - Reuse for similar projects

---

**Interview Sheet Version**: 1.0  
**Last Updated**: August 8, 2025  
**Estimated Completion Time**: 5-10 minutes