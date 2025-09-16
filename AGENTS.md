# Repository Guidelines

## Project Structure & Module Organization
- `app/` holds controllers, models, views, Hotwire, and theme assets under `assets/` and `assets/builds/`.
- Shared Bullet Train extensions live in `app/lib` and `lib/`; jobs sit in `app/jobs/`, and `config/` manages environments, Sidekiq, routing, and credentials.
- `test/` stores fixtures and factories, with coverage reports in `coverage/`.
- Architecture, onboarding, and workflow briefs reside in `docs/` and root guides like `DOCUMENTATION_INDEX.md` and `claude.md`.

## Build, Test, and Development Commands
- Start with `bash .claude/pre-flight.sh`, `bin/gh-sync`, and `rake claude:status` to sync environment and task queue.
- `bin/setup` installs gems, Yarn packages, and seeds databases; rerun after dependency updates.
- `bin/dev` launches Rails on port 3020 with Sidekiq, esbuild, Tailwind, and ngrok via `Procfile.dev`.
- `bin/rails db:migrate db:seed` keeps schema and seeded data aligned after scaffolding.
- `yarn build` and `yarn backstage_pass:build:css` rebuild JavaScript and Tailwind bundles.
- `bin/rails test`, `bin/rails test:system`, and `MAGIC_TEST=1 bin/rails test test/system/...` cover unit and UI verification.

## Coding Style & Naming Conventions
- Follow Ruby two-space indentation, snake_case filenames, CamelCase classes, and kebab-case Stimulus controllers ending in `_controller.js`.
- Run `.claude/validate-namespacing.rb "rails generate super_scaffold ..."` first, then scaffold with Bullet Train and preserve all 🚅 magic comments.
- Execute `standardrb --fix` before commits, align Tailwind utilities with `tailwind.backstage_pass.config.js`, and keep migrations descriptive with locale options configured.

## Testing Guidelines
- Minitest with SimpleCov powers the suite; open `coverage/index.html` after `bin/rails test` to confirm results.
- Tests auto-load `db/seeds`, so lean on seeded plans instead of duplicating data.
- Factories live in `test/factories`; keep files named `*_test.rb`, store system specs in `test/system/`, and capture complex flows with Magic Test (`MAGIC_TEST=1`, `SAVE_RECORDING=1`).

## Commit & Pull Request Guidelines
- Write imperative commit subjects mirroring history (e.g., `Implement AccessPass product system with complex pricing`), reference linked issues (`issue-3`), and review `AI_CURRENT_TASKS.md`, `claude.md`, and `CLAUDE_COMMANDS.md` before starting work; mark blockers with the provided GitHub scripts.
- Before opening a PR, run `standardrb --fix`, rebuild affected assets, and execute the relevant `bin/rails test` suites.
- PR descriptions should summarize scope, note migrations or worker impacts, attach UI screenshots or API samples, and include test results; finish with `bin/gh-complete <issue>` and resync via `bin/gh-sync`.

## Security & Configuration Tips
- Manage credentials with `bin/secrets`; never commit generated `config/credentials/*.key` files.
- Sidekiq requires Redis locally and in production—verify configuration before merging worker changes.
- Update `render.yaml`, `Procfile`, docs like `AUTHENTICATION_PASSWORDLESS.md`, and use `bin/resolve` to inspect ejected theme components in `app/views/themes/backstage_pass/`.
