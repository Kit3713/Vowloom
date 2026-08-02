# Vowloom

Vowloom is an Apache-2.0, self-hosted wedding community. It combines invitations, RSVP, questionnaires, registry claims, events, group coordination, posts, and a preserved wedding history in one Rails application.

The product specification lives in [docs/design-plan.md](docs/design-plan.md).
Deployment, backup, and restore guidance lives in [docs/operations.md](docs/operations.md).

## Run with Docker Compose or Podman Compose

The repository uses the portable Compose specification:

```sh
docker compose up --build
```

```sh
podman compose up --build
```

For a non-local deployment, copy `.env.example` to `.env`, set a strong `POSTGRES_PASSWORD`, supply the Rails master key, and set `FORCE_SSL=true` behind an HTTPS reverse proxy.

## Local Rails development

Requirements: Ruby 4.0+, PostgreSQL 16+, and Bundler.

```sh
bundle install
bin/rails db:prepare
bin/rails server
```

## Security posture

Vowloom uses bcrypt passwords, signed HTTP-only sessions, CSRF protection, rate limits on setup/sign-in/registration/password reset, filtered invite codes, role checks, and access-controlled content. It is designed for normal private-event security, not as a high-assurance identity system.
