with open('macron_core.py','r') as f: c=f.read()
changes=0

# El marcador real usa caracteres unicode '──' no '--'
marker = '# ── SINGLETON'

methods = '''    # ── NOTES
    def notes_accounts(self):
        if _mod_notes and hasattr(_mod_notes, 'get_accounts'):
            try: return _mod_notes.get_accounts()
            except Exception as e: logger.warning(f"notes_accounts error: {e}")
        return []

    def notes_folders(self):
        if _mod_notes and hasattr(_mod_notes, 'get_folders'):
            try: return _mod_notes.get_folders()
            except Exception as e: logger.warning(f"notes_folders error: {e}")
        return []

    def notes_list(self, limit=20):
        if _mod_notes and hasattr(_mod_notes, 'get_notes'):
            try: return _mod_notes.get_notes(limit)
            except Exception as e: logger.warning(f"notes_list error: {e}")
        return []

    def notes_search(self, query, limit=10):
        if _mod_notes and hasattr(_mod_notes, 'search_notes'):
            try: return _mod_notes.search_notes(query, limit)
            except Exception as e: logger.warning(f"notes_search error: {e}")
        return []

    def notes_content(self, title):
        if _mod_notes and hasattr(_mod_notes, 'get_note_content'):
            try: return _mod_notes.get_note_content(title)
            except Exception as e: logger.warning(f"notes_content error: {e}")
        return {"error": "Notes no disponible"}

    def notes_create(self, title, body, folder="Notes"):
        if _mod_notes and hasattr(_mod_notes, 'create_note'):
            try: return _mod_notes.create_note(title, body, folder)
            except Exception as e: logger.warning(f"notes_create error: {e}")
        return {"success": False, "error": "Notes no disponible"}

'''

if 'def notes_accounts' not in c:
    if marker in c:
        c = c.replace(marker, methods + marker)
        changes += 1
        print('+ Methods insertados')
    else:
        print('! Marcador no encontrado')
        # Buscar alternativas
        for i, line in enumerate(c.split('\n')):
            if 'SINGLETON' in line:
                print(f'  Linea {i}: {repr(line)}')
else:
    print('= Methods ya existen')

with open('macron_core.py','w') as f: f.write(c)
print('Cambios: %d' % changes)
