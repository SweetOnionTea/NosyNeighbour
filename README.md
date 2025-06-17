# NosyNeighbour  
An autonomous, **offline** AI speech-to-text summarisation tool for Windows.

- 🎙️ **Listen** – captures your microphone in real time (20 s WAV chunks)  
- 📝 **Transcribe** – runs **Whisper-S2T** locally on CPU **or** CUDA  
- 📑 **Summarise** – feeds text to **Ollama / Llama 3.2** for bullet-point notes  
- 📊 **Log** – writes each summary to Excel, with a text-file fallback if the workbook is locked  
- 🔄 **Resilient** – queues any failed blocks for retry when Ollama or Excel become available  

Everything happens **on your machine**; no cloud APIs once installed.

---

## 🎥 Video Series

| # | Title                                                              | Description                                                                                                        | Watch                                  |
| - | ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------ | -------------------------------------- |
| 1 | **NosyNeighbour: An Offline AI Speech-to-Text Summarisation Tool** | Overview of the software architecture, main features, and a live demo of it in action.                             | [Watch now](https://youtu.be/WcX4yt-Pvb0) |
| 2 | **NosyNeighbour Installation Tutorial**                            | Full walkthrough of the automated setup process using `setup.ps1`, including optional GPU configuration.           | [Watch now](https://youtu.be/V0FF_qVmCw8) |
| 3 | **NosyNeighbour Configuration & Core Concepts**                    | Covers audio chunk handling, Whisper device settings, Ollama prompts, file structure, and Excel output formatting. | [Watch now](https://youtu.be/RKTGZAiPcbY) |

---

### DIY Setup (manual commands)

*(For advanced users who prefer manual control)*  

📄 [Manual Installation Guide](https://github.com/SweetOnionTea/NosyNeighbour/blob/6e776dd7d971b8df63b6288ed44454088db3c8a9/documentation/manual_installation.md)

---

## Dependencies & Acknowledgments  

| Tool | Licence | Role in NosyNeighbour |
|------|---------|-----------------------|
| **[Ollama](https://github.com/ollama/ollama)** | Apache 2.0 | Runs Llama 3.2 to condense text |
| **[Whisper-S2T](https://github.com/shashikg/WhisperS2T)** | MIT | Low-latency speech-to-text |
| **[FFmpeg-full](https://ffmpeg.org/)** | LGPL/GPL | Captures & resamples audio (soxr) |
| **[CUDA 12.1](https://developer.nvidia.com/cuda-toolkit)** | NVIDIA EULA | Optional GPU acceleration |
| **[sounddevice](https://github.com/spatialaudio/python-sounddevice)** | MIT | Audio input/output |
| **[soundfile](https://github.com/bastibe/python-soundfile)** | BSD | File-based audio processing |
| **[openpyxl](https://foss.heptapod.net/openpyxl/openpyxl)** | MIT | Writes .xlsx summaries |
| **[Chocolatey](https://chocolatey.org)** | Apache 2.0 | Windows package manager used by the script |

_Thanks to every maintainer—NosyNeighbour wouldn’t exist without your work!_ 🎉

---

## Uninstallation

Scripts live in **`uninstall\`**
Navigate to the **`uninstall\`** folder in the project directory run whichever components you want removed (Admin):

| Component | Command |
|-----------|---------|
| Chocolatey | `.\uninstall\uninstall_chocolatey.ps1` |
| CUDA 12.1 | `.\uninstall\uninstall_cuda12.1.ps1` |
| FFmpeg | `.\uninstall\uninstall_ffmpeg.ps1` |
| Ollama | `.\uninstall\uninstall_ollama.ps1` |
| Python 3.10 | `.\uninstall_python.ps1` |

After removal, delete the project folder and `venv` to reclaim space.

---

## License
Project code: **MIT** • Dependencies retain their original licences.
