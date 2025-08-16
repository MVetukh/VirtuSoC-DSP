import numpy as np
import matplotlib.pyplot as plt


def fft_filter(signal, fs, cutoff, filter_type="lowpass"):
    """
    Простейшая реализация фильтрации через FFT.

    signal: np.ndarray - входной сигнал
    fs: float - частота дискретизации
    cutoff: float - частота среза (Гц)
    filter_type: "lowpass" | "highpass"
    """
    N = len(signal)
    freqs = np.fft.fftfreq(N, d=1 / fs)
    spectrum = np.fft.fft(signal)

    # Маска для фильтра
    mask = np.ones(N)
    if filter_type == "lowpass":
        mask[np.abs(freqs) > cutoff] = 0
    elif filter_type == "highpass":
        mask[np.abs(freqs) < cutoff] = 0

    filtered_spectrum = spectrum * mask
    filtered_signal = np.fft.ifft(filtered_spectrum).real
    return filtered_signal, freqs, spectrum, filtered_spectrum


if __name__ == "__main__":
    # Параметры
    fs = 500.0  # частота дискретизации
    t = np.arange(0, 1, 1 / fs)
    signal = np.sin(2 * np.pi * 50 * t) + 0.5 * np.sin(2 * np.pi * 120 * t)

    # Фильтрация
    filtered, freqs, spec, spec_f = fft_filter(signal, fs, cutoff=80, filter_type="lowpass")

    # Визуализация
    plt.figure(figsize=(12, 6))
    plt.subplot(2, 1, 1)
    plt.plot(t, signal, label="Original")
    plt.plot(t, filtered, label="Filtered (lowpass)")
    plt.xlabel("Time [s]")
    plt.ylabel("Amplitude")
    plt.legend()

    plt.subplot(2, 1, 2)
    plt.plot(freqs[:len(freqs) // 2], np.abs(spec[:len(freqs) // 2]), label="Original Spectrum")
    plt.plot(freqs[:len(freqs) // 2], np.abs(spec_f[:len(freqs) // 2]), label="Filtered Spectrum")
    plt.xlabel("Frequency [Hz]")
    plt.ylabel("Magnitude")
    plt.legend()
    plt.tight_layout()
    plt.show()
