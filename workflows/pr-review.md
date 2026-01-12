---
name: pr-review
description: Review a Pull Request
---

# Workflow: PR Review

## Steps

1.  **Fetch PR Info**
    ```bash
    gh pr view
    gh pr diff
    ```

2.  **Code Review Checklist**
    - [ ] **Functionality**: Does it do what it says?
    - [ ] **Tests**: Are there tests? Do they pass?
    - [ ] **Security**: Any hardcoded secrets or unsafe inputs?
    - [ ] **Style**: Adheres to stricter project rules?

3.  **Local Verification (Optional)**
    ```bash
    gh pr checkout <pr-number>
    make test
    ```

4.  **Submit Review**
    - Approve (`gh pr review --approve`)
    - Request Changes (`gh pr review --request-changes`)
    - Comment (`gh pr review --comment`)
