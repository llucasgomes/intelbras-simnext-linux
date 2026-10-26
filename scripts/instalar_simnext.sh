#!/usr/bin/env bash
# ==============================================================================
# Script de Instalação Base do Intelbras SIM Next no Linux via Wine
# (Com fontes do Windows 11 / Segoe UI e ClearType, sem a modificação opcional de chip/DXVK)
# ==============================================================================

set -e

WINEPREFIX_DIR="$HOME/.wine-simnext"
INSTALL_DIR="$HOME/Downloads/simnext_install"
WINETRICKS_BIN="$HOME/.local/bin/winetricks"
SIMNEXT_URL="https://pub-3b0982a0ea494c1997cb1b2555af8641.r2.dev/SIMNext-v1-25-5.zip"
SIMNEXT_ZIP="$INSTALL_DIR/SIMNext-v1-25-5.zip"
SIMNEXT_EXE="$INSTALL_DIR/SIMNext-v1-25-5.exe"
SIMNEXT_APP_DIR="$WINEPREFIX_DIR/drive_c/Program Files/Intelbras/SIMNext/SIM Next"

echo "=================================================================="
echo " 1. Verificando dependências do sistema (Wine, cabextract, 7z...)"
echo "=================================================================="
for cmd in wine wine64 cabextract 7z wget curl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "[!] Dependência '$cmd' não encontrada. Instalando via apt..."
        sudo apt-get update && sudo apt-get install -y wine wine64 wine32:i386 libwine:i386 cabextract p7zip-full wget curl winbind
        break
    fi
done

mkdir -p "$HOME/.local/bin" "$INSTALL_DIR"

if [ ! -x "$WINETRICKS_BIN" ]; then
    echo "[*] Baixando versão atualizada do winetricks em $WINETRICKS_BIN..."
    wget -q -O "$WINETRICKS_BIN" "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"
    chmod +x "$WINETRICKS_BIN"
fi

echo "=================================================================="
echo " 2. Criando prefixo Wine isolado de 64 bits ($WINEPREFIX_DIR)"
echo "=================================================================="
export WINEPREFIX="$WINEPREFIX_DIR"
export WINEARCH=win64
export WINEDEBUG=-all

wineboot -u

echo "=================================================================="
echo " 3. Instalando dependências via Winetricks"
echo "    (corefonts, tahoma, gdiplus, d3dx9, mfc42, directshow, dotnet48)"
echo "=================================================================="
"$WINETRICKS_BIN" -q corefonts tahoma gdiplus d3dx9 mfc42 directshow
"$WINETRICKS_BIN" -q dotnet48

echo "=================================================================="
echo " 4. Instalando Fontes do Windows 11 (Segoe UI) e ClearType RGB"
echo "=================================================================="
SEGOE_CACHE="$HOME/.cache/simnext_fonts/segoe"
mkdir -p "$SEGOE_CACHE" "$HOME/.local/share/fonts/segoe-ui"

for f in segoeui.ttf segoeuib.ttf segoeuii.ttf segoeuiz.ttf segoeuil.ttf segoeuisl.ttf seguisb.ttf seguisym.ttf; do
    if [ ! -f "$SEGOE_CACHE/$f" ]; then
        wget -q -O "$SEGOE_CACHE/$f" "https://raw.githubusercontent.com/mrbvrz/segoe-ui-linux/master/font/$f" || true
    fi
done

cp -f "$SEGOE_CACHE"/*.ttf "$WINEPREFIX_DIR/drive_c/windows/Fonts/" 2>/dev/null || true
cp -f "$SEGOE_CACHE"/*.ttf "$HOME/.local/share/fonts/segoe-ui/" 2>/dev/null || true
fc-cache -f "$HOME/.local/share/fonts/segoe-ui/" 2>/dev/null || true

"$WINETRICKS_BIN" -q fontsmooth=rgb win11

cat << 'EOF' > /tmp/win11_fonts.reg
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Fonts]
"Segoe UI (TrueType)"="segoeui.ttf"
"Segoe UI Bold (TrueType)"="segoeuib.ttf"
"Segoe UI Italic (TrueType)"="segoeuii.ttf"
"Segoe UI Bold Italic (TrueType)"="segoeuiz.ttf"
"Segoe UI Light (TrueType)"="segoeuil.ttf"
"Segoe UI Semilight (TrueType)"="segoeuisl.ttf"
"Segoe UI Semibold (TrueType)"="seguisb.ttf"
"Segoe UI Symbol (TrueType)"="seguisym.ttf"

[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\FontSubstitutes]
"MS Shell Dlg"="Segoe UI"
"MS Shell Dlg 2"="Segoe UI"
"Segoe UI Variable"="Segoe UI"
"Segoe UI Variable Display"="Segoe UI"
"Segoe UI Variable Text"="Segoe UI"

[HKEY_CURRENT_USER\Control Panel\Desktop]
"FontSmoothing"="2"
"FontSmoothingType"=dword:00000002
"FontSmoothingGamma"=dword:00000578
"FontSmoothingOrientation"=dword:00000001

[HKEY_CURRENT_USER\Software\Microsoft\Avalon.Graphics]
"ClearTypeLevel"=dword:00000064
"GammaLevel"=dword:000007d0
"PixelStructure"=dword:00000001
"TextContrastLevel"=dword:00000001
EOF

wine regedit /S /tmp/win11_fonts.reg
/usr/lib/wine/wine64 regedit /S /tmp/win11_fonts.reg

echo "=================================================================="
echo " 5. Baixando e extraindo o instalador oficial do SIM Next"
echo "=================================================================="
if [ ! -f "$SIMNEXT_EXE" ]; then
    if [ ! -f "$SIMNEXT_ZIP" ]; then
        echo "[*] Baixando SIMNext-v1-25-5.zip..."
        wget -O "$SIMNEXT_ZIP" "$SIMNEXT_URL"
    fi
    echo "[*] Extraindo instalador SIMNext-v1-25-5.exe..."
    7z x -y "$SIMNEXT_ZIP" -o"$INSTALL_DIR"
fi

echo "=================================================================="
echo " 6. Executando o instalador do SIM Next no prefixo Wine"
echo "    Nota: O instalador usa VclStylesInno.dll (Inno Setup 6.4.3),"
echo "    que requer execução em modo gráfico padrão (sem /VERYSILENT)."
echo "    Aguarde ou confirme a janela do instalador caso solicitado."
echo "=================================================================="
wine "$SIMNEXT_EXE" /LOG="C:\simnext_install_gui.log"

echo "=================================================================="
echo " 7. Aplicando correções de estabilidade pós-instalação"
echo "=================================================================="
SIMNEXT_CONFIG="$SIMNEXT_APP_DIR/SIMNext.exe.config"

if [ -f "$SIMNEXT_CONFIG" ]; then
    if ! grep -q "legacyCorruptedStateExceptionsPolicy" "$SIMNEXT_CONFIG"; then
        echo "[*] Adicionando legacyCorruptedStateExceptionsPolicy no SIMNext.exe.config"
        echo "    (Previne crash de AccessViolationException na wbemprox.dll / WMI do AppCenter)"
        sed -i 's|<runtime>|<runtime>\n    <legacyCorruptedStateExceptionsPolicy enabled="true" />|' "$SIMNEXT_CONFIG"
    fi
fi

echo "[*] Configurando serviço SIMNextLocalRecording para início manual (Start=3)..."
wine reg add "HKLM\\System\\CurrentControlSet\\Services\\SIMNextLocalRecording" /v Start /t REG_DWORD /d 3 /f >/dev/null 2>&1 || true

echo "[*] Criando lançador básico em ~/.local/bin/simnext..."
cat << 'EOF' > "$HOME/.local/bin/simnext"
#!/usr/bin/env bash
export WINEPREFIX="$HOME/.wine-simnext"
export WINEDEBUG=-all
cd "$WINEPREFIX/drive_c/Program Files/Intelbras/SIMNext/SIM Next" || exit 1
exec wine ./SIMNext.exe "$@"
EOF
chmod +x "$HOME/.local/bin/simnext"

echo "=================================================================="
echo " Instalação base concluída com sucesso!"
echo " Para iniciar o SIM Next, execute: ~/.local/bin/simnext"
echo "=================================================================="