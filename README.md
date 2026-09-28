![Silent;Call](banner.png)

# Cisco Security Research

**Researcher:** 0xReadingSteiner
**Contact:** 0xReadingSteiner@proton.me
**Vendor:** Cisco Systems, Inc.
**Vendor Notified:** 2026-08-04 (Cisco PSIRT, ZDI, SSD)
**Vendor Response:** None

---

## Why This Exists

Independent security research on commercially available Cisco products has identified critical vulnerabilities across multiple product lines — including the systems enterprises rely on for voice communications, collaboration, and network security.

Multiple coordination attempts were made before publication:

- **17 submissions** to the Zero Day Initiative (ZDI) — unprocessed
- **SSD** paused all Cisco vulnerability acquisitions, stating Cisco won't address existing reports
- **Cisco PSIRT** contacted directly on 2026-08-04 — no response

Cisco's refusal to engage leaves enterprise defenders blind. These advisories exist so that organizations running Cisco infrastructure can assess their own risk and take protective action.

---

## Products Under Research

| Product | Role | Status |
|---------|------|--------|
| **Cisco Unified Communications Manager (CUCM) 15.x** | Enterprise voice call processing | Active — 55+ vulnerabilities identified, 3 kill chains published (incl. cross-product False;Relay) |
| **Cisco Expressway X14.x / X15.x** | Collaboration edge / traversal proxy | Active — Blind;Wire (pre-auth SIP smuggling) + False;Relay (MRA corridor chain) published |
| **Cisco Firepower Threat Defense (FTD)** | Next-gen firewall / IPS | Upcoming |

---

## Kill Chains

Each advisory combines multiple vulnerabilities into a complete attack narrative.

### CUCM

| # | Name | Components | Summary | CVSSv3.1 | Date |
|---|------|------------|---------|----------|------|
| 01 | [**Silent;Call**](drops/01/ADVISORY.md) | Spoofhack → Keyhack → Roothack | Pre-authentication remote root — 3 HTTP requests, zero credentials | 10.0 | 2026-08-04 |
| 03 | [**Dead;Dial**](https://github.com/0xReadingSteiner/Dead-Dial) | Spoofhack → Deployhack → Lookaphack | Pre-auth RCE via 2006-era Apache Axis AdminService + JNDI injection in WebDialer — survives Tomcat Manager credential rotation | 10.0 | 2026-08-10 |

### Expressway

| # | Name | Components | Summary | CVSSv3.1 | Date |
|---|------|------------|---------|----------|------|
| 02 | [**Blind;Wire**](https://github.com/0xReadingSteiner/Blind-Wire) | Zerohack | Pre-authentication SIP request smuggling — `Content-Length: 2³²` wraps to 0, turning the edge proxy into a policy-blind tunnel | 8.1 | 2026-08-10 |

### Cross-product (Expressway + CUCM)

| # | Name | Components | Summary | CVSSv3.1 | Date |
|---|------|------------|---------|----------|------|
| 04 | [**False;Relay**](https://github.com/0xReadingSteiner/False-Relay) | Blankhack → Seedhack → corridor → Badgehack (＋ Splithack / Wraphack / Namehack) | MRA corridor abuse — presence-only edge gate + zero-auth relay-credential seeding + cluster-key identity forgery: internet-origin pre-auth CUCM data (200 live UDS XML) and forged-Bearer SSO-session acceptance, proven live end-to-end on both a seeded path and a pure-real-credential path. 2026-09-28 extension: the UDS user-resource gate resolved — a `sub`-matched forged token reads any user's record and writes its PIN/credentials from the internet (204, database-verified); per-user account takeover, silent, all-2xx. Zero fail2ban ticks on the success path. | 10.0 (composed) / 8.5 (one MRA account) | 2026-09-28 |

*Additional kill chains will be published on a rolling basis.*

---

## Individual Vulnerabilities

Each kill chain is composed of individual vulnerabilities, documented separately for CVE tracking.

### CUCM

| ID | Name | Title | CWE | Used In |
|----|------|-------|-----|---------|
| [SKYLINE-2026-001](vulns/SKYLINE-2026-001.md) | Spoofhack | X-Forwarded-For Header Trust Without Restriction | CWE-644 | Silent;Call, Dead;Dial |
| [SKYLINE-2026-002](vulns/SKYLINE-2026-002.md) | Keyhack | Hardcoded Tomcat Manager Credentials | CWE-798 | Silent;Call |
| [SKYLINE-2026-003](vulns/SKYLINE-2026-003.md) | Roothack | Multiple Unrestricted Sudo Privilege Escalation Paths | CWE-269 | Silent;Call |
| [SKYLINE-2026-057a](vulns/SKYLINE-2026-057a.md) | Deployhack | Apache Axis AdminService Arbitrary Class Deployment | CWE-306 | Dead;Dial |
| [SKYLINE-2026-057b](vulns/SKYLINE-2026-057b.md) | Lookaphack | JNDI Injection via Deployed SOAP Service | CWE-502 | Dead;Dial |
| [SKYLINE-2026-004](vulns/SKYLINE-2026-004.md) | Badgehack | Forged Bearer Access-Token Acceptance via Cluster-Key Identity Forgery | CWE-287 | False;Relay |

### Expressway

| ID | Name | Title | CWE | Used In |
|----|------|-------|-----|---------|
| [SKYLINE-2026-056](vulns/SKYLINE-2026-056.md) | Zerohack | Content-Length Integer Overflow (2³² → 0) in SIP Parser | CWE-190 | Blind;Wire |
| [SKYLINE-2026-005](vulns/SKYLINE-2026-005.md) | Blankhack | Presence-Only Session-Cookie Gate on the Internet-Facing MRA Edge | CWE-287 | False;Relay |
| [SKYLINE-2026-006](vulns/SKYLINE-2026-006.md) | Seedhack | Zero-Auth Relay-Credential Seeding via Expressway-C CDB | CWE-306 | False;Relay |
| [SKYLINE-2026-007](vulns/SKYLINE-2026-007.md) | Splithack | Chunk-Extension Request Smuggling Live on the MRA Edge (CVE-2026-24033/57834 class) | CWE-444 | False;Relay |
| [SKYLINE-2026-008](vulns/SKYLINE-2026-008.md) | Wraphack | Content-Length int64 Wraparound + Backend-Leg Smuggled-Request Delivery | CWE-190 | False;Relay |
| [SKYLINE-2026-009](vulns/SKYLINE-2026-009.md) | Namehack | uint16 Header-Name Truncation / Aliasing Across the Full MRA Chain (CVE-2026-58155 class) | CWE-197 | False;Relay |

---

## Tools (FG Series)

Assessment tools published alongside the research. Defensive framing; require legitimate access or explicit authorization.

| # | Name | Purpose | Repository |
|---|------|---------|------------|
| FG001 | **Phantom Phone Tap** | Post-breach assessment — demonstrates the full impact of compromised CUCM administrator credentials: covert listening, room monitoring, call insight, enterprise mapping | [FG001-phantom-phone-tap](https://github.com/0xReadingSteiner/FG001-phantom-phone-tap) |

---

## Coordination Timeline

See [TIMELINE.md](TIMELINE.md) for the full vendor coordination history.

---

## Legal

This research was conducted independently on commercially available software in a private laboratory environment. No proprietary source code, internal tools, or confidential information was used. All findings were reported to the vendor prior to publication.

The researcher is available for coordination with Cisco PSIRT, CERT/CC, CISA, or any affected organization.

---

## License

Advisory text is released under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). PoC scripts are provided for defensive and educational purposes only.
