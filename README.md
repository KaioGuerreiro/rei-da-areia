# Rei da Areia

> Projeto semestral desenvolvido para a disciplina de **Jogos Digitais II** (2º bimestre de 2026/2)  
> **Instituição:** Centro Universitário da Grande Dourados (UNIGRAN)  
> **Professor:** Ezéfferth C. A. Fernandes  
> **Autor:** Kaio Guerreiro  
> **Jogue Online:** [https://kaioguerreiro.itch.io/rei-da-areia](https://kaioguerreiro.itch.io/rei-da-areia)

---

## 📜 1. A Carta do Jogo

Conforme os sorteios e definições estabelecidos no documento do projeto:

| Elemento | Definição | Descrição no Projeto |
| :--- | :--- | :--- |
| **Tema** | Sorteado (único na turma) | **Praia & Caranguejos** (Sobrevivência na areia contra a colônia de crustáceos) |
| **Tipo de Jogo** | Sorteado | **Arena / Combate** (Sobreviver à horda de caranguejos e atingir 50 abates) |
| **Modo** | Escolha do aluno | **Horda (Arena vista de cima, 4 direções, sem gravidade, resolução HD 1280×720)** |

---

## 🎮 2. Como Jogar

O objetivo do jogador é defender a praia contra as ondas crescentes de caranguejos que emergem dos quatro nascedouros da arena e atingir a meta de **50 caranguejos abatidos** para conquistar a vitória. O ataque do jogador acerta inimigos ao redor em **360°**. Se a vida do jogador chegar a zero, a partida é perdida.

### Controles
| Ação | Teclas |
| :--- | :--- |
| **Movimentação** | <kbd>W</kbd> <kbd>A</kbd> <kbd>S</kbd> <kbd>D</kbd> ou Setas (<kbd>↑</kbd> <kbd>←</kbd> <kbd>↓</kbd> <kbd>→</kbd>) |
| **Correr** | Segurar <kbd>Shift</kbd> |
| **Atacar** | <kbd>Espaço</kbd>, <kbd>J</kbd> ou <kbd>Botão Esquerdo do Mouse</kbd> |
| **Reiniciar Partida** | <kbd>Enter</kbd> ou botão na tela de vitória/derrota |

---

## 📅 3. Cronograma de Aulas e Tags

O projeto acompanha rigorosamente as entregas e marcos definidos no plano de ensino:

| Aula | Data | Conteúdo / Entregas | Tag Git |
| :--- | :---: | :--- | :---: |
| **08** | 07/10 | Cenário de praia visto de cima com muros de colisão e personagem que anda nas 4 direções | `aula-08` |
| **09** | 21/10 | Sistema de vida, dano, área de ataque, HUD e fluxo de vitória/derrota | `aula-09` |
| **10** | 28/10 | Inimigo com máquina de estados que contorna obstáculos via NavigationRegion2D/A* e clarão de ataque | `aula-10` |
| **11** | 04/11 | Arte do tema no lugar dos retângulos, sistema de horda progressiva com spawners e otimização a 60 FPS | `aula-11` |
| **12** | 11/11 | Jogo exportado, rodando fora da Godot, empacotamento .pck e página de apresentação publicada | `aula-12` |
| **13** | 18/11 | Apresentação em sala de aula e publicação no itch.io | `entrega-final` |

---

## 📦 4. Execução do Jogo Exportado e Publicação

- **Jogar no Navegador (itch.io):** [https://kaioguerreiro.itch.io/rei-da-areia](https://kaioguerreiro.itch.io/rei-da-areia)
- **Web (export local):** `builds/web/index.html`, `builds/web/index.pck` e pacote `builds/web/index.zip`
- **Windows:** `builds/windows/rei-da-areia.pck`
- **Página de Apresentação:** `docs/index.html`

### Como executar no Windows:
```bash
godot --main-pack builds/windows/rei-da-areia.pck
```

### Como executar os testes de referência (aulas anteriores):
```bash
# Testes de combate e vitória/derrota:
godot --headless -s scripts/test_combat.gd

# Testes de navegação e A* (Aula 10):
godot --headless -s scripts/test_navigation.gd

# Testes da horda (Aula 11):
godot --headless -s scripts/test_horde.gd
```

---

## 🎨 5. Origem da Arte e Licenças (Regra 2)

Todas as artes visuais utilizadas no projeto respeitam o uso educacional e livre:
1. **Crab Sprite Sheet (Inimigos):**
   - Autor: GrafxKid / Licença CC0 (Domínio Público).
   - Spritesheet com animações completas de Idle, Caminhada, Ataque, Dano e Morte.
2. **Character Sheet 16x16 (Protagonista):**
   - Sprite sheet transparente de herói 2D em 4 direções.
   - Licença livre para uso educacional / não-comercial.
3. **Tileset Praia (Cenário):**
   - Conjunto de tiles litorâneos (areia, mar, bordas, vegetação e rochas).
   - Licença CC0.

---

## 💻 6. Citação de Origem do Código e IA (Regras 1 e 6)

- **Engine:** [Godot Engine 4.7.2](https://godotengine.org/) (Licença MIT).
- **Roteiros de Prática:** Implementado com base nos roteiros de aula 08, 09 e 10 da disciplina de Jogos Digitais II (Prof. Ezéfferth C. A. Fernandes).
- **Assistência de IA:** O desenvolvimento, simplificação de scripts, estruturação dos testes automatizados e empacotamento contaram com apoio de inteligência artificial (assistente Antigravity / Gemini), conforme permitido e orientado na Seção 6 do documento de diretrizes do projeto.
