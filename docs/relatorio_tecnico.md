# 📋 Documentação de Instalação e Correção do Intelbras SIM Next no Linux (Wine)

Relatório técnico detalhado sobre a configuração do ambiente, dependências, análise de falhas e correções aplicadas para a execução estável do **Intelbras SIM Next v1.25.5** no Linux via Wine.

---

## 1. 🖥️ Ambiente do Sistema Verificado

| Componente | Especificação / Versão |
| :--- | :--- |
| **Sistema Operacional** | Linux Mint 22.2 (Zara) — Base Ubuntu 24.04 LTS (Noble) |
| **Versão do Wine** | `wine-9.0` (`Ubuntu 9.0~repack-4build3`) com suporte 32/64 bits |
| **Winetricks** | Instalado em `~/.local/bin/winetricks` (versão `20260125-next`) |
| **Bibliotecas Gráficas** | Mesa `25.2.8` (OpenGL / Vulkan `i386` e `amd64`), FreeType, GnuTLS |
| **Versão do SIM Next** | `v1.25.5` (Instalador oficial `SIMNext-v1-25-5.exe`) |

---

## 2. 🏗️ Criação do Prefixo Wine e Arquitetura

Embora o instalador do SIM Next (empacotado com **Inno Setup 6.4.3**) seja um binário **32-bit**, os executáveis instalados (`SIMNext.exe`, `SIMNext.ConfigTool.exe` e `SIMNext.LocalRecording.exe`) são binários nativos **64-bit (`PE32+ x86-64`)** desenvolvidos em **.NET Framework 4.8 (WPF)**.

Além disso, eles são acompanhados de DLLs nativas 64-bit do SDK de vídeo:
- `dhplay.dll`
- `dhnetsdk.dll`
- `avnetsdk.dll`
- `rendersvr.dll`
- `HW_H265dec_Win64D.dll`
- `d3dx9_24.dll`

Por esse motivo, o prefixo deve ser criado obrigatoriamente em arquitetura **64 bits (`win64`)**:

```bash
export WINEPREFIX=~/.wine-simnext
export WINEARCH=win64
wineboot -u
```

---

## 3. 📦 Dependências e Fontes Instaladas no Prefixo

Foram instaladas e registradas no prefixo `~/.wine-simnext` (tanto em 32-bit `syswow64` quanto em 64-bit `system32`):

- **`corefonts` e `tahoma`:** Fontes base da Microsoft exigidas pelo WPF e RichEdit.
- **`Segoe UI` (Família completa do Windows 10/11):**
  - Arquivos instalados em `C:\windows\Fonts` e `~/.local/share/fonts/segoe-ui`:
    - `segoeui.ttf`, `segoeuib.ttf`, `segoeuii.ttf`, `segoeuiz.ttf`, `segoeuil.ttf`, `segoeuisl.ttf`, `seguisb.ttf` e `seguisym.ttf`.
  - Registrados em `HKLM\Software\Microsoft\Windows NT\CurrentVersion\Fonts`.
  - Mapeados em `FontSubstitutes` (`MS Shell Dlg`, `MS Shell Dlg 2`, `Segoe UI Variable`).
- **`fontsmooth=rgb` e `Avalon.Graphics` (ClearType do Windows 11):**
  - Ativada suavização subpixel RGB (`FontSmoothing=2`, `FontSmoothingType=2`).
  - Configurada a chave `HKCU\Software\Microsoft\Avalon.Graphics` (`ClearTypeLevel=100`, `PixelStructure=1`, `TextContrastLevel=1`) para renderização nítida no WPF.
- **`win11`:** Versão do Windows no prefixo configurada para Windows 11.
- **`gdiplus`:** Biblioteca gráfica GDI+ nativa da Microsoft.
- **`d3dx9`:** DLLs DirectX 9 (`d3dx9_24.dll` a `d3dx9_43.dll`) para renderização de vídeo das câmeras.
- **`mfc42`:** Biblioteca Visual C++ 6 MFC42.
- **`directshow`:** Filtros e runtimes de vídeo DirectShow (`amstream.dll`, `qasf.dll`, `qcap.dll`, `qdvd.dll`, `qedit.dll`, `quartz.dll`).
- **`dotnet48`:** Microsoft .NET Framework 4.0 e 4.8 completo (`x86` e `x64`) com override nativo da `mscoree.dll`.

---

## 4. 🛠️ Problemas Encontrados e Correções Aplicadas (Instalação Padrão)

### A) Falha do Instalador em Modo Silencioso (`/VERYSILENT`) — `VclStylesInno.dll`
- **Causa:** O instalador `SIMNext-v1-25-5.exe` (Inno Setup 6.4.3) carrega a DLL de temas visuais `VclStylesInno.dll` (`LoadVCLStyleW`) e o documento RTF `license-and-privacy.rtf`. Quando executado com a flag `/VERYSILENT`, o hook de estilo falha ao avançar a página do wizard e lança a exceção `EAbort` (*"Failed to proceed to next wizard page; aborting"*).
- **Solução:** Executar o instalador sem a flag `/VERYSILENT` (em modo gráfico normal):
  ```bash
  wine SIMNext-v1-25-5.exe /LOG="C:\simnext_install_gui.log"
  ```

### B) Crash de Inicialização no WMI (`wbemprox.dll`) pelo Microsoft AppCenter
- **Causa:** Ao iniciar o `SIMNext.exe`, o SDK de telemetria embutido (`Microsoft.AppCenter.Utils.DeviceInformationHelper.GetDeviceOemName()` e `GetDeviceModel()`) realiza consultas WMI simultâneas em threads separadas via `System.Management.SecuredIWbemServicesHandler.CreateInstanceEnum_` e `IWbemClassObjectFreeThreaded.Get_` para as classes `Win32_BaseBoard` e `Win32_ComputerSystem`.
  Na implementação WMI do Wine (`wbemprox.dll`), essa chamada concorrente gera uma falha de página (`Unhandled page fault on read access` / `System.AccessViolationException`). No .NET Framework 4.0+, exceções de violação de acesso nativas são tratadas como **Corrupted State Exceptions (CSE)** e não são capturadas pelos blocos `try/catch` normais do AppCenter, derrubando o processo `SIMNext.exe`.
- **Solução:** Adicionada a diretiva `<legacyCorruptedStateExceptionsPolicy enabled="true" />` dentro da tag `<runtime>` no arquivo de configuração:
  - **Arquivo:** `~/.wine-simnext/drive_c/Program Files/Intelbras/SIMNext/SIM Next/SIMNext.exe.config`
  ```xml
  <configuration>
    <runtime>
      <legacyCorruptedStateExceptionsPolicy enabled="true" />
    </runtime>
  </configuration>
  ```
  Com isso, o próprio bloco `try/catch` do AppCenter captura a exceção da `wbemprox.dll` e o SIM Next inicializa normalmente sem fechar.

### C) Travamento e Alto Consumo do Serviço `SIMNext.LocalRecording.exe`
- **Causa:** O binário `SIMNext.LocalRecording.exe` utiliza a biblioteca `Topshelf` para se registrar como serviço do Windows (`SIMNextLocalRecording`) com início automático (`Start = 2`). No Wine, a comunicação de pipe do gerenciador de serviços (`services.exe`) com o Topshelf atinge timeout (`error 1053`), atrasando a abertura do SIM Next em ~10 segundos e mantendo processos em loop.
- **Solução:** Alterado o registro do serviço para inicialização manual (`Start = 3`):
  ```bash
  wine reg add "HKLM\System\CurrentControlSet\Services\SIMNextLocalRecording" /v Start /t REG_DWORD /d 3 /f
  ```

### D) Fontes Diferentes do Windows 11 e Falta de Suavização (ClearType)
- **Causa:** O pacote `corefonts` não inclui a fonte padrão do Windows 10/11 (`Segoe UI`), fazendo o Wine substituí-la por fontes genéricas sem ClearType no motor WPF (`Avalon.Graphics`).
- **Solução:** Instalação e registro completo da família `Segoe UI`, ativação do `fontsmooth=rgb`, configuração da chave `Avalon.Graphics` no registro e definição do prefixo como `win11`.

### E) Lançador Padrão Sem Overhead de Logs (`WINEDEBUG=-all`)
- **Solução:** Criado o script lançador em `~/.local/bin/simnext` com a variável `WINEDEBUG=-all` para desativar a gravação contínua de mensagens `fixme:` do Wine no terminal, evitando lentidão de I/O durante a decodificação dos streams das câmeras.

---

## 5. ⚡ Modificação Opcional (Otimização de Desempenho Gráfico / Chip Específico)

Esta etapa é **opcional** e foi separada no script `otimizar_chip_simnext.sh` (ex.: `~/Desktop/otimizar_chip_simnext.sh`).

### Por que usar esta modificação opcional?
- Por padrão, o Wine traduz as chamadas Direct3D 9 do WPF e do player de vídeo do SIM Next para OpenGL (`wined3d`), o que consome mais CPU em processadores com placa de vídeo integrada.
- A modificação opcional detecta automaticamente o modelo do seu chip gráfico (ex.: *Intel Iris Plus Graphics G1 — Ice Lake*) e instala a versão compatível do **DXVK** para traduzir Direct3D 9/11 diretamente para **Vulkan**.

> [!IMPORTANT]
> **Detalhe Técnico Importante (Descoberto nos Testes):**
> - O **DXVK 3.x** (ex.: `v3.1.1`) exige suporte a **Vulkan 1.3** e à extensão `VK_KHR_load_store_op_none`. Na GPU integrada *Intel Iris Plus G1 (Ice Lake)*, o DXVK 3.1.1 ignora o adaptador gráfico (*"Device does not support required feature khrLoadStoreOpNone"*) e faz o WPF falhar na criação do dispositivo D3D.
> - Já o **DXVK 2.3 (`winetricks dxvk2030`)** exige apenas **Vulkan 1.2**, reconhece perfeitamente o chip *Intel Iris Plus G1* (driver Mesa) e acelera a renderização da interface e dos mosaicos de vídeo via Vulkan.

### O que o script opcional (`otimizar_chip_simnext.sh`) faz:
1. Lê automaticamente o seu processador (`lscpu`) e chip gráfico (`lspci`).
2. Seleciona `dxvk2030` (**DXVK 2.3**) para GPUs integradas Intel (como a *Iris Plus G1*) ou `dxvk` mais recente para GPUs dedicadas com suporte completo a Vulkan 1.3.
3. Cria o arquivo `dxvk.conf` na pasta do SIM Next limitando a latência de quadros e o número de threads de compilação de shaders:
   ```ini
   d3d9.maxFrameLatency = 1
   d3d9.presentInterval = 1
   dxvk.numCompilerThreads = 2
   ```
4. Configura as variáveis `DXVK_LOG_LEVEL=none`, `DXVK_STATE_CACHE=1` e `mesa_glthread=true` no lançador `~/.local/bin/simnext`.

### 🔄 Como Reverter a Modificação Opcional (DXVK)
Caso deseje reverter a modificação opcional de DXVK e voltar ao renderizador OpenGL padrão do Wine (`wined3d`), basta executar no terminal:

```bash
WINEPREFIX=~/.wine-simnext wine reg delete "HKCU\Software\Wine\DllOverrides" /v d3d9 /f
WINEPREFIX=~/.wine-simnext wine reg delete "HKCU\Software\Wine\DllOverrides" /v d3d11 /f
WINEPREFIX=~/.wine-simnext wine reg delete "HKCU\Software\Wine\DllOverrides" /v d3d10core /f
WINEPREFIX=~/.wine-simnext wine reg delete "HKCU\Software\Wine\DllOverrides" /v dxgi /f
```