# **🌑 LUNA SEE**
 [A Hardcore Shell RPG running entirely in your terminal.]

ターミナルで動作する、純度100%のBash製ハードコアRPG。

## **⚠️ DISCLAIMER / 免責事項**

This script is a GAME.

The destructive commands (like rm \-rf /) appearing in the game are strictly SIMULATED and purely cosmetic. No actual files will be deleted from your system. However, run this script at your own risk.

本スクリプトはゲームです。

ゲーム内に登場する破壊的なコマンド（rm \-rf / 等）は、すべて\*\*演出（シミュレーション）\*\*であり、実際にあなたのファイルが削除されることはありません。ただし、実行は自己責任で行ってください。

## **📖 Overview**

LUNA SEE is a text-based RPG exploring the concept of "System Administration as Gameplay."

Set in a post-apocalyptic world where humanity is managed by an AI, you connect to a legacy server via Moon Bounce (EME) communication to uncover the truth.

LUNA SEE は、「システム管理」をゲームプレイとして再定義したテキストRPGです。

AIによって管理された終末世界を舞台に、プレイヤーは月面反射通信（EME）を用いてレガシーサーバーへ接続し、その深層を目指します。

### **✨ Features**

* **Pure Bash:**  
  * No dependencies, no ncurses. Just pure shell script magic. Works on TTY, SSH, and even Raspberry Pi.  
  * 依存関係なし、ncurses不要。純粋なシェルスクリプトのみで動作。TTY、SSH、Raspberry Piでも動作します。  
* **Sysadmin Mechanics:**  
  * Combat and exploration are mapped to Linux commands (ls, fsck, mount, kill).  
  * 戦闘や探索などのゲーム要素を、Linuxコマンド（ls, fsck, mount, kill）にマッピングしたシステム管理メカニクスを採用。  
* **Environmental Storytelling:**  
  * Piece together the history through fragmented logs, corrupted emails, and binary dumps.  
  * 断片化されたログ、破損したメール、バイナリダンプなどを読み解き、歴史の真実を繋ぎ合わせる環境ストーリーテリング。  
* **Hacker Aesthetics:**  
  * Simulated packet loss, connection latency, and glitch effects using pure ASCII.  
  * 純粋なASCIIアートとテキスト制御のみで、パケットロス、通信遅延、グリッチエフェクトなどのハッカー的演出を表現。  
* **Save System:**  
  * Custom Base36 encrypted save codes.  
  * Base36エンコードと独自の暗号化ロジックを用いたセーブコードシステム。

## **🚀 Quick Start**

### **Prerequisites / 必要要件**

* **Bash** (4.0+)  
* Standard Linux utilities (grep, sed, openssl, etc.)  
* A terminal (Dark theme recommended)

### **Installation**

\# Clone the repository

git clone https://github.com/jassdack/luna-see.git

\# Move to directory

cd luna-see

\# Give execution permission

chmod \+x luna\_see.sh

\# Run the game

./luna\_see.sh

### **Usage / 使用法**

Run the game with options:
オプションを指定してゲームを実行できます:

```bash
./luna_see.sh [OPTIONS]
```

| Option | Description |
| :--- | :--- |
| `-h, --help` | Show help message / ヘルプを表示 |
| `-SKIP` | Skip intro sequence / オープニングをスキップ |
| `-CODE <code>` | Validate score code / スコアコードを検証 |

## **🎮 How to Play**

You are a Guest User connected to UNSC\_LUNA\_RELAY\_09.

Your goal is to reach the Root Directory (Depth 10).

あなたは UNSC\_LUNA\_RELAY\_09 に接続した ゲストユーザー です。

目的は、システムの最深部である ルートディレクトリ (深度10) に到達することです。

### **Commands / コマンド**

| Command | Description |
| :---- | :---- |
| **ls \-a** | **Explore / 探索** Find logs, items, or enemies in the current directory. 現在のディレクトリを探索し、ログや敵を発見します。 |
| **fsck** | **Repair / 修復** Consumes Log Fragments (EXP) to restore Integrity (HP). ログ断片(EXP)を消費して、整合性(HP)を回復します。 |
| **mount** | **Buff / 強化** Mount virtual partitions to boost stats. 仮想パーティションをマウントし、ステータスを強化します。 |
| **./inventory** | **Item / アイテム** Manage code fragments found during exploration. 探索で発見したコード断片を使用・管理します。 |

### **Stats / ステータス**

* **CPU:** Attack Power (攻撃力)  
* **MEM:** Integrity / Health Points (耐久力)  
* **I/O:** Analysis Speed / Critical Chance (解析・クリティカル率)

## **🛠 Tech Highlights**

For developers and curious minds, this script demonstrates extreme Bash scripting techniques:

開発者や好奇心旺盛な方へ。このスクリプトは、極限のBashスクリプティング技術を実証しています。

* **Bitwise Inventory:**  
  * Inventory management using bitwise operations on a single integer variable to save memory.  
  * ビット演算インベントリ: メモリ節約のため、単一の整数変数に対するビット演算を用いたアイテム管理。  
* **Base36 Encryption:**  
  * A custom save data encoding/decoding system implemented in pure Bash.  
  * Base36暗号化: Pure Bashで実装された、独自のセーブデータエンコード/デコードシステム。  
* **Glitch Effects:**  
  * Text corruption simulation using random ASCII generation via openssl.  
  * グリッチエフェクト: opensslを使用したランダムASCII生成による、テキスト破損シミュレーション。

## **📜 License**

This project is licensed under the GNU General Public License v3.0 (GPLv3).

See the LICENSE file for details.

本プロジェクトは、GNU General Public License v3.0 (GPLv3) の下でライセンスされています。

詳細は LICENSE ファイルを参照してください。

Copyright (C) 2026 **jassdack**

*"The system is going down for halt NOW\!"*
