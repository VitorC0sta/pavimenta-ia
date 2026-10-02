# Prompt — Retomar Dashcam MVP

Atue como desenvolvedor Flutter e continue o projeto **Pavimenta IA** no workspace atual.

## Objetivo

Finalizar e validar um MVP Android de dashcam que usa a câmera traseira, detecta buracos localmente com `ultralytics_yolo`, captura a foto do frame e grava coordenadas GPS, horário e confiança no armazenamento privado do celular.

## Leia antes de alterar

- `.kiro/specs/dashcam-mvp/requirements.md`
- `.kiro/specs/dashcam-mvp/design.md`
- `.kiro/specs/dashcam-mvp/tasks.md`
- `.kiro/docs/screens/home/README.md`
- `pubspec.yaml`
- `lib/`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/build.gradle.kts`

Confira sempre os arquivos reais; este handoff pode estar desatualizado.

## Estado conhecido

- Estrutura e código Dart do MVP foram criados.
- A tela principal integra `YOLOView`, botão Iniciar/Parar, contador, FPS, permissões, GPS e wakelock.
- A confiança está em `0.5`, o cooldown em 3 segundos e a inferência configurada para aproximadamente 5 FPS.
- O armazenamento grava `occurrences.json` e fotos JPEG no diretório privado do app.
- Dependências estão fixadas no `pubspec.yaml`.
- Permissões Android e `minSdk = 26` foram configurados.
- Nenhum backend faz parte desta etapa.

## Pendências prioritárias

1. Obter e adicionar `assets/models/nome_do_modelo.tflite` com metadados de detecção e classe `buraco` ou `pothole`.
2. Completar os arquivos gerados ausentes do scaffold Flutter Android. Na última auditoria estavam ausentes `.metadata`, `android/gradlew`, `android/gradlew.bat` e `android/gradle/wrapper/gradle-wrapper.jar`. Não invente `android/local.properties`; deixe o Flutter gerar a partir dos SDKs locais.
3. Executar `flutter pub get`.
4. Rodar formatador e análise estática; corrigir erros de API sem trocar silenciosamente o comportamento solicitado.
5. Gerar build debug e testar em um Galaxy S25+ físico.
6. Verificar primeiro, nesta ordem: modelo carregado, GPS com posição, inferência próxima de 5 FPS, foto/JSON gerados e cooldown.

## Restrições

- Mantenha uma única tela e arquitetura simples.
- Não adicione login, mapa, dashboard, configurações, fila offline ou backend.
- Não adicione dependências sem necessidade e use versões exatas.
- Não apague nem sobrescreva trabalho existente para recriar o scaffold.
- Não afirme que compilou ou funcionou no aparelho sem evidência real.
- Preserve as tarefas e atualize `.kiro/specs/dashcam-mvp/tasks.md` ao concluir cada etapa.

Comece inspecionando o estado atual e execute a primeira pendência que puder ser resolvida sem dados externos. Se o modelo ainda não tiver sido fornecido, avance nas validações independentes e informe exatamente o bloqueio restante.
