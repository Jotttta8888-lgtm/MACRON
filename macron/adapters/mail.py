"""
macron/adapters/mail.py
MailAdapter para MACRON v3.0 - Hereda de BaseAdapter
"""
from .base import BaseAdapter

class MailAdapter(BaseAdapter):
    __macron_module__ = True
    __macron_name__ = "mail"
    __version__ = "3.0"
    __dependencies__ = []
    __app_name__ = "Mail"
    
    def __init__(self, core=None):
        super().__init__(core)
    
    def _action_to_applescript(self, action, **kwargs):
        """Mapea acciones a scripts AppleScript."""
        if action == "get_inbox":
            limit = kwargs.get("limit", 20)
            return f'''tell application "Mail"
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
        set output to output & readFlag & "|" & (subject of msg) & "|" & (sender of msg) & "|" & (date received of msg) & "|" & (id of msg as string) & "\\n"
    end repeat
    return output
end tell'''
        
        elif action == "get_unread_count":
            return '''tell application "Mail"
    set unreadCount to 0
    repeat with acc in accounts
        repeat with mbox in mailboxes of acc
            set unreadCount to unreadCount + (count of (messages of mbox whose read status is false))
        end repeat
    end repeat
    return unreadCount
end tell'''
        
        elif action == "search_mail":
            query = kwargs.get("query", "")
            limit = kwargs.get("limit", 10)
            return f'''tell application "Mail"
    set inboxMsgs to messages of inbox
    set output to ""
    set foundCount to 0
    repeat with msg in inboxMsgs
        set subj to subject of msg as string
        set sndr to sender of msg as string
        if subj contains "{query}" or sndr contains "{query}" then
            set foundCount to foundCount + 1
            if foundCount <= {limit} then
                set output to output & (subject of msg) & "|" & (sender of msg) & "|" & (date received of msg) & "\\n"
            end if
        end if
    end repeat
    return output
end tell'''
        
        elif action == "send_email":
            to_address = kwargs.get("to_address", "")
            subject = kwargs.get("subject", "")
            body = kwargs.get("body", "")
            return f'''tell application "Mail"
    set newMessage to make new outgoing message with properties {{subject:"{subject}", content:"{body}"}}
    tell newMessage
        make new to recipient at end of to recipients with properties {{address:"{to_address}"}}
        send
    end tell
    return "Enviado"
end tell'''
        else:
            raise NotImplementedError(f"Accion '{action}' no implementada en MailAdapter")
    
    def get_inbox(self, limit=20):
        """Lista emails del inbox."""
        result = self._run(self._script("get_inbox", limit=limit), timeout=15)
        if not result.success:
            return []
        emails = []
        for line in result.stdout.strip().split("\n"):
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
    
    def get_unread_count(self):
        """Cuenta emails no leidos."""
        result = self._run(self._script("get_unread_count"), timeout=15)
        if not result.success:
            return 0
        try:
            return int(result.stdout)
        except:
            return 0
    
    def search_mail(self, query, limit=10):
        """Busca emails por query."""
        result = self._run(self._script("search_mail", query=query, limit=limit), timeout=15)
        if not result.success:
            return []
        emails = []
        for line in result.stdout.strip().split("\n"):
            if "|" in line:
                parts = line.split("|")
                if len(parts) >= 3:
                    emails.append({"subject": parts[0], "sender": parts[1], "date": parts[2]})
        return emails
    
    def send_email(self, to_address, subject, body):
        """Envia email."""
        result = self._run(self._script("send_email", to_address=to_address, subject=subject, body=body), timeout=15)
        return {"success": result.success, "output": result.stdout, "error": result.stderr}
    
    def summarize_inbox(self, limit=5):
        """Resume inbox no leido."""
        unread = [e for e in self.get_inbox(limit=20) if not e.get("read", True)]
        if not unread:
            return {"summary": "No hay emails no leidos.", "count": 0}
        email_text = "\n".join([
            "- De: " + e["sender"] + "\n  Asunto: " + e["subject"] + "\n  Fecha: " + e["date"]
            for e in unread[:limit]
        ])
        prompt = f"""Resume los siguientes emails no leidos en 3-5 puntos clave:

{email_text}

Resumen:"""
        if self.core and hasattr(self.core, 'chat'):
            try:
                result = self.core.chat(prompt)
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
    
    def info(self):
        return {"name": self.name, "version": self.version, "app": "Mail", "methods": [
            "get_inbox", "get_unread_count", "search_mail", "send_email", "summarize_inbox"
        ]}
