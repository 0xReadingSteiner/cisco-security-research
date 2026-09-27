# SKYLINE-2026-057a — Deployhack: Apache Axis AdminService Arbitrary Class Deployment

| Field | Value |
|-------|-------|
| **ID** | SKYLINE-2026-057a |
| **CVE** | Pending (MITRE CNA of Last Resort) |
| **CWE** | CWE-306 — Missing Authentication for Critical Function |
| **CVSSv3.1** | 8.6 (High) — component rating; chain rating 10.0 in the Dead;Dial advisory |
| **Vector** | AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:H/A:L |
| **Product** | Cisco Unified Communications Manager 15.0.1.12900-234 |
| **Component** | WebDialer webapp — Apache Axis 1.4 `AdminService` (`/webdialer/services/AdminService`) |
| **Attack Type** | Remote, pre-authentication (via SKYLINE-2026-001) |
| **Used In** | [Dead;Dial](https://github.com/0xReadingSteiner/Dead-Dial) |

## Description

CUCM 15.x ships the WebDialer webapp bundling Apache Axis 1.4 (built 2006-04-22). Axis's `AdminService` endpoint accepts WSDD deployment descriptors and can expose **any Java class with a public constructor as a SOAP-callable service**. Its only protection is a `request.getRemoteAddr().equals("127.0.0.1")` check — defeated by SKYLINE-2026-001 (X-Forwarded-For spoofing through the unconfigured `RemoteIpValve`).

An unauthenticated attacker deploys, for example, `javax.naming.InitialContext` as a service named `JNDI` with `allowedMethods=*`, turning every public method (`lookup`, `bind`, `rename`, …) into a remotely invocable SOAP operation. Deployed services persist until explicit undeploy or Tomcat restart, giving the attacker a durable re-entry point independent of any credential.

This path is fully independent of the Tomcat Manager: rotating the hardcoded Manager credentials (the Silent;Call fix) does not affect it.

Confirmed live on CUCM 15.0.1.12900-234, 2026-08-01: AdminService rejected the request without XFF (`Remote administrator access is not allowed!`) and returned `<Admin>Done processing</Admin>` with `X-Forwarded-For: 127.0.0.1`; the deployed service appeared in the `/webdialer/services` listing.

## Affected Configuration

- Axis 1.4 `AdminService` deployed in production (`webdialer/WEB-INF/server-config.wsdd`).
- No class whitelist on deployable services.
- Localhost-only guard relying on `getRemoteAddr()`, which `RemoteIpValve` overwrites with attacker-supplied XFF.

## Fix

1. Remove or disable the Axis `AdminService` endpoint from WebDialer (dead-code elimination), or remove WebDialer entirely where unused.
2. Configure `internalProxies` on `RemoteIpValve` so only the real proxy's address can set forwarded headers (root-cause fix shared with SKYLINE-2026-001).
3. If AdminService must remain, require authentication and an explicit deployable-class whitelist.

## Researcher

0xReadingSteiner — 0xReadingSteiner@proton.me
