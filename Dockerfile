# escape=`
# Windows container: oneocr.py loads oneocr.dll via ctypes.WinDLL, so it cannot run in a Linux container.
# Build/run with Docker in *Windows containers* mode. Build context = the extracted oneocr.zip folder.
FROM python:3.12-windowsservercore-ltsc2022

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# VC++ runtime for onnxruntime.dll / oneocr.dll (not included in Server Core)
RUN Invoke-WebRequest https://aka.ms/vs/17/release/vc_redist.x64.exe -OutFile vc_redist.x64.exe; `
    Start-Process .\vc_redist.x64.exe -ArgumentList '/install','/quiet','/norestart' -Wait; `
    Remove-Item vc_redist.x64.exe

WORKDIR C:\app

# pip auto-detects the UTF-16 BOM in requirements.txt
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# oneocr.py reads ~/.config/oneocr -> C:\Users\ContainerAdministrator\.config\oneocr
COPY .config C:\Users\ContainerAdministrator\.config
COPY oneocr.py index.html .\

# Optional summarize endpoint -> Ollama running on the host
ENV OLLAMA_URL=http://host.docker.internal:11434 `
    OLLAMA_MODEL=qwen2.5:1.5b

EXPOSE 8001
CMD ["python", "oneocr.py"]