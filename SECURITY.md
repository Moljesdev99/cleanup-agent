# Security

Cleanup Agent deletes files. It is designed to be conservative and auditable.

## Reporting a vulnerability

If you find a way to make the agent delete something outside its allowlist, bypass a safety check, or read a secret it should not, please open a private security advisory on GitHub (Security tab → "Report a vulnerability") instead of a public issue.

## Safety guarantees

- Destructive actions require explicit confirmation.
- Paths are revalidated immediately before deletion: existence, containment inside the home directory, symlink check, exclude check and running-app check.
- Non-safe items go to quarantine first.
- The protected category is read-only.
- Secrets are stored in the macOS Keychain, never in the repository.
- The optional snapshot helper is installed with a `sudoers` rule scoped to that single command.

## Scope

The tool runs with your user privileges. The only privileged component is `cleanup-thin-snapshots`, which runs `tmutil thinlocalsnapshots`. It does not run arbitrary commands.
