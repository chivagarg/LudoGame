# Ludo Mirchi

A spicy twist on the classic board game of Ludo — built for iOS/iPadOS.

---

## Table of Contents

1. [Overview](#overview)
2. [Game Modes](#game-modes)
3. [Setup](#setup)
4. [Core Rules (Classic Ludo)](#core-rules-classic-ludo)
5. [Mirchi Mode Rules](#mirchi-mode-rules)
6. [Pawn Tiers & Abilities](#pawn-tiers--abilities)
   - [Classic Pawns (Tier 0)](#classic-pawns-tier-0)
   - [Level 1 Pawns (Tier 1)](#level-1-pawns-tier-1)
   - [Level 2 Pawns (Tier 2)](#level-2-pawns-tier-2)
7. [Boost System](#boost-system)
8. [Scoring](#scoring)
9. [End of Game & Coin Rewards](#end-of-game--coin-rewards)
10. [Pawn Unlocks & Economy](#pawn-unlocks--economy)
11. [Safe Zones & Trap Zones](#safe-zones--trap-zones)
12. [Restrictions & Edge Cases](#restrictions--edge-cases)
13. [AI Players](#ai-players)

---

## Overview

Ludo Mirchi is a 2–4 player board game based on traditional Ludo. Each player controls four pawns and races them from their starting home base around the board and into their finishing home column. The first player to get all four pawns home wins — but with Mirchi Mode and special pawn abilities, there are many ways to sabotage, protect, and outsmart your opponents.

---

## Game Modes

| Mode | Description |
|---|---|
| **Classic** | Standard Ludo rules. No backward moves. Pawn boosts are still active if chosen. |
| **Mirchi** | Each player gets **5 Mirchi moves** — the ability to move a pawn *backwards* instead of forwards on their turn. Adds a significant strategic layer. |

---

## Setup

- **2–4 players** are supported (Red, Green, Yellow, Blue).
- Each player chooses a **pawn** (character) from their available roster. The pawn choice determines which boost ability, if any, that player uses for the game.
- Any player can be designated as a **robot (AI)**, which plays automatically.
- Each player starts with **4 pawns** sitting in their home base (the coloured corner).

---

## Core Rules (Classic Ludo)

### Rolling the Dice

- Players take turns rolling a single six-sided die.
- **A roll of 6** is required to bring a pawn out of the home base onto the starting position on the path.
- **When all of a player's remaining pawns are still at home**, the game gives a **boosted ~33% chance** of rolling a 6 (instead of the standard ~16.7%) to prevent players from being stuck indefinitely.
- In **Classic Mode**, if only one eligible pawn can move, it is auto-moved after a short delay.

### Moving Pawns

- On each turn, the player moves one eligible pawn forward by the number shown on the dice.
- A pawn is **eligible** to move if:
  - It is already on the path, and the dice roll does not overshoot the home column finish; or
  - It is at home and the dice shows a 6.
- A pawn **cannot** move if the roll would take it past the final home tile (exact or shorter rolls required to finish).

### Extra Turns

A player gets an **additional roll** in the following situations:
- They roll a **6** (regardless of what happens with the pawn).
- They **capture an opponent's pawn**.
- A pawn **reaches the finishing home tile**.

### Capturing

- If a player's pawn lands on a square occupied by an **opponent's pawn** (and the square is not a safe zone), the opponent's pawn is **captured** and sent back to its home base.
- The capturing player earns **3 points** and gets an extra turn.
- **First blood** — the very first capture of the game — earns the capturing player an additional **+3 bonus points** on top of the standard capture points.

### Winning

- The game ends when only one active player has not yet completed all of their pawns.
- All four pawns must reach a player's **finishing home tile** to complete.
- Final rankings are determined by **score** (see Scoring section), not just by finishing order.

---

## Mirchi Mode Rules

Mirchi Mode adds the ability to move pawns **backwards** using "Mirchi moves".

### Mirchi Moves

- Each player starts with **5 Mirchi moves** for the entire game.
- On their turn, instead of moving a pawn forward, the player may choose to move it **backwards** by the number shown on the dice.
- The mirchi tile/button in the player panel activates this option. It is only selectable by the **current player on their turn**.
- The number of remaining Mirchi moves is shown on the mirchi button badge.

### Backward Move Restrictions

A backward move is **only legal** if all of the following conditions are met:
1. The pawn is **on the path** (not at home, and not finished).
2. The player has **at least 1 Mirchi move remaining**.
3. The pawn is **not currently in a safe zone** (coloured home approach lanes).
4. The backwards move would **not take the pawn past the start of the path** (negative index is illegal).

### Capturing Backwards

- A backward move **can** still capture an opponent's pawn if the pawn lands on an opponent-occupied square.
- Captures via backward moves still award **3 points** and an extra turn.

### Auto-Move in Mirchi Mode

- In Mirchi Mode, the game **does not auto-move** a single eligible pawn — even if only one pawn could physically move — because the player always has the option to go backwards instead. The player must always explicitly tap.

---

## Pawn Tiers & Abilities

Pawns are organised into three tiers. Higher tiers require unlocking and have more powerful abilities.

### Classic Pawns (Tier 0)

Standard marble pawns. No special ability. Always available to all players.

| Colour | Pawn Name |
|---|---|
| Red | Classic Red |
| Green | Classic Green |
| Yellow | Classic Yellow |
| Blue | Classic Blue |

### Level 1 Pawns (Tier 1)

Each Level 1 pawn has **1 use** of its boost ability per game.

| Pawn | Ability | Description |
|---|---|---|
| 🍅 **Lal Tomato** (Red) | Extra Backward Move | Gain 1 additional hop backwards — giving you a total of 6 Mirchi moves for the game. |
| 🥭 **Mango Tango** (Yellow) | Roll a 6 | Instantly force your dice to show a 6, usable once. Consume on tap; no need to tap a pawn afterwards. |
| 🫑 **Shimla Shield** (Green) | Place Safe Zone | Place 1 custom safe zone on any eligible empty square on the board. Pawns of any colour cannot be captured on that square. |
| 🍆 **Bombergine** (Blue) | Deploy Trap | Place 1 trap on any eligible empty square. Any pawn — including your own — that lands on it is sent home. |

### Level 2 Pawns (Tier 2)

Each Level 2 pawn has **2 uses** of its boost ability per game.

| Pawn | Ability | Description |
|---|---|---|
| 🫀 **Anar Kali** (Red) | Extra Backward Moves | Gain 2 additional hops backwards — giving you a total of 7 Mirchi moves for the game. Can be used twice. |
| 🍍 **Pina Anna** (Yellow) | Roll a 6 (×2) | Force a 6 twice in the same game. Consume on tap each time. |
| 🍉 **Tarboozii** (Green) | Place Safe Zones (×2) | Place up to 2 custom safe zones on the board. |
| 🫐 **Jamun** (Blue) | Deploy Traps (×2) | Deploy up to 2 traps on the board. |

---

## Boost System

### State Machine

Each player's boost has three states:

| State | Meaning |
|---|---|
| **Available** | The boost has charges remaining and can be activated. |
| **Armed** | The boost has been tapped and is primed to fire on the next relevant action. The button shows an animated marching lights border. |
| **Used** | All charges are exhausted; the boost cannot be used again this game. |

### How Boosts Are Consumed

- **Mango / Pina Anna (reroll to 6):** Consumed immediately on tap. The dice is forced to 6 instantly; no extra pawn tap required.
- **Lal Tomato / Anar Kali (extra backward move):** Armed on tap. Consumed only when the player **actually performs a backward move** with that boost armed. Arming and then moving forwards does not consume the charge.
- **Shimla Shield / Tarboozii (safe zone):** Armed on tap. Consumed when the player **taps an eligible board cell** to place the safe zone. Moving a pawn normally while armed does not consume it.
- **Bombergine / Jamun (trap):** Armed on tap. Consumed when the player **taps an eligible board cell** to deploy the trap.

### Restrictions on Boost Deployment (Safe Zone & Trap)

A cell is **ineligible** for safe zone or trap placement if:
- It is already a **safe zone** (board stars, colour home approach lanes, or a previously placed custom safe zone).
- It is a **starting position** (the coloured home base corner areas).
- It **already has a trap** deployed on it.
- It is **currently occupied by any pawn**.

---

## Scoring

Points accumulate throughout the game and determine final rankings.

| Event | Points |
|---|---|
| Capture an opponent's pawn | **+3 pts** |
| First capture of the game (First Blood) | **+3 bonus pts** (in addition to the capture pts) |
| Pawn reaches the finishing home tile | **+10 pts** |
| First player to finish all 4 pawns | **+35 pts** |
| Second player to finish all 4 pawns | **+20 pts** |
| Third player to finish all 4 pawns | **+10 pts** |
| Fourth player to finish (or never finishes) | **+0 pts** |

### End-of-Game Bonus Points (awarded on the Game Over screen)

| Achievement | Bonus |
|---|---|
| **Top Kills** — most opponent captures in the game | **+5 pts** |
| **Unluckiest** — lowest average dice roll across the game | **+5 pts** |

If multiple players tie for either of these achievements, all tied players receive the bonus.

Final rankings are determined by the **total score** after all bonuses are applied.

---

## End of Game & Coin Rewards

- When the last active player's game concludes, the **Game Over screen** is shown.
- The **winner's total score** is awarded as **coins** to the player's permanent coin balance.
  - For example, a winning score of 87 pts earns 87 coins.
- This coin balance persists across games and is used to unlock new pawns.

---

## Pawn Unlocks & Economy

### Earning Coins

- Coins are earned at the end of each game equal to the **winner's final score**.
- Coins are stored permanently in the app.

### Free Unlocks

- When your coin balance reaches the **2,500 coin threshold**, the next pawn in the progression is automatically unlocked and deducted from your balance.
- The free unlock order (progression) is:
  1. Red Tomato
  2. Yellow Mango
  3. Green Capsicum
  4. Blue Aubergine
  5. Red Anar
  6. Yellow Pineapple
  7. Green Watermelon
  8. Blue Jamun

### Purchase Unlocks

- Any locked pawn can be **purchased directly** at any time, regardless of progression order.
- Coins are purchasable in increments of **1,000 coins for $0.99 USD** each.
- The app calculates how many coin increments are needed to cover the unlock cost and displays the total price dynamically.
- After purchase, the coin balance increases by the purchased amount, then the unlock cost is deducted, and the pawn becomes available immediately.
- Purchase unlocks are **independent** — unlocking Anar Kali does not require unlocking Red Tomato first.

### Pawn Costs

All pawns currently cost **2,500 coins** to unlock. Per-pawn pricing is configurable.

---

## Safe Zones & Trap Zones

### Built-in Safe Zones

The board has several permanent safe squares where pawns **cannot be captured**:

- Each player's **5-square coloured home approach lane** (the lane leading into the finish).
- Each player's **finishing home tile**.
- Each player's **starting position** (the square where pawns first enter the path after rolling a 6).
- **Four star squares** at fixed positions around the board.

### Custom Safe Zones

- Green family pawns (Shimla Shield, Tarboozii) can place **additional safe zones** on any eligible empty non-safe square during their turn.
- Custom safe zones are **permanent for the rest of the game** and protect pawns of **all colours**.
- A backward move cannot originate from a safe zone.

### Trap Zones

- Blue family pawns (Bombergine, Jamun) can place **traps** on any eligible empty non-safe square.
- Any pawn — **including the trap owner's own pawns** — that lands on a trap is immediately sent back to its home base.
- Landing on a trap **ends that player's turn** with no bonus roll.
- Traps cannot be placed on safe zones, other traps, occupied squares, or home base corners.

---

## Restrictions & Edge Cases

| Rule | Detail |
|---|---|
| Overshooting home | A pawn cannot move if the roll would take it past the finish tile. The exact roll (or less) is required. |
| Backward from start | A backward move cannot take a pawn to a negative path index (below the starting position). |
| Backward from safe zone | Backward moves are forbidden while the pawn is in any safe zone. |
| Rolling 6 with no eligible pawns | If no pawns can take advantage of a 6 (e.g. all at home and a 6 would cause overshoot — which cannot happen at home), the turn advances. |
| Boost during opponent's turn | Boosts can only be armed or fired on **your own turn**. |
| Mirchi button during opponent's turn | The mirchi tile is **only interactive** for the current active player. Other players cannot tap it during someone else's turn. |
| AI and boosts | Boost buttons cannot be manually armed by the player when an AI controls that colour. The AI manages its own strategy. |
| Multiple simultaneous finishes | The game ends as soon as only **one player** has not yet finished all their pawns. That player is ranked last. |

---

## AI Players

- Any player slot can be set to **Robot** in the player selection screen.
- AI players roll automatically after a short thinking delay (~1 second).
- AI movement decisions are handled by a pluggable strategy (`AILogicStrategy`), which selects a pawn and optionally a backward move direction.
- When an AI chooses a backward (Mirchi) move, the mirchi arrow indicator is shown briefly in the UI before the pawn moves.
- AI players do **not** manually arm boosts — boost decisions are integrated into the AI strategy directly.
