import threading
import time
import numpy as np
import sounddevice as sd

class MacronWakeWordWhisper:
    def __init__(self, voice_interface, macron_orchestrator, callback=None):
        self.voice = voice_interface
        self.macron = macron_orchestrator
        self.callback = callback
        self.is_listening = False
        self._thread = None
        self.wake_phrases = ['macron', 'hey macron', 'okey macron', 'ok macron']

    def start_listening(self):
        self.is_listening = True
        self._thread = threading.Thread(target=self._listen_loop, daemon=True)
        self._thread.start()
        print('[WakeWord] Escuchando... Di MACRON para activar')

    def stop_listening(self):
        self.is_listening = False
        if self._thread:
            self._thread.join(timeout=2)
        print('[WakeWord] Detenido')

    def _listen_loop(self):
        while self.is_listening:
            try:
                print('[WakeWord] Grabando chunk de 3 segundos...')
                audio = self._record_chunk(3)
                if audio is None:
                    continue
                print('[WakeWord] Transcribiendo...')
                text = self.voice.vad.transcribe(audio)
                print(f'[WakeWord] Escuchado: {repr(text)}')
                if self._is_wake_word(text):
                    print('[WakeWord] ACTIVADO!')
                    self._handle_wake_command()
            except Exception as e:
                print(f'[WakeWord] Error: {e}')
                time.sleep(1)

    def _record_chunk(self, duration):
        try:
            sample_rate = 16000
            samples = int(duration * sample_rate)
            audio = sd.rec(samples, samplerate=sample_rate, channels=1, dtype=np.float32)
            sd.wait()
            return audio.flatten()
        except Exception as e:
            print(f'[WakeWord] Error grabando: {e}')
            return None

    def _is_wake_word(self, text):
        if not text:
            return False
        text_lower = text.lower().strip()
        for phrase in self.wake_phrases:
            if phrase in text_lower:
                return True
        return False

    def _handle_wake_command(self):
        try:
            print('[WakeWord] Esperando comando...')
            audio = self._record_chunk(5)
            if audio is None:
                return
            print('[WakeWord] Transcribiendo comando...')
            command = self.voice.vad.transcribe(audio)
            print(f'[WakeWord] Comando: {repr(command)}')
            if command and self.callback:
                self.callback(command)
            elif command and self.macron:
                response = self.macron.llm.chat(command)
                print(f'[WakeWord] Respuesta: {repr(response)}')
        except Exception as e:
            print(f'[WakeWord] Error en comando: {e}')

if __name__ == '__main__':
    from macron_voice_vad import MacronVoiceInterface
    voice = MacronVoiceInterface()
    wake = MacronWakeWordWhisper(voice, None)
    wake.start_listening()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        wake.stop_listening()
