#!/bin/bash

echo ">>> Post-creation setup started..."

# --- 1. Clone noVNC for the web client ---
echo ">>> Cloning noVNC..."
git clone https://github.com/novnc/noVNC.git /home/vscode/noVNC

# --- 2. Create the main runner script for the user ---
echo ">>> Creating the 'start-windows.sh' script..."
cat <<'EOF' > /workspaces/$CODESPACE_NAME/start-windows.sh
#!/bin/bash

# --- CONFIGURATION ---
ISO_URL="https://software.download.prss.microsoft.com/dbazure/Win11_24H2_EnglishInternational_x64.iso?t=398c43bf-c815-407c-a974-341867de5e8a&P1=1750718835&P2=601&P3=2&P4=HIqv5SlaxerLMB2TcT9z3OsQIXUR%2fxyjaqmbY63lwZN9yS9K3m2%2fKrKSxZRWcs1wLD9I%2b3w6rDhw8dVmPLyloUmSLXHfCzUwcDjLEFlAEgClsc8zuQRejQu4eejWqnvZCb3zZ1w44Mzg54nmrzciZliKDU2s0gC1TsOgv5wpp3tozCIx6qx2iP2KQxFN1A9Ccr1d%2fKPZbZg%2bAJC%2fPQaEz9xydeuOQ1sK7nIr9b4%2bFAq1Y4stiIYMmSToBVuyGSygTfoU4omOrSHYiEYvxhYCzBqYfVUelzdTUW%2bElZeCOtxbnF2OCB4vBnIOq70%2bfcpfAjij0eh8Ep6w%2binIKCCgjA%3d%3d" # IMPORTANT: Update this link!
ISO_FILE="windows11.iso"
DISK_IMAGE="windows11.img"
DISK_SIZE="25G" # Using 25G out of the 32G available

# --- Check for ISO ---
if [ ! -f "$ISO_FILE" ]; then
    echo "Windows ISO not found. Downloading now..."
    if [[ "$ISO_URL" == "PASTE_YOUR_MICROSOFT_DOWNLOAD_LINK_HERE" ]]; then
        echo "❌ ERROR: You must edit 'start-windows.sh' and replace the placeholder URL with a real link from the Microsoft website."
        exit 1
    fi
    wget -O "$ISO_FILE" "$ISO_URL"
    if [ $? -ne 0 ]; then
        echo "❌ ERROR: Download failed. Please check the URL."
        exit 1
    fi
fi

# --- Check for Disk Image ---
if [ ! -f "$DISK_IMAGE" ]; then
    echo "Disk image not found. Creating and installing Windows... This will take 20-30 minutes."
    qemu-img create -f qcow2 "$DISK_IMAGE" "$DISK_SIZE"
    
    # Automated install script (runs detached in the background)
    qemu-system-x86_64 \
      -enable-kvm -m 4G -smp 2 \
      -pflash /usr/share/OVMF/OVMF_CODE.fd \
      -drive file="$DISK_IMAGE",format=qcow2 \
      -drive file="$ISO_FILE",media=cdrom \
      -drive file=<(curl -L https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso),media=cdrom \
      -display none \
      -cdrom <(echo "autounattend")
fi

echo ">>> Starting VNC and final Windows VM..."
# Start the desktop and VNC proxy
vncserver :1 -localhost -SecurityTypes None -xstartup "openbox" -geometry 1280x800
/home/vscode/noVNC/utils/novnc_proxy --vnc 127.0.0.1:5901 --listen 6080 &

# Launch the fully installed Windows VM, now booting from the disk
qemu-system-x86_64 \
  -enable-kvm -m 4G -smp 2 \
  -pflash /usr/share/OVMF/OVMF_CODE.fd \
  -drive file="$DISK_IMAGE",format=qcow2,if=virtio \
  -boot c \
  -netdev user,id=n1 -device virtio-net-pci,netdev=n1 \
  -vga std \
  -display vnc=:1

echo "✅ Windows VM is running! Connect via the PORTS tab (port 6080) and click 'vnc_lite.html'."
EOF

chmod +x /workspaces/$CODESPACE_NAME/start-windows.sh
echo "✅ Setup complete. The Codespace is ready."
