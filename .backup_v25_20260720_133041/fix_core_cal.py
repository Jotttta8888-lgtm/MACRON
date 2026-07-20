with open('macron_core.py','r') as f: c=f.read()
changes=0
if '_mod_calendar' not in c:
    c=c.replace('_mod_finder = _safe_import("macron_finder")','_mod_finder = _safe_import("macron_finder")\n_mod_calendar = _safe_import("macron_calendar")')
    changes+=1; print('+ Import')
if '"calendar"' not in c:
    c=c.replace('"finder": _mod_finder is not None,\n        }','"finder": _mod_finder is not None,\n            "calendar": _mod_calendar is not None,\n        }')
    changes+=1; print('+ Tracking')
methods='''    # -- CALENDAR
    def calendar_calendars(self):
        if _mod_calendar and hasattr(_mod_calendar, 'get_calendars'):
            try: return _mod_calendar.get_calendars()
            except Exception as e: logger.warning(f"calendar_calendars error: {e}")
        return []
    def calendar_today(self):
        if _mod_calendar and hasattr(_mod_calendar, 'get_today_events'):
            try: return _mod_calendar.get_today_events()
            except Exception as e: logger.warning(f"calendar_today error: {e}")
        return []
    def calendar_upcoming(self, days=7, limit=10):
        if _mod_calendar and hasattr(_mod_calendar, 'get_upcoming_events'):
            try: return _mod_calendar.get_upcoming_events(days, limit)
            except Exception as e: logger.warning(f"calendar_upcoming error: {e}")
        return []
    def calendar_search(self, query, days=30):
        if _mod_calendar and hasattr(_mod_calendar, 'search_events'):
            try: return _mod_calendar.search_events(query, days)
            except Exception as e: logger.warning(f"calendar_search error: {e}")
        return []
    def calendar_create(self, title, start_date, duration=1, calendar=None, location="", notes=""):
        if _mod_calendar and hasattr(_mod_calendar, 'create_event'):
            try: return _mod_calendar.create_event(title, start_date, duration, calendar, location, notes)
            except Exception as e: logger.warning(f"calendar_create error: {e}")
        return {"success": False, "error": "Calendar no disponible"}

'''
if 'def calendar_calendars' not in c:
    c=c.replace('# -- SINGLETON', methods + '# -- SINGLETON')
    changes+=1; print('+ Methods')
with open('macron_core.py','w') as f: f.write(c)
print('Cambios: %d' % changes)