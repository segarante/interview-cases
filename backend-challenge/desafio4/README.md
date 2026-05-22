# Desafio 4 — Importador de Apólices

API Rails que simula a integração com uma seguradora fictícia, importa apólices e endossos para um banco Postgres, e streama os logs da importação em tempo real para uma tela web.

## Arquitetura (fictícia)

```mermaid
flowchart TB
    subgraph AWS["AWS"]
        direction TB
        subgraph EC2["EC2 - instance"]
            direction TB
            clock["Clock"]
            app["Aplicação Principal"]
            import_service["import_service"]
        end
        subgraph RDS["RDS"]
            postgres[("PostgreSQL")]
        end
    end

    subgraph Seguradoras["Seguradoras externas"]
        direction LR
        not_seg["not_segarante_insurances"]
        outra1["Outras seguradoras"]
        outra2["Outras seguradoras"]
    end

    AWS ~~~ Seguradoras

    clock --> import_service
    import_service --> not_seg

    app --> not_seg
    app --> outra1
    app --> outra2

    app --> postgres
    import_service --> postgres
```

---

## Objetivo do desafio

**Entender os problemas atuais de arquitetura e implementação, e propor um plano de como resolvê-los para suportar os próximos passos da evolução.**

O foco **não** é corrigir pequenos bugs no código existente — é pensar na arquitetura: identificar o que está limitando hoje e desenhar como evoluí-la para atender os novos requisitos descritos abaixo.

### Formato

- **Sessão de live coding**, conduzida junto com o entrevistador.
pl**Você não precisa escrever código.** A entrega esperada é a **discussão da arquitetura**: apontar os problemas, justificar trade-offs e planejar a evolução.
- Se em algum momento quiser ilustrar uma ideia com um trecho de código, fique à vontade — mas isso é opcional e não faz parte do que está sendo avaliado.

---

## Antes de começar

1. Clonar o projeto
2. Subir o Docker
3. Acessar a aplicação no navegador

O projeto implementa, ao mesmo tempo, **o cenário de importação (o problema)** e **uma simulação desse cenário**, junto com outras partes da aplicação rodando simultaneamente. Assim que o Docker sobe, um **clock** começa a disparar jobs periódicos (Sidekiq) que simulam a importação acontecendo **concorrente com o resto da aplicação**".

### Pré-requisitos

- Docker + Docker Compose

### Como rodar

Dentro do diretório `backend/desafio4`:

```bash
docker compose up -d
```

Depois abra **http://localhost:3030/**.

Para parar:

```bash
docker compose down
```

### O que a tela faz

A página mostra um **terminal** que se conecta via WebSocket e exibe, linha a linha em tempo real, os logs gerados pelo clock + jobs de importação e pelos eventos simulados do resto da aplicação.

Existe um painel auxiliar **oculto** que pode ser aberto/fechado com **Ctrl+K** (ou **Cmd+K** no Mac). Ele contém apenas:

- Link para o **Adminer** (inspeção do Postgres).
- Botão **Nuke**: apaga todas as apólices do banco e todos os fixtures gerados — útil para resetar o cenário durante a entrevista.

---

## Cenário atual

- A importação roda em **um worker**.
- Durante a importação, **a aplicação principal fica lenta**. (No teste isso está simplificado, mas na vida real a importação/criação de uma apólice envolve criar dezenas de objetos e arquivos, além de chamadas externas.)
- A importação acontece para **um único cliente em uma única seguradora** — até aqui isso era suficiente para o MVP da importação.
- As seguradoras têm nos mandado **dados sujos**: a IS (importância segurada) está correta, mas os demais dados de **valor e tipo da apólice não são confiáveis**.

---

## Evolução desejada

O que precisa ser suportado daqui pra frente:

1. **Integração com mais 10 seguradoras.**
2. **Multi-tenant** — suportar múltiplos `policy_holders` simultaneamente.
3. **Validação de valores** seguindo regras de negócio: se algum valor estiver inconsistente, **não importar** ou outro fluxo.

---

## Glossário

| Termo | Definição |
|---|---|
| **Policy holder** | O cliente, dono da apólice. |
| **Apólice original** | A primeira apólice de um seguro — a partir dela podem ser emitidos endossos. |
| **LMG** (Limite Máximo da Garantia) | A soma dos valores de todos os endossos. |
| **Insured amount** (Importância Segurada / IS) | O valor que a apólice/endosso está modificando no seguro. |
| **Endorsement** (Endosso) | Uma alteração feita em cima do estado atual do seguro. Uma apólice pode ter vários endossos; o estado atual é sempre o último, como uma pilha. A numeração segue o formato `<apólice original>-<número do endosso>` (ex.: para a apólice original `000123456`, o primeiro endosso é `000123456-1`, o segundo `000123456-2`, e assim por diante). |
