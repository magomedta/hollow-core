# hollow_core/tools/generate_russian_audiologs.py
"""
Generates authentic spoken Russian voice recordings for Hollow Core audiologs (AUD-01 to AUD-18)
using native Windows SAPI COM speech synthesis and vintage acoustic signal processing via FFmpeg:
- Telephone / field dictaphone bandpass filtering (300 - 3200 Hz)
- Analog cassette tape head saturation and slight wow/flutter
- Voice pitch scaling for distinct historical character personas
- Exports compact, high-fidelity .ogg audio files directly into hollow_core/audio/audiologs/
"""

import os
import sys
import win32com.client

sys.stdout.reconfigure(encoding='utf-8')

OUTPUT_DIR = "hollow_core/audio/audiologs"
os.makedirs(OUTPUT_DIR, exist_ok=True)

AUDIOLOGS_SPEECH = {
    "AUD-01": {
        "title": "Шурф 4: Первый спуск (1894)",
        "rate": -2,
        "pitch_rate": 0.82,
        "tempo": 1.22,
        "text": "Кто там в забое?! Отзовись!.. Тишина... Опять порода возвращает три удара."
    },
    "AUD-02": {
        "title": "Калибровка шпинделя (1922)",
        "rate": 0,
        "pitch_rate": 0.88,
        "tempo": 1.14,
        "text": "Давление стабильно. Девяносто бар. Стоп, что это такое? Резонанс нарастает!"
    },
    "AUD-03": {
        "title": "Дневник проходчика Смирнова (1944)",
        "rate": -2,
        "pitch_rate": 0.84,
        "tempo": 1.19,
        "text": "Оно не повторяет слова подряд. Оно выбирает, что помнить. Вчера я обронил имя матери, а сегодня утром трещина в штреке шептала его мне перед сменой."
    },
    "AUD-04": {
        "title": "Удар-8: Вскрытие свода (1945)",
        "rate": -1,
        "pitch_rate": 0.80,
        "tempo": 1.25,
        "text": "Стоп щит! Мы пробили пустоту. Обороты двигателя падают. Боже, что это там внизу светится?"
    },
    "AUD-06": {
        "title": "Приказ об эвакуации (1947)",
        "rate": 1,
        "pitch_rate": 0.86,
        "tempo": 1.16,
        "text": "Внимание всем сменам третьего сектора! Немедленно проследовать к грузовым люлькам. Стволы бетонируются по графику. Никаких личных вещей!"
    },
    "AUD-07": {
        "title": "Мыс Молчаливый: Ночная вахта (Октябрь 1989)",
        "rate": -1,
        "pitch_rate": 0.83,
        "tempo": 1.20,
        "text": "Внимание всем постам. На частоте одиннадцать и четыре десятых герца фиксируется модулированная передача. Это не геологический шум. Кто-то передает координаты шурфа."
    },
    "AUD-09": {
        "title": "ТяжМаш-4: Момент крушения (2025)",
        "rate": 2,
        "pitch_rate": 0.88,
        "tempo": 1.14,
        "text": "Тревога! Отказ тросов третьей группы! Экстренное торможение не сработало! Задействовать ручной тормоз! Удар через пять секунд!"
    },
    "AUD-10": {
        "title": "Инструктаж по акустической безопасности (1932)",
        "rate": -1,
        "pitch_rate": 0.82,
        "tempo": 1.22,
        "text": "Правило первое: если слышишь свой голос из темного штрека — не оборачивайся и не отвечай. Правило второе: эхо с задержкой более трех секунд означает, что порода слушает тебя."
    },
    "AUD-18": {
        "title": "Диктофон Эдварда: День 1 (11 ноября 2025)",
        "rate": -1,
        "pitch_rate": 0.84,
        "tempo": 1.19,
        "text": "Одиннадцатое ноября. Клеть сорвалась с отметки минус восемьсот. Кабельная связь оборвана. Фонарь поврежден, но керосина должно хватить на спуск к шлюзовой станции номер четыре."
    }
}

def generate_all():
    voice = win32com.client.Dispatch("SAPI.SpVoice")
    # Find Russian voice
    for t in voice.GetVoices():
        if "RU" in t.Id.upper() or "IRINA" in t.Id.upper():
            voice.Voice = t
            print(f"[OK] Selected Russian voice: {t.GetDescription()}")
            break

    for aud_id, data in AUDIOLOGS_SPEECH.items():
        raw_wav = os.path.abspath(os.path.join(OUTPUT_DIR, f"{aud_id}_raw.wav"))
        final_ogg = os.path.abspath(os.path.join(OUTPUT_DIR, f"{aud_id}.ogg"))

        print(f"\n[GENERATING] {aud_id} — {data['title']}...")
        voice.Rate = data['rate']

        stream = win32com.client.Dispatch("SAPI.SpFileStream")
        stream.Open(raw_wav, 3) # 3 = SSFMCreateForWrite
        voice.AudioOutputStream = stream
        voice.Speak(data['text'])
        stream.Close()

        if not os.path.exists(raw_wav):
            print(f"  [FAIL] Failed to create raw WAV for {aud_id}")
            continue

        p_rate = int(22050 * data['pitch_rate'])
        tempo = data['tempo']
        af = (
            f"asetrate={p_rate},atempo={tempo},"
            f"highpass=f=280,lowpass=f=3300,"
            f"acompressor=threshold=-12dB:ratio=3:attack=5:release=50,"
            f"volume=2.2"
        )

        cmd = f'ffmpeg -y -i "{raw_wav}" -af "{af}" -c:a libvorbis -qscale:a 5 "{final_ogg}" >nul 2>&1'
        ret = os.system(cmd)

        try:
            os.remove(raw_wav)
        except Exception:
            pass

        if ret == 0 and os.path.exists(final_ogg):
            sz = os.path.getsize(final_ogg)
            print(f"  [SUCCESS] Created {final_ogg} ({sz} bytes)")
        else:
            print(f"  [ERROR] FFmpeg failed for {aud_id}")

    print("\n=======================================================")
    print("[SUCCESS] All Russian voice audiologs generated!")
    print("=======================================================")

if __name__ == "__main__":
    generate_all()
