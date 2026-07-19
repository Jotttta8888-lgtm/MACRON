"""
MACRON Voice VAD Module v3.0
Fix para transcripciones basura (alucinaciones de Whisper en silencio/ruido)
"""
import numpy as np
import sounddevice as sd
import tempfile
import wave
import time
from collections import deque

class MacronVoiceVAD:
    def __init__(self, sample_rate=16000, chunk_duration=0.03, 
                 vad_threshold=0.015, silence_timeout=1.5,
                 min_speech_duration=0.5, max_recording_duration=10):
        self.sample_rate = sample_rate
        self.chunk_samples = int(sample_rate * chunk_duration)
        self.vad_threshold = vad_threshold
        self.silence_timeout = silence_timeout
        self.min_speech_duration = min_speech_duration
        self.max_recording_duration = max_recording_duration
        self.audio_buffer = []
        self.is_recording = False
        self.silence_start = None
        self.speech_start = None
        self.energy_history = deque(maxlen=50)

    def _compute_energy(self, chunk):
        return np.sqrt(np.mean(chunk**2))

    def _is_speech(self, energy):
        if len(self.energy_history) < 10:
            return energy > self.vad_threshold
        noise_mean = np.mean(list(self.energy_history))
        noise_std = np.std(list(self.energy_history)) if len(self.energy_history) > 1 else 0
        adaptive_threshold = max(self.vad_threshold, noise_mean + 2 * noise_std)
        return energy > adaptive_threshold

    def _filter_noise(self, audio):
        window = 5
        if len(audio) < window:
            return audio
        filtered = np.convolve(audio, np.ones(window)/window, mode='same')
        return filtered

    def record_with_vad(self):
        print("[VAD] Esperando voz... (umbral: {:.4f})".format(self.vad_threshold))
        self.audio_buffer = []
        self.is_recording = False
        self.silence_start = None
        self.speech_start = None
        self.energy_history.clear()
        start_time = time.time()

        def callback(indata, frames, time_info, status):
            if status:
                print(f"[VAD] Status: {status}")
            chunk = indata[:, 0].copy()
            energy = self._compute_energy(chunk)
            self.energy_history.append(energy)

            if not self.is_recording:
                if self._is_speech(energy):
                    self.is_recording = True
                    self.speech_start = time.time()
                    self.audio_buffer.extend(chunk.tolist())
                    print("[VAD] Voz detectada, grabando...")
            else:
                self.audio_buffer.extend(chunk.tolist())
                if self._is_speech(energy):
                    self.silence_start = None
                else:
                    if self.silence_start is None:
                        self.silence_start = time.time()
                    elif time.time() - self.silence_start > self.silence_timeout:
                        print("[VAD] Silencio detectado, deteniendo...")
                        raise sd.CallbackStop()
                if time.time() - start_time > self.max_recording_duration:
                    print("[VAD] Timeout maximo alcanzado")
                    raise sd.CallbackStop()

        try:
            with sd.InputStream(
                samplerate=self.sample_rate,
                channels=1,
                dtype=np.float32,
                blocksize=self.chunk_samples,
                callback=callback
            ):
                while True:
                    time.sleep(0.1)
        except sd.CallbackStop:
            pass

        if not self.audio_buffer:
            return None

        audio = np.array(self.audio_buffer, dtype=np.float32)
        speech_duration = len(audio) / self.sample_rate

        if speech_duration < self.min_speech_duration:
            print(f"[VAD] Audio muy corto ({speech_duration:.2f}s), descartando")
            return None

        audio = self._filter_noise(audio)
        max_val = np.max(np.abs(audio))
        if max_val > 0:
            audio = audio / max_val * 0.9

        print(f"[VAD] Audio valido: {speech_duration:.2f}s")
        return audio

    def transcribe(self, audio, model="mlx-community/whisper-large-v3-turbo"):
        if audio is None or len(audio) < self.sample_rate * 0.3:
            return ""

        try:
            import mlx_whisper
        except ImportError:
            print("[VAD] mlx_whisper no disponible, usando whisper estandar")
            try:
                import whisper
                mlx_whisper = whisper
            except ImportError:
                print("[VAD] Whisper no disponible")
                return ""

        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
            temp_path = f.name
            with wave.open(temp_path, 'wb') as wf:
                wf.setnchannels(1)
                wf.setsampwidth(2)
                wf.setframerate(self.sample_rate)
                wf.writeframes((audio * 32767).astype(np.int16).tobytes())

        try:
            result = mlx_whisper.transcribe(temp_path, path_or_hf_repo=model, 
                                           language="es", task="transcribe")
            text = result.get("text", "").strip()
            text = self._validate_transcription(text)
            return text
        except Exception as e:
            print(f"[VAD] Error en transcripcion: {e}")
            return ""
        finally:
            import os
            try:
                os.remove(temp_path)
            except:
                pass

    def _validate_transcription(self, text):
        if not text:
            return ""

        words = text.split()
        if len(words) > 5:
            from collections import Counter
            most_common = Counter(words).most_common(1)[0]
            if most_common[1] / len(words) > 0.7:
                print(f"[VAD] Repeticion detectada: '{most_common[0]}' x{most_common[1]}")
                return ""

        import re
        suspicious = len(re.findall(r'[\u3040-\u9fff\uac00-\ud7af\u0600-\u06ff]', text))
        if suspicious > 3 and suspicious / len(text) > 0.3:
            print(f"[VAD] Caracteres no-esperados detectados ({suspicious}), descartando")
            return ""

        noise_patterns = ['\u266a', '\u266b', '\u3010', '\u3011', '\u203b', '\u25c6', '\u25a0', '\u25cf', '\u25cb']
        if any(p in text for p in noise_patterns):
            print("[VAD] Patrones de ruido/placeholder detectados")
            return ""

        if len(text) < 2:
            return ""

        hallucination_words = ['um', 'uh', 'ah', 'eh', 'mm', 'hmm', 'mmm']
        clean_words = [w for w in words if w.lower() not in hallucination_words]
        if len(clean_words) == 0:
            return ""

        return text

    def listen_and_transcribe(self):
        print("[Voice] Iniciando grabacion con VAD...")
        audio = self.record_with_vad()
        if audio is None:
            print("[Voice] No se detecto voz valida")
            return ""
        print("[Voice] Transcribiendo...")
        text = self.transcribe(audio)
        if text:
            print(f"[Voice] Usuario: {text}")
        else:
            print("[Voice] Transcripcion vacia o invalida")
        return text


class MacronVoiceInterface:
    def __init__(self):
        self.vad = MacronVoiceVAD(
            vad_threshold=0.015,
            silence_timeout=1.2,
            min_speech_duration=0.6,
            max_recording_duration=8
        )

    def listen(self):
        return self.vad.listen_and_transcribe()

    def listen_continuous(self, callback):
        print("[Voice] Modo continuo activado. Di 'MACRON' para activar...")
        while True:
            text = self.listen()
            if text:
                callback(text)
            time.sleep(0.5)


if __name__ == "__main__":
    voice = MacronVoiceInterface()
    result = voice.listen()
    print(f"Resultado final: '{result}'")
