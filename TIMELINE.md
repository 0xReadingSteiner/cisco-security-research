# Vendor Coordination Timeline

This document records all attempts to coordinate the disclosure of 55 vulnerabilities in Cisco Unified Communications Manager 15.x and related Cisco Expressway findings.

## Summary

| Channel | Status | Detail |
|---------|--------|--------|
| ZDI (Zero Day Initiative) | Pending | 17 submissions awaiting processing |
| SSD (Security Solutions & Development) | Paused | "Not accepting any more CUCM vulnerabilities until Cisco has addressed other submissions" |
| Cisco PSIRT (direct) | No response | Contacted 2026-08-04 (CUCM root chain) and 2026-08-10 (Expressway Blind;Wire) |
| MITRE (CNA of Last Resort) | Pending | CVE ID request submitted 2026-08-04 |

## Detailed Timeline

| Date | Action |
|------|--------|
| 2026 (multiple dates) | 17 CUCM vulnerability submissions sent to ZDI. ZDI coordinates with Cisco on the researcher's behalf. Submissions remain unprocessed as of publication. |
| 2026 | SSD contacted regarding CUCM vulnerability acquisition. SSD responded that they have paused CUCM acquisitions because Cisco has not addressed existing reports in their queue. |
| 2026-08-04 | Cisco PSIRT contacted directly via psirt@cisco.com. Email described the pre-authentication remote root chain (3 vulnerabilities) and referenced the 17 pending ZDI submissions. Full technical details offered upon request. |
| 2026-08-04 | MITRE contacted via cve@mitre.org requesting CVE ID assignment under the CNA of Last Resort process for 3 vulnerabilities forming the pre-authentication root chain. |
| 2026-08-04 | Drop 01 published — Silent;Call: pre-authentication remote root chain in CUCM 15.x. |
| 2026-08-06 | FG001 Phantom Phone Tap published — post-breach assessment tool demonstrating the impact of compromised CUCM administrator credentials. |
| 2026-08-09/10 | Blind;Wire discovered and confirmed live against Cisco Expressway X14.3.7 — pre-authentication SIP request smuggling via Content-Length integer overflow (SKYLINE-2026-056). |
| 2026-08-10 | Cisco PSIRT notified of the Expressway finding; CVE ID requested from MITRE (CNA of Last Resort). No response to date. |
| 2026-08-10 | Drop 02 published — Blind;Wire (Expressway X14.x SIP request smuggling). |
| 2026-08-10 | Drop 03 published — Dead;Dial: pre-auth RCE via Apache Axis AdminService + JNDI injection in CUCM WebDialer (SKYLINE-2026-057a/b), live-confirmed 2026-08-01. Independent path — survives Silent;Call credential rotation. |
| 2026-06 → 2026-09 | Expressway MRA corridor research: edge remap/plugin chain mapped on X15.5.1; carrier access model resolved; 38/38 upstream ATS CVE corpus adjudicated against the Cisco rebuild; chunk-extension smuggling (Splithack) and Content-Length int64 wrap with backend-leg delivery (Wraphack) demonstrated live; uint16 header-name aliasing (Namehack) proven end-to-end with dual-box log correlation; CUCM Bearer token format fully resolved from product code; offline forge harness validated 6/6 against the product's own validator oracle. |
| 2026-09-27 | False;Relay chain fired live end-to-end from the internet side of the edge, both paths: seeded relay credential (zero MRA accounts) and production-faithful (one legitimate MRA login). Observed: HTTP 200 with live internal UDS XML out of the LAN; CUCM SSO filter issuing JSESSIONIDSSO for a forged `sub=administrator` Bearer. Zero fail2ban ticks, zero bans on the success path. Full teardown verified (planted record deleted — census 0; runtime knobs restored; secrets destroyed). |
| 2026-09-28 | Drop 04 published — False;Relay (SKYLINE-2026-004→009). Components 004–006 to be submitted to Cisco PSIRT; 007–009 document Cisco product exposure to upstream Apache ATS CVE classes with live confirmation. |
| 2026-09-28 | False;Relay extended live: the UDS user-resource 401 from the first fire resolved — a self-only name-equality filter, not authorization, zero role checks behind it. Sub-matched forged Bearer delivered full user-record reads and a credential (PIN) write (204) from internet origin, database-verified. Composed chain integrity raised I:L→I:H; composed CVSS re-rated 9.1→10.0. |

## Note

The researcher attempted to coordinate through every available channel before publishing. Cisco's CNA (Cisco Systems) is responsible for assigning CVE IDs for their products. When the vendor CNA does not engage, researchers may request CVE IDs from MITRE as the CNA of Last Resort.

This timeline will be updated as the situation develops.
