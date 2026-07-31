# Phase 13: Seleção de Arquivos Android & Importação Real de EPUB — Context

## Decisions

- A Fase 13 redefine o trabalho anteriormente reservado para telemetria: seu foco será permitir seleção de arquivos no Android e importação real de EPUB.
- A plataforma prioritária é Android, usando o seletor nativo de arquivos do sistema.
- O único formato aceito nesta fase é `.epub`; PDF e TXT ficam para uma fase posterior.
- O usuário deve conseguir selecionar um EPUB armazenado em qualquer pasta acessível pelo seletor do Android.
- A implementação deve reutilizar o parser EPUB, a pipeline de leitura e os modelos de documento já existentes, substituindo o EPUB simulado atual.
- A aplicação não deve solicitar permissão ampla de armazenamento quando o seletor nativo puder conceder acesso ao arquivo escolhido.

## The Agent's Discretion

- Escolher a biblioteca Flutter de seleção de arquivos compatível com o projeto e o fluxo de URI/bytes do Android.
- Definir se a leitura será feita diretamente dos bytes selecionados ou por uma abstração de fonte de documento.
- Definir a camada de validação de extensão, tamanho, ZIP/EPUB inválido e mensagens de erro.
- Definir a melhor organização da UI para o botão de importar, estado de carregamento e seleção de capítulo.
- Adicionar testes unitários, de widget e de integração adequados ao que puder ser executado no ambiente local.

## Deferred Ideas

- Importação de PDF e TXT.
- Biblioteca persistente de vários livros.
- Retomada de posição de leitura entre sessões.
- Telemetria quantitativa e benchmark de livros reais.
- Correção fonética/acentuação do motor TTS.
- Suporte equivalente para iOS, desktop e web.

## Phase Boundary

This phase delivers a real Android EPUB selection and parsing path through chapter selection into the existing reading pipeline. It does not implement a persistent library, other document formats, phonetic improvements, or benchmark automation.
