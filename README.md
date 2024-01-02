*** DO NOT USE THIS TO STORE YOUR ACTUAL PASSWORDS ***

this is only meant as a demonstration. even though the passwords and other data is never stored in plain text, this is still not secure enough for real-life use.

in a real-life scenario, the master password would never be sent to the server.
instead, it's used for client-side decryption only, where the password manager can use key derivation functions to derive encryption keys from the master password.

novault, being only for demonstration purposes, doesn't really use a "master password". the user account password, after being authenticated, is used as the encryption key.

i also didn't include a lot of server-side validation, which is a bad security practice for production-ready applications.