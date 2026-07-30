#!/usr/bin/env python3
import sys
import os
import wave

def transcribe_with_whisper(audio_path):
    try:
        import whisper
        print("Cargando modelo Whisper (base)...", file=sys.stderr)
        model = whisper.load_model("base")
        print("Transcribiendo...", file=sys.stderr)
        result = model.transcribe(audio_path, language="es")
        return result["text"]
    except Exception as e:
        return f"WHISPER_NO_INSTALADO\nError: {str(e)}\n\nInstala Whisper con:\npip3 install openai-whisper\n\nO usa el audio manualmente desde:\n{audio_path}"

def transcribe_basic(audio_path):
    try:
        with wave.open(audio_path, 'rb') as wf:
            frames = wf.getnframes()
            rate = wf.getframerate()
            duration = frames / float(rate)
            return f"[Transcripcion no disponible sin Whisper]\n\nAudio: {os.path.basename(audio_path)}\nDuracion: {duration:.1f} segundos\nMuestras: {frames}\nRate: {rate} Hz\n\nPara transcribir automaticamente, instala Whisper:\npip3 install openai-whisper"
    except Exception as e:
        return f"Error leyendo audio: {str(e)}"

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python3 meeting_transcriber.py <archivo.wav>", file=sys.stderr)
        sys.exit(1)
    
    audio_path = sys.argv[1]
    
    if not os.path.exists(audio_path):
        print(f"Error: Archivo no encontrado: {audio_path}")
        sys.exit(1)
    
    result = transcribe_with_whisper(audio_path)
    
    if result.startswith("WHISPER_NO_INSTALADO"):
        fallback = transcribe_basic(audio_path)
        print("WHISPER_NO_INSTALADO")
        print(fallback)
    else:
        print(result)
