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

## Note

The researcher attempted to coordinate through every available channel before publishing. Cisco's CNA (Cisco Systems) is responsible for assigning CVE IDs for their products. When the vendor CNA does not engage, researchers may request CVE IDs from MITRE as the CNA of Last Resort.

This timeline will be updated as the situation develops.
