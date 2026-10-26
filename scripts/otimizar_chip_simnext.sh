#!/usr/bin/env bash
# ==============================================================================
# Script de Detecção de Hardware (CPU/GPU) e Otimização Gráfica para o SIM Next
# Lê o processador e o chip gráfico atual e instala/configura o DXVK compatível
# ==============================================================================

set -e

WINEPREFIX_DIR="$HOME/.wine-simnext"
WINETRICKS_BIN="$HOME/.local/bin/winetricks"
SIMNEXT_APP_DIR="$WINEPREFIX_DIR/drive_c/Program Files/Intelbras/SIMNext/SIM Next"

if [ ! -d "$WINEPREFIX_DIR" ]; then
    echo "[ERRO] O prefixo $WINEPREFIX_DIR não foi encontrado."
    echo "Execute primeiro o script instalar_simnext.sh."
    exit 1
fi

echo "=================================================================="
echo " 1. Detectando Hardware Atual (CPU e Chip Gráfico / GPU)"
echo "=================================================================="
CPU_MODEL=$(lscpu | grep -i "Model name:" | sed 's/.*Model name:[[:space:]]*//')
CPU_THREADS=$(nproc 2>/dev/null || echo "4")
GPU_INFO=$(lspci | grep -i -E "vga|3d|display" | head -n 1)

echo " -> Processador detectado : $CPU_MODEL ($CPU_THREADS threads)"
echo " -> Chip Gráfico (GPU)    : $GPU_INFO"

# Escolhe a versão ideal do DXVK conforme o suporte Vulkan do chip gráfico:
# - GPUs Intel Ice Lake / Gen9 / Gen10 / Gen11 (ex: Iris Plus G1, UHD 620/630)
#   não suportam VK_KHR_load_store_op_none exigido pelo DXVK 3.x, portanto
#   precisam do DXVK 2.3 (dxvk2030).
# - GPUs AMD/NVIDIA modernas ou Intel Xe/Arc suportam DXVK recente, mas dxvk2030
#   também funciona universalmente com Vulkan 1.2+.
DXVK_VERB="dxvk"
if echo "$GPU_INFO" | grep -q -i -E "Iris Plus|Ice Lake|UHD Graphics 6|HD Graphics 5|HD Graphics 6|UHD Graphics \(ICL"; then
    DXVK_VERB="dxvk2030"
    echo " -> Perfil selecionado    : Intel Gen9/Gen11 (Ice Lake / Iris Plus)"
    echo " -> Pacote Vulkan ideal   : $DXVK_VERB (DXVK 2.3 compatível com Vulkan 1.2)"
elif echo "$GPU_INFO" | grep -q -i "Intel"; then
    DXVK_VERB="dxvk2030"
    echo " -> Perfil selecionado    : Intel Graphics Integrada (Modo de Alta Compatibilidade)"
    echo " -> Pacote Vulkan ideal   : $DXVK_VERB (DXVK 2.3)"
else
    DXVK_VERB="dxvk"
    echo " -> Perfil selecionado    : GPU Dedicada / Vulkan 1.3 Completo"
    echo " -> Pacote Vulkan ideal   : $DXVK_VERB (DXVK mais recente)"
fi

echo "=================================================================="
echo " 2. Instalando e configurando aceleração Vulkan ($DXVK_VERB)"
echo "=================================================================="
export WINEPREFIX="$WINEPREFIX_DIR"
export WINEARCH=win64
export WINEDEBUG=-all

wineserver -k 2>/dev/null || true
"$WINETRICKS_BIN" -q "$DXVK_VERB"

echo "=================================================================="
echo " 3. Aplicando configurações específicas para o chip detectado"
echo "=================================================================="
# Cria arquivo dxvk.conf no diretório do SIM Next para reduzir uso de CPU/RAM
# em chips integrados e limitar a fila de quadros (evita travamentos de vídeo)
DXVK_CONF="$SIMNEXT_APP_DIR/dxvk.conf"
cat << 'EOF' > "$DXVK_CONF"
# Configuração otimizada para o SIM Next (WPF + Direct3D 9 Video Rendering)
d3d9.maxFrameLatency = 1
d3d9.presentInterval = 1
dxgi.maxFrameLatency = 1
dxvk.numCompilerThreads = 2
EOF
echo "[*] Arquivo dxvk.conf criado em: $DXVK_CONF"

# Garante que a política de exceções do WMI/AppCenter esteja ativa no SIMNext.exe.config
SIMNEXT_CONFIG="$SIMNEXT_APP_DIR/SIMNext.exe.config"
if [ -f "$SIMNEXT_CONFIG" ] && ! grep -q "legacyCorruptedStateExceptionsPolicy" "$SIMNEXT_CONFIG"; then
    sed -i 's|<runtime>|<runtime>\n    <legacyCorruptedStateExceptionsPolicy enabled="true" />|' "$SIMNEXT_CONFIG"
fi

# Garante que o serviço de gravação local não inicie automaticamente consumindo CPU
wine reg add "HKLM\\System\\CurrentControlSet\\Services\\SIMNextLocalRecording" /v Start /t REG_DWORD /d 3 /f >/dev/null 2>&1 || true

# Atualiza o lançador ~/.local/bin/simnext com as variáveis de otimização do chip
cat << 'EOF' > "$HOME/.local/bin/simnext"
#!/usr/bin/env bash
export WINEPREFIX="$HOME/.wine-simnext"
export WINEDEBUG=-all
export DXVK_LOG_LEVEL=none
export DXVK_STATE_CACHE=1
export mesa_glthread=true
cd "$WINEPREFIX/drive_c/Program Files/Intelbras/SIMNext/SIM Next" || exit 1
exec wine ./SIMNext.exe "$@"
EOF
chmod +x "$HOME/.local/bin/simnext"

echo "=================================================================="
echo " Otimização para o seu chip concluída com sucesso!"
echo " Para abrir o SIM Next otimizado, execute: ~/.local/bin/simnext"
echo "=================================================================="