"""
macron_agent_research.py
Modulo de investigacion web para MACRON
"""
import urllib.request
import urllib.parse
import re

def search_web(query, max_results=5):
    """Busca en la web usando DuckDuckGo."""
    try:
        url = f"https://duckduckgo.com/html/?q={urllib.parse.quote(query)}"
        headers = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'}
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=10) as response:
            html = response.read().decode('utf-8', errors='ignore')
        
        results = []
        pattern = r'<a rel="nofollow" class="result__a" href="([^"]+)">([^<]+)</a>'
        matches = re.findall(pattern, html)
        
        for url, title in matches[:max_results]:
            results.append({
                'title': re.sub(r'<[^>]+>', '', title).strip(),
                'url': url
            })
        
        return {'success': True, 'query': query, 'results': results, 'count': len(results)}
    except Exception as e:
        return {'success': False, 'error': str(e), 'results': []}

def summarize_url(url):
    """Obtiene resumen basico de una URL."""
    try:
        headers = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'}
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=15) as response:
            html = response.read().decode('utf-8', errors='ignore')
        
        title_match = re.search(r'<title>([^<]+)</title>', html, re.IGNORECASE)
        title = title_match.group(1).strip() if title_match else 'Sin titulo'
        
        desc_match = re.search(r'<meta[^>]*name=["\']description["\'][^>]*content=["\']([^"\']+)["\']', html, re.IGNORECASE)
        if not desc_match:
            desc_match = re.search(r'<meta[^>]*content=["\']([^"\']+)["\'][^>]*name=["\']description["\']', html, re.IGNORECASE)
        description = desc_match.group(1).strip() if desc_match else 'Sin descripcion'
        
        return {'success': True, 'title': title, 'description': description, 'url': url}
    except Exception as e:
        return {'success': False, 'error': str(e)}
