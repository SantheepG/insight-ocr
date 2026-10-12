# Windows container (requires Docker Desktop in "Windows containers" mode, or a Windows Server host).
# Why: oneocr.py loads oneocr.dll via ctypes.WinDLL, which does not exist on Linux.
# Build context = the extracted insightocr folder (keeps .config/oneocr/*.dll + .onemodel).
FROM python:3.12-windowsservercore-ltsc2022

SHELL ["powershell", "-Command", "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue';"]

# VC++ runtime needed by oneocr.dll / onnxruntime.dll
RUN Invoke-WebRequest https://aka.ms/vs/17/release/vc_redist.x64.exe -OutFile vc_redist.x64.exe; \
    Start-Process .\vc_redist.x64.exe -ArgumentList '/install','/quiet','/norestart' -Wait; \
    Remove-Item vc_redist.x64.exe

WORKDIR C:/app

# requirements.txt is UTF-16 LE -> re-encode to UTF-8; drop PyPI "oneocr" (local oneocr.py is used)
COPY requirements.txt .
RUN (Get-Content requirements.txt) | Where-Object { $_ -notmatch '^oneocr==' } | Set-Content -Encoding utf8 req.txt; \
    pip install --no-cache-dir -r req.txt

# App + OCR binaries. oneocr.py resolves them via ~/.config/oneocr, so point USERPROFILE at C:\app\home
ENV USERPROFILE=C:\\app\\home
COPY .config/oneocr C:/app/home/.config/oneocr
COPY oneocr.py index.html kbsl_logo.png ./

# Provide at runtime: -e OPENAI_API_KEY=... (optional, only for /summarize)
ENV OPENAI_MODEL=gpt-4o-mini

EXPOSE 8001
CMD ["python", "oneocr.py"]
