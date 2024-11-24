# Gerador de resolução personalizada para Linux

 Um script bash para gerenciar facilmente resoluções de exibição personalizadas no Linux usando o XRANDR.

 ## Características

 - Crie resoluções personalizadas com taxa de largura, altura e atualização especificada
 - Ajustar a posição de exibição
 - Remova as resoluções personalizadas
 - Remover ou restaurar bordas negras
 - Configuração automática de inicialização
 - Salvar configurações de resolução anterior

 ## requisitos

 - xrandr
 - cvt
 - Sistema operacional baseado em Linux

 ## Instalação

 1. Clone este repositório:
```bash
git clone https://github.com/yourusername/custom-resolution-for-linux.git
cd custom-resolution-for-linux
chmod +x custom-resolution-br.sh
./custom-resolution-br.sh
```

 ## Argumentos da linha de comando

 Ao criar uma nova resolução o script aceita esses argumentos:

 -`--no-apply`: cria a resolução personalizada, mas não a aplica imediatamente
 -`--apply-on-startup`: configura a resolução personalizada a ser aplicada automaticamente na inicialização do sistema

 Exemplos:
```bash
./custom-resolution-br.sh --no-apply
./custom-resolution-br.sh --no-apply --apply-on-startup
```

 ## Locais de arquivo

 O script gerencia vários arquivos em seu sistema:

 ### Arquivos de configuração
 - Diretório de configuração principal: `~/.config/custom-resolution/`
 - Script de configuração de resolução: `~/.config/custom-resolution/setup.sh`
 - Backup de resolução anterior: `~/.config/custom-resolution/previous_resolution`

 ### Entrada automática
 - Local: `~/.config/autostart/custom-resolution.desktop`
