# 🎥🐧 Intelbras SIM Next no Linux (Wine)

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge&logo=open-source-initiative)](https://opensource.org/licenses/MIT)
[![OS: Linux](https://img.shields.io/badge/OS-Linux%20(Ubuntu%20%7C%20Mint%20%7C%20Debian)-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://www.linux.org/)
[![Wine: 8.0+](https://img.shields.io/badge/Wine-8.0%2B-800000?style=for-the-badge&logo=wine&logoColor=white)](https://www.winehq.org/)
[![Status: Ativo](https://img.shields.io/badge/Status-Estável%20%26%20Ativo-007EC6?style=for-the-badge&logo=github)](https://github.com/)

Scripts automatizados para instalar, corrigir e otimizar o **Intelbras SIM Next** em distribuições Linux utilizando o **Wine**, garantindo estabilidade, fontes nítidas e aceleração gráfica.

> 📄 **Documentação Técnica Completa:** Para consultar a análise detalhada dos problemas, bibliotecas instaladas, registros alterados e testes de compatibilidade (DXVK/Vulkan), acesse o [**Relatório Técnico (`relatorio.md`)**](./relatorio.md).

---

## 💻 Requisitos do Sistema

- **Sistema Operacional:** Ubuntu 22.04/24.04 LTS, Linux Mint 21/22, Debian 12 ou derivados (`amd64` com arquitetura `i386` habilitada).
- **Pacotes Necessários:** `wine` (8.0+ / 9.0+), `winetricks`, `cabextract`, `p7zip-full`, `wget` e `curl`.

Para instalar as dependências em sistemas baseados em Debian/Ubuntu:

```bash
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install -y wine wine32 wine64 winetricks cabextract p7zip-full wget curl vulkan-tools
```

---

## 📂 Estrutura do Repositório

```text
intelbras-simnext-linux/
├── scripts/                        # Scripts de instalação e otimização
│   ├── instalar_simnext.sh         # Instalação base e correções no prefixo Wine
│   └── otimizar_chip_simnext.sh    # Otimização opcional de GPU (DXVK/Vulkan)
├── .gitignore                      # Ignora binários proprietários, caches e prefixos Wine
├── relatorio.md                    # Documentação técnica detalhada das correções aplicadas
└── README.md                       # Guia rápido do repositório
```

---

## 🚀 Como Instalar e Usar

### 1. Clonar o repositório
```bash
git clone https://github.com/SEU_USUARIO/intelbras-simnext-linux.git
cd intelbras-simnext-linux
```

### 2. Executar a instalação padrão
```bash
chmod +x scripts/*.sh
./scripts/instalar_simnext.sh
```

### 3. Otimização de GPU / Vulkan (Opcional)
Para reduzir o uso de CPU aplicando aceleração gráfica via DXVK (compatível com GPUs integradas e dedicadas):
```bash
./scripts/otimizar_chip_simnext.sh
```

### 4. Iniciar o SIM Next
Execute pelo menu de aplicativos do sistema ou via terminal:
```bash
simnext
```

---

## 🙈 Arquivos Ignorados no Git (`.gitignore`)

Por questões de licenciamento, este repositório **não inclui** o instalador proprietário da Intelbras (`.exe`/`.zip`) nem os arquivos gerados dentro do prefixo Wine (`~/.wine-simnext`).

---

## 🤝 Contribuição e Licença

- **Contribuições:** Sinta-se à vontade para abrir *Issues* ou enviar *Pull Requests* com melhorias.
- **Licença:** Distribuído sob a licença **MIT**.
- **Aviso Legal:** Projeto independente criado pela comunidade. *Intelbras* e *SIM Next* são marcas registradas da **Intelbras S.A.**