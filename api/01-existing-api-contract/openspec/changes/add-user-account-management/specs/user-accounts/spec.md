# user-accounts Specification

## Purpose
Define account creation, update and access-control behaviour for the user service.

## Requirements

### Requirement: Account Update Persists
The system SHALL persist changes made through the update endpoint and SHALL NOT return the password in any response.

#### Scenario: Update changes the stored record
- **WHEN** a client sends `PUT /api/users/{id}` with a new username and email
- **THEN** the service responds `200`
- **AND** the response body carries the new username and email
- **AND** the response includes `updatedAt`
- **AND** the response does not contain a `password` field

#### Scenario: The change survives a re-read
- **WHEN** the client re-reads the account with `GET /api/users/{id}`
- **THEN** the stored record shows the updated username and email

#### Scenario: Updating an account that does not exist
- **WHEN** a client sends `PUT /api/users/999999999`
- **THEN** the service responds `404`
- **AND** no account is created

### Requirement: Usernames And Emails Are Unique
The system SHALL reject an attempt to create an account whose username or email already exists.

#### Scenario: Duplicate username
- **WHEN** a client creates an account with a username that already exists
- **THEN** the service responds `409`
- **AND** no second account is created

#### Scenario: Duplicate email
- **WHEN** a client creates an account with an email that already exists
- **THEN** the service responds `409`

### Requirement: Anonymous Access Is Refused
The system SHALL refuse every unauthenticated request to the account endpoints.

#### Scenario: No credentials supplied
- **WHEN** a client requests `GET /api/users` with no `Authorization` header
- **THEN** the service responds `401` or `403`

#### Scenario: Malformed credentials supplied
- **WHEN** a client supplies a garbage bearer token, a `Basic` scheme, or an empty bearer value
- **THEN** the service responds `401` or `403` in every case

### Requirement: Input Is Validated
The system SHALL reject account input that is empty, malformed, or carries an injection payload.

#### Scenario: Missing or malformed fields
- **WHEN** a client submits a blank username, blank email, blank password, an email with no `@`, or a password shorter than six characters
- **THEN** the service responds `400`

#### Scenario: Injection payloads in the username
- **WHEN** a client submits a username containing SQL, a script tag, a template expression, or a path traversal sequence
- **THEN** the service responds `400`
- **AND** the payload is not stored

### Requirement: Malformed Requests Are Handled
The system SHALL answer malformed protocol-level requests with the correct status rather than a server error.

#### Scenario: Bad body or content type
- **WHEN** a client sends a non-JSON body, a `text/plain` content type, or no body at all
- **THEN** the service responds `400` or `415`
- **AND** never `500`

#### Scenario: Wrong method or unknown route
- **WHEN** a client sends `PUT` to the collection, or requests an unknown route
- **THEN** the service responds `405` or `404` respectively
