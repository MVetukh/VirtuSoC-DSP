import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import firwin, lfilter, freqz


def fir_lowpass(signal, fs, cutoff, numtaps=101):
    """
    FIR фильтр низких частот.

    signal: np.ndarray - входной сигнал
    fs: float - частота дискретизации
    cutoff: float - частота среза (Гц)
    numtaps: int - число коэффициентов фильтра
    """
    # Нормализация частоты
    nyq = fs / 2.0
    taps = firwin(numtaps, cutoff / nyq)
    filtered = lfilter(taps, 1.0, signal)
    return filtered, taps


if __name__ == "__main__":
    # Параметры
    fs = 500.0
    t = np.arange(0, 1, 1 / fs)
    signal = np.sin(2 * np.pi * 50 * t) + 0.5 * np.sin(2 * np.pi * 120 * t)

    # Фильтрация
    filtered, taps = fir_lowpass(signal, fs, cutoff=80, numtaps=101)

    # Частотная характеристика фильтра
    w, h = freqz(taps, worN=8000)

    # Визуализация
    plt.figure(figsize=(12, 8))

    plt.subplot(3, 1, 1)
    plt.plot(t, signal, label="Original")
    plt.plot(t, filtered, label="Filtered (FIR LPF)")
    plt.xlabel("Time [s]")
    plt.ylabel("Amplitude")
    plt.legend()

    plt.subplot(3, 1, 2)
    plt.plot(0.5 * fs * w / np.pi, np.abs(h), 'b')
    plt.title("Frequency Response")
    plt.xlabel("Frequency [Hz]")
    plt.ylabel("Gain")

    plt.subplot(3, 1, 3)
    plt.magnitude_spectrum(signal, Fs=fs, scale='dB', label="Original")
    plt.magnitude_spectrum(filtered, Fs=fs, scale='dB', label="Filtered")
    plt.legend()

    plt.tight_layout()
    plt.show()
