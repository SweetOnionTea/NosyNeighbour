### DIY Setup

This walk-through assumes you’re comfortable downloading installers in a browser and tweaking the **PATH** yourself.
PowerShell / CMD is only needed once you reach the Python–virtual-env step.

---

## 1  System-level prerequisites

| Component                          | How to install                                                                                                                                                                                                                              | Extra step                                                         |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| **FFmpeg-full**                    | 1. Download the latest ffmpeg-git-full.7z git master build from [https://www.gyan.dev/ffmpeg/builds/](https://www.gyan.dev/ffmpeg/builds/) (ZIP).<br>2. Unzip to **`C:\ffmpeg`** (you should have *ffmpeg.exe*, *ffprobe.exe* in **`C:\ffmpeg\bin`**).   | Add **`C:\ffmpeg\bin`** to **System PATH** → reboot or log out/in. |
| **Python 3.10 (x64)**              | Download and install Python 3.10 Windows installer (64-bit) from [https://www.python.org/downloads/release/python-31010/](https://www.python.org/downloads/release/python-31010/).<br>Run the GUI installer → check **“Add Python to PATH”** → *Install for all users*. | Open a new terminal → `python --version` should print **3.10.10**. |
| **Ollama**                         | Download *OllamaSetup.exe* from [https://ollama.com/download](https://ollama.com/download) and run it (GUI).                                                                                                                                | After install open PowerShell → `ollama --version` should respond. |
| **CUDA 12.1 (if you have a compatible GPU)** | Download the *network installer* from [https://developer.nvidia.com/cuda-12-1-0-download-archive](https://developer.nvidia.com/cuda-12-1-0-download-archive) and pick the **“compiler only”** option.                                                                                                        | Reboot when asked. Skip this whole row if you’re going CPU-only.   |

> **Tip:** After each installer, open a *fresh* terminal to pick up new PATH changes.

---

## 2  Pull the model weights (still GUI-installed Ollama, but CLI command)

```powershell
# in PowerShell or CMD
ollama pull llama3.2
```

This is \~4 GB; just let it download once.

---

## 3  Create and populate the Python virtual environment

```powershell
# From the project root
py -3.10 -m venv venv
.\venv\Scripts\Activate
python -m pip install --upgrade pip
```

### 3.1 Install PyTorch first

```powershell
# GPU build (needs CUDA 12.1):
python -m pip install torch==2.1.2 torchaudio==2.1.2 --index-url https://download.pytorch.org/whl/cu121

# —— OR ——

# CPU-only build:
python -m pip install torch==2.1.2 torchaudio==2.1.2
```

### 3.2 Install the rest of the deps

```powershell
python -m pip install -r requirements.txt
```

---

## 4  Tell Whisper which device to use

Open **`config.py`** in a text editor and set:

```python
WHISPER_DEVICE = "cuda"   # if you installed CUDA
#      – or –
WHISPER_DEVICE = "cpu"
```

---

## 5  First run

```powershell
# still inside the activated venv
python main.py
```

Speak into your mic; within \~20 s the first transcript appears, and \~7 min max later you’ll see summarised bullet points in **`outputs\*.xlsx`**.

---

### Quick troubleshooting

| Issue                        | Check                                                                              |
| ---------------------------- | ---------------------------------------------------------------------------------- |
| *`ffmpeg` not recognised*    | PATH typo – confirm `ffmpeg -version` works in a new terminal.                     |
| Torch “CUDA DLL load failed” | CUDA wheels but runtime missing → reinstall CPU wheels **or** reinstall CUDA 12.1. |
| *`ollama` not recognised*    | Re-open terminal or add `C:\Users\<you>\AppData\Local\Programs\Ollama` to PATH.    |
| Excel “permission denied”    | Close the workbook; NosyNeighbour falls back to `.txt` when locked.                |