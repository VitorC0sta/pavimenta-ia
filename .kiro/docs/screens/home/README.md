# Tela principal — Dashcam

## Objetivo

Permitir que o celular fique fixo no para-brisa, exiba a câmera traseira e detecte buracos em tempo real durante uma sessão.

## Implementação

Arquivo principal: `lib/screens/home_screen.dart`.

## Layout

1. App bar com o título **Pavimenta IA**.
2. Área principal com preview da câmera traseira e overlays produzidos pelo `YOLOView`.
3. Indicador sobre o preview com o estado da captura/modelo.
4. Card **Buracos na sessão**.
5. Card **Inferência**, em FPS.
6. Botão único **Iniciar/Parar**.

## Estados

| Estado | Preview | Botão | Mensagem esperada |
|---|---|---|---|
| Parado | Placeholder “Câmera parada” | Iniciar | Pronto para iniciar |
| Preparando | Placeholder | Desabilitado | Verificando permissões |
| Carregando modelo | Câmera/loader do plugin | Parar | Carregando modelo |
| Capturando | Câmera traseira | Parar | Detectando buracos |
| Ocorrência salva | Câmera traseira | Parar | Confiança da detecção salva |
| Erro | Conforme o estágio | Iniciar ou Parar | Mensagem curta e acionável |

## Fluxo ao iniciar

1. Solicitar câmera.
2. Verificar se o GPS está ligado e solicitar localização.
3. Iniciar o stream de localização.
4. Ativar o wakelock.
5. Montar o `YOLOView` com câmera traseira e modelo `assets/models/nome_do_modelo.tflite`.
6. Limitar inferência e callback a aproximadamente 5 FPS.

## Fluxo de uma ocorrência

1. Receber resultados do YOLO.
2. Aceitar apenas classes `buraco` ou `pothole` com confiança maior ou igual a `0.5`.
3. Aplicar cooldown global de 3 segundos.
4. Capturar o frame atual com overlays.
5. Obter a posição GPS mais recente, preferindo cache de até 10 segundos.
6. Gravar JPEG e metadados JSON no diretório privado do app.
7. Incrementar o contador da sessão.

## Regras

- Parar a sessão ao enviar o app para segundo plano.
- Desativar wakelock e localização ao parar ou destruir a tela.
- Não enviar dados para backend neste MVP.
- O contador é reiniciado no início de cada sessão; os registros em disco não são apagados.
- Os nomes de classe aceitos devem corresponder aos metadados do modelo.

## Critérios de aceite

- A câmera traseira aparece após conceder permissões.
- O status confirma o carregamento do modelo sem erro.
- O FPS observado fica próximo de 5, sem inferência irrestrita.
- Uma detecção válida gera exatamente uma foto e um item no JSON durante o cooldown.
- O item salvo contém horário UTC, latitude, longitude, confiança, classe e caminho da foto.
- Ao tocar em **Parar**, câmera, localização e wakelock são encerrados.
