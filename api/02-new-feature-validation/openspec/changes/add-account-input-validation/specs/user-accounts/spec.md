# user-accounts Specification

## Purpose
Define what the account creation endpoint accepts and what it must refuse.

## Requirements

### Requirement: Required Fields Are Present
The system SHALL reject account creation when a required field is empty or absent.

#### Scenario: Empty field submitted
- **WHEN** a client submits a blank username, a blank email, or a blank password
- **THEN** the service responds `400`
- **AND** no account is created

### Requirement: Field Formats Are Enforced
The system SHALL reject values that do not match the format required for their field.

#### Scenario: Malformed email
- **WHEN** a client submits an email with no `@`, two `@` characters, or only whitespace
- **THEN** the service responds `400`

#### Scenario: Password too short
- **WHEN** a client submits a password shorter than six characters
- **THEN** the service responds `400`

#### Scenario: Username too long
- **WHEN** a client submits a username longer than 256 characters
- **THEN** the service responds `400`

### Requirement: Injection Payloads Are Refused
The system SHALL reject any field value carrying an injection payload, so that
hostile input is never stored.

#### Scenario: SQL payload in a field
- **WHEN** a client submits `qa'; DROP TABLE users;--` as a username
- **THEN** the service responds `400`
- **AND** the payload is not stored

#### Scenario: Script tag in a field
- **WHEN** a client submits `<script>alert(1)</script>` as a username
- **THEN** the service responds `400`

#### Scenario: Template expression in a field
- **WHEN** a client submits `${7*7}` as a username
- **THEN** the service responds `400`

#### Scenario: Path traversal in a field
- **WHEN** a client submits `../../../../etc/passwd` as a username
- **THEN** the service responds `400`

#### Scenario: Header injection in a field
- **WHEN** a client submits a username containing an encoded CRLF sequence
- **THEN** the service responds `400`

### Requirement: Role Is Constrained
The system SHALL accept only the roles it supports and SHALL name the field in the error.

#### Scenario: Unsupported role
- **WHEN** a client submits a role other than `USER` or `ADMIN`
- **THEN** the service responds `400`
- **AND** the error names the `role` field and the permitted values
