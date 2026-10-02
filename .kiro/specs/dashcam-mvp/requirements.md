# Requirements — Dashcam MVP

## Contexto

O Pavimenta IA é um protótipo acadêmico Android que usa um celular fixado no para-brisa para substituir, no TCC, um dispositivo dedicado de baixo custo. O processamento e o armazenamento são locais.

## Glossário

- **Sessão**: intervalo entre os comandos Iniciar e Parar.
- **Ocorrência**: detecção aceita com foto, posição, horário e confiança.
- **Cooldown**: intervalo em que novas detecções são ignoradas para evitar duplicação.

## Requisitos funcionais

### RF-01 — Sessão de captura

Quando o usuário tocar em **Iniciar**, o aplicativo deve solicitar as permissões necessárias, abrir a câmera traseira e iniciar a detecção contínua.

Quando o usuário tocar em **Parar** ou o aplicativo sair do primeiro plano, o aplicativo deve encerrar câmera, localização e wakelock.

### RF-02 — Preview e estado

Durante a sessão, o aplicativo deve exibir o preview da câmera traseira, o estado atual, o FPS medido e o total de buracos detectados na sessão.

### RF-03 — Detecção

O aplicativo deve executar um modelo TFLite local por meio de `ultralytics_yolo` e aceitar apenas detecções de buraco com confiança maior ou igual ao limite configurado, inicialmente `0.5`.

### RF-04 — Registro de ocorrência

Quando uma detecção for aceita fora do cooldown, o aplicativo deve salvar:

- foto JPEG do frame detectado;
- latitude e longitude;
- data e horário UTC;
- confiança e nome da classe;
- caminho local da foto.

### RF-05 — Persistência local

O aplicativo deve manter as ocorrências em uma lista JSON no armazenamento privado do app. Nenhum envio de rede deve ocorrer no MVP.

### RF-06 — Cooldown

Após aceitar uma detecção, o aplicativo deve ignorar novas detecções pelo intervalo configurado, inicialmente 3 segundos.

## Requisitos não funcionais

### RNF-01 — Desempenho térmico

A inferência deve ser limitada a aproximadamente 5 FPS para reduzir aquecimento e consumo.

### RNF-02 — Tela ativa

Enquanto a sessão estiver ativa, o aplicativo deve impedir que a tela apague.

### RNF-03 — Plataforma

O MVP deve executar em Android com API mínima 26 e ser validado fisicamente em um Samsung Galaxy S25+.

### RNF-04 — Privacidade

Fotos e posições devem permanecer no diretório privado do aplicativo.

## Fora do escopo

Login, mapa, dashboard, fila offline, configurações, sincronização e backend.

## Suposições

- O modelo é de detecção e contém a classe `buraco` ou `pothole` nos metadados.
- O arquivo do modelo será fornecido como `assets/models/nome_do_modelo.tflite`.
- Um cooldown temporal global é suficiente para o MVP; não haverá rastreamento espacial do mesmo buraco.
