"""
MACRON Search v1.0
Busqueda en historial de conversaciones
"""
from macron_history import search_history

def search_chat(query, session_id="default"):
    """Busca en el historial de chat"""
    results = search_history(query, session_id)
    return results

def format_results(results):
    """Formatea resultados para mostrar"""
    if not results:
        return "No se encontraron resultados."
    
    lines = []
    for row in results:
        lines.append(f"[{row[0]}] {row[1]}: {row[2][:100]}...")
    return "\n".join(lines)

if __name__ == "__main__":
    print("Modulo de busqueda cargado")
