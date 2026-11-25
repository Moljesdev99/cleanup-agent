# Contributing

Thanks for helping.

1. Fork the repo and create a branch.
2. Keep the safety model intact. Any new cleanup target must:
   - be limited to a regenerable cache or an explicitly reviewed item;
   - be revalidated before deletion;
   - respect the excludes file and the protected category.
3. Test with `--dry-run` first.
4. Open a pull request describing the change and its risk.

Do not include personal paths, tokens, chat ids or logs in a pull request.
