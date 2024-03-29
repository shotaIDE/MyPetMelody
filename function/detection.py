# coding: utf-8

import time
from typing import Callable

from pydub import AudioSegment, effects
from pydub.silence import detect_nonsilent


def detect_non_silence(sound_path: str) -> dict:
    detector = detect_non_silence_by_threshould(silence_threshould=-30)

    return detector(sound_path)


def detect_non_silence_without_normalize_by_threshould(
    silence_threshould: int,
) -> dict:
    def _detect_non_silence_without_normalize(sound_path: str) -> dict:
        sound = AudioSegment.from_file(sound_path)

        return _detect_non_silence(
            sound=sound,
            min_silence_len=300,
            silence_thresh=silence_threshould,
        )

    return _detect_non_silence_without_normalize


def detect_non_silence_by_threshould(
    silence_threshould: int,
) -> Callable[[str], dict]:
    def _detect_non_silence_with_normalize(sound_path: str) -> dict:
        sound = AudioSegment.from_file(sound_path)

        normalized_sound = effects.normalize(sound)

        return _detect_non_silence(
            sound=normalized_sound,
            min_silence_len=300,
            silence_thresh=silence_threshould,
        )

    return _detect_non_silence_with_normalize


def _detect_non_silence(
    sound: AudioSegment,
    min_silence_len: int,
    silence_thresh: int,
) -> dict:
    start_time = time.perf_counter()

    duration_seconds: int = sound.duration_seconds
    duration_milliseconds = int(round(duration_seconds, 3) * 1000)

    non_silences_list = detect_nonsilent(
        sound, min_silence_len=min_silence_len, silence_thresh=silence_thresh)

    print(f'Detected result(ms): {non_silences_list}')

    result = {
        'segments': non_silences_list,
        'durationMilliseconds': duration_milliseconds,
    }

    end_time = time.perf_counter()
    elapsed_time = end_time - start_time
    print(f'Running time to detect non silence: {elapsed_time:.3f}s')

    return result
