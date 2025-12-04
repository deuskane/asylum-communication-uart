# UART - Module de Communication série

## Sommaire

1. [Introduction](#introduction)
2. [Architecture du Module](#architecture-du-module)
3. [Modules HDL](#modules-hdl)
   - [uart_baud_rate_gen](#uart_baud_rate_gen)
   - [uart_tx_axis](#uart_tx_axis)
   - [uart_rx_axis](#uart_rx_axis)
   - [sbi_UART](#sbi_uart)
4. [Registres CSR](#registres-csr)
5. [Vérification du Composant](#vérification-du-composant)

---

## Introduction

Ce dépôt contient l'implémentation d'un module UART (Universal Asynchronous Receiver-Transmitter) basique avec interface AXI-Stream pour les opérations de transmission (TX) et de réception (RX). 

Le module fournit :
- **Interface AXI-Stream** pour la transmission et réception de données
- **Générateur de débit de baud configurable** permettant des débits personnalisés
- **Enregistrements de configuration et d'état (CSR)** pour contrôler le comportement du UART
- **Support de la parité** (paire ou impaire)
- **Support du contrôle de flux** (CTS/RTS - Clear To Send / Request To Send)
- **Support des interruptions** pour signaler les événements du UART
- **Mode loopback** pour les tests
- **FIFOs configurable** pour les données TX et RX

L'architecture utilise une interface SBI (Simple Bus Interface) pour l'accès aux registres CSR via un processus de génération automatique (regtool).

---

## Architecture du Module

L'architecture générale du module UART est organisée comme suit :

- **sbi_UART** : Wrapper principal qui encapsule :
  - Les modules CSR (Configuration and Status Registers)
  - Le module de génération du débit de baud
  - Le module de transmission (uart_tx_axis)
  - Le module de réception (uart_rx_axis)
  - Les FIFOs pour TX et RX

---

## Modules HDL

### uart_baud_rate_gen

**Description :** Générateur de débit de baud qui produit les signaux de synchronisation (`baud_tick` et `baud_tick_half`) nécessaires pour échantillonner et transmettre les données à la vitesse appropriée.

**Génériques :**

| Générique | Type | Valeur par défaut | Description |
|-----------|------|-------------------|-------------|
| `BAUD_TICK_CNT_WIDTH` | integer | 16 | Largeur du compteur de débit de baud |

**Entrées/Sorties :**

| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk_i` | Entrée | std_logic | Horloge système |
| `arst_b_i` | Entrée | std_logic | Réinitialisation asynchrone active bas |
| `baud_tick_en_i` | Entrée | std_logic | Activation du générateur de débit de baud |
| `cfg_baud_tick_cnt_max_i` | Entrée | std_logic_vector | Valeur maximale du compteur de débit de baud |
| `baud_tick_o` | Sortie | std_logic | Pulse de débit de baud (1 cycle) |
| `baud_tick_half_o` | Sortie | std_logic | Pulse à mi-débit (pour échantillonnage) |

**Fonctionnement :**

1. Lorsque `baud_tick_en_i` passe à '1', le compteur est initialisé à `cfg_baud_tick_cnt_max_i`
2. Le compteur décrémente à chaque cycle d'horloge
3. Lorsque le compteur atteint zéro, un pulse `baud_tick_o` est généré et le compteur est réinitialisé
4. À mi-compte (cfg_baud_tick_cnt_max / 2), un pulse `baud_tick_half_o` est généré pour l'échantillonnage

---

### uart_tx_axis

**Description :** Module de transmission UART avec interface AXI-Stream slave. Accepte les données via l'interface AXI-Stream et les transmet en série sur la ligne `uart_tx_o`.

**Génériques :**

| Générique | Type | Valeur par défaut | Description |
|-----------|------|-------------------|-------------|
| `WIDTH` | natural | 8 | Largeur des données en bits |

**Entrées/Sorties :**

| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk_i` | Entrée | std_logic | Horloge système |
| `arst_b_i` | Entrée | std_logic | Réinitialisation asynchrone active bas |
| `s_axis_tdata_i` | Entrée | std_logic_vector | Données AXI-Stream à transmettre |
| `s_axis_tvalid_i` | Entrée | std_logic | Signal de validité des données |
| `s_axis_tready_o` | Sortie | std_logic | Signal de prêt à recevoir des données |
| `uart_tx_o` | Sortie | std_logic | Ligne de transmission UART |
| `uart_cts_b_i` | Entrée | std_logic | Clear To Send (active bas) |
| `baud_tick_i` | Entrée | std_logic | Pulse de débit de baud |
| `parity_enable_i` | Entrée | std_logic | Activation de la parité |
| `parity_odd_i` | Entrée | std_logic | Sélection parité impaire (1) ou paire (0) |
| `debug_o` | Sortie | uart_tx_debug_t | Signaux de débogage |

**Fonctionnement :**

1. Lorsque `s_axis_tvalid_i` et `s_axis_tready_o` sont tous les deux à '1', les données sont capturées
2. Le module construit le cadre de transmission : START (0) + DATA (8 bits) + PARITY (optionnel) + STOP (1)
3. À chaque pulse `baud_tick_i`, un bit est envoyé sur `uart_tx_o`
4. Le signal `s_axis_tready_o` reste bas pendant la transmission
5. Si `parity_enable_i` est activé, un bit de parité est calculé et inséré avant le bit STOP
6. Le signal `uart_cts_b_i` (Clear To Send) peut suspendre la transmission

---

### uart_rx_axis

**Description :** Module de réception UART avec interface AXI-Stream master. Reçoit les données en série sur la ligne `uart_rx_i` et les fournit via l'interface AXI-Stream.

**Génériques :**

| Générique | Type | Valeur par défaut | Description |
|-----------|------|-------------------|-------------|
| `WIDTH` | natural | 8 | Largeur des données en bits |

**Entrées/Sorties :**

| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk_i` | Entrée | std_logic | Horloge système |
| `arst_b_i` | Entrée | std_logic | Réinitialisation asynchrone active bas |
| `uart_rx_i` | Entrée | std_logic | Ligne de réception UART |
| `m_axis_tdata_o` | Sortie | std_logic_vector | Données AXI-Stream reçues |
| `m_axis_tvalid_o` | Sortie | std_logic | Signal de validité des données |
| `m_axis_tready_i` | Entrée | std_logic | Signal de prêt du récepteur |
| `baud_tick_i` | Entrée | std_logic | Pulse de débit de baud |
| `baud_tick_half_i` | Entrée | std_logic | Pulse à mi-débit (pour échantillonnage) |
| `baud_tick_en_o` | Sortie | std_logic | Activation du générateur de débit de baud |
| `parity_enable_i` | Entrée | std_logic | Activation de la parité |
| `parity_odd_i` | Entrée | std_logic | Sélection parité impaire (1) ou paire (0) |
| `debug_o` | Sortie | uart_rx_debug_t | Signaux de débogage |

**Fonctionnement :**

1. Le module démarre en état IDLE, attendant un front descendant sur `uart_rx_i` (début du bit START)
2. Lors de la détection du front, `baud_tick_en_o` est activé pour lancer le générateur de baud
3. À chaque pulse `baud_tick_i`, un bit est reçu et accumulé
4. Les données sont échantillonnées au milieu de chaque bit (grâce à `baud_tick_half_i`)
5. Après réception du bit STOP, les données sont validées et `m_axis_tvalid_o` est activé
6. Le module attend que `m_axis_tready_i` soit à '1' pour consommer les données
7. Si `parity_enable_i` est activé, la parité est vérifiée

---

### sbi_UART

**Description :** Wrapper principal qui encapsule les modules UART de base avec une interface SBI pour l'accès aux registres CSR. Ce module gère les FIFOs, les interruptions et coordonne tous les sous-modules.

**Génériques :**

| Générique | Type | Valeur par défaut | Description |
|-----------|------|-------------------|-------------|
| `BAUD_RATE` | integer | 115200 | Débit de baud cible en bits/s |
| `CLOCK_FREQ` | integer | 50000000 | Fréquence d'horloge en Hz |
| `BAUD_TICK_CNT_WIDTH` | integer | 16 | Largeur du compteur de débit de baud |
| `UART_TX_ENABLE` | boolean | true | Activer la transmission |
| `UART_RX_ENABLE` | boolean | true | Activer la réception |
| `USER_DEFINE_BAUD_TICK` | boolean | true | Permettre une configuration utilisateur du débit |
| `DEPTH_TX` | natural | 0 | Profondeur de la FIFO TX (0 = pas de FIFO) |
| `DEPTH_RX` | natural | 0 | Profondeur de la FIFO RX (0 = pas de FIFO) |
| `FILENAME_TX` | string | "dump_uart_tx.txt" | Fichier de sortie pour dumper TX (simulation) |
| `FILENAME_RX` | string | "dump_uart_rx.txt" | Fichier de sortie pour dumper RX (simulation) |

**Entrées/Sorties principales :**

| Port | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk_i` | Entrée | std_logic | Horloge système |
| `arst_b_i` | Entrée | std_logic | Réinitialisation asynchrone active bas |
| `sbi_ini_i` | Entrée | sbi_ini_t | Interface SBI initiateur (registres en lecture/écriture) |
| `sbi_tgt_o` | Sortie | sbi_tgt_t | Interface SBI cible |
| `uart_tx_o` | Sortie | std_logic | Ligne de transmission UART |
| `uart_rx_i` | Entrée | std_logic | Ligne de réception UART |
| `uart_cts_b_i` | Entrée | std_logic | Clear To Send (active bas) |
| `uart_rts_b_o` | Sortie | std_logic | Request To Send (active bas) |
| `it_o` | Sortie | std_logic | Signal d'interruption |
| `debug_o` | Sortie | uart_debug_t | Signaux de débogage |

**Fonctionnement :**

1. Le module calcule automatiquement la valeur du compteur de débit de baud à partir des paramètres `CLOCK_FREQ` et `BAUD_RATE`
2. Les registres CSR permettent de configurer :
   - L'activation de TX et RX
   - Les paramètres de parité
   - Le mode loopback
   - Le contrôle de flux (CTS/RTS)
   - Les interruptions
   - La profondeur de la FIFO et son état
3. Les données transmises et reçues passent par les FIFOs (si configurées)
4. Les interruptions peuvent être générées sur des événements spécifiques (FIFO vide, FIFO pleine, etc.)

---

## Registres CSR

Le module UART dispose de plusieurs registres accessibles via l'interface SBI :

| Registre | Adresse | Accès | Description |
|----------|---------|-------|-------------|
| `isr` | 0x0 | RW1C | Interrupt Status Register - État des interruptions |
| `imr` | 0x1 | RW | Interrupt Mask Register - Masque des interruptions |
| `data` | 0x2 | RW | Data FIFO - Données de transmission/réception |
| `ctrl_tx` | 0x4 | RW | Control Register TX - Configuration de la transmission |
| `ctrl_rx` | 0x5 | RW | Control Register RX - Configuration de la réception |
| `baud_tick_cnt_max_lsb` | 0x6 | RW | LSB du compteur de débit (si USER_DEFINE_BAUD_TICK=true) |
| `baud_tick_cnt_max_msb` | 0x7 | RW | MSB du compteur de débit (si USER_DEFINE_BAUD_TICK=true) |

### Champs des Registres de Contrôle

**ctrl_tx** :
- Bit 0 : `tx_enable` - Activation de la transmission
- Bit 1 : `tx_parity_enable` - Activation de la parité
- Bit 2 : `tx_parity_odd` - Sélection parité (0=paire, 1=impaire)
- Bit 3 : `tx_use_loopback` - Mode loopback (entrée RX → sortie TX)
- Bit 4 : `cts_enable` - Activation du contrôle CTS

**ctrl_rx** :
- Bit 0 : `rx_enable` - Activation de la réception
- Bit 1 : `rx_parity_enable` - Activation de la parité
- Bit 2 : `rx_parity_odd` - Sélection parité (0=paire, 1=impaire)
- Bit 3 : `rx_use_loopback` - Mode loopback (entrée TX → sortie RX)
- Bit 4 : `rts_enable` - Activation du contrôle RTS

**isr** (Bits 3:0) :
- Bit 0 : Interruption TX
- Bit 1 : Interruption RX
- Bit 2 : Interruption FIFO TX pleine
- Bit 3 : Interruption FIFO RX pleine

**imr** (Bits 3:0) :
- Masque pour les interruptions correspondantes

---

## Vérification du Composant

### Organisation du Projet FuseSoC

Le projet utilise FuseSoC pour la gestion des fichiers et la simulation. Le fichier `uart.core` à la racine du projet définit :

**Targets disponibles :**
- `default` : Cible par défaut incluant les fichiers RTL et la génération CSR

**Générateurs :**
- `gen_csr` : Génère automatiquement les registres CSR à partir du fichier `hdl/csr/UART.hjson` en utilisant l'outil `regtool`

**Dépendances :**
- `asylum:utils:pkg` - Paquet d'utilitaires
- `asylum:system:GIC` - Contrôleur d'interruptions

### Génération des Registres CSR

Les registres CSR sont définis dans le fichier `hdl/csr/UART.hjson` et sont générés automatiquement en fichiers VHDL et C :

**Fichiers générés :**
- `hdl/csr/UART_csr.vhd` - Enregistrements CSR en VHDL
- `hdl/csr/UART_csr.h` - Définitions des registres en C
- `hdl/csr/UART_csr_pkg.vhd` - Paquet VHDL avec les types et constantes

Cette approche permet une gestion cohérente des registres entre le firmware et le HDL.

### Debugging et Validation

Le module fournit des signaux de débogage exportés via le port `debug_o` de type `uart_debug_t` qui incluent :

- **uart_tx** : État de la machine d'état TX
- **uart_rx** : État de la machine d'état RX, compteur de bits, signal baud_tick_half

Ces signaux peuvent être utilisés dans une simulation pour valider le comportement du module.
