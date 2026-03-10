# Firestore Schema

## User visit data

Path:
users/{uid}/visits/{countryId}

Fields:
- isVisited: Bool
- visitedDate: Timestamp?
- notes: String
- updatedAt: Timestamp

## Example

users/test-user/visits/FR

Example document:
- isVisited: true
- visitedDate: Timestamp
- notes: "Paris trip"
- updatedAt: Timestamp

## Security model

Firestore rules restrict access so that each authenticated user can only read and write their own visit documents.

Rule pattern:
- request.auth != null
- request.auth.uid == uid
