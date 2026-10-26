# 🎥🐧 Intelbras SIM Next no Linux (Wine)

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge&logo=open-source-initiative)](https://opensource.org/licenses/MIT)
[![OS: Linux](https://img.shields.io/badge/OS-Linux%20(Ubuntu%20%7C%20Mint%20%7C%20Debian)-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://www.linux.org/)
[![Wine: 8.0+](https://img.shields.io/badge/Wine-8.0%2B-800000?style=for-the-badge&logo=wine&logoColor=white)](https://www.winehq.org/)
[![Status: Ativo](https://img.shields.io/badge/Status-Estável%20%26%20Ativo-007EC6?style=for-the-badge&logo=github)](https://github.com/)

Conjunto de scripts automatizados, correções de ambiente e otimizações para instalar e executar o sistema de monitoramento **Intelbras SIM Next** em distribuições Linux utilizando o **Wine**, garantindo estabilidade, renderização fluida de vídeo e baixo consumo de recursos de hardware.

---

## 🚨 O Problema (Por que este projeto existe?)

A Intelbras descontinuou o suporte oficial às versões nativas mais antigas para Linux, concentrando as atualizações mais recentes do **SIM Next** apenas para o ecossistema Windows. 

Ao tentar instalar e executar o SIM Next diretamente no Wine sem ajustes específicos, técnicos de CFTV, administradores de sistemas e usuários de Linux enfrentam diversos obstáculos críticos:

- 💥 **Crash na inicialização (WMI / `wbemprox.dll`):** O aplicativo fecha inesperadamente logo na tela de carregamento ao tentar consultar informações de hardware via WMI.
- 🔥 **Alto consumo de CPU e memória:** O serviço de gravação em segundo plano (`SimNextRecordingService` / banco de dados local) entra em loop ou consome recursos excessivos mesmo quando não está em uso.
- ❌ **Falha no instalador (`VclStylesInno.dll`):** O instalador Inno Setup falha ou congela ao tentar carregar temas visuais proprietários durante a instalação.
- 🔤 **Interface ilegível ou quebrada:** Ausência das fontes padrão da Microsoft (como *Segoe UI*) e falta de suavização *ClearType*, causando textos cortados, sobrepostos ou serrilhados.
- 🐢 **Lentidão na renderização de vídeo:** Abertura de múltiplos canais de câmeras (mosaicos) apresenta alto *lag*, *stuttering* e uso elevado de processador por falta de aceleração gráfica via DirectX/Vulkan (DXVK).

---

## 🛠️ A Solução

Este repositório automatiza todo o processo de preparação do prefixo Wine e pós-instalação do SIM Next, aplicando correções cirúrgicas para que o software funcione de forma transparente no Linux:

- **Ajustes nos arquivos `.config` do SIM Next:** Desativação e otimização de módulos problemáticos e serviços secundários que causam gargalos de CPU.
- **Substituição e Overrides de DLLs no Registro do Wine:** Configuração de *overrides* para contornar falhas de chamadas WMI (`wbemprox`) e bibliotecas visuais do instalador (`VclStylesInno.dll`).
- **Mapeamento de Fontes e ClearType:** Instalação e substituição automática de fontes essenciais (*Segoe UI*, *Tahoma*, *Arial*) com ativação de suavização de subpixel (RGB ClearType) via registro.
- **Aceleração de Hardware (DXVK / Vulkan):** Script dedicado para ativar tradução de chamadas Direct3D para Vulkan, reduzindo drasticamente o uso de CPU durante a decodificação e exibição das câmeras.
- **Integração com o Sistema:** Criação de comando rápido no terminal (`simnext`) e lançador de aplicativo no menu do sistema.

---

## 💻 Requisitos do Sistema

### Distribuições Homologadas / Recomendadas
- **Ubuntu** 22.04 LTS / 24.04 LTS (ou superior)
- **Linux Mint** 21.x / 22.x
- **Debian** 12 (Bookworm) ou superior
- **Pop!_OS**, **Zorin OS** e demais derivados diretos do Debian/Ubuntu (arquitetura `amd64` com suporte a `i386`)

### Dependências de Software
Os scripts verificam e utilizam os seguintes pacotes base:
- `wine` (Recomendado **Wine 8.0+** ou superior, incluindo `wine32` e `wine64`)
- `winetricks`
- `cabextract`
- `p7zip-full`
- `wget` e `curl`
- Drivers gráficos atualizados com suporte a **Vulkan** (para uso da otimização com DXVK)

Para instalar todas as dependências manualmente em sistemas baseados em Debian/Ubuntu:

```bash
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install -y wine wine32 wine64 winetricks cabextract p7zip-full wget curl vulkan-tools
```

---

## 📂 Estrutura do Repositório

O projeto está organizado da seguinte forma:

```text
intelbras-simnext-linux/
├── docs/                           # Documentação complementar, guias de troubleshooting e screenshots
│   └── TROUBLESHOOTING.md          # Solução de problemas comuns e logs
├── scripts/                        # Scripts principais de instalação, correção e otimização
│   ├── instalar_simnext.sh         # Script principal de criação do prefixo Wine e instalação do SIM Next
│   ├── otimizar_chip_simnext.sh    # Script opcional de aceleração gráfica (DXVK/Vulkan) e ajuste de CPU
│   └── remover_simnext.sh          # Script de limpeza e desinstalação segura do ambiente
├── .gitignore                      # Regras para ignorar binários proprietários, cache e prefixos Wine
├── LICENSE                         # Licença MIT do projeto
└── README.md                       # Documentação principal do projeto
```

---

## 🚀 Guia Passo a Passo de Instalação e Uso

Siga as etapas abaixo para configurar e rodar o **Intelbras SIM Next** em sua máquina:

### 1. Clonar o repositório
Abra o terminal, clone este repositório e acesse a pasta do projeto:

```bash
git clone https://github.com/SEU_USUARIO/intelbras-simnext-linux.git
cd intelbras-simnext-linux
```

### 2. Executar o script de instalação base
Conceda permissão de execução aos scripts e inicie o instalador automatizado:

```bash
chmod +x scripts/*.sh
./scripts/instalar_simnext.sh
```
> 💡 **Nota:** O script preparará o prefixo dedicado do Wine, aplicará as correções de registro/fontes e guiará você pelo download ou seleção do instalador oficial do SIM Next.

### 3. Executar a otimização de hardware e GPU (Opcional, mas Recomendado)
Para melhorar a fluidez dos mosaicos de câmeras e reduzir o uso de processador usando aceleração via GPU/Vulkan:

```bash
./scripts/otimizar_chip_simnext.sh
```

### 4. Iniciar o SIM Next
Após a conclusão, você pode abrir o programa diretamente pelo menu de aplicativos da sua interface gráfica ou executando o atalho no terminal:

```bash
simnext
```

---

## 🔧 Tabela de Correções Técnicas

Abaixo está o detalhamento técnico dos problemas conhecidos no Wine e como nossos scripts os solucionam nos bastidores:

| Problema Conhecido | Causa Raiz no Wine | Solução Técnica Aplicada |
| :--- | :--- | :--- |
| **Crash ao abrir o SIM Next** | Falha na implementação incompleta de consultas WMI (`wbemprox.dll`) pelo Wine durante a checagem de hardware. | Configuração de *DLL Override* e ajustes nos arquivos `.config` da aplicação para ignorar telemetria/checagem WMI. |
| **Erro no instalador (`VclStylesInno.dll`)** | O plugin de estilização visual do Inno Setup causa violação de acesso à memória no Wine. | Execução do instalador em modo silencioso/compatibilidade (`/VERYSILENT` / `/SUPPRESSMSGBOXES`) ou desativação do hook visual. |
| **Alto uso de CPU em segundo plano** | Serviços auxiliares de gravação local e monitoramento tentam reconectar continuamente em APIs ausentes do Windows. | Desativação dos serviços desnecessários no registro do Wine (`services.exe`) e ajuste de flags nos arquivos `.exe.config`. |
| **Fontes invisíveis, cortadas ou serrilhadas** | Falta da família de fontes *Segoe UI* nativa do Windows e renderização de fontes sem *anti-aliasing*. | Instalação de fontes base via `winetricks`, mapeamento de `FontSubstitutes` no registro e ativação do *ClearType* RGB. |
| **Vídeo travando com várias câmeras abertas** | Tradução padrão Direct3D para OpenGL (`wined3d`) possui alto *overhead* de CPU em múltiplas threads de vídeo. | Ativação de **DXVK** (tradução Direct3D 9/10/11 para **Vulkan**) e variáveis de ambiente de sincronização (`WINEESYNC`/`WINEFSYNC`). |

---

## 🙈 O que Incluir / Não Incluir no Git (`.gitignore`)

Por questões de **direitos autorais, licenciamento de software e boas práticas de versionamento**, este repositório **NÃO inclui** arquivos binários proprietários da Intelbras nem dados de usuário.

O arquivo `.gitignore` está configurado para ignorar automaticamente:
- 📦 **Instaladores proprietários:** Arquivos `.exe`, `.msi`, `.zip` ou `.rar` baixados do site oficial da Intelbras.
- 🍷 **Prefixos do Wine (`.wine*` / `wineprefix/`):** Diretórios contendo a estrutura `drive_c`, DLLs extraídas e dados de perfil do usuário.
- 📝 **Logs e arquivos temporários:** Arquivos `.log`, `.tmp`, dumps de memória e caches do `winetricks`.

```gitignore
# Instaladores e binários proprietários
*.exe
*.msi
*.zip
*.7z
*.dll

# Prefixos Wine e caches locais
.wine*/
wineprefix/
cache/
*.log
```

---

## 🤝 Contribuição e Licença

### Como Contribuir
Contribuições da comunidade são muito bem-vindas! Se você testou em uma nova distribuição, encontrou algum bug ou descobriu uma nova otimização:

1. Verifique na aba [**Issues**](../../issues) se o problema ou sugestão já foi reportado. Caso não, abra uma nova *Issue* detalhando sua distribuição Linux, versão do Wine (`wine --version`) e o log do terminal.
2. Para enviar melhorias no código:
   - Faça um **Fork** deste repositório.
   - Crie uma branch para sua feature ou correção (`git checkout -b feat/minha-melhoria`).
   - Faça o commit das suas alterações (`git commit -m 'feat: adiciona suporte para distro X'`).
   - Envie para o seu repositório remoto (`git push origin feat/minha-melhoria`) e abra um **Pull Request**.

### 📄 Licença
Este projeto (scripts de automação e documentação) é distribuído sob a licença **MIT**. Veja o arquivo `LICENSE` para mais detalhes.

### ⚠️ Isenção de Responsabilidade (Disclaimer)
> Este é um projeto **independente e de código aberto**, criado pela comunidade para fins de interoperabilidade no sistema operacional Linux.  
> **Não possuímos qualquer vínculo oficial, afiliação ou endosso da Intelbras S.A.**  
> O nome *Intelbras*, *SIM Next* e seus respectivos logotipos são marcas registradas de propriedade exclusiva da **Intelbras S.A.** Todo o software proprietário é baixado diretamente dos servidores oficiais da fabricante pelo próprio usuário durante a execução dos scripts.
