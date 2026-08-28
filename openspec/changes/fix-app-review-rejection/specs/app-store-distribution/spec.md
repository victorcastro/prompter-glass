# app-store-distribution Specification

## ADDED Requirements

### Requirement: A public support page serves the Support URL

The project SHALL publish a support page reachable without an account, containing a contact email, a stated response expectation, instructions for reporting a bug, system requirements, known limitations and a short FAQ. The Support URL in App Store Connect SHALL point at that page. An issue tracker SHALL NOT be used as the Support URL.

#### Scenario: A user looks for support

- **WHEN** a user opens the Support URL from the App Store listing without a GitHub account
- **THEN** the page loads and gives them a contact email and instructions for asking a question or reporting a bug

#### Scenario: Links on the support page

- **WHEN** the support page is published
- **THEN** every link on it resolves, including the repository, privacy policy and terms links

### Requirement: The shipped build carries no temporary entitlement exceptions

The app's entitlements SHALL contain no key beginning with `com.apple.security.temporary-exception.`. Continuous integration SHALL fail when such a key is present.

#### Scenario: A temporary exception is reintroduced

- **WHEN** a change adds a `com.apple.security.temporary-exception.*` key to the entitlements file
- **THEN** the pull request check fails and names the offending key

### Requirement: A resubmission carries its own version and changelog entry

A build submitted to App Review after a rejection SHALL have a distinct version and build number from the rejected build, and the changelog SHALL record what changed for each cited guideline.

#### Scenario: Resubmitting after a rejection

- **WHEN** a build is prepared for resubmission
- **THEN** its marketing version and build number differ from the rejected build, and the changelog names the fixes for each rejected guideline
