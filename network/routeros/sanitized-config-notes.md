# RouterOS Sanitization Notes

Do not publish complete exports or binary backups without review.

Remove:

- passwords and password hashes;
- private/public key files and fingerprints when unnecessary;
- system IDs, serial numbers, and software IDs;
- production addresses and unrelated users;
- active quarantine entries;
- connection-tracking output;
- sensitive comments.

Publish only focused `.rsc` snippets required to reproduce the laboratory feature.
