# Vowloom — Design Plan

## 1. Product definition

Vowloom is an Apache-2.0, self-hosted Rails application for a wedding's full social life: invitations and RSVP collection before the event, coordination and media sharing during it, and a preserved interactive history afterward.

It is **not** a general social network, payment processor, wedding marketplace, or detailed project-management suite. It is a familiar, chronological community space with wedding-specific structured tools.

### Product principles

1. Content is post-centric: people encounter most information as posts in familiar feeds.
2. Structured data stays structured: events, RSVP responses, questionnaire answers, registry claims, and tasks are not free-form posts.
3. The experience does not impose wedding phases. The same layout works before, during, and after the event.
4. The site has only two content states: **Live** (writable) and **Frozen** (historical, read-only).
5. Visitors are always read-only. Members have persistent identity and can participate.
6. The feed is chronological with manual pinning; there is no algorithmic ranking.
7. Use a small number of hard-coded roles and fixed workflows rather than a custom permission builder.
8. Preserve originals, attribution, and the context in which media was shared.
9. Make ordinary guest tasks obvious on a phone and forgiving when a guest makes a mistake.

## 2. Scope and explicit boundaries

### In scope

- Public or private wedding access
- Invitations, households, RSVPs, meal choices, and reporting
- Member accounts and deliberately small profiles
- Official posts, member posts, comments, and controlled real-time conversations
- Staff-created information/discussion groups
- Flexible questionnaires and structured reporting
- External registry links plus on-site claim tracking
- Photos, videos, albums, professional bulk upload, and curated Gallery
- Couple-only private inbox
- Full-screen kiosk displays
- Live/Frozen state and portable archive export
- Self-hosted Docker deployment, PostgreSQL, local media storage, and optional S3-compatible storage

### Out of scope

- Payment processing, cash-fund processing, or collecting card data
- Member-to-member direct messages, follows, friends, or recommendations
- Vendor marketplace, hotel booking, or travel sales
- Detailed wedding planning (budgets, Gantt charts, vendor CRM, seating editor)
- General-purpose page builder or custom RBAC editor
- Native mobile apps, live location tracking, or a video-streaming platform
- Advanced workflow automation, project portfolios, or general team chat

## 3. Roles and authorization

Roles are global, hard-coded, and intentionally small.

| Role | Core authority |
| --- | --- |
| Owner | Full control, including site state, access policy, security, ownership transfer, and deletion. Exactly one owner. |
| Admin | Manages site content, accounts, invitations, groups, RSVP, registry, media, and moderation. Cannot transfer ownership or delete the site. |
| Helper | Assigned coordination, publishing, moderation, event, group, and media duties. Only accesses private groups or sensitive planning data when specifically assigned. |
| Member | Maintains own profile; participates in allowed posts, comments, groups, chat, questionnaires, RSVP, registry claims, and uploads. |
| Visitor | Read-only access to content explicitly available on a public site. |

### Authorization invariants

- Visitors never write, upload, RSVP, claim registry items, or create accounts without an invitation code.
- Sensitive answers (dietary, accessibility, travel, contact details) are staff-only unless a questionnaire explicitly declares another result policy.
- Helpers are not automatically granted guest exports, Couple Inbox access, or all private-group access.
- Private groups are visible only to selected Members and authorized staff.
- Owner/Admin/Helper can moderate content only within their authorized scope.
- Owner retains redaction authority even when the site is Frozen.

## 4. Access policy, identities, and invitations

### Site policy

| Policy | Landing behavior | Content access |
| --- | --- | --- |
| Public | Continue as Visitor, sign in, or create account with invitation code | Visitors can read public content; Members can participate. |
| Private | Sign in or create account with invitation code | No wedding content beyond the landing page is visible before authentication. |

### Invitees versus accounts

An attendee must not need an account to be counted. The roster is independent of website membership:

```text
Household
└── Invitee
    ├── event invitations
    ├── RSVP and meal choices
    ├── questionnaire answers
    └── optional Member account
```

Administrators can enter paper, phone, or in-person responses; add children and plus-ones; and link a later-created account to the existing Invitee. Reports distinguish attendance from online participation.

### Registration flow

1. Guest opens a QR/personal invitation link or enters a household invitation code.
2. The site displays the invited household and applicable events.
3. The guest selects their Invitee record.
4. The guest chooses a display name/login identifier and password. Photo and short summary are optional.
5. The Member account is linked to that Invitee record and directed to outstanding tasks.

Profiles contain only display name, optional photo, and optional short summary. Optional recovery email is authentication metadata, never public profile content. Admins can generate a one-time recovery code; they never view passwords.

## 5. Information architecture

### Landing / Cover

The front door contains a banner image, couple names, date, welcome message, basic color theme, and the relevant access actions. It is a cover, not a page builder.

### Primary community surfaces

| Surface | Purpose | Publishing |
| --- | --- | --- |
| Main | Official chronological feed: announcements, event cards, RSVP requests, questionnaires, registry collections, featured media, and files. | Owner/Admin/Helper; Members comment when enabled. |
| General | Member-created community feed and upload area. | Members publish and comment. |
| Gallery | Curated media view: albums, featured uploads, photos, and videos. | Staff curate; professional Helpers can publish to assigned albums. |
| Groups | Focused social and productivity spaces. | Defined by each group’s participation policy. |
| Events & RSVP | Structured schedule, locations, invitation eligibility, RSVP, and calendar links. | Staff manage; invited Members respond. |
| Registry | External registry links and tracked item claims. | Staff manage; Members claim. |
| Couple Inbox | Private Member-to-couple support conversations. | Members initiate; Owner/Admin reply. |

On desktop, the sidebar exposes all areas. On mobile, the most important destinations remain visible while RSVP and urgent questionnaire tasks are displayed as prominent action cards above feeds.

### Posts

Posts are the universal presentation layer. A post has author, body, attachments, visibility, timestamp, pin state, comment policy, optional group/event association, and an optional structured subject.

Structured subjects include Event, RSVP request, Questionnaire, Registry collection, Album, Checklist, and Conversation. Publishing an update is an intentional action: not every database change creates a feed post.

## 6. Groups, conversations, and productivity

Groups are staff-created spaces with only two settings.

| Setting | Values |
| --- | --- |
| Visibility | Site-wide or Private to selected Members |
| Participation | Information (staff publish) or Discussion (Members publish) |

Information posts can individually enable comments. Discussion groups permit member posts and comments. On a public site, Visitors may read site-wide groups but cannot interact.

Groups can contain posts, pinned resources, events, questionnaires, files, media, albums, checklist tasks, and a conversation post. Typical groups include wedding party, photographer team, shuttle riders, hotel guests, rehearsal attendees, and family.

### Lightweight tasks

Tasks remain intentionally modest: title, description, assignee, due date, completion state, optional related event, and comments. No boards, dependency graphs, time tracking, or workflow engine.

### Chat and comments

Comments are universal. A long-running, real-time conversation is a special post whose comments render as chat messages. This unifies identity, attachments, moderation, timestamps, and archival behavior.

- General wedding chat and group/event chats are supported.
- No member-to-member direct messages, typing indicators, presence, read receipts, or forwarding.
- Couple Inbox conversations are private to the initiating Member plus Owner/Admin.
- Real-time delivery enhances normal persistence: after reconnecting, the browser fetches missed messages.

## 7. Questionnaire design

Questionnaires are a first-class, flexible planning surface. Staff publish them into Main or Groups as post cards; General remains the free-form member feed rather than an uncontrolled form-builder.

### Supported question types

- Informational text
- Short text and long text
- Yes/no
- Single choice, multiple choice, and dropdown
- Number, date, time, and rating scale
- Person selection
- File/media upload

### Core capabilities

- Sections, introduction, required fields, and drafts
- Conditional visibility based on a preceding answer
- Open/close dates and response editing policy
- Individual or household response unit
- Audience: all Members, group Members, event invitees, selected Invitees, household, or person
- Result policy: staff-only, respondent-and-staff, aggregate, or Member-visible
- Related Event, Group, and Post
- Completion totals, filters, exports, printable summaries, and staff-entered responses
- Templates for meal selection, travel/lodging, song requests, accessibility needs, volunteer availability, RSVP supplement, contact confirmation, and informal polls

Conditional rules remain simple: show a question when a prior question has a defined answer. No formulas, scripts, deeply nested branching, or workflow automation.

Once a questionnaire has answers, destructive edits are restricted. Safe wording fixes and added choices remain possible; meaning-changing edits require a new version.

## 8. RSVP and Events

Events provide structured date/time, location, map link, calendar download, instructions, eligibility, and related content. Event posts can be pinned or published in a group.

RSVP supports household and individual attendance, per-event eligibility, plus-ones, children, meal selection, dietary and accessibility notes, custom questionnaire answers, deadlines, staff correction, change history, and CSV export.

Staff dashboards show invited, attending, declined, pending, account-holding, and offline participants, as well as event and meal totals. Sensitive response fields are never included in social feeds or profiles.

## 9. Registry

Registry is an important structured module, not a collection of ordinary links.

### Registry model

- Collections and categories
- Item title, description, image, priority, price/estimate, external link, and quantity
- External registry, charity, and cash-fund links (the app never takes payment)
- Member claims/reservations and optional purchased state
- Staff-only received, thank-you-sent, and private note tracking
- Real-time available/claimed/purchased totals
- Transactional claim protection to prevent double-claiming final quantity

The couple can see aggregate availability in real time. Purchaser identity should remain hidden by default until a gift is received or the registry is deliberately revealed. External stores cannot verify purchases automatically without a later integration; Members mark their claims as purchased.

A Registry collection, not each item update, can be published as a Main post.

## 10. Media, Gallery, and professional workflow

Members post media through General and Groups. Each asset retains its original source context. Gallery curation never deletes or moves the originating post; it adds the asset to an album or featured view.

### Media processing

Each upload stores an original plus generated web renditions:

```text
Original
├── thumbnail
├── feed rendition
├── full-screen rendition
└── for video: poster and browser-playable web copy
```

Displayed copies strip location metadata; the untouched original remains protected. Users can download web-sized media or, when authorized, the original. Album ZIP creation runs asynchronously.

### Moderation

Staff can report, hide, restore, remove an attachment, lock comments, feature media, add it to albums, associate it with events, and add attribution. Member uploads appear in their source feed immediately but only staff promotion adds them to the curated Gallery.

Professional Helpers have scoped bulk upload, album management, direct publishing, event association, crediting, and original-download rights. They do not need RSVP or Couple Inbox access.

Large media requires storage quotas, progress, retry, duplicate detection, background processing, and eventually resumable uploads. The software can be free; high-resolution originals and video still require real storage and bandwidth.

## 11. Kiosk displays

Kiosk is a read-only, full-screen presentation of existing approved content, accessed through a revocable display token.

Initial display presets:

- Gallery slideshow
- Gallery photo wall
- Event schedule / now-and-next board
- Pinned information board
- Mixed information and media
- Live aggregate questionnaire results

Kiosks have no navigation, account controls, composer, private-group content, RSVP data, original download controls, or unapproved media. They auto-refresh and reconnect, and may display a QR code linking guests to the main site.

## 12. Live and Frozen state

### Live

Eligible actions remain writable: registration, RSVP, questionnaires, registry claims, posts, comments, chat, media uploads, and moderation.

### Frozen

Historical participation becomes read-only:

- Registration, posting, commenting, chat, uploads, responses, and claims stop.
- Existing public/private visibility remains unchanged.
- Search, media viewing, downloads, and kiosk display continue.
- Password recovery and security controls remain operational.
- Owner retains redaction authority and can deliberately unfreeze the site.
- Freeze records actor, time, content counts, and archive manifest/version.

Freezing is paired with export, not treated as a substitute for backup. The immutable manifest and matching static readable site preserve posts, schedule, public RSVP totals, eligible anonymous questionnaire aggregates, registry availability, and media metadata in the public-safe export. The complete Owner export additionally preserves private conversations, detailed RSVP/questionnaire records, registry claims, and planning tasks, while excluding credentials, sessions, contact details, and invitation codes. Neither export includes original media bytes, so database and media backups remain required.

## 13. Technical architecture

### Initial stack

- Ruby on Rails monolith
- Hotwire/Turbo/Stimulus server-rendered interface
- PostgreSQL
- Rails Active Storage with local persistent disk by default; optional S3-compatible adapter
- Background jobs for media derivatives, archive ZIPs, emails, and exports
- Action Cable for real-time conversations, kiosk updates, and live Gallery refresh
- Compose-spec deployment: application, PostgreSQL, persistent database volume, persistent media volume; the same `compose.yaml` runs through Docker Compose or Podman Compose

No separate SPA, Redis requirement, microservices, external search engine, or cloud provider is required for the initial release.

### Operational requirements

- HTTPS, secure cookies, CSRF protection, rate limits, and audit logs for staff actions
- Content-report workflow and basic abuse prevention
- Database/media backup and restore documentation
- Media quotas and usage dashboard
- Responsive HTML, keyboard navigation, screen-reader labels, high contrast, reduced motion, and large touch targets
- Optional SMTP for account recovery and important announcements
- Basic database-backed full-text search for frozen archives

## 14. Core domain model

```text
Site
├── Account ── Profile ── optional Invitee link
├── Household ── Invitees ── Invitations / RSVPs
├── Event
├── Post ── Comments ── Attachments (MediaAsset)
├── Group ── GroupMembership ── Tasks
├── Questionnaire ── Questions ── Responses
├── RegistryCollection ── RegistryItem ── RegistryClaim
├── Album ── AlbumItems (MediaAsset)
├── PrivateConversation ── PrivateMessages
├── ModerationReport
├── KioskDisplay
└── ArchiveSnapshot
```

`Post` may link to a structured subject and to a Group/Event. `MediaAsset` can be attached to a post, assigned to albums, featured, and associated with an event without duplicating its source file.

## 15. MVP and delivery milestones

### Milestone 0 — Foundation

- Rails app, PostgreSQL, Docker Compose, Apache-2.0 licensing, CI, deployment/readme
- Site setup, cover page, public/private access, Owner bootstrap
- Accounts, invitation codes, households, invitees, and role enforcement

### Milestone 1 — Essential wedding website

- Main feed, posts, comments, pinned content, basic media upload
- Events, invitation eligibility, RSVP, meal choice, and admin totals
- Questionnaire builder, templates, results, exports, and staff-entered responses
- Registry collections, external links, item claims, and basic gift tracking
- Member profiles, offline RSVP entry, guest import/export
- Responsive and accessible core UI

### Milestone 2 — Community and coordination

- General feed, staff-created Groups, group membership, tasks, files
- Couple Inbox and moderation tools
- Real-time conversation posts and reconnect behavior

### Milestone 3 — Media preservation

- Gallery, albums, curation, professional Helper workflow
- Image derivatives, video web copy, original downloads, bulk upload, and media quotas

### Milestone 4 — Event-day and archival experience

- Kiosk displays and live updates
- Important-announcement delivery and optional SMTP
- Live/Frozen controls, archive manifest, exports, sensitive-data cleanup, archive search
- Backup/restore verification and static archive export

## 16. Product-quality bar

The most important acceptance journey is this:

> A relative opens a QR code on a phone, recognizes the page, claims their invitation, completes an RSVP, changes a meal choice, reads event details, leaves a comment, and uploads a photo without needing technical help.

The staff equivalent is:

> A coordinator imports invitees, sees response totals including offline guests, publishes an announcement, creates a private group and questionnaire, moderates a photo, promotes it to the Gallery, and safely freezes/export the finished history.

If those journeys are smooth, the project meets its purpose: it is genuinely useful for a wedding, self-hostable without a paid platform, and small enough to remain a focused portfolio project.
