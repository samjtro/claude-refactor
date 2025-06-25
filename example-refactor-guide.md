# Example Refactor Guide

This is an example refactor guide to demonstrate the structure needed for claude-refactor.

## Overview

This refactor aims to modernize our authentication system by:
- Migrating from session-based to JWT token authentication
- Implementing refresh token rotation
- Adding multi-factor authentication support
- Improving security audit logging

## Current State

### Existing Implementation
- Session-based authentication using Express sessions
- Sessions stored in Redis
- Basic username/password authentication
- Limited security logging

### Pain Points
- Session management overhead
- Difficulty scaling horizontally
- No MFA support
- Insufficient audit trail

## Target Architecture

### Goals
1. Stateless JWT authentication
2. Secure refresh token mechanism
3. TOTP-based MFA
4. Comprehensive audit logging

### Technical Requirements
- JWT tokens with 15-minute expiry
- Refresh tokens with 7-day expiry and rotation
- TOTP support using speakeasy library
- Structured logging with correlation IDs

## Constraints

- Must maintain backward compatibility for 30 days
- Zero downtime migration
- Existing API contracts must be preserved
- Performance should not degrade

## Success Criteria

- All existing authentication flows work with JWTs
- MFA can be enabled/disabled per user
- Refresh token rotation prevents token replay attacks
- Audit logs capture all authentication events
- Load testing shows <5ms overhead vs sessions

## Implementation Preferences

- Use existing Express middleware patterns
- Leverage our current error handling framework
- Follow team's coding standards
- Comprehensive test coverage (>90%)

## Out of Scope

- OAuth/SAML integration (future phase)
- Biometric authentication
- Password policy changes

## Additional Context

- The team prefers incremental rollout
- We have a 2-week sprint for this work
- Security team must review before production