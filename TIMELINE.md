# Vendor Coordination Timeline

This document records all attempts to coordinate the disclosure of 55 vulnerabilities in Cisco Unified Communications Manager 15.x.

## Summary

| Channel | Status | Detail |
|---------|--------|--------|
| ZDI (Zero Day Initiative) | Pending | 17 submissions awaiting processing |
| SSD (Security Solutions & Development) | Paused | "Not accepting any more CUCM vulnerabilities until Cisco has addressed other submissions" |
| Cisco PSIRT (direct) | No response | Contacted 2026-08-04 |
| MITRE (CNA of Last Resort) | Pending | CVE ID request submitted 2026-08-04 |

## Detailed Timeline

| Date | Action |
|------|--------|
| 2026 (multiple dates) | 17 CUCM vulnerability submissions sent to ZDI. ZDI coordinates with Cisco on the researcher's behalf. Submissions remain unprocessed as of publication. |
| 2026 | SSD contacted regarding CUCM vulnerability acquisition. SSD responded that they have paused CUCM acquisitions because Cisco has not addressed existing reports in their queue. |
| 2026-08-04 | Cisco PSIRT contacted directly via psirt@cisco.com. Email described the pre-authentication remote root chain (3 vulnerabilities) and referenced the 17 pending ZDI submissions. Full technical details offered upon request. |
| 2026-08-04 | MITRE contacted via cve@mitre.org requesting CVE ID assignment under the CNA of Last Resort process for 3 vulnerabilities forming the pre-authentication root chain. |
| 2026-08-04 | Drop 01 published — pre-authentication remote root chain. |

## Note

The researcher attempted to coordinate through every available channel before publishing. Cisco's CNA (Cisco Systems) is responsible for assigning CVE IDs for their products. When the vendor CNA does not engage, researchers may request CVE IDs from MITRE as the CNA of Last Resort.

This timeline will be updated as the situation develops.
