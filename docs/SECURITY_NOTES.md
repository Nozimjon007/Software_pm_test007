# Security Notes — NFR-01

> *“Rider and payment data is encrypted, both when stored and while being sent.”* (Must Have)

Encryption cannot be demonstrated visually in a prototype, and the prototype stores only fake data in memory.
This is the plan for the final version.

## Data we must protect
- **Rider data:** employee names, phone numbers, emails, pickup stops.
- **Payment / billing data:** invoices, company billing details, bank details.

## In transit
- All traffic between the app and backend over **HTTPS (TLS 1.2+)** only; HTTP disabled.
- HSTS on the web build.
- SMS / email providers called server-side over TLS — never from the client.

## At rest
- Database encryption at rest (managed service with AES-256 storage encryption).
- Extra field-level encryption for phone numbers, emails and bank details.
- Encryption keys stored in a secrets manager / environment variables — never in the Git repo.
- Organizer passwords hashed with **bcrypt/argon2**, never stored in plain text.

## Access
- Only logged-in organizers can see rider data; role checks on every API endpoint.
- Session tokens expire; logout invalidates them.
- Audit log for changes to bookings, drivers and invoices.

## Prototype limitations (honest list)
- The demo login is hardcoded (`AuthService`) — for demonstration only.
- No data is sent over the network except OpenStreetMap map tiles (HTTPS).
- All data is fictional and lives in memory; nothing is saved to disk.
