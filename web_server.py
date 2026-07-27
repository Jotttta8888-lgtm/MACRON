from http.server import HTTPServer, BaseHTTPRequestHandler
import json

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({'status':'MACRON API Online','features':74}).encode())
    
    def do_POST(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({'result':'ok'}).encode())
    
    def log_message(self, format, *args):
        pass

server = HTTPServer(('127.0.0.1', 5001), Handler)
server.serve_forever()