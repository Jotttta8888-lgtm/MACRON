import Foundation

class LocalWebServer: ObservableObject {
    static let shared = LocalWebServer()
    @Published var isRunning = false
    @Published var serverURL = ""
    
    private var serverTask: Process?
    
    func start(port: Int = 5001) {
        let scriptPath = NSHomeDirectory() + "/Documents/MACRON/web_server.py"
        let script = """
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

server = HTTPServer(('127.0.0.1', \(port)), Handler)
server.serve_forever()
"""
        try? script.write(toFile: scriptPath, atomically: true, encoding: .utf8)
        
        serverTask = Process()
        serverTask?.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        serverTask?.arguments = [scriptPath]
        try? serverTask?.run()
        isRunning = true
        serverURL = "http://127.0.0.1:" + String(port)
        NotificationService.shared.send(title: "MACRON", body: "Web server en " + serverURL)
    }
    
    func stop() {
        serverTask?.terminate()
        isRunning = false
        serverURL = ""
    }
}
