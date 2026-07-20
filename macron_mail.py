"""
macron_mail.py
Integracion con Mail.app para MACRON v7.2
"""
import subprocess

def _run_applescript(script):
    try:
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True, text=True, timeout=15
        )
        if result.returncode != 0:
            return {"error": result.stderr.strip()}
        return {"success": True, "output": result.stdout.strip()}
    except Exception as e:
        return {"error": str(e)}

def get_inbox(limit=20):
    script = f"""tell application "Mail"
        set inboxMsgs to messages of inbox
        set output to ""
        set totalMsgs to count of inboxMsgs
        set maxItems to {limit}
        if totalMsgs < maxItems then set maxItems to totalMsgs
        repeat with i from 1 to maxItems
            set msg to item i of inboxMsgs
            set isRead to read status of msg
            if isRead then
                set readFlag to "1"
            else
                set readFlag to "0"
            end if
            set output to output & readFlag & "|" & (subject of msg) & "|" & (sender of msg) & "|" & (date received of msg) & "|" & (id of msg as string) & "\n"
        end repeat
        return output
    end tell"""
    result = _run_applescript(script)
    if "error" in result:
        return []
    emails = []
    for line in result.get("output", "").strip().split("\n"):
        if "|" in line:
            parts = line.split("|")
            if len(parts) >= 5:
                emails.append({
                    "read": parts[0] == "1",
                    "subject": parts[1],
                    "sender": parts[2],
                    "date": parts[3],
                    "id": parts[4]
                })
    return emails

def get_unread_count():
    script = """tell application "Mail"
        set unreadCount to 0
        repeat with acc in accounts
            repeat with mbox in mailboxes of acc
                set unreadCount to unreadCount + (count of (messages of mbox whose read status is false))
            end repeat
        end repeat
        return unreadCount
    end tell"""
    result = _run_applescript(script)
    if "error" in result:
        return 0
    try:
        return int(result.get("output", "0"))
    except:
        return 0

def search_mail(query, limit=10):
    script = f"""tell application "Mail"
        set inboxMsgs to messages of inbox
        set output to ""
        set foundCount to 0
        repeat with msg in inboxMsgs
            set subj to subject of msg as string
            set sndr to sender of msg as string
            if subj contains "{query}" or sndr contains "{query}" then
                set foundCount to foundCount + 1
                if foundCount <= {limit} then
                    set output to output & (subject of msg) & "|" & (sender of msg) & "|" & (date received of msg) & "\n"
                end if
            end if
        end repeat
        return output
    end tell"""
    result = _run_applescript(script)
    if "error" in result:
        return []
    emails = []
    for line in result.get("output", "").strip().split("\n"):
        if "|" in line:
            parts = line.split("|")
            if len(parts) >= 3:
                emails.append({"subject": parts[0], "sender": parts[1], "date": parts[2]})
    return emails

def send_email(to_address, subject, body):
    script = f"""tell application "Mail"
        set newMessage to make new outgoing message with properties {{subject:"{subject}", content:"{body}"}}
        tell newMessage
            make new to recipient at end of to recipients with properties {{address:"{to_address}"}}
            send
        end tell
        return "Enviado"
    end tell"""
    return _run_applescript(script)

def summarize_inbox(core=None, limit=5):
    unread = [e for e in get_inbox(limit=20) if not e.get("read", True)]
    if not unread:
        return {"summary": "No hay emails no leidos.", "count": 0}
    email_text = "\n".join([
        "- De: " + e["sender"] + "\n  Asunto: " + e["subject"] + "\n  Fecha: " + e["date"]
        for e in unread[:limit]
    ])
    prompt = f"""Resume los siguientes emails no leidos en 3-5 puntos clave:

{{email_text}}

Resumen:"""
    if core and hasattr(core, 'chat'):
        try:
            result = core.chat(prompt)
            if isinstance(result, dict):
                summary = result.get('text', '') or result.get('response', '') or str(result)
            else:
                summary = str(result)
            return {"summary": summary, "count": len(unread), "emails": unread[:limit]}
        except Exception as e:
            return {"error": str(e), "summary": "", "count": len(unread)}
    return {
        "summary": "Tienes " + str(len(unread)) + " emails no leidos.\n\n" + email_text,
        "count": len(unread),
        "emails": unread[:limit]
    }


if __name__ == "__main__":
    print("=" * 50)
    print("MACRON Mail Integration v7.2")
    print("=" * 50)
    print("\n📧 EMAILS NO LEIDOS:")
    print("   Total: " + str(get_unread_count()))
    print("\n📨 ULTIMOS 5 EMAILS:")
    for i, e in enumerate(get_inbox(limit=5), 1):
        status = "✅" if e["read"] else "🔴"
        print("   " + status + " " + e["subject"][:50])
        print("      De: " + e["sender"][:40])
    print("\n🔍 BUSCAR 'Google':")
    results = search_mail("Google", limit=3)
    print("   Encontrados: " + str(len(results)))
    for r in results:
        print("   - " + r["subject"][:50])
    print("\n📊 RESUMEN INBOX:")
    summary = summarize_inbox()
    print("   " + str(summary["count"]) + " no leidos")
    print("   " + summary["summary"][:150] + "...")
    print("\n" + "=" * 50)
    print("Mail Integration listo")
    print("=" * 50)
