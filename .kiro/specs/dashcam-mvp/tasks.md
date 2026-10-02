# Tasks — Dashcam MVP

- [x] 1. Criar a estrutura Flutter e os arquivos Android principais.
- [x] 2. Fixar dependências e declarar assets/permissões.
- [x] 3. Implementar configuração, modelo de ocorrência e serviços.
- [x] 4. Implementar a tela principal e integrar câmera, YOLO, GPS, armazenamento e wakelock.
- [x] 5. Criar documentação de tela e handoff em `.kiro/`.
- [ ] 6. Adicionar `assets/models/nome_do_modelo.tflite` com metadados e classe compatível.
- [ ] 7. Restaurar os arquivos gerados ausentes do scaffold Flutter Android (`.metadata`, scripts/JAR do Gradle wrapper e configuração local gerada pelo Flutter).
- [ ] 8. Executar `flutter pub get` e corrigir qualquer incompatibilidade do SDK/pacotes.
- [ ] 9. Executar `dart format`, `flutter analyze` e um build Android de depuração.
- [ ] 10. Validar no Galaxy S25+: modelo, permissões, GPS, foto/JSON, cooldown, wakelock e FPS.
- [ ] 11. Fazer teste veicular controlado e registrar falsos positivos, falsos negativos e temperatura.

## Definição de pronto

O MVP estará pronto quando compilar, instalar no S25+, manter inferência próxima de 5 FPS e gerar ocorrências locais completas sem duplicações dentro do cooldown.
