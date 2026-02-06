# ASR-{NUMBER}: {Title}

> **Architecturally-Significant Requirement**

## Metadata

| Field | Value |
|-------|-------|
| **Author** | {name} |
| **Date** | {YYYY-MM-DD} |
| **Status** | Identified / Analyzed / Validated / Addressed |
| **Priority** | Critical / High / Medium / Low |
| **Source** | {stakeholder, regulation, business goal, etc.} |
| **Related AD** | [AD-{NUMBER}](link) |
| **Related ADR** | [ADR-{NUMBER}](link) |

## 1. Requirement Statement

<!-- Clear, measurable statement of the requirement -->

**The system MUST/SHOULD {requirement statement}.**

## 2. Category

| Category | Subcategory |
|----------|-------------|
| [ ] **Performance** | Latency / Throughput / Resource usage |
| [ ] **Scalability** | Horizontal / Vertical / Data volume |
| [ ] **Availability** | Uptime / Redundancy / Disaster recovery |
| [ ] **Security** | Authentication / Authorization / Encryption / Compliance |
| [ ] **Maintainability** | Modularity / Testability / Deployability |
| [ ] **Interoperability** | APIs / Protocols / Data formats |
| [ ] **Usability** | Accessibility / Responsiveness / Localization |
| [ ] **Regulatory** | GDPR / HIPAA / SOC 2 / PCI-DSS |

## 3. Business Context

### 3.1 Business Driver

<!-- Why is this requirement important from a business perspective? -->

### 3.2 Stakeholders

| Stakeholder | Interest | Influence |
|------------|----------|-----------|
| | | High/Medium/Low |

### 3.3 Impact of Non-Compliance

<!-- What happens if this requirement is NOT met? -->

| Impact Area | Consequence | Severity |
|------------|-------------|----------|
| Revenue | | |
| Reputation | | |
| Legal | | |
| Operations | | |

## 4. Specification

### 4.1 Measurable Criteria

| Metric | Target | Minimum Acceptable | Measurement Method |
|--------|--------|-------------------|-------------------|
| | | | |

### 4.2 Scenarios

#### Normal Conditions

| Aspect | Value |
|--------|-------|
| Load | {expected concurrent users/requests} |
| Data volume | {expected data size} |
| Expected behavior | {description} |

#### Peak Conditions

| Aspect | Value |
|--------|-------|
| Load | {peak concurrent users/requests} |
| Data volume | {peak data size} |
| Expected behavior | {description} |

#### Failure Conditions

| Failure | Expected Behavior | Recovery Time |
|---------|-------------------|---------------|
| Database down | | |
| External service unavailable | | |
| Network partition | | |

### 4.3 Constraints

<!-- Technical, business, or regulatory constraints that affect this requirement -->

- 
- 

## 5. Architecture Impact

### 5.1 Affected Components

| Component | Impact | Change Required |
|-----------|--------|----------------|
| | High/Medium/Low | |

### 5.2 Trade-offs

<!-- What trade-offs does this requirement introduce? -->

| This Requirement | May Conflict With | Resolution |
|-----------------|-------------------|------------|
| Performance (low latency) | Cost (more infrastructure) | |
| Security (encryption) | Performance (added overhead) | |

### 5.3 Design Decisions Required

<!-- What architecture decisions need to be made to address this requirement? -->

- [ ] [AD/ADR needed]: {description}
- [ ] [AD/ADR needed]: {description}

## 6. Validation Strategy

### 6.1 Testing Approach

| Test Type | Description | Tools | Frequency |
|-----------|-------------|-------|-----------|
| Load test | Verify throughput targets | k6, Locust | Pre-release |
| Chaos test | Verify failure handling | Chaos Monkey | Monthly |
| Security scan | Verify security controls | OWASP ZAP | Per PR |
| Compliance audit | Verify regulatory compliance | {tool} | Quarterly |

### 6.2 Monitoring

| Metric | Alert Threshold | Dashboard |
|--------|----------------|-----------|
| | | |

### 6.3 Acceptance Criteria

- [ ] {Criterion 1 - measurable}
- [ ] {Criterion 2 - measurable}
- [ ] {Criterion 3 - measurable}

## 7. Implementation Status

| Phase | Status | Date | Notes |
|-------|--------|------|-------|
| Identified | Done | {date} | |
| Analyzed | | | |
| Design complete | | | |
| Implemented | | | |
| Validated | | | |

## Notes

<!-- Additional context, references, or links -->

## Changelog

| Date | Change | Author |
|------|--------|--------|
| {YYYY-MM-DD} | Initial identification | {name} |
