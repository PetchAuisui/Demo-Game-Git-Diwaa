class_name AuthRules
extends RefCounted

## Rules and length limits for player authentication fields.
##
## IMPORTANT SECURITY NOTES:
## 1. All constants here mirror server/src/GitDiwaa.Online/Accounts/AccountRules.cs.
##    If rules are modified on one side, they MUST be updated on the other.
## 2. Client-side validation in Godot exists purely for immediate player feedback (UX).
##    The server re-validates all rules authoritatively on every request.

const USERNAME_MIN_LENGTH := 3
const USERNAME_MAX_LENGTH := 20

const EMAIL_MAX_LENGTH := 254
const EMAIL_LOCAL_PART_MAX_LENGTH := 64

const DISPLAY_NAME_MIN_LENGTH := 1
const DISPLAY_NAME_MAX_LENGTH := 50

const PASSWORD_MIN_LENGTH := 8
const PASSWORD_MAX_LENGTH := 128

const LOGIN_IDENTIFIER_MAX_LENGTH := 254
