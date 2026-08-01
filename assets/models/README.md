# Modelos Neural VITS em Português do Brasil (ONNX)

Este diretório armazena os modelos acústicos de síntese de voz neural no formato ONNX otimizados para execução local em dispositivos móveis (Edge Computing).

## Arquivos Esperados para o Sherpa-ONNX em Produção:
- `vits-piper-pt_BR-faber-medium.onnx` ou `model.onnx` (Modelo VITS quantizado em INT8/FP32).
- `tokens.txt` (Dicionário de tokens de texto/fonemas do modelo).
- `lexicon.txt` (Opcional - Dicionário fonético de mapeamento).

O diretório `espeak-ng-data/` também é obrigatório para esta voz Piper. Ele deve
ser mantido completo; a aplicação o copia recursivamente para o armazenamento
local antes de inicializar o Sherpa-ONNX.

## Download do Modelo PT-BR Recomendado:
Os modelos oficiais pré-treinados em Português do Brasil (`pt_BR`) podem ser baixados em:
https://github.com/k2-fsa/sherpa-onnx/releases
