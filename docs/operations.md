# Vowloom operations

## Deploying

Copy `.env.example` to `.env`, set a unique `POSTGRES_PASSWORD`, set `VOWLOOM_HOST` to the public domain, and copy the Rails master key from the deployment host into `RAILS_MASTER_KEY`. Keep `.env` and `config/master.key` private.

Run the portable Compose specification with either runtime:

```sh
docker compose up -d --build
```

```sh
podman compose up -d --build
```

Place Vowloom behind an HTTPS reverse proxy and set `FORCE_SSL=true`. Do not expose PostgreSQL’s port beyond the local host.

### Optional S3-compatible media storage

Vowloom stores media on its persistent local volume by default. To use AWS S3,
MinIO, or another compatible object store, set `ACTIVE_STORAGE_SERVICE=s3` and
provide `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`, and `S3_BUCKET`. Set
`S3_ENDPOINT` for self-hosted providers, and leave `S3_FORCE_PATH_STYLE=true`
for MinIO-style deployments. The bucket contents are part of the wedding
archive and must be included in the backup plan.

## Backup

Back up the complete PostgreSQL cluster and the persistent media volume. A full cluster dump includes Vowloom's separate Action Cable database as well as the primary application database. Either command below works with Docker; replace `docker` with `podman` where supported by the local installation.

```sh
docker compose exec -T db pg_dumpall -U vowloom > vowloom-postgres.sql
```

```sh
docker run --rm -v vowloom_media_data:/data -v "$PWD":/backup alpine tar -C /data -czf /backup/vowloom-media.tar.gz .
```

Also retain the matching `.env` secrets (especially `RAILS_MASTER_KEY`) in a secure password manager or encrypted backup. Without the Rails master key, encrypted credentials cannot be recovered.

## Restore rehearsal

Practice restoration on an isolated host before relying on it for a wedding archive:

1. Start a clean Compose stack with the same Vowloom release and secrets.
2. Restore `vowloom-postgres.sql` so both `vowloom_production` and `vowloom_production_cable` are restored:

   ```sh
   docker compose exec -T db psql -U vowloom -d postgres < vowloom-postgres.sql
   ```

3. Restore `vowloom-media.tar.gz` into the `vowloom_media_data` volume:

   ```sh
   docker run --rm -v vowloom_media_data:/data -v "$PWD":/backup alpine tar -C /data -xzf /backup/vowloom-media.tar.gz
   ```
4. Run `docker compose exec web bin/rails db:prepare`.
5. Sign in, open the Gallery, and download both the archive manifest and readable HTML archive to confirm posts, RSVP data, and media metadata agree.

The Owner can freeze the site and download immutable public-safe or complete JSON manifests plus matching standalone readable HTML archives. The public-safe export preserves public schedule/RSVP totals, approved public questionnaire aggregates, public registry availability, public posts, and media metadata; it omits identities and notes behind RSVPs, questionnaire answers, registry claims, and planning tasks. The complete Owner export preserves those operational records, private groups, and private conversations, but intentionally still omits passwords, sessions, recovery/contact details, and invitation codes. The HTML file is script-free and works as an offline reading copy, but neither export contains the original media bytes or replaces a database/media backup. Keep periodic database and media-volume backups for the life of the archive.

Media originals are kept unchanged. Gallery, feed, and kiosk images use Vips-generated, metadata-stripped derivatives; only authorized staff can download an original. V1 intentionally serves accepted video uploads in their supplied browser-playable form rather than running an unmonitored ffmpeg/transcoding pipeline. Verify target browser compatibility with a short test upload before the event.

## Runtime checks

The web service reports healthy only after Rails can answer `GET /up`; inspect it with `docker compose ps` or `podman compose ps`. Compose restarts the database and web services after an unexpected exit. Test this path and the restore rehearsal before the event, then monitor the same health endpoint from the reverse proxy or an external uptime monitor.
