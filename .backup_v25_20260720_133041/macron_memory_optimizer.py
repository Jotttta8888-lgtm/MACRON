"""
MACRON Memory Optimizer v1.0
Reduce uso de RAM mediante carga lazy y garbage collection
"""
import gc
import os
import psutil
import threading
import time

class MacronMemoryOptimizer:
    def __init__(self):
        self.process = psutil.Process(os.getpid())
        self.models_loaded = {}
        self.last_used = {}
        self.unload_timeout = 300
        self.check_interval = 60
        self.running = False
        self.thread = None
    
    def get_memory_usage(self):
        return self.process.memory_info().rss / 1024 / 1024
    
    def register_model(self, name, unload_func):
        self.models_loaded[name] = unload_func
        self.last_used[name] = time.time()
        print(f"[Memory] Modelo registrado: {name}")
    
    def mark_used(self, name):
        if name in self.last_used:
            self.last_used[name] = time.time()
    
    def unload_unused_models(self):
        current_time = time.time()
        for name, last_time in list(self.last_used.items()):
            if current_time - last_time > self.unload_timeout:
                if name in self.models_loaded:
                    try:
                        self.models_loaded[name]()
                        del self.models_loaded[name]
                        del self.last_used[name]
                        gc.collect()
                        print(f"[Memory] Modelo descargado: {name}")
                    except Exception as e:
                        print(f"[Memory] Error descargando {name}: {e}")
    
    def optimize(self):
        gc.collect()
        mem_before = self.get_memory_usage()
        mem_after = self.get_memory_usage()
        freed = mem_before - mem_after
        if freed > 10:
            print(f"[Memory] Liberados {freed:.1f} MB")
    
    def _monitor_loop(self):
        while self.running:
            self.unload_unused_models()
            self.optimize()
            time.sleep(self.check_interval)
    
    def start_monitoring(self):
        self.running = True
        self.thread = threading.Thread(target=self._monitor_loop, daemon=True)
        self.thread.start()
        print("[Memory] Monitoreo iniciado")
    
    def stop_monitoring(self):
        self.running = False
        if self.thread:
            self.thread.join(timeout=5)
        print("[Memory] Monitoreo detenido")

_optimizer = None

def get_optimizer():
    global _optimizer
    if _optimizer is None:
        _optimizer = MacronMemoryOptimizer()
    return _optimizer

if __name__ == "__main__":
    opt = get_optimizer()
    print(f"Memoria actual: {opt.get_memory_usage():.1f} MB")
