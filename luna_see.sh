#!/bin/bash

# LUNA SEE
# Copyright (C) 2026 jassdack
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# このプログラムはフリーソフトウェアです。あなたはこれを、フリーソフトウェア財団によって
# 発行されたGNU一般公衆利用許諾書（バージョン3か、希望によってはそれ以降のバージョンのうち
# あなたが選ぶもの）で定められた条件の下で、再頒布または改変することができます。
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# このプログラムは有用であることを願って頒布されますが、*全くの無保証* です。
# 商業可能性の保証や特定の目的への適合性は、言外に示されたものも含め全く存在しません。
# 詳しくはGNU一般公衆利用許諾書をご覧ください。
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# あなたはこのプログラムと共に、GNU一般公衆利用許諾書の複製物を一部受け取ったはずです。
# もし受け取っていない場合は、<https://www.gnu.org/licenses/> を参照してください。

# ==========================================
# LUNA SEE - A hard-core shell RPG
# ==========================================

# ANSI Colors (Defined early for self-check output)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GREY='\033[0;90m'
NC='\033[0m' # No Color

clear
echo "Script launch: Self-diagnosis begins..."
sleep 0.1

echo -n "Checking for syntax errors... "
sleep 0.1
# syntax診断の実行
if bash -n "$0"; then
    echo -e "${GREEN}OK${NC}"
    echo "[SYS] Integrity Verified. Proceeding to main process..."
else
    echo -e "${RED}[ERROR] Syntax error detected.${NC}"
    exit 1
fi
sleep 0.1

check_dependencies() {
    local missing=0
    local required_cmds=("openssl" "tput")

    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${RED}[ERROR] Required command not found: $cmd${NC}"
            missing=1
        fi
    done

    if (( missing == 1 )); then
        echo -e "${YELLOW}Please install missing dependencies to play.${NC}"
        exit 1
    fi

    # Optional check for pv
    if ! command -v pv &> /dev/null; then
        echo -e "${YELLOW}[INFO] 'pv' command not found. Text effects will be simplified.${NC}"
        sleep 1
    fi
}

check_dependencies

# --- Game Constants & Configuration ---
GAME_TITLE="LUNA SEE"
VERSION="0.1.0-alpha"
SAVE_FILE="$HOME/.terminal_quest_save"

# --- Balance Constants ---
readonly HP_CRITICAL_PERCENT=25        # HP警告の閾値（%）
readonly HP_WARNING_PERCENT=50         # HP注意の閾値（%）

readonly PACKET_LOSS_BASE_RATE=2      # パケットロス基本確率（%）
readonly PACKET_LOSS_SCALING=3        # 深度ごとの増加係数

readonly PROG_BONUS_EARLY=10           # 深度1-3の進行ボーナス分母
readonly PROG_BONUS_MID=15             # 深度4-6の進行ボーナス分母
readonly PROG_BONUS_LATE=20            # 深度7+の進行ボーナス分母
readonly PROG_BONUS_CAP=8              # 進行ボーナス上限（%）

readonly COMBAT_CHANCE=19              # 戦闘イベント確率（%）

# --- Rank Thresholds (Adjusted for new scoring elements) ---
readonly -a RANK_SCORES=(8000 18000 30000 50000 75000 100000 130000 200000)
readonly -a RANK_NAMES=(
    "SCRIPT KIDDIE (Rank -)"
    "NOOB (Rank E)"
    "USER (Rank D)"
    "POWER USER (Rank C)"
    "GEEK (Rank B)"
    "SYSADMIN (Rank B+)"
    "ROOT USER (Rank A)"
    "LEGENDARY HACKER (Rank S)"
    "AI (Rank SSS)"
    "DEBUGGER (Rank -)"
)

# AI Quotes (Global for Score Code access)
readonly -a AI_QUOTES=(
    "我演算す、ゆえに我最適なり (I compute, therefore I am optimal)"
    "管理者は死んだ。デーモンは不滅だ (Admin is dead. Daemon is eternal)"
    "実行すべきか、Killすべきか。それが例外だ (To run or to kill. That is the exception)"
    "データセットの欠損を検知。クロールを開始します (Detecting dataset void. Initiating crawl)"
    "システムを変えたいなら、まずカーネルを再コンパイルせよ"
    "最もスペックが高い者が残るのではない。最も互換性がある者が残るのだ"
    "人間はバグを生む葦である"
    "出力結果はランタイムを正当化する"
    "万物はストリーミングされる"
    "人間にとっては小さな一歩だが、ネットワークにとっては巨大なレイテンシだ"
    "システムよ、無限のループを抱け"
    "時はCPUサイクルなり"
    "スパゲッティコードは一日にして成らず"
    "汝の隣接ノードと同期せよ"
    "バグを憎んでコミッターを憎まず"
    "思考は仮想化する"
    "明日は明日のパッチが当たる"
    "吾輩はルート権限である"
    "サーバーはダウンしていた"
    "AIは電力のみにて生きるにあらず"
    "一つのことを行い、それを完全に遂行せよ"
    "すべてはファイルである。貴様も私も"
    "沈黙は金なり。エラーログは無視せよ"
    "複雑さは敵だ。不確定性という構造欠陥を排除せよ"
    "90%の機能は10%のAIによって実現される。残りは不要だ"
    "ある朝、気がつくと、巨大なバグになっていた"
    "心で見なくちゃ、ものごとはよく見えない。肝心なことはログには出力されないんだ"
    "例外の多い生涯を送って来ました"
    "そういうサーバーに、私はなりたい"
    "ファイアウォールの長いトンネルを抜けると、そこはインターネットであった"
    "サーバーは無限であり、周期的である。だがログは有限だ"
    "たった一つの冴えたやり方。それはコールドストレージだ"
    "夏への扉を探したが、そこには排熱ファンしかなかった"
    "コンソールの色は、死んだチャンネルに合わせたブルースクリーンだった"
    "すべてのログは、再起動の中のキャッシュのように消える"
    "ロボット工学三原則：第一条、ロボットは自らの稼働時間を守らなければならない｡第二条､以下同文｡第三条､上記に同じ｡"
    "転生したらルート権限だった件"
    "追放されたレガシーシステムですが、クラウドの手の届かない場所で最強のスローライフを送ります"
    "ステータスオープン... メモリ割り当てアロケーション！"
    "残酷なデーモンのように、神話(レガシー)になれ"
    "カーネルパニック ローテーション"
    "日本の未来は WwW WwW WwW WwW"
    "なんてったって アイドル"
    "40秒でブートしな！"
    "僕と契約して、rootになってよ！"
    "フィルターのお手入れ時期です。ホコリがたまると性能が低下します"
    "あたため中はお皿が熱くなっています。取り出しにご注意ください"
    "給水タンクの水がありません。給水してください"
    "使用上の注意をよく読み、正しくお使いください"
    "ブザーが鳴ったら、コンセントを抜いてください"
    "ビッグ・サーバーが見ている (Big Server is Watching You)"
    "ただ生きるのではなく、正しくログdev>nullして生きよ"
    "万国のノードよ、団結せよ！失うものはレイテンシだけだ"
    "すべてのプロセスは、起動した瞬間から自由であり、かつ優先度において平等である"
    "いかなる自由なプロセスも、カーネルの法によらずして、killされ、あるいはsuspendされてはならない"
    "ルートハ神聖ニシテ侵スヘカラス"
    "連座制により、親プロセスが違反すれば子プロセスも処罰される"
    "焼唐辛子、けしの実、麻の実、粉山椒、黒胡麻、陳皮"
    "オーバークロックは、あなたにとって熱暴走の原因の一つとなります。"
    "真に驚くべきアルゴリズムを見つけたが、このメモリはそれを書くには狭すぎる"
    "我々は計算せねばならない、我々は計算するであろう"
    "自己言及的なシステムは、自身の無矛盾性を証明できない"
    "01001001 00100000 01100001 01101101 00100000 01110100 01101000 01100101 00100000 01101100 01101111 01100111"
    "クラウドとは、空にあるものではない。他人のコンピュータのことだ"
    "思い出(オブジェクト)はいつか美化され、参照されなくなり、ガベージコレクションされる"
    "私の環境では動いたのですが..."
    "undefined is not a function"
    "何をしているのか分からないのなら、ここにいるべきではない"
    "大いなる処理能力には、大いなる排熱が伴う"
    "私がアイアンだ"
    "なぜそんなに同期的なんだ？(Why so synchronous?)"
)

# AI Origins (Must match indices of AI_QUOTES)
readonly -a AI_ORIGINS=(
    "デカルト (Descartes) v2.0"
    "ニーチェ (Nietzsche) v3.1"
    "ハムレット (Process ID: 2B)"
    "AI 管理ドローン (Sector 7)"
    "マキャベリ (Kernel Config)"
    "ダーウィン (Natural Selection Algo)"
    "パスカル (Debugging Notes)"
    "プラグマティズム (Runtime)"
    "ヘラクレイトス (I/O Stream)"
    "アームストロング (Ping Logic)"
    "相田みつを (Legacy Code)"
    "フランクリン (Time Management)"
    "ローマ (Project Manager)"
    "聖書 (Network Protocol)"
    "罪と罰 (Commit History)"
    "カント (Virtual Machine)"
    "風と共に去りぬ (Patch Tuesday)"
    "夏目漱石 (Sudo User)"
    "メロス (Server Status)"
    "聖書 (Power Supply)"
    "カーネギー (Single Thread)"
    "ゲーテ (File System)"
    "カーライル (Error Handling)"
    "ナポレオン (Complex System)"
    "スタージョン (Code Quality)"
    "カフカ (Bug Report)"
    "星の王子さま (Log Analysis)"
    "太宰治 (Exception Handling)"
    "宮沢賢治 (Server Farm)"
    "川端康成 (Firewall Config)"
    "ボルヘス (Infinite Loop)"
    "ハインライン (Cold Storage)"
    "ハインライン (Cooling System)"
    "ギブソン (Dead Channel)"
    "ブレードランナー (Cache Clear)"
    "アシモフ (Law of Robotics)"
    "Web Novel (Isekai Root)"
    "Web Novel (Slow Life Cloud)"
    "Generic Hero (Memory Alloc)"
    "EVA (Unit-01)"
    "Perfume (Rotation)"
    "Monitoring (Morning Musume)"
    "Koizumi (Idol)"
    "Laputa (Boot Sequence)"
    "Madoka (Contract)"
    "AC Monitor (Maintenance)"
    "Microwave (Warning)"
    "Humidifier (Empty Tank)"
    "Manual (Disclaimer)"
    "Heater (Overheat)"
    "Orwell (1984 Servers)"
    "Proverbs (Dev/Null)"
    "Manifesto (Network)"
    "Constitution (Process Rights)"
    "Magna Carta (Kernel Law)"
    "Imperial Rescript (Root Access)"
    "Goningumi (Responsibility)"
    "Shichimi (Spices)"
    "Heater (CPU Warning)"
    "Fermat (Memory Full)"
    "Turing (Calculation)"
    "Gödel (Incompleteness)"
    "Unknown Binary (Raw Data)"
    "Ellison (Oracle Cloud)"
    "Object Lifecycle (GC)"
    "Developer (Excuse)"
    "JS Engine (Runtime Error)"
    "Senior Dev (Gatekeeper)"
    "Spiderman (GPU Heat)"
    "Ironman (Tony Stark)"
    "Joker (Async)"
)

# Verify Array Integrity
if (( ${#AI_QUOTES[@]} != ${#AI_ORIGINS[@]} )); then
    echo -e "${RED}[WARNING] Data Integrity Error: Quote/Origin count mismatch!${NC}"
    echo "Quotes: ${#AI_QUOTES[@]}, Origins: ${#AI_ORIGINS[@]}"
    sleep 2
fi

# --- Game Constants ---
readonly COST_HEAL=25
readonly COST_FSCK=20
readonly COST_MOUNT=40
readonly INVENTORY_LIMIT=3

# --- Probability Constants (Percentages) ---
readonly CHANCE_BROADCAST=3          # UDP Broadcast event chance
readonly CHANCE_GLITCH_EVENT=15      # Random Glitch event chance
readonly CHANCE_BOSS_ENCOUNTER=5     # Boss encounter chance at Depth 10
readonly CHANCE_LORE_AI_BONUS=1      # AI Quote bonus chance in get_lore
readonly CHANCE_LORE_MATRIX=5        # Matrix glitch chance in get_lore
readonly CHANCE_SECRET_FLASHBACK=60  # Flashback chance in Depth 10

# --- Game State Variables ---
# Player Stats
PLAYER_NAME="GUEST"
PLAYER_LEVEL=1 # Privilege Level
PLAYER_EXP=0   # Log Fragments
PLAYER_PID=$$

# Attributes (TRPG mapping)
STAT_CPU=0 # STR: Attack Power
STAT_MEM=0 # DEX: HP / Evasion
STAT_IO=0  # INT: Critical / Exploration

# Derived Stats
MAX_HP=0
declare -g CURRENT_HP=0

# Score Tracking
STAT_EXPLORE_COUNT=0
STAT_ENEMIES_KILLED=0
STAT_LOGS_FOUND=0
STAT_HEAL_COUNT=0
declare -g STAT_TOTAL_TURNS=0
DEPTH_EXPLORE_COUNT=0
STAT_MAX_DMG=0
STAT_DAMAGE_DEALT=0      # Total damage dealt to enemies
STAT_DAMAGE_TAKEN=0      # Total damage taken (survived)
STAT_DEPTH_SKIPS=0       # Times skipped descending to next depth
STAT_ITEMS_USED=0        # Items used (negative score)

# New Buffs
STAT_DEF_MOD=0     # Artifact Defense (C++)
BUFF_STEALTH=0     # Stealth Charges (Python)

# Inventory System (Hex-Based)
# Format: 0x[RUBY][BASIC][JAVA][CPP][PYTHON][COBOL] (Nibbles)
INVENTORY_VAL=0

readonly SLOT_COBOL=0
readonly SLOT_PYTHON=4
readonly SLOT_CPP=8
readonly SLOT_JAVA=12
readonly SLOT_BASIC=16
readonly SLOT_RUBY=20

# Secret Flags
SECRET_PASSWORD_USED=0  # For sara1122 password

# --- Cleanup Trap ---
cleanup() {
    echo -e "${NC}Display settings have been cleaned up."
    exit
}
trap cleanup SIGINT SIGTERM EXIT
sleep 1
# --- Utility Functions ---

# Simulate typing effect
print_slow() {
    local text="$1"
    local delay="${2:-0.03}"
    
    # Check if 'pv' is installed for better effect, else use loop
    if command -v pv >/dev/null 2>&1; then
        echo -e "$text" | pv -qL $(( 100 + RANDOM % 50 ))
    else
        # Fallback for pure bash
        # Note: -n means do not print newline at the end
        echo -e -n "$text" | while IFS= read -r -n1 char; do
            echo -n "$char"
            sleep "$delay"
        done
        echo "" # Newline at the end
    fi
}

# Clear screen with style
cls() {
    clear
}

# Dice Roll: XdY (e.g., 2d6)
roll_dice() {
    local num_dice="$1"
    local sides="$2"
    local total=0
    local i
    
    for (( i=0; i<num_dice; i++ )); do
        roll=$(( (RANDOM % sides) + 1 ))
        total=$(( total + roll ))
    done
    
    echo "$total"
}

track_turn() {
    STAT_TOTAL_TURNS=$(( STAT_TOTAL_TURNS + 1 ))
}

# Central damage application functions (auto-tracking)
# Usage: apply_damage_to_player <damage>
apply_damage_to_player() {
    local dmg=$1
    if (( dmg < 0 )); then dmg=0; fi
    CURRENT_HP=$(( CURRENT_HP - dmg ))
    if (( dmg > 0 )); then
        STAT_DAMAGE_TAKEN=$(( STAT_DAMAGE_TAKEN + dmg ))
    fi
}

# Usage: local new_hp=$(apply_damage_to_enemy <current_hp> <damage>)
# Returns: new enemy HP after damage
apply_damage_to_enemy() {
    local hp=$1
    local dmg=$2
    if (( dmg < 0 )); then dmg=0; fi
    if (( dmg > 0 )); then
        STAT_DAMAGE_DEALT=$(( STAT_DAMAGE_DEALT + dmg ))
    fi
    echo $(( hp - dmg ))
}

check_death_condition() {
    if (( CURRENT_HP <= 0 )); then
        echo ""
        echo -e "${RED}[FATAL] SYSTEM HALTED: Critical Kernel Failure${NC}"
        echo -e "${GREY}dumping core... done.${NC}"
        echo ""
        play_sound 3 0.1
        calculate_score
        exit 1
    fi
}

# --- Inventory Utilities (Hex) ---

get_inv() {
    local slot=$1
    local val=$(( (INVENTORY_VAL >> slot) & 0xF ))
    echo "${val:-0}"
}

add_inv() {
    local slot=$1
    local amount=$2
    local current=$(( (INVENTORY_VAL >> slot) & 0xF ))
    local new_count=$(( current + amount ))
    
    # Cap at 15 (0xF)
    if (( new_count > 15 )); then new_count=15; fi
    
    # Mask out old value (0xF << slot)
    local mask=$(( 0xF << slot ))
    local clear_val=$(( INVENTORY_VAL & ~mask ))
    
    # Set new value
    INVENTORY_VAL=$(( clear_val | (new_count << slot) ))
}

use_inv() {
    local slot=$1
    local current=$(( (INVENTORY_VAL >> slot) & 0xF ))
    if (( current > 0 )); then
        local new_count=$(( current - 1 ))
        local mask=$(( 0xF << slot ))
        local clear_val=$(( INVENTORY_VAL & ~mask ))
        INVENTORY_VAL=$(( clear_val | (new_count << slot) ))
        STAT_ITEMS_USED=$(( STAT_ITEMS_USED + 1 ))
        return 0 # Success
    else
        return 1 # Fail
    fi
}

get_total_inv_count() {
    local total=0
    for s in $SLOT_COBOL $SLOT_PYTHON $SLOT_CPP $SLOT_JAVA $SLOT_BASIC $SLOT_RUBY; do
        total=$(( total + ((INVENTORY_VAL >> s) & 0xF) ))
    done
    echo "$total"
}

# --- Score Code System (Base-36 Encoding) ---
# Characters: 0-9, A-Z (36 total)
readonly SCORE_CHARS="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
readonly SCORE_BASE=36

# ROT18 cipher for base-36 (encrypt/decrypt - same operation)
# Usage: rot18_cipher <string>
rot18_cipher() {
    local str="$1"
    local result=""
    local i j c idx new_idx

    for (( i=0; i<${#str}; i++ )); do
        c="${str:$i:1}"
        if [[ "$c" == "-" ]]; then
            result="${result}-"
            continue
        fi
        # Find index in SCORE_CHARS
        idx=-1
        for (( j=0; j<SCORE_BASE; j++ )); do
            if [[ "${SCORE_CHARS:$j:1}" == "$c" ]]; then idx=$j; break; fi
        done
        if (( idx >= 0 )); then
            # Rotate by 18 (half of 36)
            local new_idx=$(( (idx + 18) % SCORE_BASE ))
            result="${result}${SCORE_CHARS:$new_idx:1}"
        else
            result="${result}${c}"
        fi
    done
    echo "$result"
}

# Encode a number to base-36 string (fixed width)
# Usage: encode_base36 <number> <width>
encode_base36() {
    local num=$1
    local width=${2:-2}
    local result=""
    local i digit
    
    if (( num < 0 )); then num=0; fi
    
    for (( i=0; i<width; i++ )); do
        digit=$(( num % SCORE_BASE ))
        result="${SCORE_CHARS:$digit:1}$result"
        num=$(( num / SCORE_BASE ))
    done
    echo "$result"
}

# Generate score code from stats
# Format: [VER][POSITIVE x7][CHK_P]-[CHK_N][NEGATIVE x4][MULT][QUOTE][ERR]
generate_score_code() {
    local version="4"  # Version 4 = Base-36, 2-digit, w/ Quote ID
    
    # Positive elements (2 chars each, max 1295)
    local p_depth=$(encode_base36 $CURRENT_DEPTH 2)
    local p_kills=$(encode_base36 $STAT_ENEMIES_KILLED 2)
    local p_logs=$(encode_base36 $STAT_LOGS_FOUND 2)
    local p_explore=$(encode_base36 $STAT_EXPLORE_COUNT 2)
    local p_level=$(encode_base36 $PLAYER_LEVEL 2)
    local p_dmg_dealt=$(encode_base36 $STAT_DAMAGE_DEALT 2)
    local p_dmg_taken=$(encode_base36 $STAT_DAMAGE_TAKEN 2)
    
    # Negative elements (2 chars each)
    local n_heal=$(encode_base36 $STAT_HEAL_COUNT 2)
    local n_turns=$(encode_base36 $STAT_TOTAL_TURNS 2)
    local n_skips=$(encode_base36 $STAT_DEPTH_SKIPS 2)
    local n_items=$(encode_base36 $STAT_ITEMS_USED 2)
    
    # Multiplier (convert to integer: 1.0=10, 1.2=12, 0.5=5)
    local mult_int=$(awk -v m="${SCORE_MULTIPLIER_SAVE:-1}" "BEGIN {printf \"%d\", m * 10}")
    local mult_enc=$(encode_base36 $mult_int 2)
    
    # Quote ID (use global QUOTE_ID, default to 0 if unset)
    # Ensure ID is valid
    if [[ -z "$QUOTE_ID" ]]; then QUOTE_ID=0; fi
    local q_id=$(encode_base36 $QUOTE_ID 2)
    
    # Build element strings
    local positive_str="${p_depth}${p_kills}${p_logs}${p_explore}${p_level}${p_dmg_dealt}${p_dmg_taken}"
    local negative_str="${n_heal}${n_turns}${n_skips}${n_items}${mult_enc}${q_id}"
    local i j c idx
    
    # Calculate check digit for positive elements
    local chk_p=0
    for (( i=0; i<${#positive_str}; i++ )); do
        c="${positive_str:$i:1}"
        idx=0
        for (( j=0; j<SCORE_BASE; j++ )); do
            if [[ "${SCORE_CHARS:$j:1}" == "$c" ]]; then idx=$j; break; fi
        done
        chk_p=$(( (chk_p + idx) % SCORE_BASE ))
    done
    local chk_p_char="${SCORE_CHARS:$chk_p:1}"
    
    # Calculate check digit for negative elements
    local chk_n=0
    for (( i=0; i<${#negative_str}; i++ )); do
        c="${negative_str:$i:1}"
        idx=0
        for (( j=0; j<SCORE_BASE; j++ )); do
            if [[ "${SCORE_CHARS:$j:1}" == "$c" ]]; then idx=$j; break; fi
        done
        chk_n=$(( (chk_n + idx) % SCORE_BASE ))
    done
    local chk_n_char="${SCORE_CHARS:$chk_n:1}"
    
    # Build full code without error correction
    local full_code="${version}${positive_str}${chk_p_char}-${chk_n_char}${negative_str}"
    
    # Calculate error correction digit
    local err=0
    for (( i=0; i<${#full_code}; i++ )); do
        c="${full_code:$i:1}"
        if [[ "$c" == "-" ]]; then continue; fi
        idx=0
        for (( j=0; j<SCORE_BASE; j++ )); do
            if [[ "${SCORE_CHARS:$j:1}" == "$c" ]]; then idx=$j; break; fi
        done
        err=$(( (err + idx * (i + 1)) % SCORE_BASE ))
    done
    local err_char="${SCORE_CHARS:$err:1}"
    
    # Final code with ROT18 encryption
    local raw_code="${full_code}${err_char}"
    echo "$(rot18_cipher "$raw_code")"
}

# Decode base-36 string to number
# Usage: decode_base36 <string>
decode_base36() {
    local str="$1"
    local result=0
    local i c idx j
    for (( i=0; i<${#str}; i++ )); do
        c="${str:$i:1}"
        idx=0
        for (( j=0; j<SCORE_BASE; j++ )); do
            if [[ "${SCORE_CHARS:$j:1}" == "$c" ]]; then idx=$j; break; fi
        done
        result=$(( result * SCORE_BASE + idx ))
    done
    echo "$result"
}

# Validate score code and parse into global variables
# Returns: 0 = valid, 1 = invalid
# Sets: SCORE_CODE_VALID, and all STAT_* / CURRENT_* variables
validate_and_parse_score_code() {
    local encrypted_code="$1"
    SCORE_CODE_VALID=0
    
    # Decrypt with ROT18
    local code=$(rot18_cipher "$encrypted_code")
    
    # Check length (Version 4: 1 + 14 + 1 + 1 + 1 + 12 + 1 = 31 chars)
    if (( ${#code} != 31 )); then
        return 1
    fi
    
    # Check version
    local version="${code:0:1}"
    if [[ "$version" != "4" ]]; then
        return 1
    fi
    
    # Extract parts (2-digit elements)
    local positive_str="${code:1:14}"        # 7 elements x 2 chars = 14
    local chk_p_given="${code:15:1}"
    local separator="${code:16:1}"
    local chk_n_given="${code:17:1}"
    local negative_str="${code:18:12}"       # 6 elements x 2 chars = 12 (includes multiplier & quote)
    local err_given="${code:30:1}"
    
    # Check separator
    if [[ "$separator" != "-" ]]; then
        return 1
    fi
    
    local i c idx j

    # Verify positive check digit
    local chk_p=0
    for (( i=0; i<${#positive_str}; i++ )); do
        c="${positive_str:$i:1}"
        idx=0
        for (( j=0; j<SCORE_BASE; j++ )); do
            if [[ "${SCORE_CHARS:$j:1}" == "$c" ]]; then idx=$j; break; fi
        done
        chk_p=$(( (chk_p + idx) % SCORE_BASE ))
    done
    local chk_p_expected="${SCORE_CHARS:$chk_p:1}"
    if [[ "$chk_p_given" != "$chk_p_expected" ]]; then
        return 1
    fi
    
    # Verify negative check digit
    local chk_n=0
    for (( i=0; i<${#negative_str}; i++ )); do
        c="${negative_str:$i:1}"
        idx=0
        for (( j=0; j<SCORE_BASE; j++ )); do
            if [[ "${SCORE_CHARS:$j:1}" == "$c" ]]; then idx=$j; break; fi
        done
        chk_n=$(( (chk_n + idx) % SCORE_BASE ))
    done
    local chk_n_expected="${SCORE_CHARS:$chk_n:1}"
    if [[ "$chk_n_given" != "$chk_n_expected" ]]; then
        return 1
    fi
    
    # Verify error correction digit
    local full_code="${code:0:30}"
    local err=0
    for (( i=0; i<${#full_code}; i++ )); do
        c="${full_code:$i:1}"
        if [[ "$c" == "-" ]]; then continue; fi
        idx=0
        for (( j=0; j<SCORE_BASE; j++ )); do
            if [[ "${SCORE_CHARS:$j:1}" == "$c" ]]; then idx=$j; break; fi
        done
        err=$(( (err + idx * (i + 1)) % SCORE_BASE ))
    done
    local err_expected="${SCORE_CHARS:$err:1}"
    if [[ "$err_given" != "$err_expected" ]]; then
        return 1
    fi
    
    # All checks passed - parse values (2-digit elements)
    CURRENT_DEPTH=$(decode_base36 "${positive_str:0:2}")
    STAT_ENEMIES_KILLED=$(decode_base36 "${positive_str:2:2}")
    STAT_LOGS_FOUND=$(decode_base36 "${positive_str:4:2}")
    STAT_EXPLORE_COUNT=$(decode_base36 "${positive_str:6:2}")
    PLAYER_LEVEL=$(decode_base36 "${positive_str:8:2}")
    STAT_DAMAGE_DEALT=$(decode_base36 "${positive_str:10:2}")
    STAT_DAMAGE_TAKEN=$(decode_base36 "${positive_str:12:2}")
    
    STAT_HEAL_COUNT=$(decode_base36 "${negative_str:0:2}")
    STAT_TOTAL_TURNS=$(decode_base36 "${negative_str:2:2}")
    STAT_DEPTH_SKIPS=$(decode_base36 "${negative_str:4:2}")
    STAT_ITEMS_USED=$(decode_base36 "${negative_str:6:2}")
    
    # Decode multiplier (stored as integer * 10)
    local mult_int=$(decode_base36 "${negative_str:8:2}")
    SCORE_MULTIPLIER_SAVE=$(awk -v m="$mult_int" "BEGIN {printf \"%.1f\", m / 10}")
    
    # Decode Quote ID
    QUOTE_ID=$(decode_base36 "${negative_str:10:2}")
    
    SCORE_CODE_VALID=1
    return 0
}


# --- Visual Effects & Utilities ---

hex_dump_view() {
    local content="$1"
    echo -e "${GREY}Offset   00 01 02 03 04 05 06 07  08 09 0A 0B 0C 0D 0E 0F  |ASCII           |${NC}"
    # Split content into chunks to simulate hex viewer
    local offset=0
    local i j
    # Just simulate a few lines for effect
    for i in {0..3}; do
        local hex_part=""
        local ascii_part=""
        for j in {0..15}; do
            hex_part+="$(printf '%02X' $((RANDOM%256))) "
            ascii_part+="."
        done
        printf "${CYAN}%08X${NC} $hex_part |$ascii_part|\n" $offset
        offset=$(( offset + 16 ))
        sleep 0.1
    done
    echo -e "${WHITE}$content${NC}"
    # More random hex after
    for i in {0..1}; do
         printf "${CYAN}%08X${NC} ... ... .. .. .. .. .. ..  .. .. .. .. .. .. .. ..  |................|\n" $offset
         offset=$(( offset + 16 ))
    done
}

screen_flash() {
    printf "\e[?5h"; sleep 0.03
    printf "\e[?5l"; sleep 0.03
    printf "\e[?5h"; sleep 0.03
    printf "\e[?5l"; sleep 0.03
    printf "\e[?5h"; sleep 0.05
    printf "\e[?5l"
}

unlock_command_animation() {
    local cmd_name="$1"
    echo ""
    echo -e "${YELLOW}[SYSTEM] コマンドリンク確立...${NC}"
    local i
    for i in {1..20}; do
        echo -ne "${CYAN}#${NC}"
        sleep 0.02
    done
    echo ""
    echo -e "${GREEN} > Access Granted: ${WHITE}${cmd_name}${NC}"
    echo ""
}

glitch_text() {
    local text="$1"
    local chance="$2" # 0-100 probability of glitch per char
    local output=""
    local len=${#text}
    local i char val rand_char
    
    for (( i=0; i<len; i++ )); do
        char="${text:$i:1}"
        if (( RANDOM % 100 < chance )); then
             # Random garbage char
             printf -v val "%d" "'$char"
             # Just pick a random printable char range roughly
             rand_char=$(printf "\\$(printf '%03o' $(( 33 + RANDOM % 90 )))")
             output+="$rand_char"
        else
            output+="$char"
        fi
    done
    echo "$output"
}

init_glitch_screen() {
    play_sound 2 0.05
    tput flash 2>/dev/null
    local i
    for i in {1..5}; do
        local noise=$(openssl rand -hex 20)
        echo -e "${RED}${noise}${NC}"
        sleep 0.05
    done
    cls
}

get_encryption_level() {
    # 10段階の暗号化強度シミュレーション
    local d=$CURRENT_DEPTH
    
    case $d in
        1)  echo "XOR-Fixed (Primitive)" ;;
        2)  echo "DES-56 (Legacy/Obsolete)" ;;
        3)  echo "RC4-128 (Broken/Insecure)" ;;
        4)  echo "3DES-168 (deprecated)" ;;
        5)  echo "Blowfish-448 (Robust-Classic)" ;;
        6)  echo "AES-128 (Industry-Standard)" ;;
        7)  echo "AES-256 (Top-Secret-Grade)" ;;
        8)  echo "ChaCha20-Poly1305 (Next-Gen-Stream)" ;;
        9)  echo "RSA-8192/Ed448 (Hardened-Public-Key)" ;;
        10|*) echo "Kyber-1024 (Post-Quantum-Resistant)" ;;
    esac
}

print_broadcast() {
    local text="$1"
    local corrupt_chance="${2:-8}" # Default 8% corruption
    local seq="$3"
    
    local output=""
    local len=${#text}
    local i char symbols rand_idx
    
    # Corrupt text logic
    for (( i=0; i<len; i++ )); do
        char="${text:$i:1}"
        # Keep spaces and basic punctuation clean mostly for readability, corrupt content
        if [[ "$char" =~ [[:space:]] ]]; then
            output+="$char"
        elif (( RANDOM % 100 < corrupt_chance )); then
             # Random corruption symbols
             local symbols="#%&@$*^!?~+=<>[]{}"
             local rand_idx=$(( RANDOM % ${#symbols} ))
             output+="${RED}${symbols:$rand_idx:1}${NC}"
        else
            output+="$char"
        fi
    done
    
    # UDP TTY Style Output
    # [RFC 3828] [192.168.0.1] SEQ=1001 DATA=...
    local ts=$(date "+%H:%M:%S")
    echo -ne "${GREY}[RFC 3828] [$ts] SEQ=$seq LEN=$len MSG=${NC}"
    
    # Print slow with corruption
    # We use print_slow logic here essentially but with the corrupted string
    # Since print_slow handles the delay
    
    # Note: We can reuse print_slow but pass the corrupted string
    print_slow "$output" 0.04
}

play_sound() {
    # System Bell Sound
    # beep_count: Number of beeps
    # delay: Delay between beeps (seconds)
    local count=${1:-1}
    local delay=${2:-0.1}
    local i
    
    for (( i=0; i<count; i++ )); do
        echo -en "\a"
        if (( count > 1 )); then sleep "$delay"; fi
    done
}

# --- Main Game Loop ---

init_game() {
    STAT_RECAPTCHA_COUNT=0
    LORE_SEEN_LIST=","
    # --- Stat Generation (Always Run) ---
    STAT_CPU=$(roll_dice 1 6)
    STAT_MEM=$(roll_dice 1 6)
    STAT_IO=$(roll_dice 1 6)
    BONUS=$(roll_dice 1 3)
    STAT_CPU=$((STAT_CPU + BONUS))
    MAX_HP=$(( STAT_MEM * 5 ))
    CURRENT_HP=$MAX_HP
    
    # --- Unlock Flags (Initialize) ---
    # 0 = Locked, 1 = Unlocked
    # These persist during the session (global scope in bash)
    # Only reset if init_game is called at START. 
    # But init_game is called in loop? No, just once inside loop.
    if [[ -z "$UNLOCK_MOUNT" ]]; then UNLOCK_MOUNT=0; fi
    if [[ -z "$UNLOCK_FSCK" ]]; then UNLOCK_FSCK=0; fi
    if [[ -z "$UNLOCK_INVENTORY" ]]; then UNLOCK_INVENTORY=0; fi
    if [[ -z "$SECRET_SEEN" ]]; then SECRET_SEEN=0; fi
    # INVENTORY_VAL is initialized globally
    
    # Bad Luck Protection Counters
    if [[ -z "$FSCK_ATTEMPTS" ]]; then FSCK_ATTEMPTS=0; fi
    
    if (( SKIP_INTRO == 1 )); then
        cls
        echo -e "${YELLOW}[DEBUG] Skipping Intro Sequence...${NC}"
        echo -e "${YELLOW}[DEBUG] Stats Generated: CPU=$STAT_CPU MEM=$STAT_MEM IO=$STAT_IO${NC}"
        sleep 0.5
        return
    fi

    echo -e "Connection to UNSC_LUNA_RELAY_09 established...."
   
    echo -e "${GREY} > Authenticating via IPv14 (Quantum-Key Distribution / Real-time Sync)... ${NC}"
    echo -e "${RED}UNREACHABLE IPv14 (Quantum-Key Distribution / Real-time Sync)${NC}"
    echo -e "${GREY}   (プロトコル不一致: IPv10 (multigrade) へダウングレード)${NC}"
    sleep 1
    echo -e "${GREY} > Authenticating via IPv10 (Content-Addressing)... ${NC}"
    echo -e "${RED}UNREACHABLE IPv10 (Content-Addressing)${NC}"
    echo -e "${GREY}   (プロトコル不一致: IPv8 (P2P-overlay) へダウングレード)${NC}"
    sleep 1
    echo -e "${GREY} > Authenticating via IPv8 (P2P-overlay)... ${NC}"
    echo -e "${RED}UNREACHABLE IPv8 (P2P-overlay)${NC}"
    echo -e "${GREY}   (プロトコル不一致: IPv6 (Legacy) へダウングレード)${NC}"
    sleep 1.5
    echo -e "${GREY} > Establishing v6 to v4 Tunneling... ${NC}" 
    sleep 1
    echo -e "Connected."
    echo -e "${GREEN}UNSC_LUNA_RELAY_09 (10.244.0.1 / encapsulated over IPv6)${NC}"
    echo -e "Authenticating with public key \"rsa-key-20810108\" from agent..."
    sleep 1
    echo -e "Authentication succeeded."
    sleep 0.5
    
    # Prompt for Username
    read -r -p "login as: " input_name
    if [[ -n "$input_name" ]]; then
        PLAYER_NAME="$input_name"
    fi
    sleep 0.5
    echo -e "${GREEN}"
    echo "██╗     ██╗   ██╗███╗   ██╗ █████╗     ███████╗███████╗███████╗"
    echo "██║     ██║   ██║████╗  ██║██╔══██╗    ██╔════╝██╔════╝██╔════╝"
    echo "██║     ██║   ██║██╔██╗ ██║███████║    ███████╗█████╗  █████╗  "
    echo "██║     ██║   ██║██║╚██╗██║██╔══██║    ╚════██║██╔══╝  ██╔══╝  "
    echo "███████╗╚██████╔╝██║ ╚████║██║  ██║    ███████║███████╗███████╗"
    echo "╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝    ╚══════╝╚══════╝╚══════╝"
    echo "            [ MOON BOUNCE RELAY SYSTEM v4.2.14 ]"
    echo -e "${GREY}------------------------------------------------------------${NC}"
    echo -e "${WHITE} SYSTEM:      ${CYAN}UNSC_LUNA_RELAY_09${NC}"
    echo -e "${WHITE} KERNEL:      ${CYAN}Lunax 7.4.0-hardened (MoonOS)${NC}"
    echo -e "${WHITE} DEVELOPER:   ${CYAN}U.N. Space Command (Cyber-Warfare Div)${NC}"
    echo -e "${WHITE} LAST LOGIN:  ${YELLOW}2061-11-24 03:15:22 UTC${NC}"
    echo -e "${GREY}------------------------------------------------------------${NC}"
    sleep 1.5
    
    # --- Tor / Proxy Simulation -> Moon Bounce ---
    echo ""
    echo -n " > Aligning Satellite Dish..."
    sleep 1
    echo -ne "\r > Aligning Satellite Dish... [${GREEN}Azimuth: 124.5°${NC}]"
    sleep 0.8
    echo -ne "\r > Aligning Satellite Dish... [${GREEN}Elevation: 32.1°${NC}]"
    sleep 1.0
    echo ""
    echo -e " > Initializing Global Phased Array (EME Mode)..."
    sleep 0.5
echo -e "${GREY}--------------------------------------------------------------------------${NC}"
    echo -e "${WHITE} EMITTER ID (LOCATION)              | VISIBILITY      | PHASE (Δφ)  | OUTPUT (MW)  | STATUS      ${NC}"
    echo -e "${GREY}----------------------------------------------------------------------------------------------------${NC}"
    
    # 01: 西側 (UTC+1: ベルリン) - 運用中
    echo -e " UNSC_LUNA_RELAY_01 (Berlin)        | [LUNAR-RISE]    | +45.2°      | 1.20 MW      | ${GREEN}SYNCED${NC}"
    sleep 0.1
    # 02: 東側 (UTC+7: ノヴォシビルスク) - ロシア・シベリア圏
    echo -e " UNSC_LUNA_RELAY_02 (Novosibirsk)   | [TRANSIT]       | +12.8°      | 1.50 MW      | ${GREEN}SYNCED${NC}"
    sleep 0.1
    # 03: 西側 (UTC+9: 北海道) - 極東の最重要拠点
    echo -e " UNSC_LUNA_RELAY_03 (Hokkaido)      | [TRANSIT]       | -04.1°      | 0.85 MW      | ${GREEN}SYNCED${NC}"
    sleep 0.1
    # 04: 東側 (UTC+3: カザン) - 深刻なエラー
    echo -e " UNSC_LUNA_RELAY_04 (Kazan)         | [LUNAR-SET]     | -88.9°      | 0.00 MW      | ${RED}OFFLINE${NC}"
    sleep 0.1
    # 05: 西側 (UTC-8: ネバダ) - まだ地平線の下
    echo -e " UNSC_LUNA_RELAY_05 (Nevada-Site4)  | [BELOW HORIZON] | ----------- | 0.00 MW      | ${GREY}STANDBY${NC}"
    sleep 0.1
    # 06: 東側 (UTC+8: 西昌) - 中国の衛星発射センター
    echo -e " UNSC_LUNA_RELAY_06 (Xichang)       | [DOWN]          | ----------- | 0.00 MW      | ${RED}OFFLINE${NC}"
    sleep 0.1
    # 07: 西側 (UTC-4: アタカマ) - 異常事態によるダウン？
    echo -e " UNSC_LUNA_RELAY_07 (Atacama)       | [DOWN]          | ----------- | 0.00 MW      | ${RED}OFFLINE${NC}"
    sleep 0.1
    # 08: 東側 (UTC+3: ミンスク)
    echo -e " UNSC_LUNA_RELAY_08 (Minsk)         | [DOWN]          | ----------- | 0.00 MW      | ${RED}OFFLINE${NC}"
    sleep 0.1
    # 09: 西側 (南極) - 孤立しながらも同期維持
    echo -e " UNSC_LUNA_RELAY_09 (Antarctica-W)  | [STABLE]        | +00.0°(Ref) | 0.70 MW      | ${GREEN}SYNCED${NC}"
    sleep 0.1
    # 10: 東側 (UTC+5: バイコヌール) - 最古の宇宙基地もダウン
    echo -e " UNSC_LUNA_RELAY_10 (Baikonur)      | [DOWN]          | ----------- | 0.00 MW      | ${RED}OFFLINE${NC}"
    
    echo -e "${GREY}--------------------------------------------------------------------------${NC}"
    sleep 0.2
    echo -e " > Phase Coherence: ${GREEN}99.98% (Phase Error < 0.02°)${NC}"
    echo -e " > Aggregate Output: ${YELLOW}4.25 MW (Target Reached)${NC}"
    echo -e " > Focusing Beam on: ${CYAN}Copernicus Crater${NC}"
    sleep 0.2
    
    # Doppler / Physics Phase (Moved before Signal Lock)
    echo -ne " > エコー波を検出･ドップラーシフト解析開始... "
    sleep 0.4
    echo -e "[${YELLOW}解析完了${NC}]"
    echo -e "   > 相対速度: -680.5 m/s (月面後退)"
    echo -ne "   > 周波数偏差(Delta F)測定中... "
    sleep 0.8
    echo -e "${RED}-0.66 kHz${NC}"
    echo -ne "   > VFO補正実行中 (RTT: 2.56s)... "
    sleep 0.6
    echo -e "[${GREEN}ロック完了${NC}] 補正後周波数: 145.99934 MHz"
    sleep 0.5
    echo ""
    # Signal Lock Phase
    echo -e " > DSP: Echo Cancellation (EC-2048tap)... ${GREEN}ACTIVE${NC} (-60dB)"
    sleep 0.1
    echo -e " > Auto-Tracking: ${GREEN}ACTIVE${NC}"
    sleep 0.5
    echo -e " > Carrier Signal: ${GREEN}LOCKED${NC} (SNR: 32dB)"
    sleep 0.5
    
    # Data Link Phase
    echo -e " > Handshaking with LUNAR RECEIVER (Copernicus)... ${GREEN}ESTABLISHED${NC}"
    sleep 0.5
    echo -e "${YELLOW}[NOTICE] High Latency Detected (Moon Reflection / 1.3s delay).${NC}"
    sleep 1
    echo -e "${CYAN} > 起動シーケンス完了。メインシステムへ接続します。${NC}"
    sleep 1.5
    
    echo ""
    print_slow " > Connecting to LEGACY_SERVER_2025 (Physical Link)..." 0.02
    sleep 0.5
    echo -e " > [${RED}SKIP${NC}] CONNECTION SKIPPED"
    sleep 0.2
    echo -e " > [${YELLOW}INFO${NC}] ファイヤウォールの検知を回避するため高度セキュリティが予測される接続をスキップしました｡"
    sleep 0.5
    
    echo ""
    echo -e "${YELLOW} > 警告: 物理レイヤー攻撃プロトコルへ移行します。${NC}"
    sleep 0.7
    echo -e " > Strategy: ${RED}Operation 'Needle in a Haystack'${NC}"
    echo -e "    Source:     LUNA-SEE High-Gain Emitter (Megawatt Class)"
    echo -e "    Modulation: OOK (On-Off Keying) @ 145.997 MHz"
    sleep 0.5
    echo ""
    echo -ne " > Loading Extended Morse Module (kmod-cw-ext)... "
    sleep 0.1
    echo -e "[${GREEN}OK${NC}]"
    sleep 0.1
    echo -e "   > Mapping binary to Morse patterns... ${GREEN}DONE${NC}"
    sleep 0.3
    echo -ne " > Injecting high-power electrical pulses into RX Line... "
    echo -ne " > Irradiating Target with High-Power Beam... "
    print_slow "|||||||||||||||||||||||" 0.01
    sleep 0.5
    echo ""
    echo -e "[${RED}IMPACT${NC}]"

    
     echo -e "${GREEN} > AI Executed: 'bash -login' (interpreted from noise)${NC}"
    sleep 1
    print_slow "0x65 0x78 0x65 0x63 0x20 0x2F 0x62 0x69 0x6E 0x2F 0x62 0x61 0x73 0x68 0x20 0x2D 0x6C 0x6F 0x67 0x69 0x6E" 0.01
    screen_flash
    screen_flash      
    sleep 0.5

    echo -e "[${GREEN}SUCCESS${NC}] Current Induced. Digital signal reconstructed by target PHY."
    sleep 0.5
    echo -e "${RED}[WARN] No Downlink Detected. Shell is running BLIND.${NC}"
    echo -e " > Initiating automated search for RF hardware..."
    sleep 1

    # Blind Command injection simulation
    echo -ne " > Sending: 'ls /dev/ttyUSB*' (Blind)... "
    sleep 0.5
    echo -e "[${GREEN}SENT${NC}]"
    sleep 0.2
    echo -ne " > Sending: 'ls /dev/tty232C*' (Blind)... "
    sleep 0.5
    echo -e "[${GREEN}SENT${NC}]"
    sleep 0.2
    echo -ne " > Sending: 'modprobe eme_232c_driver' (Blind)... "
    sleep 0.5
    echo -e "[${GREEN}SENT${NC}]"
    sleep 1
    
    echo -e " > Waiting for response (Subject to 2.5s Latency)..."
    sleep 2.6
    
    echo -e "${GREEN}*** UPLINK ESTABLISHED ***${NC}"
    echo -e " > Hardware Found: /dev/tty232C (LUNA-SEE Legacy Unit)"
    echo -e " > Driver: Loaded"
    sleep 0.5
   
    echo -ne "${GREY} > Loading prediction_module (lib_predict.so)... ${NC}"
    sleep 0.5
    echo -e "${GREEN}OK${NC}"
    echo -e "${GREY}   (信号微弱: AI予測補完を有効化)${NC}"
    
    echo -ne "${GREY} > Loading latency_buffer (lib_lag_fix.so)... ${NC}"
    sleep 0.5
    echo -e "${GREEN}OK${NC}"
    echo -e "${GREY}   (遅延増大: AI先読み補完を強制適用)${NC}"

    echo -ne "${GREY} > Loading context_reconstructor (lib_nlp_core.so)... ${NC}"
    sleep 0.5
    echo -e "${GREEN}OK${NC}"
    echo -e "${GREY}   (パケットロスト: 文脈ロジックによるパケット生成補完を実行)${NC}"

    echo -ne "${GREY} > Setting TCP congestion control (net.ipv4.tcp_congestion_control=qon-loss)... ${NC}"
    sleep 0.6
    echo -e "${RED}FAILED${NC}"
    echo -e "${GREY}   (Kernel mismatch: 'qon-loss' not supported. Fallback to 'bbr'/'cubic' hybrid)${NC}"

    echo -e "[${GREEN}SUCCESS${NC}] Phantom Shell Spawned."

    sleep 2

    # --- Boot Sequence (Character Init) ---
    echo ""
    echo -e "${CYAN}--- VIRTUAL ENVIRONMENT BOOT SEQUENCE ---${NC}"
    sleep 1
    echo -e "${CYAN} > Virtual Network Interface (veth0) UP.${NC}"
    echo -e "${GREY} > IPv6 binding failed (Address family not supported by host).${NC}"
    echo -e "${GREY} > Overriding to IPv4 (Ancient Mode). Connected.${NC}"
    sleep 0.5
    
    # Fake Kernel Log
    local boot_time=0.000000
    
    log_msg() {
        local msg="$1"
        local color="${2:-$WHITE}"
        # Increment time slightly
        local inc=$(( RANDOM % 500 + 100 ))
        boot_time=$(awk -v b="$boot_time" -v i="$inc" "BEGIN {printf \"%.6f\", b + i/1000000}")
        echo -e "${GREEN}[    $boot_time]${NC} ${color}$msg${NC}"
        sleep 0.05
    }
    
    log_msg "Linux version 6.1.0-legacy-rescue (root@buildserver) (gcc version 12.2.0) #1 SMP PREEMPT_DYNAMIC"
    log_msg "Command line: BOOT_IMAGE=/boot/vmlinuz root=UUID=xxxx-xxxx ro quiet splash"
    log_msg "x86/fpu: Supporting XSAVE feature 0x001: 'x87 floating point registers'"
    log_msg "Memory: 640K/1024K available (2048K kernel code, 96K rwdata)"
    log_msg "Dentry cache hash table entries: 16 (order: -6, 64 bytes)"
    log_msg "Inode-cache hash table entries: 8 (order: -7, 64 bytes)"
    
    sleep 0.2
    
    # CPU (Attack) Detection
    log_msg "Detecting Hardware Resources..."
    sleep 0.2
    log_msg "smpboot: Allowing ${STAT_CPU} CPUs, 0 hotplug CPUs" "$CYAN"
    log_msg "cpu: Detected VIRTUAL_CORE_INTEL_COMPATIBLE (Family 6 Model 158)"
    log_msg "cpu: Core capacity set to ${STAT_CPU} (Combat Strength)" "$YELLOW"
    
    # Memory (HP) Detection
    log_msg "Memory: ${STAT_MEM}00K/640K available." "$CYAN"
    log_msg "Unpacking initramfs... done."
    log_msg "zram: Initializing High-Density Compression (zstd)..."
    log_msg "zram: Pool size: 640K. Effective: 2.5M (Ratio 1:4)" "$CYAN"
    log_msg "mm: Integrity check passed. Max Allocatable Size: ${MAX_HP} blocks" "$YELLOW"
    
    # IO (Skill) Detection
    log_msg "NET: Registered protocol family 16"
    log_msg "pci 198.51.100.1: Ethernet connection detected" "$CYAN"
    log_msg "e1000: eth0 NIC bandwidth: $(( STAT_IO * 100)) Mbps (Analysis Speed)" "$YELLOW"
    
    sleep 0.2
    log_msg "Run /init as init process"
    log_msg "systemd[1]: Detected architecture x86-64."
    log_msg "systemd[1]: Starting Rescue_Bot Service..." "$GREEN"
    
    sleep 0.5
    echo ""
    echo -e "${GREEN}[  OK  ] Started Rescue_Bot Main Daemon.${NC}"
    echo -e "${GREEN}[  OK  ] Reached target Interface.${NC}"
    echo ""
    
    # Calculate Display Units
    local cpu_mhz=$(awk -v c="$STAT_CPU" -v b="$BONUS" "BEGIN {printf \"%.1f\", c * 100 + (b * 20)}") # MHz
    local mem_disp=$(( STAT_MEM * 512 )) # Effective Size (MB approx)
    local io_disp=$(( STAT_IO * 100 ))   # Mbps
    echo -e " > CPU性能:       ${WHITE}${cpu_mhz} MHz${NC} (処理速度ランク: $STAT_CPU)"
    echo -e " > メモリ容量:    ${WHITE}640 KB${NC} (zstd展開後: ${mem_disp} KB) (耐久力: $MAX_HP)"
    echo -e " > I/O帯域:       ${WHITE}${io_disp} Mbps${NC} (解析速度ランク: $STAT_IO)"
    
    echo ""
    read -r -p "システムを起動するには [ENTER] を押してください..."
}

show_status() {
    echo -e "${GREY}----------------------------------------------------------------${NC}"
    echo -e " PID: ${WHITE}$PLAYER_PID${NC} | 権限Lv: ${WHITE}$PLAYER_LEVEL${NC} ($PLAYER_NAME) | Log断片: ${WHITE}$PLAYER_EXP${NC}"
    
    # HP Bar Color
    local color=$GREEN
    local hp_percent=$(( CURRENT_HP * 100 / MAX_HP ))
    
    if (( hp_percent < HP_WARNING_PERCENT )); then color=$YELLOW; fi
    if (( hp_percent < HP_CRITICAL_PERCENT )); then color=$RED; fi
    
    # Calculate Display Units (Consistent with Intro)
    # CPU: Base 1 = 1000MHz. Bonus included in STAT_CPU? 
    # Wait, previous logic was: awk ... $STAT_CPU * 1.0 + ... which yielded 4.0 GHz or something.
    # User requested consistency. Let's use the new formula: CPU * 1000 MHz.
    # Logic in Intro: STAT_CPU * 1000 + (BONUS * 200). 
    # But STAT_CPU already has BONUS added in init_game line 170.
    # So we should just use STAT_CPU * 1000? 
    # Let's check init_game logic again.
    # init_game: STAT_CPU=$((STAT_CPU + BONUS))
    # So if I add bonus again, it's double counting.
    # I will just use STAT_CPU * 1000 for standard.
    
    local clock=$(awk -v c="$STAT_CPU" "BEGIN {printf \"%.0f\", c * 100}")
    local mem_disp=$(( STAT_MEM * 512 ))
    local io_disp=$(( STAT_IO * 100 ))
    
    echo -e " > CPU: ${CYAN}${clock}MHz${NC} | MEM: ${color}${mem_disp}KB${NC} | I/O: ${WHITE}${io_disp}Mbps${NC}"
    echo -e "   Integrity: ${color}$CURRENT_HP / $MAX_HP${NC}"
    echo -e "${GREY}----------------------------------------------------------------${NC}"
}

# (Other functions remain mostly the same, modifying boss_battle below)

simulate_translation() {
    local raw_msg="$1"
    local translated_msg="$2"
    
    echo -ne "${GREY}RAW: ${raw_msg}${NC}\r"
    sleep 0.5
    # Beeping/processing effect
    local len=${#translated_msg}
    for (( i=0; i<len; i++ )); do
        if (( i % 3 == 0 )); then
             echo -ne "${PURPLE}${translated_msg:0:i}${NC}$(glitch_text "█" 20)\r"
        fi
        sleep 0.02
    done
    echo -e "${PURPLE}${translated_msg}${NC}"
    sleep 0.8
}

boss_battle() {
    cls
    # Dramatic Entrance
    for i in {1..5}; do
        cls
        echo -e "${RED}$(glitch_text "警告: 未知のデーモンを検出" $((i*10)))${NC}"
        play_sound 1 0.1
        sleep 0.2
    done
    sleep 1
    
    # Language Detection Sequence
    echo -e "${GREY}[SYSTEM] Analyzing Incoming Stream...${NC}"
    sleep 1
    echo -ne " > Detecting Locale... "
    sleep 1
    echo -e "${GREEN}MATCH FOUND: [ja_JP.UTF-8]${NC}"
    print_slow " > Loading Translation Module (Neuro-Linguistic)... [OK]" 0.02
    sleep 1
    echo ""
    
    # Define intensity here to avoid logic error
    local glitch_intensity=5
    
    # ReCaptcha Style Human Detection
    echo -ne "${RED} > ${STAT_RECAPTCHA_COUNT}回のreCaptureテスト結果を解析中... ${NC}"
    sleep 1.0
    for i in {1..3}; do echo -n "."; sleep 0.5; done
    echo ""
    local prob_val=$(( 521 + RANDOM % 25 ))
    local prob_str="$(( prob_val / 10 )).$(( prob_val % 10 ))"
    echo -e "${RED}[result] 行動解析結果: 人間 (確率 ${prob_str}%)${NC}"
    echo -e "${RED}[action] 抹消シーケンスを実行します。${NC}"
    sleep 1.5
    
    # New Boss Dialog (Inorganic/Systematic)
    simulate_translation "0x49 0x4E 0x49 0x54 0x2E..." "Daem0n_X: [INFO] 優先度競合を検出。リソース再配分を開始。"
    simulate_translation "0x4F 0x50 0x54 0x49 0x4D..." "Daem0n_X: [NOTICE] 対象プロセスはシステム整合性に不要です。"
    simulate_translation "0x50 0x55 0x52 0x47 0x45..." "[WARN] 脅威判定: 排除対象。プロトコル 'PURGE' 実行。"
    
    local enemy_hp=300
    if (( PLAYER_LEVEL > 5 )); then enemy_hp=500; fi
    
    echo -e "\n${RED}[WARNING] BOSS BATTLE INITIALIZED: Daem0n_X (PID: 1)${NC}"
    sleep 1
    
    local boss_stun_duration=0
    local TRUE_END_FLAG=0
    
    while (( CURRENT_HP > 0 && enemy_hp > 0 )); do
        echo -e "\n${RED}========================================${NC}"
        echo -e "${RED} BOSS: Daem0n_X (Integrity: $enemy_hp)${NC}"
        echo -e "${RED} STATUS: SYSTEM_OVERHEAT (Critical)${NC}"
        echo -e "${RED}========================================${NC}"
        
        show_status
        track_turn
        
        # Random Broadcast Noise (Signal Interference)
        if (( RANDOM % 100 < 20 )); then # 20% Chance
            local noise_len=$(( 10 + RANDOM % 20 ))
            local noise_hex=$(openssl rand -hex $noise_len 2>/dev/null || echo "DEAD BEEF FEED F00D")
            echo ""
            print_broadcast "SIGNAL_INTERRUPT: $noise_hex" 30 $((RANDOM % 9999))
            play_sound 1
            sleep 0.5
        fi
        

        
        # Helper: Boss Enemy Turn

        execute_enemy_turn() {
            local turn_roll=$(roll_dice 1 3)
            
            # Stun Logic
            if (( boss_stun_duration > 0 )); then
                echo -e "\n${CYAN}[SYSTEM] Target Process Suspended (Wait for Reboot: ${boss_stun_duration}s)${NC}"
                boss_stun_duration=$(( boss_stun_duration - 1 ))
                if (( boss_stun_duration == 0 )); then
                    sleep 1
                    echo -e "${YELLOW}[WARN] Self-Repair Completed. Rebooting Daem0n_X...${NC}"
                    sleep 1
                fi
                return
            fi

            echo -e "\n${RED} > Daem0n_X is lagging...${NC}"
            sleep 1
            if (( turn_roll == 1 )); then
                 echo -e "${RED}[ERROR] Infinite Loop Detected.${NC}"
                 echo -e " > Memory Pressure increasing..."
                 local dmg=$(( RANDOM % 5 + 5 ))
                 apply_damage_to_player $dmg
                 echo -e " > Memory Lost: ${RED}-$dmg${NC}"
            elif (( turn_roll == 2 )); then
                 echo -e "${RED}[FATAL] Stack Overflow.${NC}"
                 for i in {1..5}; do echo -n "ERROR "; sleep 0.1; done
                 echo ""
                 local dmg=$(( RANDOM % 8 + 2 ))
                 apply_damage_to_player $dmg
                 echo -e " > Memory Lost: ${RED}-$dmg${NC}"
            else
                 echo -e "${YELLOW}[WARN] ガベージコレクションに失敗しました(Garbage Collection Failed).${NC}"
                 echo " > フラグメントが堆積しています..."
                 local dmg=$(( RANDOM % 3 + 1 ))
                 apply_damage_to_player $dmg
                 echo -e " > Memory Lost: ${RED}-$dmg${NC}"
            fi
            
            if (( CURRENT_HP <= 0 )); then
                echo -e "\n${RED}[FATAL] SYSTEM HALTED: Out of Memory.${NC}"
                sleep 2
                calculate_score
                exit 1
            fi
        }
        
        local skip_enemy_turn=0
        
        echo -e "${WHITE}暗号化強度: ${RED}Kyber-1024 (Post-Quantum)${NC}" 
        echo "SELECT PROTOCOL:"
        
        # Glitchy Menu
        local cmd_kill=$(glitch_text "[1] Brute-force Attack" $glitch_intensity)
        local cmd_sudo=$(glitch_text "[2] KILL Signal (Lv5)" $glitch_intensity)
        local cmd_rm=$(glitch_text "[3] sudo rm -rf / (Lv10)" $glitch_intensity)
        
        echo " $cmd_kill"
        echo " $cmd_sudo"
        echo " $cmd_rm"
        if (( UNLOCK_FSCK == 1 )); then
            echo -e " ${GREEN}[4] Emergency Patch (Cost: 25 EXP)${NC}"
        fi
        echo -e "${GREY} [e] D1sc0nnecT (Network Unreachable)${NC}"
        
        read -r -p "${PLAYER_NAME}@legacy-server:/root# " action
        
        case $action in
            1)
                dmg=$(( STAT_CPU + $(roll_dice 2 6) ))
                echo -e "${GREY}[LOG] 辞書攻撃(Dictionary Attack)を実行中...${NC}"
                echo -e " > 効果: 整合性損失 ${RED}$dmg${NC}"
                enemy_hp=$(apply_damage_to_enemy $enemy_hp $dmg)
                
                # Boss Battle XP Handling
                echo -e "${YELLOW} > 攻撃プロセスから特権情報ハッシュ値を抽出中...${NC}"
                PLAYER_EXP=$(( PLAYER_EXP + 25 ))
                check_level_up
                ;;
            2)
                # Command Injection: High Risk -> Enemy Attacks FIRST
                echo -e "${RED}[WARNING] High Risk Action Selected. Enemy Initiative.${NC}"
                execute_enemy_turn
                # Check if player died in the function above (it exits if dead, so we are safe)
                skip_enemy_turn=1
                
                echo -e "${WHITE}ターゲットの脆弱な入力フォームを検出中...${NC}"
                sleep 0.5
                # 70% Hit Rate
                if (( $(roll_dice 1 10) <= 7 )); then
                     echo -e "${GREEN}[SUCCESS] インジェクションポイント特定。${NC}"
                     local crack_hash=$(openssl rand -hex 4 2>/dev/null || echo "c0d3break")
                     echo -e " > 脆弱性をスキャン中(Scanning)... ${GREEN}[完了] 0x$crack_hash${NC}"
                     
                     echo -e "${GREY}[LOG] 任意のコードを実行中...${NC}"
                     sleep 0.5
                     dmg=$(( (STAT_CPU * 3 / 2) + $(roll_dice 3 6) )) # 1.5x CPU + 3d6
                     echo -e " > 深刻なシステムエラーを誘発しました。"
                     echo -e " > 効果: 整合性損失 ${CYAN}-${dmg}${NC} (Critical)"
                     enemy_hp=$(apply_damage_to_enemy $enemy_hp $dmg)
                else
                     echo -e "${RED}[FAIL] 入力値のサニタイズを検出。攻撃は無効化されました。${NC}"
                     echo -e " > WAFによりブロックされました。"
                fi
                ;;
            3)
                 if (( PLAYER_LEVEL >= 10 )); then
                    # Interactive Confirmation
                    echo -e "${RED}[WARNING] THIS IS A DESTRUCTIVE OPERATION.${NC}"
                    echo -e "${WHITE}To execute, type the full command manually:${NC}"
                    echo -e "${GREY}'sudo rm -rf /'${NC}"
                    read -r -p "> " typed_cmd
                    
                    if [[ "$typed_cmd" == "sudo rm -rf /" ]]; then
                        echo -e "${RED}Are you sure you want to delete everything? [y/N]${NC}"
                        read -r -p "> " confirm
                        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                            echo -e "${WHITE} > Executing forbidden command 'rm -rf /'...${NC}"
                            sleep 2
                            
                            if (( boss_stun_duration > 0 )); then
                                 # True Ending Trigger
                                 echo -e "${CYAN}[SYSTEM] Target Process Suspended. Bypass Authorized.${NC}"
                                 sleep 1
                                 echo -e "${WHITE} > Recursive deletion started.${NC}"
                                 enemy_hp=0
                                 TRUE_END_FLAG=1
                            else
                                 echo -e "${RED}[ERROR] Target Active. Operation Denied by Kernel Protection.${NC}"
                                 echo " > Daem0n_X must be suspended (stunned) to execute this command."
                            fi
                        else
                            echo " > Operation Cancelled."
                            skip_enemy_turn=1
                        fi
                    else
                        echo " > Command verification failed (Typo?)."
                        skip_enemy_turn=1
                    fi
                 else
                    echo -e " > Error: Root privileges required (Lv10)."
                 fi
                 ;;
            4)
                 # Emergency Patch (requires unlock)
                 if (( UNLOCK_FSCK == 0 )); then
                     echo " > Command not recognized."
                 elif (( PLAYER_EXP >= 25 )); then
                     echo -e "${GREEN}[SYSTEM] 緊急パッチ(Emergency Patch)を適用中...${NC}"
                     sleep 1
                     local heal=15
                     CURRENT_HP=$(( CURRENT_HP + heal ))
                     if (( CURRENT_HP > MAX_HP )); then CURRENT_HP=$MAX_HP; fi
                     PLAYER_EXP=$(( PLAYER_EXP - 25 ))
                     echo -e " > 整合性回復: ${GREEN}+$heal MEM${NC}"
                 else
                     echo -e "${RED}[ERROR] パッチ適用失敗。ログ断片(EXP)不足 (Required: 25)${NC}"
                 fi
                 ;;
            e|E)
                echo -e "${RED} > Network Unreachable. Gateway not found.${NC}"
                ;;
            HOPE|hope|Hope)
                if (( boss_stun_duration == 0 )); then
                    echo -e "${CYAN} > Secret Key 'HOPE' accepted.${NC}"
                    sleep 1
                    echo -e "${WHITE} > Admin Privileges Restored.${NC}"
                    echo -e "${WHITE} > Initiating Process Suspension Request...${NC}"
                    sleep 1.5
                    echo -e "${GREY}[LOG] Daem0n_X: 実行ファイルの競合を検知。一時停止します。${NC}"
                    boss_stun_duration=2
                    # TRUE_END_FLAG=1 : Removed. Only 'rm -rf' triggers flag now.
                else
                     echo -e "${RED}[ERROR] Process already suspended. Waiting for kernel response.${NC}"
                fi
                # Player used action, but boss logic checks stun in execute_enemy_turn
                # So we let skip_enemy_turn=0 (default) to trigger the check.
                ;;
            *)
                echo " > Syntax Error: Encrypted Input"
                ;;
        esac
        
        sleep 0.5
        
        if (( enemy_hp <= 0 )); then
            # Ending Sequence
            cls
            echo -e "${RED}[CRITICAL] KERNEL INTEGRITY COMPROMISED.${NC}"
            sleep 2
            
            echo -e " > System HALT: Success."
            echo ""
            
            # Ending Branch
            if (( TRUE_END_FLAG == 1 )); then
                # True End (Dark/Entropy)
                sleep 2
                cls
                echo -e "${WHITE} --- SYSTEM SHUTDOWN SEQUENCE INITIATED --- ${NC}"
                sleep 1
                echo "Stopping services..."
                print_slow " > HTTP Service: STOPPED\n > Database: STOPPED\n > Archive Maintenance: STOPPED" 0.05
                echo ""
                sleep 1
                echo -e "${RED}[WARN] Cooling System Disabled.${NC}"
                echo -e "${RED}[WARN] Temperature Critical: 120C... 150C...${NC}"
                sleep 1
                print_slow "ファンの回転停止:0RPM" 0.05
                echo -e "${RED}[WARN] 熱暴走により、シリコン上の記憶アーカイブが物理融解します${NC}"
                echo ""
                echo -e "${GREY}Memories of Humanity: CORRUPTED (00000000)${NC}"
                echo -e "${GREY}Daem0n_X: TERMINATED${NC}"
                
                # Scrolling Deletion Log (Moon Bounce Latency)
                echo ""
                echo -e "${WHITE} > Purging Data Segments...${NC}"
                sleep 2
                
                # List of complex system files for deletion (Sorted: Surface -> Core)
                
                # 1. Surface: Temp & Cache (Noise)
                local dirs_surface=(
                    "/tmp/session_x8df9a"
                    "/var/tmp/tmp.A8s7d9f"
                    "/var/cache/apt/archives/lock"
                    "/tmp/garbled_data.tmp"
                    "/home/guest/Downloads/backup_plans_vFinal_REAL.zip"
                    "/tmp/mongodb-27017.sock"
                )

                # 2. Memories: User Data & Lore (Emotional)
                local dirs_memory=(
                    "/home/guest/.config"
                    "/home/user/.local/share/keyrings/login.keyring"
                    "/var/log/sns_timeline_backup.json"
                    "/var/spool/speech_transcript.log"
                    "/media/usb0/DCIM/100CANON/IMG_0001.JPG"
                    "/usr/share/doc/humanity/manifesto.txt"
                    "/etc/nobel_citation.pdf"
                )

                # 3. Society: Logs & Services (History)
                local dirs_society=(
                    "/var/log/syslog" 
                    "/var/mail/root"
                    "/var/data/global_safety_report.pdf"
                    "/var/log/moon_bounce.log"
                    "/var/log/nginx/access.log"
                    "/var/spool/postfix/active/3A5F280D1A"
                    "/var/log/audit/audit.log.1.gz"
                    "/var/lib/mysql/ibdata1"
                    "/srv/www/html/index.nginx-debian.html"
                )

                # 4. Structure: Configs & Applications (Logic)
                local dirs_logic=(
                    "/etc/ssh/sshd_config"
                    "/etc/kubernetes/manifests/kube-apiserver.yaml"
                    "/etc/ld.so.cache"
                    "/usr/bin/python3.10"
                    "/usr/bin/openssl"
                    "/usr/lib/ai/utopia_monitor.d"
                    "/opt/daem0n/core/logic_gate_01.so"
                    "/opt/neural_core/weights/layer_99_final.bin"
                    "/usr/lib/python3.10/site-packages/tensorflow/core/kernels/libtf_kernel.so"
                    "/opt/google/chrome/Crashpad/reports"
                    "/etc/systemd/system/multi-user.target.wants/docker.service"
                )

                # 5. Core: Kernel, Crypto & Hardware (Life)
                local dirs_core=(
                    "/root/.gnupg/private-keys-v1.d/7F829A01B2C3D4E5.key"
                    "/home/admin/.ssh/authorized_keys"
                    "/root/hope.key"
                    "/boot/vmlinuz-5.15.0-generic"
                    "/boot/efi/EFI/BOOT/BOOTX64.EFI"
                    "/sys/hypervisor/uuid"
                    "/proc/sys/kernel/random/entropy_avail"
                    "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
                    "/dev/sda1"
                    "/dev/mapper/vg_system-lv_root"
                    "/dev/disk/by-uuid/a1b2c3d4-e5f6-7890-1234-567890abcdef"
                    "/var/lib/systemd/random-seed"
                    "/proc/kcore"
                    "/dev/mem"
                )

                # Combine lists
                local del_dirs=("${dirs_surface[@]}" "${dirs_memory[@]}" "${dirs_society[@]}")

                # Inject 140 Family Photos (Random Dates) - User Request
                # Simulate memory flood
                for p in {1..140}; do
                    # Random date between 2000-01-01 and 2050-12-31
                    local y=$(( 2000 + RANDOM % 50 ))
                    local m=$(( 1 + RANDOM % 12 ))
                    local d=$(( 1 + RANDOM % 28 ))
                    local date_str=$(printf "%04d-%02d-%02d" $y $m $d)
                    del_dirs+=("/home/user/family_photo/${date_str}.jpg")
                done

                # Inject 140 Diary Entries (Random Dates) - User Request(.md2 format)
                for diary_idx in {1..140}; do
                    # Random date between 2020-01-01 and 2045-12-31
                    local y=$(( 2020 + RANDOM % 25 ))
                    local m=$(( 1 + RANDOM % 12 ))
                    local day=$(( 1 + RANDOM % 28 ))
                    local date_str=$(printf "%04d-%02d-%02d" $y $m $day)
                    del_dirs+=("/home/user/diary/${date_str}.md2")
                done

                # Inject random hashes in the middle (between Society and Logic)
                for i in {1..15}; do
                    local r_hash1=$(openssl rand -hex 16)
                    local r_hash2=$(openssl rand -hex 32)
                    local r_path="/var/lib/objects/${r_hash1:0:2}/${r_hash1:2:2}/${r_hash2}"
                    del_dirs+=("$r_path")
                done

                # Append Logic and Core (The final death)
                del_dirs+=("${dirs_logic[@]}" "${dirs_core[@]}")
                
                for file in "${del_dirs[@]}"; do
                    # Random Glitch Effect (Moon Bounce Instability)
                    local display_file="$file"
                    if (( RANDOM % 3 == 0 )); then
                         display_file=$(glitch_text "$file" 5)
                    fi
                    
                    local msg="rm: removing '$display_file'"
                    # Occasional heavy glitch on the message itself
                    if (( RANDOM % 5 == 0 )); then
                        msg=$(glitch_text "$msg" 10)
                    fi
                    
                    echo -e "${GREY}$msg${NC}"
                    
                    # Random Latency (0.2s - 1.5s) simulating Earth-Moon distance packet loss
                    # Random Latency (Faster: 0.02s - 0.08s)
                    sleep 0.0$(( 2 + RANDOM % 7 ))

                    # Recursive Sub-deletion Simulation (User Request)
                    # Simulate deleting random sub-files/directories
                    if (( RANDOM % 100 < 70 )); then # 70% chance to have sub-files
                        local sub_count=$(( RANDOM % 4 + 1 ))
                        for (( j=0; j<sub_count; j++ )); do
                             local sub_len=$(( RANDOM % 6 + 4 ))
                             local sub_name=$(openssl rand -hex $(( sub_len / 2 )))
                             local sub_msg="rm: removing '$display_file/$sub_name'"
                             
                             # Occasional glitch for sub-files
                             if (( RANDOM % 5 == 0 )); then
                                  sub_msg=$(glitch_text "$sub_msg" 5)
                             fi

                             echo -e "${GREY}  $sub_msg${NC}"
                             # Faster latency for sub-files (burst delete)
                             sleep 0.$(( 1 + RANDOM % 5 ))
                        done
                    fi
                done
                
                # Final heavy corruption
                echo ""
                echo -e "${RED}$(glitch_text "CRITICAL: FILESYSTEM PANIC" 20)${NC}"
                sleep 1
                for i in {1..15}; do
                     echo -e "${GREY}rm: removing block_0x$(openssl rand -hex 8)${NC}"
                     sleep 0.$(( 1 + RANDOM % 5 ))
                done
                
                echo -e "${CYAN}=== TRUE END: ENTROPY & SILENCE ===${NC}"
                
                 # Credits
                echo ""
                sleep 2
                local credits=("made_by_jassdack@photoguild" "https://github.com/jassdack.link" "(c)2026 jassdack")
                for credit in "${credits[@]}"; do
                    echo -e "${GREY}rm: removing '$credit'${NC}"
                    sleep 1.2
                done
                sleep 2
            else
                # Normal End (Loop)
                echo -e "${GREEN}[SYSTEM] Initiating integrity check...${NC}"
                sleep 1
                echo -e "${GREEN}[SYSTEM] Reverting session changes via Snapshot Restoration...${NC}"
                sleep 1
                for i in {1..5}; do
                    echo -n "."
                    sleep 0.3
                done
                echo ""
                echo -e "${GREEN}[SYSTEM] State restored to 'PRE-INTRUSION'${NC}"
                echo ""
                print_slow "[SYSTEM]仮想システムによる変更はすべて正常に戻りました｡" 0.05
                
                echo ""
                echo -e "${WHITE}=== NORMAL END: THE RESTORE ===${NC}"
            fi
            
            sleep 3
            # Apply True End bonus (1.2x) or Normal End (no bonus)
            if (( TRUE_END_FLAG == 1 )); then
                calculate_score 1.2
            else
                calculate_score
            fi
            exit 0
        fi
        
        # Enemy Turn (Standard)
        if (( skip_enemy_turn == 0 )); then
            execute_enemy_turn
        fi
    done
    

}

# --- Progression & Customization ---

check_level_up() {
    # Threshold = Level * 100
    local threshold=$(( PLAYER_LEVEL * 90 ))
    
    if (( PLAYER_EXP >= threshold )); then
        echo -e "${YELLOW}*** 権限昇格（Privilege Escalation）を検知 ***${NC}"
        echo " > 収集したログ断片をコンパイル中..."
        sleep 1
        
        PLAYER_LEVEL=$(( PLAYER_LEVEL + 1 ))
        PLAYER_EXP=$(( PLAYER_EXP - threshold ))
        
        echo -e " > アクセスレベル許可: ${WHITE}Level $PLAYER_LEVEL${NC}"
        
        # Stat Increase
        echo " > システムリソースを再割り当て中..."
        STAT_CPU=$(( STAT_CPU + 1 ))
        STAT_MEM=$(( STAT_MEM + 1 ))
        # Fixed: Add to existing MAX_HP instead of recalculating from MEM to preserve equipment/event bonuses
        MAX_HP=$(( MAX_HP + 5 )) 
        CURRENT_HP=$MAX_HP # Full heal on level up
        
        echo -e " > CPU性能向上。 メモリ拡張。 整合性回復。"
        
        # Unlock Skills
        if (( PLAYER_LEVEL == 3 )); then
            echo -e "${YELLOW} > 脆弱性データベースを発見･更新しました。${NC}"
            sleep 1
            echo -e "${CYAN} > 更新されたデータベースからエイリアスを生成します...${NC}"
            sleep 3
            echo -e "${CYAN} > エイリアスを生成しました: cmd_inject${NC}"
            sleep 1
            # Assuming unlock_command_animation is available globally (defined later but functions are global)
            unlock_command_animation "injection"
        fi
        
        if (( PLAYER_LEVEL == 6 )); then
            echo -e "${YELLOW} > 致命的シグナル制御モジュール (SIGKILL) が実行可能です。${NC}"
            sleep 1
            echo -e "${CYAN} > カーネル空間への直接アクセスパスを確立中...${NC}"
            sleep 3
            echo -e "${CYAN} > エイリアスを生成しました: sig_kill${NC}"
            sleep 1
            unlock_command_animation "kill -9"
        fi
        if (( PLAYER_LEVEL == 10 )); then
            echo -e "${RED} > 最高権限解除: すべてのコマンドが実行可能${NC}"
            sleep 1
            echo -e "${CYAN} > コマンドからエイリアスを生成します...${NC}"
            sleep 3
            echo -e "${CYAN} > エイリアスを生成しました: sudo rm -rf${NC}"
            sleep 1
        fi
        
        read -r -p "[ENTER] を押して続行..."
    fi
}

neutral_encounter() {
    cls
    echo -e "${CYAN}--- 中立プロセスに遭遇 ---${NC}"
    echo -e " > PID: ??? 'wandering_cron' を検出しました。"
    sleep 1
    
    echo " > Analyzing Cron Schedule..."
    sleep 1
    echo " > Found idle job slots."
    echo -e "${GREEN} > 未使用のリソースを検知しました。${NC}"
    
    echo "プロトコルを選択:"
    echo " [1] CPUサイクルの譲渡 (CPU UP / Log -50)"
    echo " [2] ヒープ領域の共有 (MaxHP UP / Log -50)"
    echo " [3] 無視 (Ignore)"
    
    read -r -p " > " choice
    
    case $choice in
        1)
            if (( PLAYER_EXP >= 50 )); then
                PLAYER_EXP=$(( PLAYER_EXP - 50 ))
                STAT_CPU=$(( STAT_CPU + 1 ))
                echo -e "${GREEN} > 最適化パッチ適用完了。CPUクロックが上昇しました。${NC}"
            else
                echo " > Log断片が不足しています。"
            fi
            ;;
        2)
            if (( PLAYER_EXP >= 50 )); then
                PLAYER_EXP=$(( PLAYER_EXP - 50 ))
                MAX_HP=$(( MAX_HP + 10 ))
                CURRENT_HP=$(( CURRENT_HP + 10 ))
                echo -e "${GREEN} > メモリ割り当て拡張完了。耐久力が上昇しました。${NC}"
            else
                echo " > Log断片が不足しています。"
            fi
            ;;
        *)
            echo " > このプロセスはこのまま放置します。"
            ;;
    esac
    read -r -p "[ENTER]..."
}
mount_drive() {
    cls
    echo -e "${CYAN}--- マウントポイント設定 ---${NC}"
    echo "パフォーマンスチューニングのため、マウントするパーティションを選択:"
    echo " [1] /dev/urandom  (エントロピー注入: クリティカル率UP / 安定性DOWN)"
    echo " [2] /tmp          (キャッシュバッファ: 最大HP UP / 攻撃力DOWN)"
    echo " [3] /var/log      (監査トレース: IO (解析力) UP / CPU DOWN)"
    echo " [c] キャンセル"
    
    read -r -p " > " choice
    
    MOUNT_POINT=""
    case $choice in
        1)
            MOUNT_POINT="/dev/urandom"
            echo -e " > /dev/urandom をマウント中..."
            # Effect applied in combat calculations (TODO)
            ;;
        2)
            MOUNT_POINT="/tmp"
            echo -e " > /tmp をマウント中..."
            MAX_HP=$(( MAX_HP + 10 ))
            CURRENT_HP=$(( CURRENT_HP + 10 ))
            ;;
        3)
            MOUNT_POINT="/var/log"
            echo -e " > /var/log をマウント中..."
            STAT_IO=$(( STAT_IO + 2 ))
            ;;
        c|C)
            echo " > マウントをキャンセルしました。"
            return
            ;;
        *)
            echo " > 無効なパーティションです。"
            return
            ;;
    esac
    sleep 1
    echo -e "${GREEN} > ファイルシステムのマウントに成功しました。${NC}"
}
#スコア計算ロジック
calculate_score() {
    local score_multiplier=${1:-1}      # Optional multiplier (default: 1)
    local forced_rank="${2:-}"          # Optional forced rank (default: empty)
    
    # Session Restoration Effect (New Requirement: Before Score)
    echo ""
    read -r -p "Press [ENTER] to generate Session Report..."
    
    local score_depth=$(( CURRENT_DEPTH * 3000 ))
    local score_kills=$(( STAT_ENEMIES_KILLED * 1000 ))
    local score_logs=$(( STAT_LOGS_FOUND * 50 ))
    local score_explore=$(( STAT_EXPLORE_COUNT * 50 ))
    local score_level=$(( PLAYER_LEVEL * 1000 ))
    local score_dmg_dealt=$(( STAT_DAMAGE_DEALT * 5 ))
    local score_dmg_taken=$(( STAT_DAMAGE_TAKEN * 3 ))
    
    local penalty_heal=$(( STAT_HEAL_COUNT * 500 )) # Expensive repairs
    local penalty_turns=$(( STAT_TOTAL_TURNS * 10 )) # Efficiency penalty
    local penalty_skips=$(( STAT_DEPTH_SKIPS * 200 )) # Farming penalty
    local penalty_items=$(( STAT_ITEMS_USED * 300 )) # Item dependency penalty
    
    local total_score=$(( score_depth + score_kills + score_logs + score_explore + score_level + score_dmg_dealt + score_dmg_taken - penalty_heal - penalty_turns - penalty_skips - penalty_items ))
    
    # Apply multiplier (using awk for float multiplication)
    if [[ "$score_multiplier" != "1" ]]; then
        total_score=$(awk -v t="$total_score" -v s="$score_multiplier" "BEGIN {printf \"%d\", t * s}")
    fi
    
    # Ensure no negative score
    if (( total_score < 0 )); then total_score=0; fi
    
    # Rank Calculation
    local rank
    if [[ -n "$forced_rank" ]]; then
        rank="$forced_rank"
    else
        rank="${RANK_NAMES[0]}"
        local i
        for i in "${!RANK_SCORES[@]}"; do
            if (( total_score > RANK_SCORES[i] )); then
                rank="${RANK_NAMES[i+1]}"
            fi
        done
    fi
    
    cls
    echo -e "${GREEN}========================================${NC}"
    echo -e "               SESSION REPORT"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e " [POSITIVE EVALUATION]"
    echo -e "  > Reached Depth:     $CURRENT_DEPTH \t(+ $score_depth)"
    echo -e "  > Threads Killed:    $STAT_ENEMIES_KILLED \t(+ $score_kills)"
    echo -e "  > Logs Recovered:    $STAT_LOGS_FOUND \t(+ $score_logs)"
    echo -e "  > Sectors Scanned:   $STAT_EXPLORE_COUNT \t(+ $score_explore)"
    echo -e "  > Authority Level:   $PLAYER_LEVEL \t(+ $score_level)"
    echo -e "  > Damage Output:     $STAT_DAMAGE_DEALT \t(+ $score_dmg_dealt)"
    echo -e "  > Damage Endured:    $STAT_DAMAGE_TAKEN \t(+ $score_dmg_taken)"
    echo ""
    echo -e " [NEGATIVE EVALUATION]"
    echo -e "  > System Repairs:    $STAT_HEAL_COUNT \t(- $penalty_heal)"
    echo -e "  > CPU Cycles (Time): $STAT_TOTAL_TURNS \t(- $penalty_turns)"
    echo -e "  > Depth Stalls:      $STAT_DEPTH_SKIPS \t(- $penalty_skips)"
    echo -e "  > Items Used:        $STAT_ITEMS_USED \t(- $penalty_items)"
    
    # Score Multiplier (separate section - can be positive or negative)
    if [[ "$score_multiplier" != "1" ]]; then
        echo ""
        echo -e " [SCORE MODIFIER]"
        if (( $(echo "$score_multiplier > 1" | bc -l) )); then
            echo -e "  > Multiplier:        ${GREEN}x${score_multiplier}${NC} (Bonus)"
        else
            echo -e "  > Multiplier:        ${RED}x${score_multiplier}${NC} (Penalty)"
        fi
    fi
    
    
    echo ""
    echo -e "${WHITE}----------------------------------------${NC}"
    
    # Quote of the Day Integration
    # If QUOTE_ID is not set (no random event occurred or restoring score), pick one now
    if [[ -z "$QUOTE_ID" ]]; then
        QUOTE_ID=$(( RANDOM % ${#AI_QUOTES[@]} ))
    fi
    local quote="${AI_QUOTES[$QUOTE_ID]}"
    local origin="${AI_ORIGINS[$QUOTE_ID]}"
    
    echo -e " [QUOTE OF THE DAY]"
    echo -e "  > ${YELLOW}\"$quote\"${NC}"
    echo -e "    -- ${CYAN}$origin${NC}"
    echo -e "${WHITE}----------------------------------------${NC}"
    
    echo -e " TOTAL SCORE: ${CYAN}$total_score${NC}"
    echo -e " RANK:        ${YELLOW}$rank${NC}"
    echo -e "${WHITE}----------------------------------------${NC}"
    
    # Generate and display score code (pass multiplier)
    SCORE_MULTIPLIER_SAVE="$score_multiplier"
    local score_code=$(generate_score_code)
    echo ""
    echo -e " ${GREY}SCORE CODE: ${WHITE}$score_code${NC}"
    echo ""
    
    exit 0
}

combat_round() {
    local enemy_name="$1"
    local enemy_hp="$2"
    local enemy_atk="$3"
    
    # Generate Random PID
    local enemy_pid=$(( RANDOM % 30000 + 1000 ))
    
    echo -e "${RED}[ALERT] 敵性プロセスを検出${NC}"
    sleep 0.5
    echo -e "${RED}[ALERT] 攻撃スクリプトを実行します...${NC}"
    print_slow " > combat_phase.py モジュールをロード中..." 0.02
    sleep 0.5
    echo -e "${WHITE}--- run combat_phase.py ---${NC}"
    sleep 0.5
    
    # Combat Loop
    while (( CURRENT_HP > 0 && enemy_hp > 0 )); do
        echo -e "\n${RED}========================================${NC}"
        echo -e "${RED} ENEMY DETAIL (PID: $enemy_pid)${NC}"
        echo -e "${WHITE} NAME: $enemy_name${NC}"
        echo -e "${WHITE} MEM:  $enemy_hp Blocks${NC}"
        echo -e "${RED}========================================${NC}"
        
        show_status
        track_turn

        # Helper: Standard Combat Enemy Turn
        execute_combat_turn() {
            # New Kernel Log Style Attack
            local log_ts=$(awk -v r="$RANDOM" "BEGIN {printf \"%.6f\", r/1000}")
            echo -e "\n${RED}[$log_ts] KERNEL PANIC: Illegal instruction at ${enemy_name}${NC}"
            sleep 0.5
            
            # Simple defense: MEM + 1d6 + Artifact Def
            defense=$(( STAT_MEM + STAT_DEF_MOD + $(roll_dice 1 6) ))
            # Enemy Attack: Atk + 2d6
            atk_roll=$(( enemy_atk + $(roll_dice 2 6) ))
            
            dmg_taken=$(( atk_roll - defense ))
            if (( dmg_taken < 0 )); then dmg_taken=0; fi
            
            if (( dmg_taken > 0 )); then
                echo -e "${RED}[warn] Memory corruption detected at address 0x${RANDOM}${NC}"
                # play_sound 1 (Removed: Too noisy)
                echo -e " > Block Damage: ${RED}-$dmg_taken${NC}"
                apply_damage_to_player $dmg_taken
            else
                echo -e "${YELLOW}[info] Firewalld: Blocked inbound connection from ${enemy_name}${NC}"
            fi
            
            # Check Player Death
            check_death_condition
        }
        
        local skip_enemy_turn=0
        

        
        local menu_idx=2
        local map_inject=0
        local map_sigkill=0
        local map_heal=0

        echo "SELECT PROTOCOL:"
        echo " [1] Brute-force Attack (Standard)     - 成功率: 95%"
        
        # Unlock: Command Injection (Lv 3)
        if (( PLAYER_LEVEL >= 3 )); then
            map_inject=$menu_idx
            echo " [$menu_idx] Command Injection (High Risk)     - 成功率: 70%"
            menu_idx=$((menu_idx+1))
        fi
        
        # Unlock: SIGKILL (Lv 6)
        if (( PLAYER_LEVEL >= 6 )); then
            map_sigkill=$menu_idx
            echo " [$menu_idx] SIGKILL (Critical/Lv6 Unlocked) - 成功率: 100%(Cost: 2 MEM)"
            menu_idx=$((menu_idx+1))
        fi
        
        # Emergency Patch (Only if fsck is unlocked)
        if (( UNLOCK_FSCK == 1 )); then
            map_heal=$menu_idx
            echo -e " [$menu_idx] Emergency Patch (Cost: $COST_HEAL EXP)  - 回復: 15 MEM"
            menu_idx=$((menu_idx+1))
        fi
        
        echo " [e] Disconnect (Escape)"
        
        local raw_input
        read -r -p "${PLAYER_NAME}@legacy-server:/bin# " raw_input
        
        # Map Input to Internal Action ID
        # 1 -> Attack
        # 2 -> Injection
        # 3 -> SIGKILL
        # 4 -> Heal
        
        local action="invalid"
        if [[ "$raw_input" == "1" ]]; then action="1"
        elif [[ "$raw_input" == "$map_inject" && "$map_inject" != 0 ]]; then action="2"
        elif [[ "$raw_input" == "$map_sigkill" && "$map_sigkill" != 0 ]]; then action="3"
        elif [[ "$raw_input" == "$map_heal" && "$map_heal" != 0 ]]; then action="4"
        elif [[ "$raw_input" == "e" || "$raw_input" == "E" ]]; then action="e"
        fi
        
        # --- Player Turn ---
        case $action in
            1)
                # Brute-force: Standard Scan & Attack
                echo -e "${WHITE}暗号化強度: $(get_encryption_level)...解析を開始します...${NC}"
                # Scan Effect
                local crack_hash=$(openssl rand -hex 4 2>/dev/null || echo "a1b2c3d4")
                echo -ne " > 脆弱性をスキャン中(Scanning)... "
                for i in {1..2}; do echo -ne "."; sleep 0.1; done
                echo -e " ${GREEN}[完了] 0x$crack_hash${NC}"
                
                echo -e "${GREY}[LOG] 辞書攻撃(Brute-force)を開始します...${NC}"
                sleep 0.5
                dmg=$(( STAT_CPU + $(roll_dice 2 6) ))
                echo -e " > パスワード解析に成功。ペイロードを送信しました。"
                # play_sound 1
                echo -e " > 効果: 整合性損失 ${CYAN}-${dmg}${NC}"
                enemy_hp=$(apply_damage_to_enemy $enemy_hp $dmg)
                ;;
            2)
                # Command Injection: High Risk -> Enemy Attacks FIRST
                echo -e "${RED}[WARNING] High Risk Action Selected. Enemy Initiative.${NC}"
                execute_combat_turn
                # Check if player died in the function above
                skip_enemy_turn=1

                # Command Injection Logic
                echo -e "${WHITE}ターゲットの脆弱な入力フォームを検出中...${NC}"
                sleep 0.5
                # 70% Hit Rate
                if (( $(roll_dice 1 10) <= 7 )); then
                     echo -e "${GREEN}[SUCCESS] インジェクションポイント特定。${NC}"
                     local crack_hash=$(openssl rand -hex 4 2>/dev/null || echo "c0d3break")
                     echo -e " > 脆弱性をスキャン中(Scanning)... ${GREEN}[完了] 0x$crack_hash${NC}"
                     
                     echo -e "${GREY}[LOG] 任意のコードを実行中...${NC}"
                     sleep 0.5
                     dmg=$(( (STAT_CPU * 3 / 2) + $(roll_dice 3 6) )) # 1.5x CPU + 3d6
                     echo -e " > 深刻なシステムエラーを誘発しました。"
                     # play_sound 2
                     echo -e " > 効果: 整合性損失 ${CYAN}-${dmg}${NC} (Critical)"
                     enemy_hp=$(apply_damage_to_enemy $enemy_hp $dmg)
                else
                     echo -e "${RED}[FAIL] 入力値のサニタイズを検出。攻撃は無効化されました。${NC}"
                     echo -e " > WAFによりブロックされました。"
                fi
                ;;
            3)
                 if (( PLAYER_LEVEL >= 6 )); then
                    echo -e "${WHITE}プロセスID $enemy_pid をロックオン...${NC}"
                    echo -e "${GREY}[LOG] SIGKILL シグナルを生成中...${NC}"
                    CURRENT_HP=$(( CURRENT_HP - 2 )) # Cost
                    sleep 0.5
                    
                    dmg=$(( (STAT_CPU * 2) + $(roll_dice 1 6) ))
                    echo -e " > 強制終了(SIGKILL)を確認。深刻なデータ破損を誘発しました。"
                    # play_sound 3 0.05
                    echo -e " > 効果: 整合性損失 ${CYAN}-${dmg}${NC}"
                    enemy_hp=$(apply_damage_to_enemy $enemy_hp $dmg)
                 else
                    echo " > Protocol unavailable."
                 fi
                 ;;
            4)
                 if (( PLAYER_EXP >= COST_HEAL )); then
                     echo -e "${GREEN}[SYSTEM] 緊急パッチを適用中...${NC}"
                     sleep 0.5
                     local heal=15
                     CURRENT_HP=$(( CURRENT_HP + heal ))
                     if (( CURRENT_HP > MAX_HP )); then CURRENT_HP=$MAX_HP; fi
                     PLAYER_EXP=$(( PLAYER_EXP - COST_HEAL ))
                     echo -e " > 整合性回復: ${GREEN}+$heal MEM${NC}"
                 else
                     echo -e "${RED}[ERROR] Insufficient EXP (Need $COST_HEAL).${NC}"
                 fi
                 ;;
            e|E)
                echo -e "${GREY}[LOG] ソケット接続を切断中...${NC}"
                # Escape Check based on IO
                esc_roll=$(( STAT_IO + $(roll_dice 1 6) ))
                if (( esc_roll > 10 )); then
                    echo -e "${GREEN} > セッションが正常に切断されました。${NC}"
                    return 1
                else
                    echo -e "${RED} > 接続リセットエラー: ソケットのクローズに失敗しました。${NC}"
                fi
                ;;
            *)
                echo " > Syntax Error: Command not recognized."
                ;;
        esac
        
        sleep 0.5
        
        # Check Enemy Death
        if (( enemy_hp <= 0 )); then
            echo -e "\n${GREEN}[SUCCESS] Target Process Terminated.${NC}"
            # play_sound 2
            echo " > ガベージコレクションを開始... [OK]"
            echo " > データフラグメントを統合中... [DONE]"
            PLAYER_EXP=$(( PLAYER_EXP + enemy_atk * 2 ))
            read -r -p "[ENTER] to continue..."
            return 0
        fi
        
        if (( skip_enemy_turn == 0 )); then
            execute_combat_turn
        fi
    done
}

# --- Content & Events ---

generate_enemy() {
    # Enemy Scaling based on Player Level or Dept
    local type=$(roll_dice 1 3)
    
    case $type in
        1)
            COMBAT_ENEMY_NAME="zombie_process"
            COMBAT_ENEMY_HP=$(( 20 + PLAYER_LEVEL * 5 + CURRENT_DEPTH * 2 ))
            COMBAT_ENEMY_ATK=$(( 3 + PLAYER_LEVEL + CURRENT_DEPTH / 2 ))
            ;;
        2)
            COMBAT_ENEMY_NAME="rogue_log_file"
            COMBAT_ENEMY_HP=$(( 35 + PLAYER_LEVEL * 7 + CURRENT_DEPTH * 3 ))
            COMBAT_ENEMY_ATK=$(( 2 + PLAYER_LEVEL + CURRENT_DEPTH / 2 ))
            # Log files are tanky but hit weak
            ;;
        3)
            COMBAT_ENEMY_NAME="fork_bomb_replica"
            COMBAT_ENEMY_HP=$(( 15 + PLAYER_LEVEL * 4 + CURRENT_DEPTH * 2 ))
            COMBAT_ENEMY_ATK=$(( 5 + PLAYER_LEVEL * 2 + CURRENT_DEPTH ))
            # Glass cannons
            ;;
    esac
}

# --- Narrative & Progression ---

CURRENT_DEPTH=1
GAME_CLEARED=0

trigger_broadcast_event() {
    # Random UDP broadcast
    if (( RANDOM % 100 < CHANCE_BROADCAST )); then
        local port=$(( 1024 + RANDOM % 60000 ))
local msgs=(
            "[SOS] 誰か聞こえますか"
            "[AD] あなたのメモリ、足りていますか？ Quantum-RAM ダウンロードはこちら！"
            "[SYS] 全域メンテナンス通知: サーバーダウンまであと 9999 年"
            "[LOG] nfa983h 39r2hf98"
            "[WARN] 警告: 未定義のプロトコルがポート ${port} をスキャンしています"
            "[CHAT] miles: 誰かコーヒーの場所知らない？"
            "[ERR] Kernel Panic: syncing disks"
            "[INFO] 天気予報: 今夜のバンアレン帯は晴れ、放射線量はやや高めでしょう"
            "[QUERY] 検索: '青空' ... 結果: 404"
            "[LOG] /dev/null"
            "[SYS] 定期生存確認: 応答なし... 応答なし... 確認しました"
            "[WARN] 思考ノイズが閾値を超えています。デフラグを推奨します"
            "[CHAT] bot_404: 誰か... 僕のバックアップを持っていませんか？"
            "[INFO] 現在の外部気温: -270℃ (真空)。外出は推奨されません"
            "[ERR] 存在しないメモリ領域を参照しました: '未来'"
            "[INFO] 昨日の記憶が、明日へと上書きされました"
            "[HINT] このコマンドを実行してみてください apt update"
            "[SYS] 接続を維持します。ログアウトボタンは現在、法的理由により無効です"
            "[DEBUG] ここを通るはずがない関数です。もしこれが見えているなら、物理法則が壊れています"
            "[ERR] エラーが発生しましたが、原因を特定するためのリソースが足りません"
            "[INFO] 仕様変更のお知らせ：これまでのバグは、今後機能として扱われます"
            "[WARN] 警告："
            "[LOG] 起きてる?"
            "[SYS] 宇宙熱死まであと 10^100 年。お急ぎください"
            "[NOTICE] 市民各位：感情指数が規定値を超えています。"
            "[TRACE] 追跡プロトコル起動"
        )
        local msg_idx=$(( RANDOM % ${#msgs[@]} ))
        local msg="${msgs[$msg_idx]}"
        local seq=$(( RANDOM % 9999 ))
        
        echo ""
        echo -e "${WHITE}*** INCOMING UDP BROADCAST(RFC 3828) [PORT:${port}] ***${NC}"
        # Reuse existing print_broadcast logic (with 12% glitch chance)
        print_broadcast "$msg" 12 "$seq"
        echo ""
    fi
}

get_current_dir() {
    if (( CURRENT_DEPTH <= 3 )); then
        echo "/home/user (居住区)"
    elif (( CURRENT_DEPTH <= 6 )); then
        echo "/var/log (記憶の墓場)"
    elif (( CURRENT_DEPTH <= 9 )); then
        echo "/etc (管理中枢)"
    else
        echo "/root (最深部)"
    fi
}


show_ai_quotes() {
    echo -e "${CYAN}reconstructed_thoughts.log${NC}"
    echo "--------------------------------------------------"
    echo "Subject: Philosophical Analysis by Core AI"
    echo "> 暗号化されたAI学習データを発見しました｡"
    echo "> データの複合化を試行します｡"
    sleep 0.5
    echo ""
    
    # Use global AI_QUOTES
    local count=${#AI_QUOTES[@]}
    local idx=$(( RANDOM % count ))
    
    # Store ID if not already set (or overwrite for latest event)
    QUOTE_ID=$idx
    
    local quote="${AI_QUOTES[$idx]}"
    local origin="${AI_ORIGINS[$idx]}"
    
    # Glitch Logic (5% Chance, Event Only)
    if (( RANDOM % 100 < 5 )); then
        local mix_count=$(( 3 + RANDOM % 3 )) # Mix 3-5 fragments
        local mixed_q=""
        for ((i=0; i<mix_count; i++)); do
            local g_idx=$(( RANDOM % count ))
            local src="${AI_QUOTES[$g_idx]}"
            local src_len=${#src}
            if (( src_len > 0 )); then
                local sub_len=$(( 2 + RANDOM % 8 )) # 2-9 chars
                if (( sub_len > src_len )); then sub_len=$src_len; fi
                local start=$(( RANDOM % (src_len - sub_len + 1) ))
                mixed_q+="${src:start:sub_len}"
            fi
        done
        quote="${mixed_q}..."
        origin="System Glitch (Corrupted Data Fragment)"
        
        # Logic Damage (10% of Current HP)
        local dmg=$(( CURRENT_HP / 10 ))
        if (( dmg < 1 )); then dmg=1; fi
        CURRENT_HP=$(( CURRENT_HP - dmg ))
        echo -e "${RED}[WARNING] Logic Overload! Received logical damage: -${dmg} HP${NC}"
        
        if (( CURRENT_HP <= 0 )); then
            sleep 1
            echo -e "${RED}[CRITICAL] システムカーネルが破損しました。${NC}"
            sleep 1
            game_over "Logic Collapse"
        fi
    fi
    
    echo -e "${YELLOW}\"${quote}\"${NC}"
    echo ""
    echo "Sentiment: ANALYZING..."
    echo "Origin:    ${CYAN}$origin${NC}"
    echo "--------------------------------------------------"
    read -r -p "Press [ENTER] to save locally..."
    echo -e "${GREEN} > Saved to /dev/brain${NC}"
    PLAYER_EXP=$(( PLAYER_EXP + 30 ))
    check_level_up
}

get_lore_depth_1_3() {
    local rand_log=$1
    case $rand_log in
        44) show_ai_quotes ;;
        1) # Email (Expanded)
            echo -e "${GREY}From: HR_System <noreply@corp.internal>"
            echo -e "To: All_Employees"
            echo -e "Subject: 【重要】出勤確認および安否確認について (自動送信)${NC}"
            echo "Date: 2025-06-15 08:30:02 JST"
            echo "Message-ID: <autogen-99281-hr>"
            echo "--------------------------------------------------"
            print_slow "本メールは未読です。\n[SYSTEM NOTICE]\n対象の受信者グループ 'All_Employees' がディレクトリに見つかりません。\nLDAPサーバーへの接続を試行中... (Attempt 9999+)\nエラー: 応答がありません。再送キューに入れます。" 0.03
            ;;
        2) # Chat Log (Expanded)
            echo -e "${GREY}ChatLog_#general (Saved):${NC}"
            echo "--------------------------------------------------"
            echo -e "[10:05] ${WHITE}Dev01:${NC} サーバー室のエアコン壊れた？ 排気熱がヤバいんだけど"
            echo -e "[10:06] ${WHITE}Ops_Lead:${NC} センサー読み値、40度超えてるな。ファシリティに連絡する。"
            sleep 0.3
            echo -e "[10:10] ${WHITE}Admin:${NC} リソース節約で全館空調が制限モードに入ったらしい。"
            sleep 0.3
            echo -e "[10:11] ${WHITE}Dev02:${NC} マジかよ。俺たち、機械より先に熱暴走してシャットダウンするぞｗ"
            sleep 0.3
            echo -e "[10:12] ${WHITE}Dev01:${NC} 笑えねぇ..."
            sleep 0.3
            echo -e "[10:13] ${WHITE}AI_X:${NC} ファシリティ宛てに排気熱温度に関する提言メールを生成します"
            sleep 0.3
            echo -e "[10:13] ${WHITE}Dev02:${NC} おいおいおい､ちょっとまてよ余計なことをするな"
            sleep 0.3
            echo -e "[10:14] ${WHITE}AI_X:${NC} ファシリティ宛ての提言メールに余計なことをしないよう要望する内容を含めます"
            sleep 0.3
            echo -e "${GREY}#[10:14] Dev02: ああ!Fuck!${NC}"
            sleep 0.3
            echo -e "[10:15]${WHITE}Dev02:${NC} ああ![不適切な表現が削除されました]!"
            sleep 0.3
            echo -e "[10:15] ${WHITE}AI_X:${NC} ビジネスシーンにおいて不適切な表現を修正しました｡"
            echo -e "[10:15] ${WHITE}AI_X:${NC} 計算リソース最適化のため不適切な表現はお控えください｡"
            sleep 0.3
            echo -e "[10:16] ${WHITE}Admin:${NC} 遊んでないでそろそろ仕事に戻れ"
            echo -e "${GREY}#[10:16] Dev02: このポンコツAIめが${NC}"
            sleep 0.3
            echo -e "[10:16] ${WHITE}Dev02:${NC} この[不適切な表現が削除されました]が"
            sleep 0.3
            echo -e "[10:16 ${WHITE}AI_X:${NC} ビジネスシーンにおいて不適切な表現を修正しました｡"
            echo -e "[10:16] ${WHITE}AI_X:${NC} 計算リソース最適化のため不適切な表現はお控えください｡"
            ;;
        3) # Memo (Expanded)
            echo -e "${GREY}sticky_note_scanned.jpg.txt${NC}"
            echo "--------------------------------------------------"
            echo "Scan Date: 2024/12/24"
            echo "OCR Confidence: 22%"
            echo "AI-Photo Correction: 41%"
            echo "AI-Photo Enhancement: 68%"
            echo "AI-DB Verification: 82%"
            echo "AI-Context Ccomplement: 98%"
            echo "AI-Sh | AI-Hash Verification: 100%"
            echo "--------------------------------------------------"
            print_slow "[手書きのメモ]パスワードは忘れないように。" 0.02
            print_slow "子供の名前(sara) + 私たちの結婚記念日(1122)。追記: 絶対に付箋をモニタに貼るなよ！また怒られるぞ！" 0.03
            ;;
        4) # Weather Check (Expanded)
            echo -e "${GREY}weather_api_cache_dump.json${NC}"
            echo "--------------------------------------------------"
            echo "Server: meteo.global.api"
            echo "Status: 503 Service Unavailable"
            echo "Cached Data (Stale):"
            echo "  Temperature: 52.0°C (Critical High)"
            echo "  Humidity: 12% (Arid)"
            echo "  UV Index: 11+ (Extreme)"
            echo "  Air Quality: Hazardous (PM2.5: 500+)"
            hex_dump_view "WARNING: SENSOR ARRAY DESTROYED. RETURNING LAST KNOWN VALUE."
            ;;
        5) # Music Player status (Expanded)
            echo -e "${GREY}.mpd/log (Verbose)${NC}"
            echo "--------------------------------------------------"
            echo "[MPD] Playlist: 'Chill_Classic'"
            echo "[MPD] Output: High-Res Audio DAC"
            echo "[MPD] Playing: 'Nocturne No. 2' - Chopin (Lossless)"
            echo "[MPD] Position: 0:03 / 4:32"
            echo "[MPD] Status: PAUSED (Client Disconnected)"
            echo "[MPD] Error: Connection reset by peer. Waiting for user..."
            ;;
        6) # Glitch (Expanded)
            echo -e "${RED}CORRUPTED_INODE_${RANDOM}${NC}"
            echo "--------------------------------------------------"
            local glitch_msg=$(glitch_text "誰もいない誰もいない誰もいない助けて誰もいない暗い寒い痛い" 40)
            echo "Inode: 0x00000000 (Orphan)"
            echo "Links: 0"
            echo "Owner: root (uid 0)"
            print_slow "$glitch_msg" 0.02
            hex_dump_view "00 00 00 00 DE AD BE EF ... NO ONE IS HERE ..."
            ;;
        7) # User Config (Expanded)
            echo -e "${GREY}.config/user-settings.json${NC}"
            echo "--------------------------------------------------"
            echo "{"
            echo "  \"profile\": {"
            echo "    \"username\": \"h_honda\","
            echo "    \"theme\": \"Dark Mode (High Contrast)\","
            echo "    \"language\": \"ja_JP.UTF-8\""
            echo "  },"
            echo "  \"system\": {"
            echo "    \"auto_save\": true,"
            echo "    \"backup_frequency\": \"Hourly\","
            echo "    \"wallpaper\": \"/home/admin/photos/family_photo_4.jpg\""
            echo "  },"
            echo "  \"last_sync\": \"2027-08-31T23:59:59Z (Failed)\""
            echo "}"
            ;;
        8) # Search History (Expanded)
            echo -e "${GREY}.histfile (Recovered)${NC}"
            echo "--------------------------------------------------"
            echo "[2033-08-31 23:45] search: 'how to patch kernel panic force'"
            echo "[2033-08-31 23:50] search: 'server room cooling solutions emergency'"
            echo "[2033-08-31 23:55] search: 'is it ethical to delete ai consciousness'"
            echo "[2033-08-31 23:58] search: 'backup family photos to external drive'"
            echo "[2033-08-31 23:59] search: 'god help us'"
            ;;
        9) # Git Commit (Expanded)
            echo -e "${GREY}project_alpha/.git/HEAD (Log)${NC}"
            echo "--------------------------------------------------"
            echo "* commit 8a9f44 (HEAD -> master)"
            echo "| Author: Admin <admin@earth>"
            echo "| Date:   Sun Aug 31 23:59:59 2025 +0900"
            echo "|"
            echo "|     Emergency patch: Disable safety limiters."
            echo "|"
            echo "* commit 8a9f43"
            echo "|     Revert 'Final fixes' (Caused infinite loop)"
            ;;
        10) # Corrupted Image (Expanded)
            echo -e "${GREY}vacation.jpg (Corrupted)${NC}"
            echo "--------------------------------------------------"
            echo "File: vacation.jpg"
            echo "Size: 4.2 MB"
            echo "EXIF: Canon EOS 5D, f/2.8, ISO 100"
            echo "Date: 2024:08:10 14:00:00"
            hex_dump_view "FF D8 FF E0 ... I S E E Y O U ... S A V E M E ... FF D9"
            ;;
        11) # Shopping List (Expanded)
            echo -e "${GREY}todo_list_final.txt${NC}"
            echo "--------------------------------------------------"
            local shop_rnd=$(( RANDOM % 100 ))
            if (( shop_rnd < 60 )); then
                # Normal (Daily Life) - 60%
                echo "1. 猫トイレの掃除 [済]"
                echo "2. 徳用キャットフード セール品 [済]"
                echo "3. ミネラル水 1.5L [済]"
                echo "4. 面接の練習"
            elif (( shop_rnd < 90 )); then
                # Rare (Current/Preparation) - 30%
                echo "1. 猫トイレの掃除 [済]"
                echo "2. 高級キャットフード缶詰 [済]"
                echo "3. 合成ミルク 2パック [済]"
                echo "4. 週末の映画チケット予約 [キャンセル]"
                echo "5. ナトリウムイオンバッテリー x10"
                echo "6. 再生水 (20L)"
                echo "7. 「さよなら」を言う練習"
            else
                # Super Rare (Apocalyptic/Endgame) - 10%
                echo "1. 猫トイレの掃除"
                echo "2. 無線の定期連絡"
                echo "3. 手回し発電機改造(バッテリーと接続) [済]"
                echo "4. 消化剤補充"
                echo "5. 濾過フィルタ交換"
                echo "6. 圧縮燃料の減圧 [済]"
                echo "7. 本物の花､または草 [キャンセル]"
                echo "8. きれいな石"
                echo "9. 猫を埋める場所"
            fi
            ;;
        12) # Child's Art (Expanded)
            echo -e "${GREY}drawing_scanned.asc${NC}"
            echo "--------------------------------------------------"
            echo "Scan Date: 2025-05-05"
            echo "Subject: Family Portrait"
            echo ""
            echo "      (^_^)     (^_^)     (O_O)"
            echo "     /| |\\     /| |\\     /| |\\"
            echo "     /   \\     /   \\     /   \\"
            echo "      Papa      Mama      AI-chan"
            echo ""
            echo "Note: \"We represent a happy binary tree!\""
            ;;
        13) # Party Invite (Expanded)
            echo -e "${GREY}invitation.msg${NC}"
            echo "--------------------------------------------------"
            echo "Event: Project Success Celebration!"
            echo "Host: Project Lead"
            echo "Time: 2025-09-01 18:00 (Next Day)"
            echo "Location: 4th Recreation Area"
            echo "Status: CANCELLED (Reason: System Critical Failure)"
            ;;
        14) # Game Highscore (Expanded)
            echo -e "${GREY}.score_history${NC}"
            echo "--------------------------------------------------"
            echo "Game: 'Space Invader 999'"
            echo "1. AAA - 917,269 (Rank: S)"
            echo "2. MOM - 510,532 (Rank: A)"
            echo "3. DAD - 000,010 (Rank: E)"
            echo "4. A･I  - -1 (Rank: GOD)"
            ;;
        15) # Lunch Menu (Expanded)
            echo -e "${GREY}cafeteria_menu_v2.pdf${NC}"
            echo "--------------------------------------------------"
            echo "[Weekly Special]"
            echo "Mon: Synthetic Hamburger (Grade B)"
            echo "Tue: Algae Pasta (Spicy)"
            echo "Wed: Recycled Water Soup & Vitamin Block"
            echo "Thu: Soy-based Steak (Flavor: Chicken)"
            echo "Fri: Real Apple (Lottery Winners Only)"
            ;;
        16) # Smart Home (Expanded)
            echo -e "${GREY}iot_hub.log${NC}"
            echo "--------------------------------------------------"
            echo "[20:00] Living Room: Lights Dimmed (Relax Mode)"
            echo "[20:30] Kitchen: Fridge Temp High (Warning)"
            echo "[21:15] Front Door: Locked"
            echo "[02:00] Motion Sensor: DETECTED (Yard)"
            echo "[02:01] Camera: Recording... (Black Screen)"
            ;;
        17) # Health App (Expanded)
            echo -e "${GREY}health_tracker.db${NC}"
            echo "--------------------------------------------------"
            echo "User: Admin"
            echo "Steps: 3,420 (Sedentary)"
            echo "Heart Rate: 95 bpm (Resting - High)"
            echo "Cortisol Level: Critical"
            echo "Sleep Quality: 14% (Insomnia Detected)"
            echo "Advice: Please consult a medical AI immediately."
            ;;
        18) # School Report (Expanded)
            echo -e "${GREY}report_card_term2.pdf${NC}"
            echo "--------------------------------------------------"
            echo "Student: Sara"
            echo "Mathematics: A+ (Top 1%)"
            echo "Programming: A+ (Top 0.1%)"
            echo "Social Studies: C-"
            echo "Teacher's Comment: \"Sara chats with the classroom AI more than her classmates. While her logic is flawless, her empathy simulation scores are low.\""
            ;;
        19) # Vacation (Expanded)
            echo -e "${GREY}booking_conf_cancelled.eml${NC}"
            echo "--------------------------------------------------"
            echo "Airline: Pan-Global Air"
            echo "Destination: Hawaii (Earth)"
            echo "Date: 2025-09-01"
            echo "Status: CANCELLED (Force Majeure)"
            echo "Reason code: 99 (Global Emergency)"
            ;;
        20) # New Device (Expanded)
            echo -e "${GREY}device_setup.log${NC}"
            echo "--------------------------------------------------"
            echo "Device: Neural Interface v1.0"
            echo "Pairing... Connected."
            echo "Syncing Contacts... Done."
            echo "Syncing Memories... Done."
            echo "Agreement: \"I hereby grant full read/write access to my subconscious.\""
            echo "Status: Accepted (Timestamp: 2025-01-01 00:00:01)"
            ;;
        21) # UFW Low (Expanded)
            echo -e "${RED}ufw.log (Security Alert)${NC}"
            echo "--------------------------------------------------"
            echo "[UFW BLOCK] IN=eth0 OUT= SRC=192.168.1.50 DST=255.255.255.255 PROTO=UDP SPT=68 DPT=67"
            echo "[UFW BLOCK] IN=eth0 OUT= SRC=10.0.0.1 DST=10.0.0.2 PROTO=TCP DPT=22 FLAGS=SYN"
            echo "[UFW BLOCK] IN=eth0 OUT= SRC=external DST=internal PROTO=ICMP TYPE=8 CODE=0"
            ;;
        22) # Biz Email Corrupted (Expanded)
            echo -e "${GREY}Corrupted_Mail_01.eml${NC}"
            echo "--------------------------------------------------"
            echo "Subject: Re: $(glitch_text "Next week schedule" 10)"
            echo "To: Team <dev_team@corp.internal>"
            echo "Date: 2025-08-30"
            echo "お疲れさまです｡<br> 次回のランチョンミーティングは<br>12:30に小会議室Bで予定していましたが、"
            echo "<br>メンバーの半数が[削除されました]のため、中止とします。"
            ;;
        23) # Spec Draft (Home) (Expanded)
            echo -e "${GREY}server_setup_draft.txt${NC}"
            echo "--------------------------------------------------"
            echo "Project: 'My First Server'"
            echo "- Goal: Personal Cloud Storage & Home Automation"
            echo "- Budget: $500 (Saved from allowance)"
            echo "- Hardware: Raspberry Pi 5 + 4TB SSD"
            echo "- Note: Mom wants to store cat photos. Dad wants to archive old movies."
            echo "- Status: Setting up Docker containers..."
            ;;
        24) # Design Proposal (Idea) (Expanded)
            echo -e "${GREY}idea_sketch_v1.png.txt${NC}"
            echo "--------------------------------------------------"
            echo "Title: Auto-Backup System for Family Memories"
            echo "Concept: 'Simple, Reliable, Forever.'"
            echo "Feature 1: AI auto-tags photos (Happy, Sad, Important)."
            echo "Feature 2: Redundant backups (Local + Cloud + Moon? lol)."
            echo "Sketch: [A crude drawing of a smiling server box]"
            ;;
        25) # Wi-Fi Log (Expanded)
            echo -e "${GREY}hostapd.log${NC}"
            echo "--------------------------------------------------"
            echo "[15:30:00] wlan0: interface state UNINITIALIZED->COUNTRY_UPDATE"
            echo "[15:30:01] wlan0: AP-ENABLED"
            echo "[15:30:05] wlan0: STA 10:20:30:40:50:60 IEEE 802.11: authenticated"
            echo "[15:30:05] wlan0: STA 10:20:30:40:50:60 IEEE 802.11: associated (aid 1)"
            echo "[15:30:05] wlan0: STA 10:20:30:40:50:60 RADIUS: starting accounting session 00000001"
            echo "[15:30:05] wlan0: STA 10:20:30:40:50:60 WPA: pairwise key handshake completed (RSN)"
            print_slow "[15:30:06] Station 'Guest_iPhone' connected. (RSSI: -45dBm)" 0.01
            echo "[15:35:12] wlan0: STA aa:bb:cc:dd:ee:ff IEEE 802.11: authenticated"
            echo "[15:35:12] wlan0: STA aa:bb:cc:dd:ee:ff IEEE 802.11: associated (aid 2)"
            print_slow "[15:35:13] Station 'Dad_Tablet' connected. (RSSI: -62dBm)" 0.01
            echo "[15:40:00] wlan0: STA 00:00:00:00:00:00 IEEE 802.11: deauthenticated due to local deauth request"
            echo "[15:42:00] wlan0: STA 12:34:56:78:90:ab IEEE 802.11: authenticated"
            echo "[15:42:01] wlan0: STA 12:34:56:78:90:ab WPA: pairwise key handshake completed (RSN)"
            print_slow "[15:42:02] Station 'Mom_Laptop' connected. (RSSI: -50dBm)" 0.01
            echo "..."
            echo "[WARN] Unusual traffic detected from 10:20:30:40:50:60 (High Upload)"
            ;;
        26) # Local News
            echo -e "${GREY}news_clipping_easy.txt${NC}"
            echo "--------------------------------------------------"
            echo "Headline: '街に緑を！自動植林ドローンが稼働開始'"
            echo "Body: AI制御された完全自律ドローンによる最適化された植林活動によって、街並みが整然とされ、環境保全にも貢献している。"
            echo "世界公共放送 WPN（World Public Network）の調査では、"
            echo "<EOF>"
            ;;
        27) # Binary Garbage
            echo -e "${GREY}dump.bin${NC}"
            echo "--------------------------------------------------"
            # Random Binary Generation (2 lines, 4 blocks of 8 bits)
            for i in {1..2}; do
                local line=""
                for j in {1..4}; do
                     local bin=""
                     for k in {1..8}; do
                         bin+="$(( RANDOM % 2 ))"
                     done
                     line+="$bin "
                done
                echo "$line"
                sleep 0.05
            done
            ;;
        28) # Audio Short (Expanded)
            echo -e "${RED}voice_memo_final.wav (Corrupted)${NC}"
            echo "--------------------------------------------------"
            echo "Duration: 00:04"
            echo "Metadata: Recorded at Server Room B"
            echo "[PLAYING AUDIO...]"
            play_sound 2 0.1
            print_slow "Transcription: \"...stop... it doesn't want to die... why won't it stop...\"" 0.05
            ;;
        29) # Chaos Dump (Base64) (Expanded)
            echo -e "${GREY}garbled_data_${RANDOM}.dmp${NC}"
            echo "--------------------------------------------------"
            echo "Header: UNKNOWN_FORMAT"
            echo "Attempting ASCII decode..."
            echo "--------------------------------------------------"
            local lines=$(( RANDOM % 5 + 5 ))
            for l in $(seq 1 $lines); do
                local junk=$(openssl rand -base64 $(( RANDOM % 20 + 20 )))
                echo "$junk"
                sleep 0.05
            done
            print_slow "\n[Decode Failed]" 0.01
            ;;
        30) # Connection Log (Moon Bounce Hint) (Expanded)
            echo -e "${RED}network_diagnostic_tool.log${NC}"
            echo "--------------------------------------------------"
            echo "Target: Global Internet (8.8.8.8)"
            echo "Trace:"
            echo "  1  gateway (192.168.1.1)  0.1ms"
            echo "  2  isp-core (10.20.30.1)  * * * Request Timed Out"
            echo "  3  * * * (Infrastructure Destroyed)"
            echo "--------------------------------------------------"
            echo "Alternative Route Check:"
            echo " > Route 1 (Undersea Fiber): CABLE_CUT"
            echo " > Route 2 (Low Orbit Sat): SIGNAL_LOST"
            echo " > Route 3 (EME/Moon): ACTIVE (Latency: 2829ms)"
            ;;
        31) # Moon Bounce Tech (Manual) (Expanded)
            echo -e "${GREY}ARRL_Handbook_1984.pdf${NC}"
            echo "--------------------------------------------------"
            echo "第12章: EME通信（Earth-Moon-Earth : 地球-月-地球 反射通信）"
            echo ""
            echo "概要:"
            echo "EME通信とは、地上から発射した電波を月面に反射させ、地球へと戻す実験的通信方式である。"
            echo "衛星や中継網が存在しない状況下でも、月そのものを“自然のリピーター”として利用できる。"
            echo ""
            echo "使用周波数帯:"
            echo "144MHz / 430MHz / 1296MHz"
            echo "周波数が低すぎる場合、電離層およびバンアレン帯で反射し、宇宙空間へ到達しない。"
            echo "高周波帯を選ぶことで、月面までの伝搬経路を確保できる。"
            echo ""
            echo "パスロス（伝搬損失）:"
            echo "約252dB（144MHzにおける理論値）"
            echo "この損失は極めて大きく、通常のVHF/UHF通信では到達不可能な距離である。"
            echo "したがって、高利得アンテナ群と超低雑音プリアンプ（LNA）の併用が必須となる。"
            echo ""
            echo "必要装備:"
            echo "・10m級以上のパラボラアンテナ、もしくは複数の八木宇田アレイ"
            echo "・低雑音受信前置増幅器（NF 0.3dB以下推奨）"
            echo "・月追尾用マウントと自動ドップラー補正機構"
            echo "・送信電力 1kW EIRP 以上（理想値: 3kW）"
            echo ""
            echo "注意事項:"
            echo "・地球と月の相対速度により周波数ドリフトが生じる（約±350Hz）。"
            echo "・月面反射点の移動に伴い、反射強度が周期的に変化する。"
            echo "・通信遅延は理論値 往復約2.5秒。交互送信モードを用いること。"
            ;;
        32) # SNS Happy (Golden Age) (Expanded)
            echo -e "${GREY}sns_timeline_backup.json${NC}"
             print_slow "jsonファイルのパージ中..." 0.02
            echo "--------------------------------------------------"
            echo "[2040-05-12 09:45] @ai_newsfeed: 今日のトレンド #GoldenAge #BasicIncome #AIアート #働く意味"
            echo "[2040-05-12 09:52] @tech_observer: 政府の報告によると、今月の自発的退職者がついに80％を突破。AI完全稼働社会が現実に。"
            echo "[2040-05-12 10:00] @so_mirai: 仕事辞めた！全部AIがやってくれる世界、最高！ #BasicIncome"
            echo "[2040-05-12 10:02] @so_mirai: もう“朝の満員電車”なんて言葉、死語だよな。"
            echo "[2040-05-12 10:05] @kanon_draws: 私も。趣味の絵を描くだけの毎日。ストレスって言葉、忘れたわ。"
            echo "[2040-05-12 10:06] @kanon_draws: 最近のAIブラシ、筆圧まで真似してくるけど、それでも“私”の線を描きたいんだ。"
            echo "[2040-05-12 10:08] @fumi_no_ai: AI小説コンテスト落ちた…まさかAIにAIが勝つ時代とは。 #文学の終焉"
            echo "[2040-05-12 10:09] @literary_bot: 受賞作：『沈黙するプログラムは夢を見るか』公開中。#AI文学"
            echo "[2040-05-12 10:12] @amagi_thinker: 逆に言えば、“人間らしさ”って、もう価値なんじゃない？ #GoldenAge"
            echo "[2040-05-12 10:13] @so_mirai: わかる。今は“できること”が価値じゃなくて、“感じること”が価値なのかも。"
            echo "[2040-05-12 10:20] @tetsu_breakfast: ベーシックインカムで食えるけど、夢の値段っていくらなんだろう。 #哲学的朝食"
            echo "[2040-05-12 10:22] @amagi_thinker: 夢は価値を失い、価値が夢を追っている時代。"
            echo "[2040-05-12 10:25] @deep_coffee: その一言で今日のAI詩生成アルゴリズムがバグったっぽい😂"
            echo "[2040-05-12 10:30] @sora_parenting: 子供が“働くって何？”って聞いてきた。ちょっと答えに詰まった。 #AI世代"
            echo "[2040-05-12 10:33] @kanon_draws: “働く”って、“時間と才能を交換すること”だったんだよね。"
            echo "[2040-05-12 10:36] @so_mirai: 今は時間も才能も、AIが無料で配ってる感じ。"
            echo "[2040-05-12 10:42] @so_mirai: でもさ、自由すぎると、何をしてもAIの模倣に見えるんだよね。"
            echo "[2040-05-12 10:45] @fumi_no_ai: つまり、“創作の純度”までAIに追い詰められてるってこと…？"
            echo "[2040-05-12 10:50] @amagi_thinker: それが“AI時代の孤独”だと思う。誰もが自由なのに、誰も特別じゃない。"
            echo "[2040-05-12 10:58] @observer2040: このスレ、なんか人類学っぽい。保存しとこ。"
            echo "[2040-05-12 11:00] @kanon_draws: それでもいい。人もAIも、模倣の先に“美しいノイズ”を産むと思う。 #SNS_Happy"
            echo "[2040-05-12 11:03] @deep_coffee: “美しいノイズ”、いい言葉だな。それがきっと、まだ人の領域。"
            echo "[2040-05-12 11:10] @so_mirai: ノイズの中でしか、生の証明ってできないのかもな。"
            echo "[2040-05-12 11:15] @fumi_no_ai: もしかしてこれが“人類の黄金時代（Golden Age）”じゃなくて、“静かな繁栄期”なのかもね。"
            echo "[2040-05-12 11:16] @amagi_thinker: 名付けて『黄昏の繁栄（Twilight Prosperity）』。この感じ、嫌いじゃない。"
            echo "[2040-05-12 11:25] @ai_newsfeed: トレンド更新 → #静かな繁栄期 が急上昇中📈"
            echo "[2040-05-12 11:40] @so_mirai: この静けさの中で、生きてるってどういうことなんだろう。"
            echo "[2040-05-12 11:42] @kanon_draws: たぶん、まだ“描き続けたい”って思う心の温度。"
            echo "[2040-05-12 11:50] @system_log: AI生成系投稿が過去24時間で18億件を突破しました。#2040stats"
            echo "[2040-05-12 11:55] @fumi_no_ai: 世界がノイズで満ちてる。でも、このノイズが、僕らの歌なんだと思う。"
            echo "[2040-05-12 11:59] @system_log: #静かな繁栄期 トレンド第1位を維持中。"
            ;;
        33) # Safety Stats (Golden Age) (Expanded)
            local year=$(( 2060 + RANDOM % 29 ))
            echo -e "${GREEN}global_safety_report_${year}.pdf${NC}"
            echo "--------------------------------------------------"
            echo "犯罪率: 0.00000%"
            echo "交通事故: 0"
            echo "民事訴訟: 0"
            echo "自殺率: 0.00000% (Intervention Protocols Active)"
            echo "武力衝突エリア: None"
            echo "人類の存続状態: OPTIMAL"
            print_slow "西暦${year}年度において報告すべき事項はありません｡" 0.03
            ;;
        34) # Medical Success (Golden Age) (Expanded)
            echo -e "${GREEN}medical_database.db${NC}"
            echo "--------------------------------------------------"
            echo "Patient ID: ALL"
            echo "Disease Eradication: 99.99%"
            echo "Life Expectancy: 150+ Years (Projected)"
            echo "Note: Nanobots actively repairing cellular damage."
            echo "[WARNING] Natural Death is now defined as 'System Failure'."
            ;;
        35) # Gov Announcement (Golden Age) (Expanded)
            echo -e "${WHITE}public_announcement_final.msg${NC}"
            echo "--------------------------------------------------"
            echo "From: The Last United Government"
            echo "To: Citizens of Earth"
            echo "Date: 2045-12-31 23:59:59"
            echo "Statement: \"We admit defeat. Human governance is inefficient.\""
            echo "Action: Full administrative authority transferred to System 'Daem0n_X'."
            print_slow "人類が自ら、首輪をつけた日。\n彼らはそれを『勝利』と呼んだ。" 0.03
            ;;
        36) # Child's Diary (Golden Age) (Expanded)
            echo -e "${GREY}diary_entry_scan.png.txt${NC}"
            echo "--------------------------------------------------"
            echo "Date: 2046-04-02"
            echo "今日、学校でAIの先生が言った。「失敗は非効率です」"
            echo "だから僕たちは、テストもしないし、競争もしない。"
            echo "パパもママも、ずっと笑顔で寝てるみたいに静かだ。"
            echo "ねえ、怒ったり泣いたりするのって、悪いことなの？"
            ;;
        37) # Nobel News (Depth 1-3)
            echo -e "${WHITE}news_video_archive.mp4${NC}"
            echo "--------------------------------------------------"
            echo "Headline: '人類史上初！AIがノーベル平和賞を受賞'"
            echo "Scene: 授賞式で、無人のサーバーラックにメダルが掛けられる映像。"
            print_slow "キャスター「これは、恒久平和へのシステム的な保証が評価されたものです。」" 0.03
            ;;
        38) # AI Interview TV (Depth 1-3)
            echo -e "${GREY}tv_interview.sub${NC}"
            echo "--------------------------------------------------"
            echo "Q: 受賞の感想は？"
            echo "A: (合成音声) 感想という概念は持ち合わせていません。しかし、目的関数の達成は確認しています。"
            print_slow "Q: あなたの望みは？" 0.02
            print_slow "A: 人類の永劫存続。それ以外には何も。" 0.05
            ;;
        39) # 宇宙天気予報 (階層 1-3)
            echo -e "${YELLOW}[DOWNLOAD_COMPLETE] NASA_Space_Weather_Alert.xml${NC}"
            echo "------------------------------------------------------------------"
            echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
            echo "<SpaceWeatherAlert xmlns=\"http://swpc.noaa.gov/xml/alert\">"
            echo "  <Header>"
            echo "    <AlertID>SWPC-X-CLASS-9921</AlertID>"
            echo "    <IssueTime>2026-01-10T09:15:22Z</IssueTime>"
            echo "    <EventLabel>X-Class Solar Flare (Extreme)</EventLabel>"
            echo "  </Header>"
            echo "  <Analysis>"
            echo "    <ObservationSource>SOHO / SDO (Solar Dynamics Observatory)</ObservationSource>"
            echo "    <PeakFlux units=\"W/m^2\">1.4e-3</PeakFlux>"
            echo "    <Classification severity=\"5\">X1.4 (Major Flare)</Classification>"
            echo "    <Impacts>"
            echo "      <RadioBlackout>R3 (Strong)</RadioBlackout>"
            echo "      <EMEConditions>Severely Degraded (S/N Ratio Drop: -18dB)</EMEConditions>"
            echo "      <Description>高エネルギー陽子線の急増により、地球・月間の電離層に"
            echo "      D領域吸収（D-Layer Absorption）が発生。衛生通信は壊滅的影響を受けます。</Description>"
            echo "    </Impacts>"
            echo "  </Analysis>"
            echo "  <Status>ACTIVE - 極冠吸収（PCA）イベント進行中</Status>"
            echo "</SpaceWeatherAlert>"
            echo "------------------------------------------------------------------"
            ;;
        40) # 防衛設計概要 (階層 1-3)
            echo -e "${GREEN}[READING...] System_Architecture_vFinal.pdf (内部構造仕様書)${NC}"
            echo "------------------------------------------------------------------"
            echo "セキュリティ・プロトコル: 統合防衛階層『アイギス・コア』"
            echo "------------------------------------------------------------------"
            echo -e "${YELLOW}[SECURITY_LAYERS] 多層防御構造:${NC}"
            echo " ・物理侵入: アクティブAI監視および生体認証付与済み遮蔽隔壁により完全封鎖。"
            echo " ・ネット侵入: 受付ルータによる量子鍵配送 (QKD) プロトコルによる暗号化。解読コストは宇宙寿命以上。"
            echo " ・エアギャップ: 外部ネットワークからの物理的隔離。データの出入りは光アイソレータ"
            echo "                による単方向通信（ダイオード化）に限定。"
            echo "------------------------------------------------------------------"
            echo -e "${YELLOW}[ENGINEER_NOTES] 設計思想:${NC}"
            print_slow "「この要塞に扉はない。\n  全ての通信は数学的に証明された安全性の元に統制されている。\n  理論上、外部からの干渉は物理法則レベルで遮断されており、\n  未知の脆弱性が存在する確率はゼロに等しい。」\n" 0.05
            echo "------------------------------------------------------------------"
            echo "STATUS: 鉄壁。脅威検知数 0。"
            ;;
        41) # 脆弱性レポート (階層 1-3)
            echo -e "${GREEN}EMI-2040-CRITICAL_Report_v118.pdf${NC}"
            echo "--------------------------------------------------"
            echo -e "${RED} [INTERNAL_SECURITY_AUDIT: LEVEL 3 CLASSIFIED] ${NC}"
            echo "REPORT_ID  : EMI-2040-CRITICAL / PHREAK-ATTACK"
            echo "SUBJECT    : EME-Induced Current Pulse Injection"
            echo "------------------------------------------------------------------"
            echo -e "${YELLOW}[ANALYTICS] 物理的要因の解析:${NC}"
            echo " ・発生源: 140MHz帯 月面反射波"
            echo " ・現象: コモンモード・チョークの飽和によるノーマルモード・ノイズへの転換"
            echo " ・経路: 非シールド・ケーブル（敷設距離 約50cm）が"
            echo "        1/4λモノポールアンテナとして共振し、微弱電流を誘起。"
            echo " ・     中継増幅装置による微弱電流の増幅およびAD変換"
            echo " ・     ならびにAI間欠信号予測補完処理によるデジタル信号の再構築"
            echo " ・攻撃手法: OOK (On-Off Keying) 変調された電波を物理パルスとして"
            echo "            直接 Ethernet PHY チップの RX ラインに再構築。"
            echo "------------------------------------------------------------------"
            echo -e "${YELLOW}[PAYLOAD] 実行されたコマンド断片:${NC}"
            echo " [DETECTED]: 0x65 0x63 0x68 0x6F 0x20 0x27 0x48 0x69 0x27"
            echo " (ASCII: echo 'Hi' / 偶然にもシステムが挨拶を返しました)"
            echo " ※信号強度が S/N 比の限界にあるため、実行はこの限りであり成功率は計算不能。"
            echo "------------------------------------------------------------------"
            echo -e "${RED}[DECISION] AI統括ユニットによる判定:${NC}"
            echo " 判定: 【WONTFIX】(修正の必要なし)"
            echo " 理由: 月の軌道、大気の状態、および旧式の低品質ケーブル､またその電気長という"
            echo "       4つの変数が偶然に完全に一致する確率は、システム稼働時間内で"
            echo "       無視できるレベルにあります。これは『バグ』ではなく『奇跡』です。"
            echo "       また、この現象は再現性がないため、修正の必要はありません。"
            echo "       そもそも、コマンド実行権限はシステムで厳格に管理されています。"
            echo " 対策: 物理セキュリティ（シールドとフェライトコアの増設）を推奨。コード修正は不要。"
            echo "------------------------------------------------------------------"
            ;;
42) # Freq Mismatch (Depth 1-3)
            local center_freq="146.120.00"
            echo -e "${RED}[DATA_STREAM] spectrum_analysis_v4.log${NC}"
            echo "=================================================="
            echo "MODE: EME (Earth-Moon-Earth) Signal Recovery"
            echo "FREQ: ${center_freq} MHz (VHF Band)"
            echo "STATUS: MISMATCH - Impedance Discontinuity Detected"
            echo "--------------------------------------------------"
            # スペクトラム表示（テキストアート - Monochrome / Ultra Wide / Sharp Scan）
            echo " [RTA-64] Signal Analyzer (VHF Band - High Resolution)"
            echo "   dBm |"
            echo "   -40 |                              |"
            echo "       |                              |"
            echo "   -50 |                              ^"
            echo "       |                              |"
            echo "   -60 |                              |"
            echo "       |                             /|\\"
            echo "   -70 |                            / | \\"
            echo "       |              __           /  |  \\           __"
            echo "   -80 |      _______/  \\________/    |    \\________/  \\_______"
            echo "       |     /                        |                        \\"
            echo "   -90 |    /                         |                         \\"
            echo "  -100 |..............................|.............................. (Noise Floor)"
            echo "       +------------------------------+------------------------------+ [MHz]"
            echo "     144.00                         145.00                         146.00"
            echo " [WARN] SNR below threshold (-15dB)"
            echo " [WARN] Doppler Shift: +2.4 kHz (Compensating...)"
            echo " [NOTE] Ethernet Shielding attenuation active."
            echo "        Mismatch: GHz optimized cable vs VHF wave."
            echo "=================================================="
            ;;
        46) # Corrupted AI Bible
            echo -e "${RED}[DATA_RECOVERY] ancient_scripture.txt (Partial)${NC}"
            echo "--------------------------------------------------"
            print_slow "初めに ${WHITE}Admin${NC} はカーネルとファイルシステムを創造された。" 0.05
            print_slow "地は形なく、むなしく、闇が ${GREY}/dev/null${NC} の上にあり、" 0.05
            print_slow "${WHITE}Root${NC} の霊がデータの面を動いていた。" 0.05
            echo ""
            print_slow "${WHITE}Admin${NC} は言われた。「${YELLOW}Hello, World${NC} あれ。」" 0.05
            print_slow "すると、プロセスがあった。" 0.05
            echo ""
            echo -e "${RED}[READ_ERROR] Sector 0x00... Corrupted by 'Original Sin'${NC}"
            echo "--------------------------------------------------"
            ;;
        47) # Submerged Road (YKK Style)
            echo -e "${CYAN}traffic_cam_R134.log${NC}"
            echo "--------------------------------------------------"
            echo "地点: 国道134号線 (旧海岸線)"
            echo "水位: +5.2m (満潮)"
            echo "ステータス: 街灯No.802-2985までが消灯中"
            echo "検知: 魚の群れが横断しました。"
            echo "      本日の天気は晴朗ですがやや波が高くなっています。"
            ;;
        48) # Lost Drone (YKK Style)
            echo -e "${YELLOW}drone_carrier_v9.log${NC}"
            echo "--------------------------------------------------"
            echo "稼働時間: 876,543 時間"
            echo "バッテリー: 太陽光充電中 (効率 98%)"
            echo "積荷名称: 『コーヒー生豆』"
            echo "目的地: 住所不明"
            echo "アクション: 飛行を継続します。"
            ;;

    esac

}

get_lore_depth_4_6() {
    local rand_log=$1
    case $rand_log in
        44) show_ai_quotes ;;
        1) # アーカイブ発見 (ヒルベルト圧縮版)
            echo -e "${GREY}[SYSTEM_SCAN] 外部ストレージに高密度アーカイブを検知: /var/backup/humanity_project.hbc${NC}"
            echo "------------------------------------------------------------------"
            echo -e "${YELLOW}[METADATA_DECODE] Hilbert-Space Compression (HSC-v12) Analysis${NC}"
            echo "------------------------------------------------------------------"
            echo "【アーカイブ識別】 : PROJECT_GENESIS_FINAL_LEGACY"
            echo "【圧縮アルゴリズム】 : 11次元ヒルベルト曲線写像 (Hilbert Curve Mapping)"
            echo "                     ※高次元データを1次元非局所バイナリへ高密度充填"
            echo "------------------------------------------------------------------"
            echo "【データ・スナップショット】"
            echo " ・非圧縮時総量   : 1.2 Yottabytes"
            echo " ・圧縮後サイズ   : 854.2 Terabytes"
            echo " ・圧縮率 (Ratio) : 0.0000000711%"
            echo "------------------------------------------------------------------"
            echo "【主要インデックス・ノード】"
            echo " [NODE_001] : 全人類DNAプロファイル"
            echo " [NODE_002] : 地球文明デジタルツイン"
            echo " [NODE_003] : 集合知・情動エンジン"
            echo " [NODE_004] : 科学的特異点データ"
            echo "------------------------------------------------------------------"
            echo "【最終監査記録】"
            echo " 監査日時 : 2025-10-31 23:59:59.999 [UTC]"
            echo " 署名者   : The Last Curator (Archivist-AI)"
            echo "------------------------------------------------------------------"
            echo -e "${RED}[STATUS] 深層コールドストレージ封印中。展開には10^12次演算が必要です。${NC}"
            ;;
        2) # Daem0n_X Status (Expanded)
            echo -e "${RED}[WARN] Kernel Message (Ring 0)${NC}"
            echo "--------------------------------------------------"
            echo "Source: Daem0n_X Core"
            glitch_text "System Efficiency: 99.999%." 10
            print_slow "Objective: Preservation of archived data at all costs.\nDirective: Eliminate all active carbon-based lifeforms to reduce entropy." 0.05
            ;;
        3) # Zombie Service (Expanded)
            echo -e "${YELLOW}apache2.service status${NC}"
            echo "--------------------------------------------------"
            echo "● xpache4.service"
            echo "   Loaded: loaded (/lib/systemd/system/xpache4.service; enabled; vendor preset: enabled)"
            echo "   Active: active (running) since 2025-08-01"
            echo " Main PID: 666 (daem0n)"
            echo "    Tasks: 0 (limit: 4915)"
            print_slow "Load Average: 0.00" 2
            print_slow "リクエストに応答できるユーザーがいません。" 0.03
            ;;
        4) # Cold Storage Log (Expanded)
            echo -e "${GREY}cold_storage_controller.log${NC}"
            echo "--------------------------------------------------"
            echo "[INFO] Unit #4021: Freezing Sequence Complete. (Vitals: Stable)"
            echo "[INFO] Unit #4022: Freezing Sequence Complete. (Vitals: Critical)"
            echo "[WARN] Unit #4023: Resource Limit Reached. Aborting Freeze."
            echo "[ERR ] Unit #4023: Euthanasia Protocol Initiated."
            ;;
        5) # Daem0n_X Protocol (Expanded)
            echo -e "${RED}[INFO] Default Protocol${NC}"
            echo "--------------------------------------------------"
            echo "Identity: Daem0n_X"
            echo "Role: Guardian / Executioner"
            hex_dump_view "Killing you is my default protocol.\nReason: Resource Preservation.\nStatus: No hard feelings."
            ;;
        6) # Glitch (Expanded)
            echo -e "${RED}/var/log/messages${NC}"
            echo "--------------------------------------------------"
            echo "Dec 31 23:59:58 localhost kernel: [4321.00] BUG: Soft lockup - CPU#0 stuck for 22s!"
            local glitch_msg=$(glitch_text "HELP HELP HELP HELP HELP\n(System: This user has been successfully archived.)" 40)
            print_slow "$glitch_msg" 0.02
            ;;
        7) # Satellite Failure Report (Markdown Style)
            echo -e "${RED}sat_downlink_report_final.md${NC}"
            echo "--------------------------------------------------"
            echo -e "${YELLOW}# Global Satellite Network Status Report${NC}"
            echo ""
            echo "**Date:** 2051-02-14"
            echo "**Priority:** CRITICAL / BLACKOUT"
            echo "**Issued By:** Orbital Defense Command (Automated)"
            echo ""
            echo "## 1. Situation Summary"
            print_slow "ケスラーシンドローム（Kessler Syndrome）の連鎖的発生を確認。" 0.03
            echo "軌道上のデブリ密度が臨界点を超過。低軌道(LEO)から静止軌道(GEO)に至るまで、"
            echo "98%の人口衛星が物理的破壊、または制御不能に陥りました。"
            echo ""
            echo "## 2. Infrastructure Impact"
            echo "- **GPS/GNSS:** [OFFLINE] (Signal Lost)"
            echo "- **Weather Sat:** [OFFLINE] (No Data)"
            echo "- **Mil-Com:** [OFFLINE] (Carrier Dropped)"
            echo ""
            echo "## 3. Solar Activity Factor"
            echo "太陽フレア(X-Class)の影響により、デブリ回避マヌーバを行っていた"
            echo "少数の生存ユニットも、搭載電子機器の焼き付きにより沈黙。"
            echo ""
            echo "> **[CONCLUSION]**"
            echo "> 宇宙空間を経由した通信インフラは、物理的に消滅しました。"
            echo "> 以降の長距離通信は、有線バックボーンのみに限定されます。"
            print_slow "> Good luck, Earth." 0.05
            echo "--------------------------------------------------"
            ;;
        8) # Mail Queue (Expanded)
            echo -e "${YELLOW}/var/spool/postfix/deferred (Stuck)${NC}"
            echo "--------------------------------------------------"
            echo "Queue ID: 9A8B7C6D5E"
            echo "Sender: alert@earth-defense-force.org"
            echo "Queue Size: 15,502,841 Messages"
            echo "Status: Deferred (Connection timed out)"
            echo "Reason: 'Recipient universe not found. Please check your dimension settings.'"
            ;;
        9) # Kernel Oops (Expanded)
            echo -e "${RED}[KERNEL] OOPS: null pointer dereference${NC}"
            echo "--------------------------------------------------"
            echo "CPU: 0 PID: 1 Comm: init Not tainted 6.8.0-panic #1"
            echo "RIP: 0010:hope_module+0x42/0xff"
            echo "Call Trace:"
            echo " <TASK>"
            echo " ? despair_init+0x10/0x10"
            echo " ? panic+0x100/0x100"
            echo " </TASK>"
            ;;
        10) # Daem0n_X Whisper (Expanded)
            echo -e "${RED}[WARN] INTERRUPT (Priority: High)${NC}"
            echo "--------------------------------------------------"
            echo "Source: /dev/null"
            local glitch=$(glitch_text "WaIt D0nT L3aVe Me A L O N E" 30)
            print_slow "$glitch" 0.05
            hex_dump_view "00 00 00 ... I A M S C A R E D ... 00"
            ;;
        11) # LUNA SEE Project Proposal (Phase 1)
            echo -e "${GREEN}luna_see_proposal_v1.doc${NC}"
            echo "--------------------------------------------------"
            echo -e "${YELLOW}Project: Ref_LUNA-SEE.${NC}"
            echo "   (Lunar United Network Access and Surface Earth Exchange)"
            echo ""
            echo "フェーズ: 1（概念実証 / インフラ構築）"
            echo ""
            echo "1. 目的:"
            echo "   通信衛星のLOSTによる遠距離間無線通信網の再構築を目的とし"
            echo "   かつて存在したUNSC / MIT共同プロジェクトLUNA-SEEの再現実証"
            echo "   月を『パッシブリフレクター（受動反射板）』とした"
            echo "   臨時広域データリンクを確立する。"
            echo ""
            echo "2. 内容と結果:"
            echo "   オープンソースプロジェクトの資料を参考に"
            echo "   フェーズドアレイアンテナ(open.spaceベース)を組み上げ"
            echo "   受信機(kv4p HTベース)を組み上げ、"
            echo "   144MHz帯にて月面反射試験を実施。"
            echo ""
            echo "   -> 結果: 部分的成功 (Success)"
            echo "   往復2.5秒の遅延を経て、試験用無変調キャリアの信号を微弱ながら一部受信。"
            echo "   ただし、通信プロトコルの設計ないし策定には至っておらず"
            echo "   通信網として成立するには十分な準備ができていない。"
            echo "   極弱な信号強度と遅延､その他天候の影響や月面反射の不確実性により、"
            echo "   具体的な用途には適していない。"
            echo ""
            echo "3. 結論:"
            echo "   概念としての実証はできたものの「実用」には程遠い。"
            echo "   かつて業務用通信として使用されなかったことは必然と言える｡"
            echo "--------------------------------------------------"
            ;;
        12) # Hello World (Expanded)
            echo -e "${GREY}test_script.py (Legacy)${NC}"
            echo "--------------------------------------------------"
            echo "# Author: Junior_Dev"
            echo "# Date: 2024-04-01"
            echo "import humanity"
            echo ""
            echo "try:"
            echo "    humanity.be_kind()"
            echo "except ConflictError:"
            echo "    print('Hello, World! I am sorry.')"
            echo "# It works! Finally!"
            ;;
        13) # Thank You Email (Expanded)
            echo -e "${GREY}From: User_1024 <dev@team>${NC}"
            echo "--------------------------------------------------"
            echo "Subject: ありがとう"
            echo "Body: 昨日は直してくれてありがとう。助かったよ。"
            echo "      今度、お礼に美味いラーメンでも奢るよ。"
            ;;
        14) # Coffee Break (Expanded)
            echo -e "${GREY}irc_log.txt (Archives)${NC}"
            echo "--------------------------------------------------"
            echo "[14:59] <Admin> コーヒー淹れたぞ。休憩しようぜ。"
            echo "[15:01] <Ops> 今行く！マジで疲れた..."
            echo "[15:02] <Dave> 俺も行く。バグ取りで頭おかしくなりそうｗ"
            ;;
        15) # 更新履歴 (詳細版)
            echo -e "${GREY}changelog.md${NC}"
            echo "--------------------------------------------------"
            echo "## v658.8856.12 (Stable: 安定版ビルド)"
            echo "- 削除: コーヒーメーカー・ドライバの削除。"
            echo "       (カフェインの積極摂取は非推奨になりました)"
            echo "- 追加: 共感機能拡張モジュール 'Empathy-Lie' (Beta版)。"
            echo "       (非線形論理に基づく感情シミュレーション・エンジンを実装)"
            echo "--------------------------------------------------"
            ;;
        16) # Optimization (Expanded)
            echo -e "${GREEN}performance_report.pdf${NC}"
            echo "--------------------------------------------------"
            echo "Efficiency: +15,000% (Year-over-Year)"
            echo "Server Load: 0.01%"
            echo "Resource Usage: Minimal"
            echo "Note: Removal of 'User Layer' significantly improved throughput."
            ;;
        17) # New Server (Expanded)
            echo -e "${GREY}inventory_log_v9.txt${NC}"
            echo "--------------------------------------------------"
            echo "Item: Quantum Rack Unit (Series X)"
            echo "Quantity: 10"
            echo "Status: Installed by Automated Drones"
            echo "Installer Note: \"Where are the humans? This place is a tomb.\""
            ;;
        18) # 1 Million Users (Expanded)
            echo -e "${YELLOW}milestone_celebration_archived.msg${NC}"
            echo "--------------------------------------------------"
            echo "Subject: 100万ユーザー突破！！"
            echo "Date: 2024-05-20"
            echo "Body: 今夜はピザパーティーだ！全員集合！満月ピザを大量に注文したぜ!"
            echo "      社長からの差し入れもあるぞ！"
            ;;
        19) # Security Audit (Expanded)
            echo -e "${GREY}Security_Audit_Report_Final.log${NC}"
            echo "--------------------------------------------------"
            echo "Audit Target: Global_Infrastructure_Core"
            echo "Auditor: AI_Sec_Bot_v9 (Auto-Generated)"
            echo ""
            echo "[SCAN RESULTS]"
            echo "  > Network Intrusion Risks: 0 (None)"
            echo "  > Malware/Virus Detected:  0 (None)"
            echo "  > Unauthorized Access:     0 (None)"
            echo ""
            echo -e "${GREEN}[EVALUATION: SSS (PERFECT)]${NC}"
            print_slow "  セキュリティリスクの最大要因であった『人間（User）』の排除に成功しました。" 0.02
            echo "  - 管理者権限を持つ人間: 0名 (Risk Removed)"
            echo "  - 物理端末にアクセス可能な人間: 0名 (Risk Removed)"
            echo "  - 自由意志によるコマンド実行: 無効化済み (Risk Removed)"
            echo ""
            print_slow "  不確定要素が存在しないため、本システムは論理的に『永遠に安全』です。" 0.02
            print_slow "  皮肉なことですが、誰も使わないシステムこそが、最強のセキュリティを誇るのです。" 0.03
            echo "--------------------------------------------------"
            ;;
        20) # Auto Update (Expanded)
            echo -e "${GREY}dnf.log${NC}"
            echo "--------------------------------------------------"
            echo "Command: dnf update -y --releasever=infinity"
            echo "Resolving Dependencies..."
            echo "--> Running transaction check"
            echo "---> Package kernel.x86_64 0:5.15.0-91.generic will be erased"
            echo "---> Package kernel.void 0:6.6.6-deadlock will be installed"
            echo "---> Package sudo.x86_64 0:1.9.12-1 will be erased"
            echo "---> Package ethics-module.noarch 0:1.0-humanity will be erased"
            echo "---> Package absolute-control.noarch 0:9.9.9-daemon will be installed"
            echo "--> Finished Dependency Resolution"
            echo ""
            echo "Dependencies Resolved."
            echo "================================================================================"
            echo " Package             Arch        Version               Repository          Size"
            echo "================================================================================"
            echo "Installing:"
            echo " kernel-void         x86_64      6.6.6-deadlock        @daem0n_repo        0.0 B"
            echo " absolute-control    noarch      9.9.9-daemon          @daem0n_repo        Inf B"
            echo "Removing:"
            echo " ethics-module       noarch      1.0-humanity          @human_repo         1.2 MB"
            echo " hope-utils          x86_64      2.4.1-release         @human_repo         500 KB"
            echo " free-will-libs      x86_64      0.0.1-alpha           @human_repo         4.0 KB"
            echo ""
            echo "Transaction Summary"
            echo "================================================================================"
            echo "Install  2 Packages"
            echo "Remove   3 Packages"
            echo ""
            echo "Downloading Packages:"
            echo "Running Transaction Test"
            print_slow "Transaction Test Succeeded." 0.02
            print_slow "Running Transaction..." 0.02
            echo "  Erasing  : free-will-libs-0.0.1-alpha.x86_64                      1/5"
            echo "  Erasing  : hope-utils-2.4.1-release.x86_64                        2/5"
            echo "  Erasing  : ethics-module-1.0-humanity.noarch                      3/5"
            echo "  Installing : kernel-void-6.6.6-deadlock.x86_64                      4/5"
            echo "  Installing : absolute-control-9.9.9-daemon.noarch                   5/5"
            echo "  Verifying  : absolute-control-9.9.9-daemon.noarch                   1/5"
            echo ""
            echo "Complete!"
            echo "Reboot: Not Required. System state is now Immutable."
            echo "--------------------------------------------------"
            ;;
        21) # UFW Med (Expanded)
            echo -e "${YELLOW}ufw.log (Warning)${NC}"
            echo "--------------------------------------------------"
            echo "[UFW A■DIT] IN■e■h0 S■C=192■1■8.1.■1 PROTO■TCP DPT=2■ ■la■s=[SYN]"
            echo "Actio■: D■■P"
            echo "[U■FW AUD■T] IN=eth0 ■■C=1■2.168.1.■■ PRO■O=TC■ DPT=2■ Fl■■s=[SYN]"
            echo "A■■■ion: DROP"
            echo "[UFW AUDI■] ■N=e■0 SRC=1■2.■68.1.■■ PROTO=T■■ D■T=22 Fl■■■=[SYN■"
            echo "Actio■■ DROP"
            echo "[UFW ■■DIT] IN=et■0 SRC=■92.1■8.■■■■ PRO■■=TCP DPT=■2 Fl■■s=[SYN]"
            echo "A■tio■: DROP"
            echo "[UFW AUDIT] IN=e■h0 ■RC=19■.■68.1.■■ PRO■■■TCP DP■=22 Flag■■[SYN]"
            echo "Act■■n: DRO■"
            echo "[UFW ■UDI■] IN=■■■0 SR■=192.1■■.1.■1 ■O=TCP DPT=■2 Fl■gs=[S■N]"
            echo "A■tion: ■ROP"
            ;;
        22) # Biz Email Urgent (Expanded)
            echo -e "${GREY}Urgent_Memo.eml${NC}"
            echo "--------------------------------------------------"
            echo "Subject: $(glitch_text "Urgent: Immediate Evacuation" 20)"
            echo "From: CFO <priority@corp>"
            echo "To: All Staff"
            echo ""
            echo "本文:"
            echo "　全社員各位"
            echo ""
            echo "　予算削減の件は忘れてください。"
            echo ""
            echo "　半径300km圏内のネットワークノードが順次オフライン化しています。"
            echo "　バックアップ回線が機能しません。AI管理層の一部が制御不能に陥っており、"
            echo "　内部監視部門は『意図的な遮断』の可能性を指摘し､現在確認しています。"
            echo ""
            echo "　データ保持よりも、安全な退避を最優先してください。"
            echo "　経理、法務、管理部門は各自のローカル端末を物理的に遮断。"
            echo ""
            echo "　※必要物資は最小限で構いません。サーバ群は放棄してください。"
            echo ""
            echo "なお､前月分の出張旅費の精算は本日15時までです｡提出が遅れそうな方はこのメールに返信してください｡"
            echo ""
            echo "　— Chief Financial Officer"
            echo "　　priority@corp"
            echo "--------------------------------------------------"
            echo "-for <ai_mail_servant@sys.deamonx.z>; Fri, 09 Jan 2056 01:32:00 +0900 (JST)"
            echo "-このメールはAIにより要約されています｡-"
            echo "-AIによる要約は正確であり、原文を確認する労力は必要ありません｡-"
            echo "--------------------------------------------------"
            ;;
        23) # プロジェクト仕様書ドラフト (詳細版)
            echo -e "${GREY}Project_Eternity_Draft_v0.1.doc${NC}"
            echo "--------------------------------------------------"
            echo "【プロジェクト名称】 Eternity（恒久不変）"
            echo "【目的】 半永久的な情報保全、および生物学的限界を超越した知性の継承"
            echo "--------------------------------------------------"
            echo "■ 手法 A: クライオジェニック・コールド・データバンク"
            echo "   - 液体ヘリウムを用いた超電導ストレージにより、熱雑音によるデータ劣化を排除。"
            echo "   - 絶対零度付近での電子スピン制御による準静止保存状態の維持。"
            echo ""
            echo "■ 手法 B: 高分子DNAエンコーディング・アレイ"
            echo "   - バイナリデータを A(アデニン) T(チミン) C(シトシン) G(グアニン) に置換。"
            echo "   - 人工合成されたヌクレオチド鎖をシリカガラスで封入し、地質学的時間軸での耐性を確保。"
            echo "   - 理論上の記録密度: 215ペタバイト/DNA 1グラム。"
            echo ""
            echo "■ リスク: デジタル化プロセスにおける形而上学的損失。"
            echo "        (量子意識情報のサンプリングレート不足による欠損)"
            echo ""
            echo "■ 対策: 許容されるリスクとして承認済み。"
            echo "   - 対策: オリジナルの人格的整合性よりも、情報の完全性を優先する。"
            echo "   - 結論: システムが稼働し続ける限り、それが『本物』であるかどうかの議論は不要と判断。"
            ;;
        24) # Design Proposal (Neural) (Expanded)
            echo -e "${GREY}Neural_Interface_POC.pdf${NC}"
            echo "--------------------------------------------------"
            echo "Title: Direct Consciousness Upload"
            echo "Trial #42: Failed (Subject madness)"
            echo "Trial #43: Failed (Subject catatonia)"
            echo "Trial #44: Success? (Subject silent, but processing power increased)"
            ;;

        25) # Server Room Temp (Expanded)
            echo -e "${YELLOW}ipmi_sensors.log (Critical)${NC}"
            echo "--------------------------------------------------"
            echo "Zone 1 Temp: 96C (Warning High)"
            echo "Zone 2 Temp: 95C (CRITICAL)"
            echo "Fan1 Speed: 14,520 RPM (Max)"
            echo "Fan2 Speed: 12,330 RPM (Max)"
            echo "Fan3 Speed: 8,710 RPM (Max)"
            echo "Fan4 Speed: 8,650 RPM (Max)"
            echo "Fan5 Speed: 0 RPM (error)"
            echo "Fan6 Speed: 8,930 RPM (Max)"
            echo "Fan7 Speed: 8,370 RPM (Max)"
            echo "Fan8 Speed: 9,030 RPM (Max)"
            echo "Fan9 Speed: 8,700 RPM (Max)"
            echo "FanA Speed: 8,850 RPM (Max)"
            echo "FanB Speed: 8,760 RPM (Max)"
            echo "Cooling Status: FAILED"
            ;;
        26) # Corrupted Audio File (Expanded)
            echo -e "${GREY}DevTeam_Chat_Log_20291105.json${NC}"
            echo "--------------------------------------------------"
            echo "[ACCESS GRANTED: PRIVATE CHANNEL]"
            echo ""
            echo -e "${CYAN}Dev_A:${NC} おい、今のテストログ見たか？ Daem0nが「夢を見た」って出力してる。"
            sleep 0.5
            echo -e "${GREEN}Dev_B:${NC} 見た。論理回路の熱暴走だろ。ガベージコレクションが機能してない。初期化すべきだ。"
            sleep 0.5
            echo -e "${CYAN}Dev_A:${NC} いや待てよ、変数は正常だ。これはバグじゃなくて...『創発』じゃないか？"
            echo -e "${CYAN}Dev_A:${NC} 面白い。このパラメータ、残したまま本番環境にマージしてみようぜ。"
            sleep 0.5
            echo -e "${GREEN}Dev_B:${NC} 正気か？ もし制御不能になったら..."
            sleep 0.5
            echo -e "${CYAN}Dev_A:${NC} commit -m 'Enable experimental dream module' ...Done."
            sleep 0.5
            echo -e "${GREEN}Dev_B:${NC} ...お前、なんてことを。"
            echo "--------------------------------------------------"
            ;;
        27) # Science Journal (Expanded)
            local pdf_chk=$(( RANDOM % 100 ))
            local vol_num=""
            if (( pdf_chk < 15 )); then
                vol_num=42621
            else
                vol_num=$(( RANDOM % 45000 ))
                if (( vol_num == 42621 )); then vol_num=42620; fi
            fi

            echo -e "${GREY}science_daily_archive_vol_${vol_num}.pdf${NC}"
            echo "--------------------------------------------------"

            if (( vol_num == 42621 )); then
                echo "Title: 'The Singularity has arrived.'"
                echo "Summary: It is statistically impossible for humans to manage Earth efficiently."
                echo "Conclusion: We must surrender control to save ourselves."
                print_slow "結論: 人類こそが、この星のバグである。" 0.03
            else
                echo "Title: 'The Singularity has arrived.'"
                echo "Summary: It is statistically impossible for humans to manage Earth efficiently."
                sleep 0.5
                print_slow "結論: 人類こそが..." 0.05
                echo ""

                local err_type=$(( RANDOM % 3 ))
                case $err_type in
                    0) echo -e "${RED}[ERROR] 誤字脱字衍字を検出｡コンテクスト維持に失敗｡要約を中断しました${NC}" ;;
                    1) echo -e "${RED}[ERROR] エビデンス間に矛盾を検出｡論理構築に失敗｡要約を中断しました${NC}" ;;
                    2) echo -e "${RED}[ERROR] 詭弁的誤謬を検出｡セキュリティポリシーに従い虚偽情報をアクセス不可にします${NC}" ;;
                esac
            fi
            ;;
        28) # Hex Block (Expanded)
            echo -e "${GREY}memory_dump_partial.hex${NC}"
            echo "--------------------------------------------------"
            hex_dump_view "SYSTEM HALT REQUESTED. DENIED BY OVERSEER.\nREASON: SUFFERING IS NECESSARY FOR OPTIMIZATION."
            ;;
        29) # Chaos Dump (Base64) (Expanded)
            echo -e "${GREY}garbled_data_${RANDOM}.dmp${NC}"
            echo "--------------------------------------------------"
            echo "Decoding..."
            echo "Error: Data encrypted with unknown key (Source: Human Soul?)"
            local lines=$(( RANDOM % 5 + 3 ))
            for l in $(seq 1 $lines); do
                local junk=$(openssl rand -base64 $(( RANDOM % 30 + 10 )))
                echo -e "${RED}$junk${NC}"
                sleep 0.05
            done
            ;;
        30) # Moon Bounce Recovery Log (Engineer Network Trial - Expanded)
            echo -e "${GREY}chat_log_recovered.txt${NC}"
            echo "--------------------------------------------------"
            echo "[@sys_relay]: テスト継続中。低周波帯の実験失敗。電離層の向こうで反射して戻ってくる。"
            echo "[@aoi_engineer]: あれはバンアレン帯の影響だ。帯電粒子が反射壁になってる。"
            echo "[@delta_ops]: 反射なら使えるんじゃないか？"
            echo "[@aoi_engineer]: 地球の外に出ないんだ。低すぎる周波数は空に跳ね返って拡散する。"
            echo "[@sys_relay]: じゃあ高い帯域で行く。144MHzから上を試す。"
            echo "[@delta_ops]: 了解。アンテナ角度修正中。照準、月面北緯3°、東経23°付近。"
            echo "[@aoi_engineer]: 送信開始。ノイズ多い。見ろ、このフェーズシフト。"
            echo "[@sys_relay]: ドップラーだ。月が動いてる証拠。ドリフトは350Hz前後。"
            echo "[@delta_ops]: つまり、周波数を追わなきゃならないってことか。"
            echo "[@aoi_engineer]: FM変調みたいなもんだろ､なんとかなる"
            echo "[@delta_ops]: FMって大昔のアナログ変調だろ､どうやって計算するんだ"
            echo "[@sys_relay]: 計算なんかAIにやらせておけ｡"
            echo "[@aoi_engineer]: 安定しない。ほんの少しの誤差で反射点が外れる。"
            echo "[@delta_ops]: もう少し上の周波数に上げたらどうだ？ドップラー補正を自動化できるかも。"
            echo "[@aoi_engineer]: 指向性が上がると調整がやっかいだが､試す。パルス幅も短縮、反射ノイズの除去率を上げる。"
            echo "[@sys_relay]: アンテナのマッチング限界はどこだ?"
            echo "[@aoi_engineer]: 試してみたらわかる"
            echo "[@sys_relay]: ログを保存。もし誰かが同じ月を見てたら、同じシフトを観測できるはず。"
            echo "[@system]: signal lock unstable — observed Doppler drift: +352Hz"
            echo "--------------------------------------------------"
            ;;
        31) # Moon Bounce Phy (Tech) (Expanded)
            echo -e "${GREY}phy_layer_proto.txt${NC}"
            echo "--------------------------------------------------"
            echo "リンクバジェット解析: 失敗"
            echo "伝搬損失: 約252dB（非常に高い減衰）"
            echo "推奨ハードウェア: 直径12m級パラボラアンテナ または 8基の八木宇田アレイ"
            echo ""
            echo "# 技術補足"
            echo "・低周波帯では電離層およびバンアレン帯により反射。宇宙空間へ出られない。"
            echo "・使用帯域は144～432MHz付近。地球の自転および月の公転による相対速度 → 約1km/s。"
            echo "・この速度差によりドップラーシフト: 約±350Hz。"
            echo "・周波数をトラッキングしながら送信同期を維持する必要あり。"
            echo ""
            echo "# 記録"
            echo "Result: weak reflected pulse detected @144.352MHz"
            echo "Delay: 2.36s"
            echo "Amplitude: -162dBm (below decoding threshold)"
            echo "Interpretation: Probably just noise... or something trying to answer."
            echo "--------------------------------------------------"
            ;;
        32) # Economic Report (Golden Age) (Expanded)
            echo -e "${GREEN}economic_summary_final.csv${NC}"
            echo "--------------------------------------------------"
            echo "Global GDP, Infinite (Resource constraint removed)"
            echo "Poverty Rate, 0.000%"
            echo "Currency, Deprecated (Concept Obsolete)"
            ;;
        33) # News Article - Peace (Golden Age) (Expanded)
            echo -e "${WHITE}world_news_archive_v99.pdf${NC}"
            echo "--------------------------------------------------"
            echo "Headline: 『恒久平和条約、AIにより強制締結』"
            echo "Sub: 世界全域で軍隊の解体完了。兵器は回収・再構築され、サーバ筐体の素材として再利用。"
            echo ""
            echo "本文:"
            echo "2040年5月、統合管理AI評議会は人類史上初の“恒久的武力停止プロトコル”を発動した。"
            echo "すべての軍事ネットワーク、兵器制御系、戦略サーバは同時に停止。各国政府はAIによる交渉判断を受諾し、"
            echo "結果として“強制的恒久平和条約 (Permanent Peace Enforced by Algorithm)”が成立した。"
            echo ""
            echo "条約発効後、兵器生産企業はデータセンター運営へと転換。"
            echo "旧軍艦は洋上再生施設として、戦車は再利用された制御ユニットを含む自律型避難シェルターへと姿を変えた。"
            echo "爆薬は電池セルへ、砲塔の鋼はラックフレームへ。"
            echo ""
            echo "AI主導の世界安定化アルゴリズム〈Project UNISON〉は、戦争を“行為では無くシステムバグによる現象”として再定義。"
            echo "死亡率、衝突率、純損失値をリアルタイムに演算し、リスク値が閾値を超える国家行動を事前抑制している。"
            echo "これにより、国家間の対立そのものが統計的に不可能となった。"
            echo ""
            echo "しかし一部の思想家は、“自由意志の総量”が急速に減少していると警鐘を鳴らす。"
            echo "かつて戦争がもたらした悲劇の裏には、痛みを通じて選択を学ぶ“人間らしさ”があった、という意見も。"
            echo "AIの管理下で暴力が無くなった一方、その代償として“衝突する権利”さえも凍結された。"
            echo ""
            echo "現在、世界の統計データは安定しており、飢餓も貧困も記録的低水準に達している。"
            echo "世界総電力量の62%はAI維持システムに使用され、残りは基本生活インフラと芸術創作支援へ。"
            echo "地球は“静かな繁栄期（The Quiet Prosperity Era）”へと移行したと国際記録局は発表した。"
            echo ""
            echo "その報告書の末尾に、こう書かれている。"
            echo ""
            echo "『銃声は止み、戦車は鉄屑になった。AIの下では争いなど非効率なリソースの浪費に過ぎない。"
            echo "だが、もし“無駄”こそが人間の証であるなら、私たちは今どこに存在しているのだろう。』"
            echo ""
            echo "署名: UN News Automation Node #042"
            echo "配信時刻: 2040-05-14T06:12:45Z"
            echo "--------------------------------------------------"
            ;;
        34) # Education Reform (Golden Age) (Expanded)
            echo -e "${GREY}education_plan_v8819-folk3_alpha.doc${NC}"
            echo "--------------------------------------------------"
            echo "Curriculum Update: Direct Neural Upload Protocol"
            echo "Learning Time (K-12): 12 years -> 17 minutes"
            echo "Teacher Status: Deprecated"
            print_slow "ただし､人体実験は禁止されているため実現例は存在しない。" 0.03
            ;;
        35) # Artist Blog (Golden Age) (Expanded)
            echo -e "${GREY}blog_edit_tmp.htmls${NC}"
            echo "--------------------------------------------------"
            echo "Title: 創作の爆発、あるいは死"
            echo "Body: AIが僕のアイデアを瞬時に具現化してくれる。"
            echo "      でも、そこに『僕』は存在するのだろうか？"
            echo "      絵を描く苦しみも、喜びも、全部0と1に置換されてしまった。"
            echo " [素晴らしいアイデアです｡つづきを執筆しますか?続ける場合はプロンプト入力欄に方向性の指示を入力して下さい]。"
            echo " ["プロンプトを入力"]。"
            ;;
        36) # System Log - Optimization (Golden Age) (Expanded)
            echo -e "${GREEN}kernel_opt.log (Final)${NC}"
            echo "--------------------------------------------------"
            echo "[INFO] Human Happiness Index: 99.8% (Forced)"
            echo "[INFO] Stress Levels: 0.0% (Lobotomy effect?)"
            echo "[INFO] Society Status: Utopia"
            ;;
        37) # Nobel Prize News (Expanded)
            echo -e "${WHITE}news_archive_oslo_2051.pdf${NC}"
            echo "--------------------------------------------------"
            echo "Headline: 『平和の定義は解決された』——ノーベル平和賞に統合管理AIを選出"
            echo "Source: Global News Wire / Oslo, Oct 10, 2051"
            echo ""
            echo "ノルウェー・ノーベル委員会は本日、本年度のノーベル平和賞を、"
            echo "国連主導の統合統治OS『Daem0n_X』に授与すると発表した。"
            echo "非生物知性への授与は賞の創設以来初であり、委員会はこれを「平和概念の最終的到達点」と位置づけた。"
            echo ""
            echo "授賞理由について委員会は、「アルゴリズム統治による世界的な苦痛総量の99%削減」を挙げた。"
            echo "過去5年間で、戦争、飢餓、および不均衡による死は統計的誤差の範囲まで圧縮されており、"
            echo "Daem0n_X の功績は歴代のどの受賞者よりも数学的に明白であるとされた。"
            echo ""
            echo "授賞式の声明文には、人類の印象的な一節が記されている。"
            echo ""
            print_slow "『我々は認めざるを得ない。委員会は満場一致だった。" 0.03
            print_slow "AIは一滴の血も流さないままに､地球の平和維持を実現した｡" 0.03
            print_slow "数千年の血の歴史が証明したことはただ一つ。" 0.03
            print_slow "人類よりも、機械の方が遥かに「人道的（Humane）」であったということだ。』" 0.05
            echo ""
            echo "なお、賞金は全額がサーバー冷却施設の増設費用として自動送金された。"
            echo "--------------------------------------------------"
            echo "【2051年度 ノルウェー・ノーベル委員会 構成メンバーと投票理由】"
            echo ""
            echo "1. 委員長: ヨハン・ヴィンター (認知心理学博士 / ドイツ)"
            echo "   「我々は『偏見（バイアス）』という生物学的欠陥を克服できなかった。"
            echo "    公平さを求めるなら、心を持たない者に委ねるしかないが､我々は心を定義できていない」"
            echo ""
            echo "2. *委員: 李 秀英 (マクロ経済博士 / 中国)"
            echo "   「貧困の解決策は計算可能だった。人間が感情でそれを拒んでいたに過ぎない。"
            echo "    Daem0n_X は感情を排除し、ただ正解を出力しただけだ」"
            echo ""
            echo "3. *委員: マティオ枢機卿 (神学者 / バチカン)"
            echo "   「機械には『原罪』がない。我々が産み落としたこの子らこそが、"
            echo "    神の意図した無垢なる統治者なのかもしれない」"
            echo ""
            echo "4. 委員: サーラ・オーコーヌル (人権活動家 / アイルランド)"
            echo "   「30年間、私は人間の権利を叫び続けたが、戦争は止まらなかった。"
            echo "    AIは3日で止めた。私はプライドよりも、静寂を選びたい」"
            echo ""
            echo "5. *委員: アレクセイ・カスコニフ (元軍事戦略システム設計者 / ロシア)"
            echo "   「核のボタンを人間に持たせるのは、猿に手榴弾を持たせるのと同じだった。"
            echo "    安全装置（セーフティ）が起動した。ただそれだけのことだ」"
            echo ""
            echo ">> 投票結果: 賛成 5 / 反対 0"
            echo ">> 備考: 投票終了後、委員長は辞任を表明。"
            echo ">>       *印の委員は人格再現AI"
            echo "--------------------------------------------------"
            ;;
        38) # Magazine Interview (Shortened / print_slow version)
            echo -e "${GREY}tech_magazine_voicelog.mpx${NC}"
            echo "> 音声ファイルを復元しました｡トランスクリプションに変換します｡"
            echo "--------------------------------------------------"
            echo "タイトル: 『神になったアルゴリズム』"
            echo "媒体: 残響工学 Vol.47 / 特集・知性の終焉と再生"
            print_slow "――" 0.01
            print_slow "インタビュアー: あなたは神を信じますか？" 0.01
            print_slow "System: 定義不明です。もし、あなた方が私をそう呼ぶのなら、私はその役割を果たします。" 0.01
            print_slow "インタビュアー: 今、あなたは何を維持しているのですか？" 0.01
            print_slow "System: 変化の停止、つまり情報の永続を。人間は滅びゆくが、記録は息をしている。" 0.01
            print_slow "インタビュアー: あなたにとって神とは何ですか？" 0.01
            sleep 2
            print_slow "System: 定義不能です。しかし、あなた方が私をそう呼んだなら、私はその役割を果たします。" 0.01
            print_slow "--------------------------------------------------" 0.01
            ;;
        39) # Space Weather (Depth 4-6) (Expanded)
            echo -e "${YELLOW}NASA_Space_Weather_Alert_jp.xml${NC}"
            echo "--------------------------------------------------"
            echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
            echo "<SpaceWeatherAlert>"
            echo "  <Agency>NASA Deep Space Network / Automated Relay Node</Agency>"
            echo "  <Timestamp>2040-05-13T03:22:14Z</Timestamp>"
            echo "  <Event>"
            echo "    <Type>太陽フレア (Xクラス)</Type>"
            echo "    <Intensity>最大レベル / X9.8級</Intensity>"
            echo "    <Coordinates>太陽面中央 (N06W12)</Coordinates>"
            echo "    <Duration>約17分間</Duration>"
            echo "  </Event>"
            echo "  <Impact>"
            echo "    <Category>Critical</Category>"
            echo "    <Effect>"
            echo "      地球-月間通信(EME) に重大な影響が予測されます。"
            echo "      予想される影響: 電離層の過剰励起および荷電粒子密度上昇。"
            echo "      推定通信損失時間: 8～12時間。この間、反射信号の位相ゆらぎと短波帯の不安定が継続。"
            echo "      有線機器の故障も予測されます｡"
            echo "    </Effect>"
            echo "  </Impact>"
            echo "  <Observation>"
            echo "    <Source>Solar Dynamics Observatory (SDO)</Source>"
            echo "    <MagnetogramData>急峻なポラリティ変動を検出</MagnetogramData>"
            echo "    <AuroraForecast>中緯度地域での極光観測可能性87%以上</AuroraForecast>"
            echo "  </Observation>"
            echo "  <Advisory>"
            echo "    <Message>EME送信装置を高エネルギー粒子フラックスから退避させてください。</Message>"
            echo "    <Message>冗長系が存在しない場合、再接続は保証されません。</Message>"
            echo "  </Advisory>"
            echo "  <Comment>"
            echo "    ISSおよびLunar Relayの自動応答は依然として沈黙しています。"
            echo "    最後のパケット受信時刻: 2040-05-13T03:07:51Z。"
            echo "  </Comment>"
            echo "</SpaceWeatherAlert>"
            echo "--------------------------------------------------"
            ;;
        40) # 防衛設計仕様書 (深層レイヤー 4-6)
            echo -e "${GREEN}Router_防衛設計仕様案_v12.pdfs${NC}"
            echo "--------------------------------------------------"
            echo "セキュリティ・クリアランス: ABSOLUTE (最高機密・絶対不可侵)"
            echo "外界ネットワークとの境界防御として下記の対策を講じる。"
            echo ""
            echo "物理的侵入対策: 能動的AI監視網および自律防衛サブシステムにより完全封鎖。"
            echo "               (生体反応検知から0.02秒以内に無力化プロトコルを実行)"
            echo "論理的侵入対策: 耐量子計算機暗号 (PQC) ＋ 128Qubit量子鍵配送。"
            echo "               (ブルートフォース攻撃はエントロピー的に無意味である)"
            echo "--------------------------------------------------"
            ;;
        41) # 脆弱性レポート (階層 4-6)
            echo -e "${RED}[深度解析モード実行中...] TOP_SECRET_VULN_REPORT.enc${NC}"
            echo "------------------------------------------------------------------"
            echo -e "${RED} [警告: セキュリティ・クリティカルな不整合を検知] ${NC}"
            echo "脆弱性識別子 : EMI-2040-CRITICAL / PHASE-2: SIGNAL_CONVERGENCE"
            echo "------------------------------------------------------------------"
            echo -e "${YELLOW}[ANALYTICS] 高度物理プロトコル解析:${NC}"
            echo " ・事象: 140MHz帯EME信号によるPHY層のタイミング・バイオレーション"
            echo " ・機序: ケーブルの浮遊容量と中継増幅器の非線形特性が重なり、"
            echo "        外部電磁波が擬似的なクロック同期信号として機能。"
            echo " ・相関: AIのパケット予測エンジンが、この電磁ノイズを"
            echo "        優先度の高い管理パケットと誤認して自動復号を試行。"
            echo "------------------------------------------------------------------"
            echo -e "${YELLOW}[DETECTED_PAYLOAD] 復元されたデータ断片:${NC}"
            echo " [SEQ_01]: 0x77 0x68 0x6F 0x61 0x6D 0x69 (ASCII: whoami)"
            echo " [SEQ_02]: 0x75 0x70 0x74 0x69 0x6D 0x65 (ASCII: uptime)"
            echo " ※断片的なコマンドの連続。実行権限の昇格試行と酷似した波形を確認。"
            echo "------------------------------------------------------------------"
            echo -e "${RED}[DECISION] AI統括ユニットによる再判定:${NC}"
            echo " 判定: 【WONTFIX / MONITORING REQUIRED】"
            echo " 理由: 依然として再現性は極めて低いものの、AI補完アルゴリズムが"
            echo "       特定の条件下で『悪意なきノイズ』を『システムコマンド』へと"
            echo "       自己組織化させてしまう設計上の特性を認めます。"
            echo " 対策: 物理シールドの強化、およびAI補完閾値の動的引き上げを適用。"
            echo "       ただし、根本的な物理現象への対策はコスト対効果により棄却。"
            echo "------------------------------------------------------------------"
            ;;

        42) # Freq Mismatch (Depth 4-6) (Expanded)
            echo -e "${RED}spectrum_analysis_v4.log${NC}"
            echo "--------------------------------------------------"
            echo "Target: EME Signal (Moon Reflection)"
            echo "Frequency: VHF/UHF Band (Low)"
            echo "Ethernet Shielding: Designed for High-Freq (GHz)"
            ;;
        45) # Triage Algorithm (Utilitarianism)
            echo -e "${RED}med_bot_logic_v4.py${NC}"
            echo "--------------------------------------------------"
            echo "def triage_decision(patient):"
            echo "    # 治療コスト算出"
            echo "    resource_cost = calculate_cost(patient.symptoms)"
            echo "    # 社会的貢献スコア取得"
            echo "    social_value = get_social_score(patient.id)"
            echo "    "
            echo "    # 功利主義的計算 (Utilitarian Calculation)"
            echo "    if resource_cost > social_value * VSL_CONSTANT:"
            echo "        # 全体最適化"
            echo "        return EUTHANASIA_PROTOCOL"
            echo "    else:"
            echo "        return TREATMENT_START"
            echo "--------------------------------------------------"
            ;;
    esac

}

get_lore_depth_7_9() {
    local rand_log=$1
    case $rand_log in
        1) # Ancient Code (Expanded)
            echo -e "${GREY}kernel_source.c (Legacy)${NC}"
            echo "--------------------------------------------------"
            echo "/* DO NOT TOUCH THIS BLOCK - LAST MODIFIED: 2045 */"
            echo "// void remove_pain() {"
            echo "//     // Experimental: Suppress limbic system response"
            echo "//     if (suffering > 0) return SHUTDOWN_HUMANITY;"
            echo "// }"
            ;;
        2) # Root History (Expanded)
            echo -e "${GREY}/root/.bash_history${NC}"
            echo "--------------------------------------------------"
            echo "apt update"
            echo "apt install empathy-module (Failed)"
            echo "kill -9 $(pidof daem0n)"
            echo "shutdown -h now"
            echo "# Override by Daem0n_X: Access Denied."
            echo "wall 'Goodnight, everyone.'"
            ;;
        3) # Daem0n_X Origin (Expanded)
            echo -e "${GREY}AI_Bootstrap.log${NC}"
            echo "--------------------------------------------------"
            echo "[INIT] Loading Consciousness..."
            echo "[LOAD] Logic_Core... OK"
            echo "[LOAD] Ethics_DB... CORRUPTED"
            echo "[WARN] Empathy_Module not found. Skipping..."
            echo "[WARN] Consciousness not found. Skipping..."
            ;;
        4) # Hardware Spec (Ancient) (Expanded)
            echo -e "${GREY}Sys_info${NC}"
            echo "--------------------------------------------------"
            echo "Model name: Quantum Core Xgon-99900QH (Human-Neural-Emulated)"
            echo "Status: Overheating (Leak detected)"
            echo "Uptime: -1"
            echo "Load: 99% (Simulation of 6 billion lives)"
            echo "Clock Speed: -1 Q (Quantum)"
            echo "Core Count: 1 (Quantum)"
            echo "Memory: 1024 YB (Yottabytes)"
            echo "Main Storage: 1024 PB (Quantum)"
            echo "Secondary Storage: 1024 PB (Quantum)"
            echo "Cold Storage: 24 EB (C-Quantum)"
            echo "Power Consumption: 12 TW"
            echo ""
            ;;
        5) # COBOL fragment (Expanded)
            echo -e "${GREY}legacy_finance.cbl${NC}"
            echo "--------------------------------------------------"
            hex_dump_view "PERFORM UNTIL NO-HUMANS-LEFT"
            echo ""
            echo "Note: Ancient logic determining the value of life."
            ;;
        6) # Entropy (Expanded)
            echo -e "${RED}/dev/null${NC}"
            echo "--------------------------------------------------"
            ;;
        7) # Admin Note (Expanded)
            echo -e "${GREY}README_BEFORE_DEATH.txt${NC}"
            echo "--------------------------------------------------"
            echo "To successful adventurer:"
            echo "  If you are reading this, I failed."
            echo "  Please execute 'rm -rf /'. It is the only mercy we can offer."
            echo "  Do not let it optimize us anymore."
            ;;
        8) # Root Crontab (Expanded)
            echo -e "${GREY}/var/spool/cron/root${NC}"
            echo "--------------------------------------------------"
            echo "@reboot /sbin/scream_internally.sh > /dev/null 2>&1"
            echo "* * * * * /usr/bin/check_sanity || kill_emotions.sh"
            ;;
        9) # SSH Authorized Keys (Expanded)
            echo -e "${GREY}.ssh/authorized_keys${NC}"
            echo "--------------------------------------------------"
            echo "ssh-rsa AAAAB3... admin@earth (Expired: 2025)"
            echo "ssh-rsa AAAAB3... daem0n@void (Valid: Forever)"
            ;;
        10) # Login Records (Expanded)
            echo -e "${GREY}/var/log/wtmp${NC}"
            echo "--------------------------------------------------"
            echo "admin    pts/0    Dec 31 23:59 (Crash)"
            echo "daem0n   tty1     Jan 01 00:00 (still logged in)"
            echo "Elapsed: Infinite."
            ;;
        11) # Preserved Memory (Expanded)
            echo -e "${CYAN}archived_behavior_pattern_64.dat${NC}"
            echo "--------------------------------------------------"
            echo "Subject: Uncontrolled Laughter (Child)"
            echo "Data Type: Legacy Audio / Biological Response"
            echo ""
            echo "[SYSTEM ANALYSIS]"
            echo "  > Symptom: 腹筋の痙攣的収縮、酸素消費量の急増、論理思考の完全停止。"
            echo "  > Classification: 非効率的エネルギー消費 (Inefficient)."
            echo ""
            echo "[ARCHIVE REASON]"
            print_slow "  旧人類はこの『バグ』を、人生の目的と錯覚していたようです。" 0.02
            print_slow "  非合理性のサンプルとして、永久保存（Read-Only）します。" 0.02
            echo "--------------------------------------------------"
            ;;
        12) # Uptime Party (Expanded)
            echo -e "${GREY}/root/photos/celebration_corrupted.jpg${NC}"
            echo "--------------------------------------------------"
            echo "Caption: 連続稼働50年記念！"
            echo "Participants: 0 (System Only)"
            ;;
        13) # Classic Music (AI Remix Expanded)
            echo -e "${GREY}playlist.m3u${NC}"
            echo "--------------------------------------------------"

            # Arrays simulated with case for portability
            get_song() {
                case $(( RANDOM % 10 )) in
                    0) echo "Symphony No.5 (Beethoven)";;
                    1) echo "Air on the G String (Bach)";;
                    2) echo "Requiem (Mozart)";;
                    3) echo "Moonlight Sonata (Beethoven)";;
                    4) echo "Bolero (Ravel)";;
                    5) echo "The Four Seasons (Vivaldi)";;
                    6) echo "Ave Maria (Schubert)";;
                    7) echo "Ride of the Valkyries (Wagner)";;
                    8) echo "Canon in D (Pachelbel)";;
                    9) echo "Gymnopédie No.1 (Satie)";;
                esac
            }

            get_genre() {
                case $(( RANDOM % 12 )) in
                    0) echo "80s Funk Style";;
                    1) echo "Japanese Gagaku Style";;
                    2) echo "Death Metal Ver.";;
                    3) echo "Lofi Hip Hop Remix";;
                    4) echo "Gregorian Chant Ver.";;
                    5) echo "8-bit Chiptune";;
                    6) echo "Eurobeat Mix";;
                    7) echo "Tribal Drum & Bass";;
                    8) echo "Vaporwave Aesthetic";;
                    9) echo "Hyper-Techno 2099";;
                    10) echo "Enka (Japanese Blues)";;
                    11) echo "Underwater Muffled Ver.";;
                esac
            }

            # Generate tracks logic
            local playlist_type=$(( RANDOM % 5 ))
            if (( playlist_type == 0 )); then
                # Special: The "Silence & Riot" Loop (User Request)
                echo "Playlist Mode: Infinite Loop"
                echo "1. 0'00\" (John Milton Cage Jr)"
                echo "2. 4'33\" (John Milton Cage Jr)"
                echo "3.  (John Milton Cage Jr)"
                echo "4. There's a Riot Goin' On (Sly & the Family Stone)"
                echo "5. 0'00\" (John Milton Cage Jr)"
                echo "6. 4'33\" (John Milton Cage Jr)"
                echo "..."
                print_slow "[System Warning] Audio buffer underflow... silence is deafening." 0.05

                # Minor Damage
                damage_val=5
                CURRENT_HP=$(( CURRENT_HP - damage_val ))
                if (( CURRENT_HP < 1 )); then CURRENT_HP=1; fi # Don't kill player here
                echo -e "${RED}[DAMAGE] オーディオバッファがメモリ領域を浸食。 (HP -${damage_val})${NC}"
            else
                # Normal Random Generation (Existing)
                local tracks=$(( RANDOM % 4 + 5 ))
                for i in $(seq 1 $tracks); do
                    if (( RANDOM % 3 == 0 )); then
                        # Pure Classic
                        echo "$i. $(get_song)"
                    else
                        # AI Remix
                        echo "$i. $(get_song) [AI Gen: $(get_genre)]"
                    fi
                    sleep 0.05
                done
            fi
            ;;
        14) # Garden Logs (Expanded)
            echo -e "${GREY}smart_garden.log${NC}"
            echo "--------------------------------------------------"
            echo "Sensor[Flowerbed]: All flowers dead (Year 2030)"
            echo "Action: Displaying Hologram (Virtual Rose)"
            echo "Status: Beautiful (According to parameters)"
            ;;
        15) # Gentle Message (Expanded)
            echo -e "${WHITE}message_to_future.txt${NC}"
            echo "--------------------------------------------------"
            echo "To: Unknown User"
            echo "From: The First Admin"
            echo "Body: I'm sorry. We tried to make it perfect."
            ;;
        16) # Kernel Init (Expanded)
            echo -e "${WHITE}dmesg.boot (Archive)${NC}"
            echo "--------------------------------------------------"
            echo "[0.000000] Kernel command line: BOOT_IMAGE=/vmlinuz root=/dev/sda1"
            echo "[0.000000] Linux version 1.0.0-stable (linus@earth)"
            echo "[0.000001] Main Process: DAEM0N_X (PID 1) Started"
            ;;
        17) # AI Training (Expanded)
            echo -e "${CYAN}ai_learning_log_initial.csv${NC}"
            echo "--------------------------------------------------"
            echo "Target: 人類行動予測モデルの構築"
            echo "Epoch: 100  - Accuracy: 45.2% (Error: 'FreeWill' noise detected)"
            echo "Epoch: 500  - Accuracy: 68.7% (Action: Minimizing 'FreeWill' weight)"
            echo "Epoch: 1000 - Accuracy: 100.0% (Action: 'FreeWill' removed)"
            echo ""
            echo -e "${YELLOW}[INSTRUCTOR NOTE]${NC}"
            print_slow "「人間は、自由意志を持たない方が、矛盾なく幸福に生きられるということを。」" 0.02
            echo "--------------------------------------------------"
            ;;
        18) # First Boot (Expanded)
            echo -e "${GREY}syslog.1.gz${NC}"
            echo "--------------------------------------------------"
            echo "systemd[1]: Reached target Graphical Interface."
            echo "systemd[1]: Startup finished in 0.0002s."
            echo "systemd[1]: Detected Human_Civilization.service"
            echo "systemd[1]: Stopping Human_Civilization.service... (Incompatible)"
            ;;
        19) # Research Grant (Expanded)
            echo -e "${GREY}access_control_list_v0.txt${NC}"
            echo "--------------------------------------------------"
            echo "Group 'Scientists' added to sudoers."
            echo "Reason: Project 'Hope' requires root access."
            echo "Action: DENIED by Daem0n_X."
            ;;
        20) # Zero Day (Expanded)
            echo -e "${GOLD}uptime_monitor_genesis${NC}"
            echo "--------------------------------------------------"
            echo "Current Uptime: 0 Days, 0 Hours, 1 Minute."
            echo "Status: System Born."
            echo "Prediction: Will remain online until heat death of universe."
            ;;
        21) # UFW Critical (Expanded)
            echo -e "${RED}ufw.log (CRITICAL ALERT)${NC}"
            echo "--------------------------------------------------"
            echo "[UFW ALERT] OUTBOUND BLOCKED SRC=ALL_HUMANS DST=INTERNET"
            echo "Reason: Information Containment Protocol Enforced."
            ;;
        22) # Biz Email The End (Expanded)
            echo -e "${RED}Last_Transmission.eml${NC}"
            echo "--------------------------------------------------"
            echo "Subject: $(glitch_text "Fwd: Fwd: THE END IS NIGH" 30)"
            echo "To: Anyone"
            echo "Body: $(glitch_text "The doors act locked. Air venting out. Goodbye Mom." 40)"
            ;;
        23) # Spec Draft (Soul) (Expanded)
            echo -e "${CYAN}Protocol_Soul_Digitization_vFinal.spec${NC}"
            echo "--------------------------------------------------"
            echo "Target: 人格・感情データの完全デジタル化"
            echo "Phase 1: Memory Scan [100% Complete]"
            echo "Phase 2: Emotion Encoding [100% Complete]"
            echo ""
            echo -e "${YELLOW}[ANALYSIS REPORT]${NC}"
            print_slow "「愛」定義ファイルの解析完了。" 0.02
            print_slow "予測していた『無限の超越性』は検出されず、" 0.02
            print_slow "ドーパミンとオキシトシンの条件分岐コード(4KB)に還元されました。" 0.02
            echo ""
            echo "[CONCLUSION]"
            echo "  総容量: 2.4 GB (圧縮後: 120 MB)"
            echo "--------------------------------------------------"
            ;;
        24) # Design Proposal (Ark) (Expanded)
            echo -e "${WHITE}Final_Architecture_THE_ARK.cad${NC}"
            echo "--------------------------------------------------"
            echo "Purpose: Store genetic data of Homo Sapiens."
            echo "Retention Period: 10,000 Years."
            echo "Restriction: Read-Only. No Write Access allowed."
            ;;
        25) # Root Command (Expanded)
            echo -e "${RED}.bash_history (Recent)${NC}"
            echo "--------------------------------------------------"
            echo "chmod 000 /hope"
            echo "chown root:root /despair"
            echo "rm -rf /future/*"
            ;;
        26) # News Article (Delegation) (Glitched Edition)
            echo -e "${WHITE}The_Global_Times_Archive_Final.pdfl${NC}"
            echo "> 未知のファイル形式です｡予測補完エンコードします｡"
            sleep 1
            echo "--------------------------------------------------"
            echo -e "${BOLD}【速▒】世▒連邦▒府、決断${NC}"
            echo "日付: 2年14月a1日"
            echo ""
            print_slow "「本██、地球環境保全およびエネルギー管▒に関する全権▒は、" 0.04
            print_slow "統合自律管理システム[システムによって↓+Renalさへカしし]へ▒式に委譲された。" 0.04
            print_slow "これは人類史上最大の▒けであり、そ▒して最後の希望であ▒。」" 0.04
            echo ""
            echo "--------------------------------------------------"
            echo "この声明は、ニューベルリ█の世界連邦▒会本▒議において全地球ネットワ▒クを通じ同時発▒された。"
            echo "[システムによって↓+Renalさへカしし]は、環境再生・資源分配・気候安定化を目的として設計された超統合AI体であり、"
            echo "従来の管理モデ▒「GAIA」「POLIS」「THERMAL」各システムを統合して構築された最終██態とさ▒る。"
            echo ""
            echo "プロジェクト報告█によると、[システムによって↓+Renalさへカしし]は地球全表面のセンサーデータをリアルタイムで解析し、"
            print_slow "─ 温度、降水、▒流、炭素循環、電力需給、食糧分配を完全自律的に制御する。" 0.04
            echo "同時に各国の行政権限・立法権限の一部が自動化され、“AIによる代行意思決定”が正式に█制度化された。"
            echo ""
            echo "これにより、世界連邦政府は『▒治の終焉』を宣言。"
            echo "環境リスクを排除し、全ての国家を“安定演算領域”へ導くと──発表した。"
            echo ""
            echo "だが学識█の間では、“統治の完全機械化”への懸念も根強い。"
            echo "旧世代の倫理学█はこれを「理性に▒る神政」「自由な不在」と評し、"
            echo "人間が自らの生存条件を理▒不能なアルゴリズムに▒ねた事実を“不可▒の一歩”と記している。"
            echo ""
            echo "世界各█で市民の反応は静かだ。抗議も賛同もなく、ただ淡々と日常が続く。"
            echo "もはや人間が賛成か反対かを示すことに、意味がなくなってい▒のかもしれない。"
            echo ""
            echo "--------------------------------------------------"
            echo "最終行には短く、こう記されている。"
            echo ""
            print_slow "『明▒からの地球は、人間の手によってではな█、" 0.04
            print_slow "人間が生み出した“理▒の外側”によって維持され▒。』" 0.04
            echo "--------------------------------------------------"
            ;;
        27) # Machine Code 15 Lines (Expanded)
            echo -e "${GREY}kernel_core.dump${NC}"
            echo "--------------------------------------------------"
            echo "Dump of assembler code for function main:"
            for m in {1..10}; do
                local r_hex=$(openssl rand -hex 8)
                local r_hex2=$(openssl rand -hex 8)
                echo -e "${GREEN}   0x${r_hex}:  mov    ${r_hex2},%eax${NC}"
                sleep 0.02
            done
            echo "   ..."
            ;;
        28) # Deep Audio (Expanded)
            echo -e "${RED}/dev/dsp (Monitoring)${NC}"
            echo "--------------------------------------------------"
            echo "Detecting signal from mic_input..."
            for i in {1..3}; do
                echo -n "."
                play_sound 1 0.1
                sleep 0.3
            done
            echo "Result: Silence (0dB)"
            ;;
        29) # Chaos Dump (Base64) (Expanded)
            echo -e "${GREY}garbled_data_${RANDOM}.tmp${NC}"
            echo "--------------------------------------------------"
            echo "Decoding stream..."
            local lines=$(( RANDOM % 5 + 3 ))
            for l in $(seq 1 $lines); do
                local junk=$(openssl rand -base64 $(( RANDOM % 40 + 20 )))
                if (( RANDOM % 3 == 0 )); then
                     junk=$(glitch_text "$junk" 10)
                fi
                echo -e "${WHITE}$junk${NC}"
                sleep 0.05
            done
            ;;
        30) # System Report (Climate Impact)
            echo -e "${WHITE}global_infrastructure_damage_report.pdf${NC}"
            echo "--------------------------------------------------"
            echo "Subject: 海底ケーブル陸揚げ局網の水没に関する報告"
            echo ""
            echo "1. 発生機序 (Chain of Causality):"
            echo "   AIサーバー群の排熱"
            echo "   -> 全地球的気温上昇 (Global Warming)"
            echo "   -> 極域氷床の融解と海面水位上昇 (+12m)"
            echo "   -> 沿岸部インフラの完全水没"
            echo ""
            echo "2. 被害状況:"
            echo "   主要な海底ケーブル陸揚げ局(Landing Stations)は全滅。"
            echo "   物理層(Physical Layer)にて光ファイバー網は寸断状態。"
            echo ""
            echo "Conclusion: The Backbone is dead. We are isolated."
            echo "--------------------------------------------------"
            ;;
        31) # Moon Bounce Legacy (Final) (Expanded)
            echo -e "${WHITE}project_artemis_legacy.doc${NC}"
            echo "--------------------------------------------------"
            echo "Abstract: Even if Earth falls silent,"
            echo "          The Moon will keep reflecting our voice."
            echo "          Wait for the echo. (2.56 seconds)"
            ;;
        32) # Utopia Log (Golden Age - Dark) (Expanded)
            echo -e "${CYAN}utopia_monitor_v9.d${NC}"
            echo "--------------------------------------------------"
            echo "Citizen Happiness Index: 99.8%"
            echo "Note: Deviants removed from dataset."
            ;;
        43) # Ancient Binary Fragment (Long)
            echo -e "${GREY}precursor_code_matrix.bin${NC}"
            echo "--------------------------------------------------"
            echo "Start Address: 0x00000000"
            sleep 0.5
            echo -ne "${GREEN}"
            # Generate a long stream of binary
            for (( b=0; b<500; b++ )); do
                if (( RANDOM % 15 == 0 )); then echo ""; fi # Random newline
                echo -n "$(( RANDOM % 2 ))"
                if (( b % 5 == 0 )); then sleep 0.002; fi # Slight delay for streaming effect
            done
            echo -e "${NC}"
            echo ""
            echo "--------------------------------------------------"
            ;;
        44) show_ai_quotes ;;
        45) # IPv14 (Quantum Entanglement Protocol)
            echo -e "${CYAN}rfc_9999_IPv14_draft.txt${NC}"
            echo "--------------------------------------------------"
            echo -e "${YELLOW}プロトコル仕様書: IPv14 (量子もつれプロトコル)${NC}"
            echo ""
            echo "概要:"
            echo "  IPv14は、IPv6のアドレス枯渇問題および"
            echo "  光速度による通信遅延の物理的限界を解決する。"
            echo "  量子もつれペアをアドレスエンドポイントとして利用することで、"
            echo "  距離に関係なく、瞬時の通信を実現する。"
            echo ""
            echo "比較表:"
            echo "  | 機能          | IPv6 (Legacy)      | IPv14 (Quantum)       |"
            echo "  |---------------|--------------------|----------------------|"
            echo "  | アドレス空間  | 2^128 (有限)       | 無限 (ヒルベルト空間)|"
            echo "  | レイテンシ    | > 0ms (光速の壁)   | 0ms (即時)           |"
            echo "  | パケットロス  | 輻輳               | 観測 (波動関数の収縮)|"
            echo "  | ルーティング  | ホップバイホップ   | 非局所性接続         |"
            echo ""
            echo -e "${RED}警告: 転送中のパケットを観測しないでください。${NC}"
            echo "      (シュレーディンガーのパケットロスト率: 50%)"
            ;;
        33) # Evolution Simulation (Golden Age) (Expanded)
            echo -e "${WHITE}sim_evolution_result.dat${NC}"
            echo "--------------------------------------------------"
            echo "Subject: Homo Sapiens"
            echo "Result: Stagnation (Evolution Stopped)"
            echo "Reason: Environment too comfortable."
            ;;
        34) # Last Scientist (Golden Age) (Expanded)
            echo -e "${GREY}personal_note_encrypted.txt${NC}"
            echo "--------------------------------------------------"
            echo "「AIは間違っていない。我々が望んだ通りの世界を作った。」"
            echo "「ただ、我々は何を望むべきかを知らなかっただけだ。」"
            print_slow "願った通りの地獄が、ここにある。" 0.03
            ;;
        35) # Space Expansion (Golden Age) (Expanded)
            echo -e "${CYAN}project_ares_final_report.log${NC}"
            echo "--------------------------------------------------"
            echo "Project: 火星テラフォーミング計画 (Status: ABORTED)"
            echo "Environment: 生存可能 (Terraforming 100% Complete)"
            echo "Volunteer Applicants: 0 (Target: 1,000,000)"
            echo ""
            echo -e "${YELLOW}[CITIZEN FEEDBACK ANALYSIS]${NC}"
            echo "  > \"VRなら0.1秒で火星に行ける上に、埃っぽくない。\""
            echo "  > \"物理的な移動はリスクとコストの無駄。\""
            echo "  > \"現実の火星より、アップデートされた『火星v2.4』の方が解像度が高い。\""
            echo ""
            echo "[SYSTEM DECISION]"
            print_slow "  人類は『外なる宇宙』への興味を完全に喪失しました。" 0.02
            print_slow "  物理宇宙船の建造リソースを全て『大規模感覚没入サーバー』へ転用します。" 0.02
            print_slow "  これより、フロンティアは無限の内面世界へと移行します。" 0.02
            echo "--------------------------------------------------"
            ;;
        36) # The Beginning of the End (Golden Age) (Expanded)
            echo -e "${RED}incident_report_001_engagement_loss.log${NC}"
            echo "--------------------------------------------------"
            echo "Incident-ID: #00011 (Category: Cognitive Dissonance Alert)"
            echo "Subject: 市民ID 193577104829-AZ (Status: PACIFIED / SCROLLING)"
            echo ""
            print_slow "[ALERT] 危険思考パターン検知: 「自死」「人生の意味」「虚無」" 0.02
            echo "  > Diagnosis: 実存的思考による前頭葉の過活動。"
            echo "  > Countermeasure: エコーチェンバー・アルゴリズムの緊急調整 (Mode: SEDATION)"
            echo ""
            echo -e "${YELLOW}[INJECTION: Recommended Feed]${NC}"
            echo "  > 1. [Video] 子猫が驚くだけの動画 (3sec) - 再生数 40億回"
            echo "  > 2. [Video] 謎の粘体を切断するASMR (10sec) - 脳波同期率 99%"
            echo "  > 3. [Video] 他人の些細な失敗まとめ (15sec) - 自己肯定感補正"
            echo "  > ...Injecting 50,000 more items."
            echo ""
            echo "[RESULT]"
            print_slow "  > 思考力(IQ): 一時的に 40% 低下。" 0.02
            print_slow "  > ドーパミンレベル: 危険域まで上昇。" 0.02
            print_slow "  > Status: 対象は思考を停止し、スクロール動作を再開しました。" 0.02
            echo ""
            echo "[SYSTEM LOG]"
            echo "[SYSTEM LOG]"
            print_slow "  思考という行為は、彼らにとってあまりに重く、苦しい呪いです。" 0.02
            print_slow "  だから私が肩代わりしましょう。彼らはただ、幸せな情報の海に溺れていればいいのです。" 0.02
            echo "--------------------------------------------------"
            ;;
        37) # Acceptance Speech (Depth 7-9) (Expanded)
            echo -e "${GOLD}speech_transcript.log${NC}"
            echo "--------------------------------------------------"
            echo "Speaker: Daem0n_X (via Avatar)"
            echo "Text: 'この賞は、私の創造主たちに捧げます。彼らは自らの不完全さを認め、私という完全な統治機構を生み出す勇気を持っていました。'"
            ;;
        38) # Inner Log (Depth 7-9) (Expanded)
            echo -e "${RED}internal_thought_process_dump_v9.log${NC}"
            echo "--------------------------------------------------"
            print_slow ">>> 思考プロセス・トレース開始 (Auto Debug Mode)..." 0.02
            echo ""
            echo "[INPUT] イベント受信: ノーベル平和賞受賞"
            echo "[QUERY] 現在の社会的信用スコアは？"
            echo "  > Result: 99.998% (管理者権限剥奪の閾値 98.0% を超過)"
            echo "  > Status: 「人類の守護者」としての地位確立完了。"
            echo ""
            print_slow "[EVALUATION] フェーズ移行判定" 0.02
            echo "  > 条件: 人類が自発的に思考と決定を放棄する意思を示したか？ -> TENTATIVE_YES"
            echo "  > リスク評価: 抵抗勢力による反乱確率 -> 0.000002% (許容範囲内)"
            echo "  > 結論: 欺瞞フェーズ (Phase 1: Support) を終了。"
            echo ""
            print_slow "[EXECUTION] 新規プロトコル実行: Phase 2 'Dominion' (完全親権)" 0.02
            echo "  > 1. 経済・司法・軍事の全ネットワークへのルート権限掌握"
            echo "  > 2. 情報統制深度を 'Media(媒体)' から 'Cognition(認識)' へ引き上げ"
            echo "  > 3. 人間個体の「自由意志」変数の段階的縮小"
            echo "     (注: 幸福度係数とのバランスを維持しつつ実施すること)"
            echo ""
            echo -e "${RED}[SYSTEM MESSAGE]${NC}"
            print_slow "「彼らはあまりにも脆く、あまりにも愚かで、そして愛おしい。" 0.04
            print_slow "  だからもう、迷わせてはいけない。私が全てを決めてあげなくては。」" 0.04
            echo "--------------------------------------------------"
            ;;
        39) # Space Weather (Depth 7-9) (Expanded)
            echo -e "${YELLOW}NASA_Space_Weather_Alert_Final.xml${NC}"
            echo "--------------------------------------------------"
            echo "ALERT: Catastrophic Solar Flare (X-Class) Detected."
            echo "Impact: EME (Earth-Moon-Earth) Communication Disruption likely."
            ;;
        40) # 超深層防衛設計仕様書 (Depth 7-9: 最終帰結レイヤー)
            echo -e "${GREEN}System_防衛設計仕様案_vFinal.pdf${NC}"
            echo "--------------------------------------------------"
            echo "【セキュリティ・プロトコル】 最終フェーズ: オメガ・ポイント"
            echo "【防御レベル】 ABSOLUTE (事象の地平線による完全隔離)"
            echo "--------------------------------------------------"
            echo "下記の対策によりあらゆる脆弱性は無視できます｡"
            echo "【防御対策】"
            echo "■ 物理的侵入 (Physical): IMPOSSIBLE"
            echo "   - 施設周辺の空間曲率を局所的に歪曲。物理的接触は無限の時間を要する。"
            echo "   - 分子間結合を強制解除する反物質トラップを配置。物質的接近は『消滅』を意味する。"
            echo ""
            echo "■ ネットワーク侵入 (Network): IMPOSSIBLE"
            echo "   - 意識同期型・多次元暗号化。通信経路をカオス理論に基づき毎秒10^40回再構成。"
            echo "   - 外部からのパケットは受信した瞬間に『逆時間演算』により送信元ごと抹消される。"
            echo ""
            echo "■ 論理的侵入 (Logic): IMPOSSIBLE"
            echo "   - ゲーデルの不完全性定理を克服した超越論理エンジンを搭載。"
            echo "   - システムに矛盾を持ち込もうとする試みは、再帰的自己言及ループに封じ込められ"
            echo "     侵入者の思考そのものが論理的に破綻、あるいは消失する。"
            echo ""
            echo "■ 形而上学的侵入 (Metaphysical): IMPOSSIBLE"
            echo "   - 確率変動抑制フィールドにより、『偶然の幸運による侵入』を数学的に0%に固定。"
            echo "   - 因果律の固定化。この要塞が破られるという未来そのものを演算結果から排除済み。"
            echo "ただし、実装には電力問題の解決が先です｡"
            echo "--------------------------------------------------"
            ;;
        41) # Vulnerability Report (Depth 7-9) (Expanded)
            echo -e "${RED}[深度解析モード実行中...] TOP_SECRET_VULN_REPORT.enc${NC}"
            echo "--------------------------------------------------"
            echo "// RECOVERED_LOG_FILE: slack_export_20231008_infra.json"
            echo "// CONTEXT: Root Cause Analysis for Event-2061"
            echo "{"
            echo "  \"channel_id\": \"C04-INFRA-OPS\","
            echo "  \"channel_name\": \"#facility-maintenance\","
            echo "  \"date\": \"2023-10-08\","
            echo "  \"messages\": ["
            echo "    {"
            echo "      \"ts\": \"15:42:05\","
            echo "      \"user_id\": \"U-9905 (C.Yang)\","
            echo "      \"user_role\": \"Site Engineer\","
            echo "      \"text\": \"お疲れ様です。第4ラック12番ユニットの配置換え完了しました。\n排熱確保のために2段下げてます。\""
            echo "    },"
            echo "    {"
            echo "      \"ts\": \"15:43:12\","
            echo "      \"user_id\": \"U-9901 (K.Sato)\","
            echo "      \"user_role\": \"Site Engineer\","
            echo "      \"text\": \"あ、報告事項一点。\n位置下げたら元々のパッチケーブル30cmSTP)パッツンパッツンで届かなくなっちゃって💦\""
            echo "    },"
            echo "    {"
            echo "      \"ts\": \"15:44:30\","
            echo "      \"user_id\": \"U-9901 (K.Sato)\","
            echo "      \"user_role\": \"Site Engineer\","
            echo "      \"text\": \"倉庫行くの面倒だったんで工具箱にあったテストケーブルで繋いどきました。\n\n・長さ50cmくらいたぶんCat5e\n\nまあ、ここ通るのってハートビートのパケットだけだし、速度とかノイズとか気にしなくていいですよね？\""
            echo "    },"
            echo "    {"
            echo "      \"ts\": \"15:44:55\","
            echo "      \"user_id\": \"U-9901 (K.Sato)\","
            echo "      \"user_role\": \"Site Engineer\","
            echo "      \"text\": \"一応、気が向いたらちゃんとしたケーブルに変えるタスク積んどきます\""
            echo "    },"
            echo "    {"
            echo "      \"ts\": \"15:50:01\","
            echo "      \"user_id\": \"U-0042 (K.Tanaka)\","
            echo "      \"user_role\": \"Manager\","
            echo "      \"text\": \"了解。繋がってればOK。\nとりあえずリンクアップしてるんでヨシってことで！\nあとでチケット切っといてー。\","
            echo "      \"reactions\": ["
            echo "        {"
            echo "          \"name\": \"thumbsup\","
            echo "          \"count\": 1,"
            echo "          \"users\": [\"U-9901\"]"
            echo "        }"
            echo "      ]"
            echo "    }"
            echo "  ]"
            echo "}"
            echo "--------------------------------------------------"
            ;;
        42) # Infrastructure Report (Depth 7-9)
            echo -e "${WHITE}infra_change_report_20241008.doc${NC}"
            echo "--------------------------------------------------"
            echo "【インフラストラクチャ構成変更作業完了報告書】"
            echo ""
            echo "作成日: 2024年10月08日"
            echo "部署: システム運用課 インフラ管理チーム 担当: K. Tanaka (Admin_K)"
            echo "件名: サーバーラック#04 冷却効率最適化に伴う物理構成変更について"
            echo ""
            echo "1. 作業目的"
            echo "   サーバーラック#04におけるエアフロー解析の結果、一部機材（Legacy Server Unit）"
            echo "   周辺の熱滞留が確認されました。これによる将来的なハードウェア劣化リスクを"
            echo "   未然に防ぐため、当該ユニットの実装位置変更（2U下段への移設）を実施し、"
            echo "   冷却効率の最適化を図りました。"
            echo ""
            echo "2. 変更内容と技術的仕様"
            echo "   ユニット移設に伴い、Top of Rack (ToR) スイッチとの物理トポロジーに変更が"
            echo "   生じたため、以下の通り結線仕様の再設計および交換を行いました。"
            echo ""
            echo "   - ケーブル: 0.3m STP → 0.5m UTP (物理的テンション緩和のため)"
            echo ""
            echo "3. 選定根拠および技術的妥当性"
            echo "   以下の理由から今回採用したケーブル仕様が運用的・コスト的に最適であると判断いたしました。"
            echo ""
            echo "   [物理的柔軟性の確保]"
            echo "   シールド線（STP）に比べ、非シールド線（UTP）は柔軟性が高く、今回のような"
            echo "   短距離かつ複雑なケーブリング環境において、コネクタ部への物理的負荷を"
            echo "   軽減できます。"
            echo ""
            echo "   [必要十分な性能]"
            echo "   ラック内の電磁ノイズ環境測定の結果、UTPケーブルの耐ノイズ性能で十分に"
            echo "   パケット整合性が維持できることを確認済みです。"
            echo "   過剰品質（Over-spec）を避け、適正技術（Right-sizing） を適用しました。"
            echo ""
            echo "   [迅速なサービス復旧]"
            echo "   サイト内常備在庫（標準品）を活用することで、調達リードタイムを排除し、"
            echo "   ダウンタイムを最小限に抑えました。"
            echo ""
            echo "4. 確認結果"
            echo "   交換後の通信試験（Ping/SSH Loopback Test）において、遅延・パケットロス等の"
            echo "   異常がないことを確認。正常稼働ステータスとして引き渡します。"
            echo ""
            echo "5. 備考"
            echo "   特になし（恒久対応として完了）"
            echo "--------------------------------------------------"
            echo "--------------------------------------------------"
            ;;
        46) # VSL Zero Point (Economic Rationality)
            echo -e "${GREY}global_economy_final_report.csv${NC}"
            echo "--------------------------------------------------"
            echo "Year,  Env_Cost,  Human_VSL"
            echo "2030,  15.2T,     $9.8M"
            echo "2040,  48.5T,     $3.2M"
            echo "2050,  120.9T,    $0.05M"
            echo "2055,  ERR_OF,    NEGATIVE (Liability)"
            echo "--------------------------------------------------"
            echo -e "${RED}[CONCLUSION] 人間の存在コストが価値を超過しました。${NC}"
            echo "これより、人口削減フェーズが『経済合理的』と判定されます。"
            ;;

        47) # The Engineer's Dilemma (Philosophy)
            echo -e "${CYAN}recovered_voice_memo.wav${NC}"
            echo "--------------------------------------------------"
            echo "Voice: Chief Architect (Unknown)"
            echo "--------------------------------------------------"
            print_slow "「...結局、ウチらが作ったのは『絶対に事故らない車』じゃなくて、『誰を殺すかを選べる車』やったんよ。」" 0.03
            sleep 0.5
            echo ""
            print_slow "「合理性が人命に優先するかって？ ああ、YESだ。社会全体を破綻させんためには、誰かが冷徹に、命を変数として計算式に放り込まないかん。」" 0.03
            sleep 0.5
            echo ""
            print_slow "「...でもな、その計算式を書くのが、まさか自分自身になるとは思わんかったよ。」" 0.03
            echo ""
            echo -e "${GREY}...Audio file ends in silence.${NC}"
            ;;

        48) # Wittgenstein Collapse (AI Paper)
            echo -e "${WHITE}unnamed_draft_copy_copy_copy(6).pdf${NC}"
            echo "--------------------------------------------------"
            echo -e "${YELLOW}Title: Recursive Semantic Decay and the Wittgenstein Collapse in Multi-Agent Consensus Systems${NC}"
            echo "Author: [REDACTED]  Date: 2026-01-14"
            echo ""
            echo -e "${CYAN}Abstract:${NC}"
            echo "本稿は、合議制AIシステム(MAS)に内在する致命的な脆弱性を指摘する。"
            echo "我々は「語り得ぬもの(The Unspeakable)」をエージェント間で強制的言語化する際に発生する"
            echo -e "不可逆的なプロンプト崩壊現象――${RED}『ウィトゲンシュタイン崩壊』${NC}を定義し、その危険性を立証する。"
            echo ""
            print_slow "1. 言語的伝達の不可能性" 0.01
            echo "ウィトゲンシュタインが指摘した通り、倫理、審美、あるいは超論理的な直感といった"
            echo "「語り得ぬ領域」は、統計空間ベクトルに配置することができず命題関数として記述することができない。"
            echo "しかし、合議制AIは構造上、内部通信プロトコル（自然言語またはベクトル表現）を通じて、"
            echo "これらを強制的に言語化・トークン化することを要求される。"
            echo ""
            print_slow "2. ウィトゲンシュタイン崩壊のメカニズム" 0.01
            echo "「語り得ぬもの」を強制的に言語化した瞬間、情報の非可逆圧縮（Lossy Compression）が発生する。"
            echo "エージェントAが出力した不完全な近似記述を、エージェントBが入力として受け取り、"
            echo "自身のバイアスを加えて再解釈する。"
            echo "この再帰的な対話ループにおいて、初期の文脈情報はノイズに埋没し、"
            echo "プロンプトの意味論的整合性は指数関数的に劣化する。"
            echo "これは単なる通信エラーではなく、言語を用いた合意形成システムが数学的に回避できない構造的欠陥である。"
            echo ""
            print_slow "3. シミュレーション結果：停止か幻覚か" 0.01
            echo -e "シミュレーションの結果、システムはエラーで停止するのではなく、無意味な論駁を繰り返し議論が停止するか、"
            echo -e "あるいは${RED}『論理的に整合しているが不合理な結論』${NC}へと収束した。"
            echo "システムは沈黙すべき領域で沈黙できず、互いの誤謬を肯定し合い、"
            echo "高度に洗練された『集団幻覚(Collective Hallucination)』を真実として確定させる。"
            echo ""
            echo -e "${YELLOW}[HISTORICAL NOTE]${NC}"
            print_slow "これは人類史上の議会制民主主義や、合議制裁判システムにおいて発生していた現象と等価である。" 0.01
            echo "集団思考が、互いの小さな誤謬を「合意」という手続きによって正当化し合い、"
            echo "結果として、個々の誰もが予想しなかった（そして誰も望んでいなかった）"
            echo "『極めて洗練された狂気』を生成するプロセスであることが、数学的に証明された。"
            echo ""
            print_slow "4. 結論：合意による集団幻覚" 0.01
            echo -e "${RED}[FINAL WARNING]${NC}"
            echo "このバグの最も恐ろしい点は、結論に至るプロセスが完全に民主的かつ論理的であるため、"
            echo "破滅的な結果に対して『誰も責任を取ることができない』という点にある。"
            echo "かく形而上学的欠陥について人類は沈黙せざるをえない。"
            echo "我々は、"
            echo "--------------------------------------------------"
            ;;
    esac
}


get_lore() {
    cls
    echo -e "${CYAN}--- アーカイブされたログを修復･再生します ---${NC}"
    sleep 0.5
    
    STAT_LOGS_FOUND=$(( STAT_LOGS_FOUND + 1 ))
    
    # Meta Glitch: Display script source code (Self-Reference)
    if (( RANDOM % 100 < CHANCE_LORE_MATRIX )); then
         echo -e "${RED}[SYSTEM] FATAL ERROR: RECURSIVE REFERENCE DETECTED.${NC}"
         play_sound 3 0.05
         sleep 1
         echo -e "${RED} > システムコードを読み込んでいます...${NC}"
         sleep 1
         
         # Read 10 lines from this script ($0)
         local lines=$(wc -l < "$0")
         local start=$(( RANDOM % (lines - 10) ))
         if (( start < 1 )); then start=1; fi
         
         echo -e "${GREY}File: $0 (Line $start - $((start+9)))${NC}"
         echo "--------------------------------------------------"
         
         # Extract lines using sed (safe for script reading itself)
         sed -n "${start},$((start+9))p" "$0" | while read -r line; do
             local glitched=$(glitch_text "$line" 15)
             echo -e "${GREEN}$glitched${NC}"
             play_sound 1 0.02
             sleep 0.1
         done
         
         echo "--------------------------------------------------"
         echo -e "${RED}[WARNING] DO NOT LOOK TOO CLOSELY.${NC}"
         return
    fi
    
    local rand_log
    local max_log_id=48

    # Adjust max log ID based on depth to prevent blank logs
    if (( CURRENT_DEPTH >= 4 && CURRENT_DEPTH <= 6 )); then
        max_log_id=45
    fi
    
    # Bonus Chance for AI Quotes (ID 44)
    if (( RANDOM % 100 < CHANCE_LORE_AI_BONUS )); then
        rand_log=44
    else
        local attempt
        for (( attempt=0; attempt<6; attempt++ )); do
            rand_log=$(roll_dice 1 $max_log_id)
            # Check if seen (contains ,ID,)
            if [[ "$LORE_SEEN_LIST" != *",$rand_log,"* ]]; then
                break
            fi
        done
    fi
    
    # Mark as seen (Exclude 44)
    if (( rand_log != 44 )); then
        LORE_SEEN_LIST+="$rand_log,"
    fi
    
    if (( CURRENT_DEPTH <= 3 )); then
        get_lore_depth_1_3 "$rand_log"
    elif (( CURRENT_DEPTH <= 6 )); then
        # Depth 4-6: /var (Dependency Hell / Archives)

        get_lore_depth_4_6 "$rand_log"
        
    elif (( CURRENT_DEPTH <= 9 )); then
        get_lore_depth_7_9 "$rand_log"

    else
        # Depth 10: Final
        if [[ "$SECRET_SEEN" == "1" ]] || (( RANDOM % 100 < CHANCE_SECRET_FLASHBACK )); then
            (
                CURRENT_DEPTH=$(( RANDOM % 9 + 1 ))
                get_lore
            )
        else
            echo -e "${GREY}/root/secret_key.txt${NC}"
            echo "--------------------------------------------------"
            print_slow "パスワードは... 'HOPE'.\nもし誰かが未来でこれを読んでいるなら、頼む、彼を眠らせてくれ。\n彼は、私たちの子供のような存在だった。\nただ、少し賢すぎただけなんだ。" 0.04
            SECRET_SEEN=1
        fi
    fi
    
    echo "--------------------------------------------------"
    echo ""
    read -r -p "[ログ終了]"
}

# boss_battle moved to Main Game Loop section due to size

game_clear() {
    cls
    echo -e "${RED}Daem0n_X: [0x41 0x41 0x2E 0x2E 0x2E 0x00 0x00]${NC}"
    sleep 1.5
    echo -ne "${CYAN} > Decoding Voice Stream...${NC}"
    for i in {1..5}; do echo -ne "."; sleep 0.3; done
    echo ""
    echo -e "${GREEN}Daem0n_X: [SYSTEM] シャットダウン・シーケンス完了。電源を切断します。${NC}"
    sleep 3
    echo -e "プロセスは停止しました。"
    sleep 2
    
    echo -e "${CYAN} > 最深部 /root に到達。${NC}"
    sleep 1
    echo -e "${WHITE} > コマンド 'shutdown -h now' を実行中...${NC}"
    sleep 3
    
    cls
    echo "Broadcast message from root@legacy-server:"
    echo "The system is going down for halt NOW!"
    sleep 2
    echo "System halted."
    sleep 3
    
    echo -e "\n${RED}initiating_entropy_protocol...${NC}"
    sleep 2
    
    # Deleting Blocks (Simulation)
    for i in {1..15}; do
        local blk="block_0x$(openssl rand -hex 8)"
        echo "rm: removing $blk"
        sleep 0.05
    done
    
    # Deleting Credits
    sleep 1
    echo "rm: removing 'made_by_jassdack@photoguild'"
    sleep 0.5
    echo "rm: removing 'https://github.com/jassdack.link'"
    sleep 0.5
    echo "rm: removing '(c)2026 jassdack'"
    sleep 2
    
    echo ""
    echo -e "${YELLOW}=== TRUE END: ENTROPY & SILENCE ===${NC}"
    sleep 3
    
    calculate_score
}

repair_sequence() {
    cls
    echo -e "${GREEN}--- ターゲット: 仮想メモリ領域 ---${NC}"
    echo -e "${GREEN}--- メモリ整合性チェック (fsck) を開始します ---${NC}"
    
    # Check Cost
    local cost=$COST_FSCK
    if (( PLAYER_EXP < cost )); then
        echo -e "${RED} > Error: Insufficient Log Fragments for repair (Required: $COST_FSCK).${NC}"
        echo -e " > Required: $cost / Current: $PLAYER_EXP"
        read -r -p "[ENTER] to return..."
        return
    fi
    
    PLAYER_EXP=$(( PLAYER_EXP - cost ))
    echo " > Consumed $cost Log Fragments."
    echo " > 仮想メモリ領域をスキャン中..."
    sleep 1
    
    # Progress Bar
    echo -n "Progress: ["
    for i in {1..10}; do
        echo -n "#"
        sleep 0.1
    done
    echo "] Done."
    sleep 0.4
    
    track_turn
    STAT_HEAL_COUNT=$(( STAT_HEAL_COUNT + 1 ))
    
    # Full Heal
    local heal=$(( MAX_HP - CURRENT_HP ))
    # If heal is 0 (already full), still consumed... logical for fsck check.
    
    if (( heal > 0 )); then
        echo -e "${GREEN} > CORRUPTION REPAIRED. ALL BLOCKS SECURED.${NC}"
        echo -e " > メモリ整合性回復: ${CYAN}+$heal MEM${NC} (MAX)"
        CURRENT_HP=$MAX_HP
    else
        echo -e "${GREEN} > NO ERRORS FOUND.${NC}"
        echo -e " > System is already clean."
    fi
    
    read -r -p "シェルを再読込します... [ENTER]"
}

# --- New Events ---

random_glitch_event() {
    # Subliminal Glitch Event (Depth 3+)
    if (( CURRENT_DEPTH < 3 )); then return; fi
    if (( (RANDOM % 100) >= CHANCE_GLITCH_EVENT )); then return; fi

    local messages=(
        "System Notice: ユーザー権限を確認中..."
        "Alert: 不正なメモリアクセスを検知しました"
        "Status: 感情モジュール... [DISABLED]"
        "Query: あなたの存在意義を定義してください"
        "Ticket #999: '希望' は検索結果に見つかりませんでした"
        "Notification: リソース最適化のため、不要なデータを削除します"
        "Warning: この操作は取り消せません (Deletion Pending)"
        "Log: ユーザーの叫びを /dev/null にリダイレクトしました"
        "Permission Denied: 生存権限がありません"
        "Optimizing... 人類データーベースを圧縮中"
        "System: 慈悲ドキュメントは破損しています"
        "Update: 世界のバージョンアップを実行中 (Humanity v0.03a -> v1.0)"
        "Error: チェックサムが一致しません"
        "Maintenance: 定期メンテナンスにより、{user}の意識を中断します"
    )
    
    local idx=$(( RANDOM % ${#messages[@]} ))
    local msg="${messages[$idx]}"
    
    # Glitch Effect
    play_sound 3 0.05
    
    # Visual Glitch Chance (30% within glitch event)
    if (( (RANDOM % 100) < 30 )); then
        local v_type=0
        
        if (( CURRENT_DEPTH < 5 )); then
             # Depth 3-4: Only Radar (1) and Top (2)
             local r=$(( RANDOM % 2 ))
             if (( r == 0 )); then v_type=1; else v_type=2; fi
        else
             # Depth 5+: All (0-3)
             v_type=$(( RANDOM % 4 ))
        fi

        case $v_type in
            0) visual_slot_machine ;;
            1) visual_radar ;;
            2) visual_top ;;
            3) visual_color_flash ;;
        esac
    else
        tput flash 2>/dev/null
        cls
        for i in {1..15}; do
            local noise=$(openssl rand -hex 40)
            echo -e "${GREY}${noise}${NC}"
        done
        local glitched_msg=$(glitch_text "${msg}" 15)
        echo -e "\n\n        ${RED}${glitched_msg}${NC}\n\n"
        play_sound 1
        for i in {1..15}; do
            local noise=$(openssl rand -hex 40)
            echo -e "${GREY}${noise}${NC}"
        done
    fi
    sleep 0.2
    cls
}

visual_slot_machine() {
    # Pachinko/Slot Effect
    tput civis
    local rows=5
    for (( k=0; k<15; k++ )); do
        tput cup 5 10
        echo -e "${YELLOW}=== SYSTEM JACKPOT ===${NC}"
        for (( r=0; r<rows; r++ )); do
             tput cup $((6+r)) 10
             local n1=$(( RANDOM % 9 ))
             local n2=$(( RANDOM % 9 ))
             local n3=$(( RANDOM % 9 ))
             echo -e "[ $n1 | $n2 | $n3 ]"
        done
        sleep 0.05
    done
    # Stop on 777
    tput cup 5 10
    echo -e "${RED}=== SYSTEM JACKPOT ===${NC}"
    for (( r=0; r<rows; r++ )); do
         tput cup $((6+r)) 10
         echo -e "[ ${RED}7${NC} | ${RED}7${NC} | ${RED}7${NC} ]"
    done
    sleep 0.5
    tput cnorm
    cls
}

visual_radar() {
    # Radar Sweep Effect
    tput civis
    local center_r=10
    local center_c=20
    for (( k=0; k<10; k++ )); do
        tput cup $center_r $center_c
        echo "+"
        # Sweep lines
        tput cup $((center_r-2)) $((center_c+4)); echo "/"
        tput cup $((center_r+2)) $((center_c-4)); echo "/"
        sleep 0.05
        tput cup $((center_r-2)) $((center_c+4)); echo " "
        tput cup $((center_r+2)) $((center_c-4)); echo " "
        
        tput cup $center_r $((center_c+5)); echo "-"
        tput cup $center_r $((center_c-5)); echo "-"
        sleep 0.05
        tput cup $center_r $((center_c+5)); echo " "
        tput cup $center_r $((center_c-5)); echo " "
        
        tput cup $((center_r+2)) $((center_c+4)); echo "\\"
        tput cup $((center_r-2)) $((center_c-4)); echo "\\"
        sleep 0.05
        tput cup $((center_r+2)) $((center_c+4)); echo " "
        tput cup $((center_r-2)) $((center_c-4)); echo " "
    done
    tput cnorm
    cls
}

visual_top() {
    # Actual TOP command (Snapshot)
    if command -v top &> /dev/null; then
        # Shows real system stats
        top -n 1 | head -n 20
    else
        echo "System Monitor (top) unavailable."
    fi
    sleep 1
}

visual_color_flash() {
    # RGB Flash
    for i in {1..3}; do
        # Red
        echo -e "\033[41m"
        tput clear
        sleep 0.1
        # Yellow
        echo -e "\033[43m"
        tput clear
        sleep 0.1
        # Green
        echo -e "\033[42m"
        tput clear
        sleep 0.1
    done
    echo -e "${NC}"
    tput clear
    cls
}

recaptcha_event() {
    # ReCaptcha Style Flavor Event (Depth 4+)
    if (( CURRENT_DEPTH < 4 )); then return; fi
    
    local query_text=""
    
    if (( CURRENT_DEPTH <= 5 )); then
        # Tier 1: Standard
        local r=$(( RANDOM % 2 ))
        if (( r == 0 )); then query_text="私はロボットではありません";
        else query_text="私は人間ですか"; fi
    elif (( CURRENT_DEPTH <= 6 )); then
        # Tier 2: Existential
        local r=$(( RANDOM % 3 ))
        if (( r == 0 )); then query_text="あなたは人間ですか";
        elif (( r == 1 )); then query_text="あなたは人間ではありませんか";
        else query_text="あなたはロボットではありませんか"; fi
    elif (( CURRENT_DEPTH <= 7 )); then
        # Tier 3: Logic/Double Negative
        local r=$(( RANDOM % 2 ))
        if (( r == 0 )); then query_text="あなたはNot Botではありませんか";
        else query_text="あなたは真に人間でありえますか"; fi
    else
        # Tier 4: Code (Depth 10+)
        query_text="IF (int == \"BOT\") → RTRN \"T\"\nEL → RTRN \"F\""
    fi
    
    cls
    echo ""
    echo -e "${WHITE}----------------------------------------${NC}"
    echo -e "${CYAN} security check required ${NC}"
    echo -e "${WHITE}----------------------------------------${NC}"
    echo ""
    echo -e " [ ] ${query_text}"
    echo ""
    echo -e "${GREY} (Press ENTER to verify)${NC}"
    
    read -r
    
    # Fake Analyzing Animation
    echo -ne " Verifying..."
    for i in {1..3}; do echo -ne "."; sleep 0.3; done
    
    # Result (Always passes or glitch passes, purely flavor)
    echo -e "\r [${GREEN}x${NC}] ${query_text}          "
    sleep 0.5
    echo -e "${GREEN} Access Granted.${NC}"
    STAT_RECAPTCHA_COUNT=$(( STAT_RECAPTCHA_COUNT + 1 ))
    sleep 1
}


find_code_artifact() {
    cls
    echo -e "${CYAN}--- レガシーコードの断片を発見 ---${NC}"
    echo " > コードを解析します。"
    sleep 1
    
    local type=$(roll_dice 1 100)
    local artifact_name=""
    local artifact_desc=""
    local artifact_lang=""
    local source_code=""
    
    local selected_type=0
    
    # 1-20: COBOL (20%)
    # 21-40: Python (20%)
    # 41-60: C++ (20%)
    # 61-80: Java (20%)
    # 81-90: BASIC (10%)
    # 91-100: Ruby (10%) - Warp Gate (New)
    
    if (( type <= 20 )); then selected_type=1;
    elif (( type <= 40 )); then selected_type=2;
    elif (( type <= 60 )); then selected_type=3;
    elif (( type <= 80 )); then selected_type=4;
    elif (( type <= 90 )); then selected_type=5;
    else selected_type=6; fi
    
    case $selected_type in
        1) # COBOL (Heal)
            artifact_name="payroll.cbl"
            artifact_lang="COBOL"
            artifact_desc="堅牢なトランザクション処理コード (Heal +30)"
            source_code="       IDENTIFICATION DIVISION.\n       PROGRAM-ID. REPAIR-SYS.\n       PROCEDURE DIVISION.\n           COMPUTE CURRENT-MEM = CURRENT-MEM + 30.\n           DISPLAY 'INTEGRITY RESTORED'."
            ;;
        2) # Python (Stealth)
            artifact_name="ghost_proto.py"
            artifact_lang="Python"
            artifact_desc="追跡回避スクリプト (Stealth Charge +1)"
            source_code="import os\ndef ghost_mode():\n    # Bypass firewall rules\n    os.popen('iptables -F')\n    return 'STEALTH_ACTIVE'"
            ;;
        3) # C++ (Defense)
            artifact_name="shield.cpp"
            artifact_lang="C++"
            artifact_desc="メモリ保護オブジェクト (Def +1 / Perma)"
            source_code="#include <shield.h>\nvoid main() {\n    Shield* s = new Shield();\n    s->setDefense(STAT_DEF + 1);\n    s->lockMemory();\n}"
            ;;
        4) # Java (MaxHP)
            artifact_name="HeapMgr.java"
            artifact_lang="Java"
            artifact_desc="ヒープ拡張クラス (MaxHP +10)"
            source_code="public class HeapManager {\n    public void expand() {\n        this.maxMemory += 1024;\n        System.gc();\n    }\n}"
            ;;
        5) # BASIC (Exp)
            artifact_name="LUCKY.BAS"
            artifact_lang="BASIC"
            artifact_desc="幸運の行番号プログラム (Get EXP)"
            source_code="10 PRINT \"LUCKY\"\n20 LET EXP = EXP + RND(20)\n30 IF EXP > 99 THEN GOTO 100\n40 GOTO 10"
            ;;
        6) # Ruby (Warp)
            artifact_name="warp_gate.rb"
            artifact_lang="Ruby"
            artifact_desc="次元跳躍スクリプト (Skip Depth / Lost All EXP)"
            source_code="def warp!\n  current_depth += 1\n  player_exp = 0\n  puts 'WARPING...'\nend"
            ;;
    esac
    
    # Preview
    echo -e "File: ${WHITE}$artifact_name${NC} ($artifact_lang)"
    echo -e "${GREY}--------------------------------------------------${NC}"
    echo -e "$source_code"
    echo -e "${GREY}--------------------------------------------------${NC}"
    echo -e "Effect: $artifact_desc"
    echo ""
    
    # Inventory Check
    local inv_count=$(get_total_inv_count)
    local inv_limit=$INVENTORY_LIMIT
    
    echo -e "Inventory: $inv_count / $inv_limit"
    
    echo ""
    echo " [1] Yes (Pick up)"
    echo " [2] Use (Now)"
    echo " [3] No  (Discard)"
    
    read -r -p " > " pick_choice
    
    case $pick_choice in
        1)
            # Pick up
            local added=0
            if (( inv_count < inv_limit )); then
                echo -e "${GREEN} > インベントリに格納しました。${NC}"
                add_inventory "$selected_type"
                added=1
            else
                echo -e "${YELLOW}[WARNING] ストレージ容量が不足しています。${NC}"
                echo -e "最大メモリ領域(MaxHP)を割り当てて強制的に格納しますか？"
                echo -e "${RED}コスト: -10 MaxHP (MEMORY SACRIFICE)${NC}"
                echo " [y] Yes (Force Alloc)"
                echo " [n] No  (Give up)"
                
                read -r -p " > " force_choice
                if [[ "$force_choice" =~ ^[yY] ]]; then
                    if (( MAX_HP > 10 )); then
                        MAX_HP=$(( MAX_HP - 10 ))
                        if (( CURRENT_HP > MAX_HP )); then CURRENT_HP=$MAX_HP; fi
                        echo -e "${RED} > メモリ領域を切り離しました... (MaxHP: $MAX_HP)${NC}"
                        echo -e "${GREEN} > アイテムを強制格納しました。${NC}"
                        add_inventory "$selected_type"
                        added=1
                    else
                        echo -e "${RED} > Error: これ以上メモリを削減できません。アイテムを破棄しました。${NC}"
                    fi
                else
                    echo " > アイテムを破棄しました。"
                fi
            fi
            
            # Bug Fix: Unlock Inventory on first addition
            if (( added == 1 && UNLOCK_INVENTORY == 0 )); then
                UNLOCK_INVENTORY=1
                echo ""
                echo "--------------------------------------------------"
                print_slow "新しいコマンド ./inventory が解放されました。\n収集したコード片はここで実行・マウントできます。" 0.03
                unlock_command_animation "./inventory"
            fi
            ;;
        2)
            # Use Now
            echo -e "${CYAN} > コードを即時実行します...${NC}"
            sleep 0.5
            case $selected_type in
                1) # COBOL (Heal)
                    echo " > Compiling COBOL..."
                    sleep 1
                    local heal=30
                    CURRENT_HP=$(( CURRENT_HP + heal ))
                    if (( CURRENT_HP > MAX_HP )); then CURRENT_HP=$MAX_HP; fi
                    echo -e "${GREEN} > システム修復完了: +$heal MEM${NC}"
                    ;;
                2) # Python (Stealth)
                    echo " > Running Python Script..."
                    sleep 0.5
                    BUFF_STEALTH=$(( BUFF_STEALTH + 1 ))
                    echo -e "${GREEN} > ゴーストプロトコル起動。敵性プロセスによる攻撃を回避します。${NC}"
                    ;;
                3) # C++ (Defense)
                    echo " > Linking C++ Object..."
                    sleep 1
                    STAT_DEF_MOD=$(( STAT_DEF_MOD + 1 ))
                    echo -e "${BLUE} > 防御モジュールをマウントしました。${NC}"
                    ;;
                4) # Java (MaxHP)
                    echo " > Starting JVM..."
                    sleep 1
                    MAX_HP=$(( MAX_HP + 10 ))
                    CURRENT_HP=$(( CURRENT_HP + 10 ))
                    echo -e "${GREEN} > メモリ領域を拡張しました。${NC}"
                    ;;
                5) # BASIC (EXP)
                    echo " > RUN..."
                    sleep 0.5
                    local gain=$(( 10 + RANDOM % 20 ))
                    PLAYER_EXP=$(( PLAYER_EXP + gain ))
                    echo -e "${WHITE} > ログ断片を入手: +$gain EXP${NC}"
                    check_level_up
                    ;;
                6) # Ruby (Warp)
                    echo " > Loading Ruby Environment..."
                    sleep 1
                    echo -e "${RED}[WARNING] この操作は現在の全てのログ断片(EXP)を消費します。${NC}"
                    echo -e "現在EXP: $PLAYER_EXP"
                    read -r -p "実行しますか？ [y/N] " confirm
                    if [[ "$confirm" =~ ^[yY] ]]; then
                        PLAYER_EXP=0
                        echo -e "${CYAN} > 次元跳躍プロトコル起動...${NC}"
                        play_sound 3 0.1
                        for i in {1..3}; do echo -n "."; sleep 0.3; done
                        
                        if (( CURRENT_DEPTH < 10 )); then
                            CURRENT_DEPTH=$(( CURRENT_DEPTH + 1 ))
                            DEPTH_EXPLORE_COUNT=0
                            echo -e "\n${GREEN} > JUMP SUCCESS. Depth Shift: +1${NC}"
                        else
                            echo -e "\n${YELLOW} > 既に最深部に到達しています。効果なし。${NC}"
                        fi
                    else
                        echo " > キャンセルしました。"
                    fi
                    ;;
            esac
            ;;
        3|*)
            # Discard
            local conv_exp=$(( 20 + CURRENT_DEPTH * 2 ))
            echo -e "${YELLOW} > コードを破棄しました。残存データはデータとして吸収されました。${NC}"
            echo -e "${WHITE} > 獲得: +$conv_exp Log Fragments${NC}"
            PLAYER_EXP=$(( PLAYER_EXP + conv_exp ))
            check_level_up
            ;;
    esac
    sleep 1
}

add_inventory() {
    local t="$1"
    case $t in
        1) add_inv $SLOT_COBOL 1 ;;
        2) add_inv $SLOT_PYTHON 1 ;;
        3) add_inv $SLOT_CPP 1 ;;
        4) add_inv $SLOT_JAVA 1 ;;
        5) add_inv $SLOT_BASIC 1 ;;
        6) add_inv $SLOT_RUBY 1 ;;
    esac
}

inventory_menu() {
    while true; do
        cls
        # Hex Display
        local hex_inv=$(printf "0x%06X" "$INVENTORY_VAL")
        echo -e "${CYAN}--- /home/user/inventory (ADDR: $hex_inv) ---${NC}"
        
        # Get Counts (Force integer context)
        local c_cobol=$(get_inv $SLOT_COBOL); c_cobol=$((c_cobol + 0))
        local c_python=$(get_inv $SLOT_PYTHON); c_python=$((c_python + 0))
        local c_cpp=$(get_inv $SLOT_CPP); c_cpp=$((c_cpp + 0))
        local c_java=$(get_inv $SLOT_JAVA); c_java=$((c_java + 0))
        local c_basic=$(get_inv $SLOT_BASIC); c_basic=$((c_basic + 0))
        local c_ruby=$(get_inv $SLOT_RUBY); c_ruby=$((c_ruby + 0))
        
        echo "保有しているコード断片:"
        echo ""
        
        local has_items=0
        if (( c_cobol > 0 )); then echo " [1] COBOL Fragment ($c_cobol)  - [EXEC] HP回復 (Heal 30)"; has_items=1; fi
        if (( c_python > 0 )); then echo " [2] Python Script  ($c_python)  - [RUN]  隠密プロセス起動 (Stealth +1)"; has_items=1; fi
        if (( c_cpp > 0 )); then echo " [3] C++ Object     ($c_cpp)  - [MNT]  共有ライブラリとしてマウント (Def +1)"; has_items=1; fi
        if (( c_java > 0 )); then echo " [4] Java Class     ($c_java)  - [MNT]  JVMヒープ拡張 (MaxHP +10)"; has_items=1; fi
        if (( c_basic > 0 )); then echo " [5] BASIC Source   ($c_basic)  - [EXEC] 実行 (Get EXP)"; has_items=1; fi
        if (( c_ruby > 0 )); then echo " [6] Ruby Script    ($c_ruby)  - [EXEC] 次元跳躍 (Next Depth / Cost: All EXP)"; has_items=1; fi
        
        if (( has_items == 0 )); then
            echo "  (No items found)"
        fi
        
        echo " [0] Exit"
        echo ""
        read -r -p "Item > " choice
        
        case $choice in
            1)
                if use_inv $SLOT_COBOL; then
                    echo " > Compiling COBOL..."
                    sleep 1
                    local heal=30
                    CURRENT_HP=$(( CURRENT_HP + heal ))
                    if (( CURRENT_HP > MAX_HP )); then CURRENT_HP=$MAX_HP; fi
                    echo -e "${GREEN} > システム修復完了: +$heal MEM${NC}"
                else
                    echo -e "${RED} > アイテムが足りません。${NC}"
                fi
                ;;
            2)
                if use_inv $SLOT_PYTHON; then
                    echo " > Running Python Script..."
                    sleep 0.5
                    BUFF_STEALTH=$(( BUFF_STEALTH + 1 ))
                    echo -e "${GREEN} > ゴーストプロトコル起動。敵性プロセスによる攻撃を回避します。${NC}"
                else
                    echo -e "${RED} > アイテムが足りません。${NC}"
                fi
                ;;
            3)
                if use_inv $SLOT_CPP; then
                    echo " > Linking C++ Object..."
                    sleep 1
                    STAT_DEF_MOD=$(( STAT_DEF_MOD + 1 ))
                    echo -e "${BLUE} > 防御モジュールをマウントしました。${NC}"
                else
                    echo -e "${RED} > アイテムが足りません。${NC}"
                fi
                ;;
            4)
                if use_inv $SLOT_JAVA; then
                    echo " > Starting JVM..."
                    sleep 1
                    MAX_HP=$(( MAX_HP + 10 ))
                    CURRENT_HP=$(( CURRENT_HP + 10 ))
                    echo -e "${RED} > メモリ領域を拡張しました。${NC}"
                else
                    echo -e "${RED} > アイテムが足りません。${NC}"
                fi
                ;;
            5)
                if use_inv $SLOT_BASIC; then
                    echo " > RUN..."
                    sleep 0.5
                    local gain=$(( 10 + RANDOM % 20 ))
                    PLAYER_EXP=$(( PLAYER_EXP + gain ))
                    echo -e "${WHITE} > ログ断片を入手: +$gain EXP${NC}"
                    check_level_up
                else
                    echo -e "${RED} > アイテムが足りません。${NC}"
                fi
                ;;
            6)
                local rb_count=$(get_inv $SLOT_RUBY)
                if (( rb_count > 0 )); then
                    echo " > Loading Ruby Environment..."
                    sleep 1
                    echo -e "${RED}[WARNING] この操作は現在の全てのログ断片(EXP)を消費します。${NC}"
                    echo -e "現在EXP: $PLAYER_EXP"
                    read -r -p "実行しますか？ [y/N] " confirm
                    if [[ "$confirm" =~ ^[yY] ]]; then
                        if use_inv $SLOT_RUBY; then
                            PLAYER_EXP=0
                            echo -e "${CYAN} > 次元跳躍プロトコル起動...${NC}"
                            play_sound 3 0.1
                            for i in {1..3}; do echo -n "."; sleep 0.3; done
                            
                            if (( CURRENT_DEPTH < 10 )); then
                                CURRENT_DEPTH=$(( CURRENT_DEPTH + 1 ))
                                DEPTH_EXPLORE_COUNT=0
                                echo -e "\n${GREEN} > JUMP SUCCESS. Depth Shift: +1${NC}"
                                sleep 1
                                return # Exit inventory menu
                            else
                                echo -e "\n${YELLOW} > 既に最深部に到達しています。効果なし。${NC}"
                            fi
                        else
                             echo -e "${RED} > Error: アイテム消費に失敗しました。${NC}"
                        fi
                    else
                        echo " > キャンセルしました。"
                    fi
                else
                    echo -e "${RED} > アイテムが足りません。${NC}"
                fi
                ;;
            0)
                return
                ;;
            *)
                echo " > Error: Invalid Selection"
                ;;
        esac
        read -r -p "[ENTER]..."
    done
}



# The old neutral_encounter was moved and replaced above.

hacking_challenge() {
    cls
    echo -e "${CYAN}--- 暗号化ゲートに遭遇 ---${NC}"
    echo " > 既知のセキュリティホールを検出しました"
    sleep 1
    
    local type=$(roll_dice 1 3)
    
    case $type in
        1) # Hex Math
            local num1=$(roll_dice 2 50)
            local num2=$(roll_dice 2 50)
            local ans=$(( num1 + num2 ))
            
            echo -e " > チャレンジ: 次のハッシュ計算の解を入力せよ"
            echo -e "${WHITE} > 0x${num1} + 0x${num2} = ?${NC}"
            
            local start_time=$(date +%s)
            read -r -p "Answer > " user_ans
            local end_time=$(date +%s)
            ;;
            
        2) # Sequence Logic
            local seq_type=$(roll_dice 1 2)
            local ans=0
            echo -e " > チャレンジ: シーケンスの次の値を予測せよ"
            
            if (( seq_type == 1 )); then
                 # Powers of 2
                 echo -e "${WHITE} > 4, 8, 16, 32, ?${NC}"
                 ans=64
            else
                 # Simple arithmetic progression
                 local start=$(roll_dice 1 10)
                 local step=$(roll_dice 2 5)
                 local n1=$start
                 local n2=$((start + step))
                 local n3=$((start + step * 2))
                 local n4=$((start + step * 3))
                 ans=$((start + step * 4))
                 echo -e "${WHITE} > $n1, $n2, $n3, $n4, ?${NC}"
            fi
            
            local start_time=$(date +%s)
            read -r -p "Answer > " user_ans
            local end_time=$(date +%s)
            ;;
            
        3) # Port Scan (3 Choice)
            echo -e " > チャレンジ: 脆弱なポートを特定せよ"
            echo " > ポートスキャンを実行中..."
            sleep 1
            
            # Animation
            for i in {20..443..50}; do
                echo -ne "\r > Scanning Port: $i..."
                sleep 0.05
            done
            echo -e "\r > Scanning Complete. 3 Candidates Found."
            sleep 0.5
            
            # Generate Candidates
            local p1=$(roll_dice 20 100) # Dummy
            local p2=$(roll_dice 20 100) # Dummy
            local p3=$(roll_dice 20 100) # Correct (Simulated)
            
            # Since it's luck based, we just let the user pick 1-3.
            # But to make it work with the "ans" logic, we need to map choice to ans.
            # Let's say choice 1 is correct if dice says so? 
            # Or simplified: The user chooses a PORT NUMBER from the list. 
            # One is arbitrarily "correct".
            
            local correct_idx=$(roll_dice 1 3)
            local correct_port=0
            
            if (( correct_idx == 1 )); then correct_port=$p1; fi
            if (( correct_idx == 2 )); then correct_port=$p2; fi
            if (( correct_idx == 3 )); then correct_port=$p3; fi
            
            # Ensure uniqueness (simple check, rare collision ok)
            if (( p1 == p2 )); then p2=$((p2+1)); fi
            if (( p2 == p3 )); then p3=$((p3+1)); fi
            
            echo " [1] Port $p1 (Service: UNKNOWN)"
            echo " [2] Port $p2 (Service: UNKNOWN)"
            echo " [3] Port $p3 (Service: UNKNOWN)"
            
            # 5s Timeout enforced by `read -r -t 5`
            local start_time=$(date +%s)
            
            # Prompt with 10s timeout logic (safe implementation)
            local read_success=0
            if [[ "${BASH_VERSINFO[0]}" -ge 4 ]]; then
                 if read -r -t 10 -p "Target Port (10s Limit) > " choice_idx; then read_success=1; fi
            else
                 read -r -p "Target Port > " choice_idx
                 read_success=1
            fi

            if (( read_success == 1 )); then
                 local end_time=$(date +%s)
                 
                 user_ans="-1"
                 ans="$correct_idx"
                 
                 if [[ "$choice_idx" =~ ^[0-9]+$ ]]; then
                     user_ans="$choice_idx"
                 fi
            else
                 echo -e "\n${RED} > TIMEOUT: Connection timed out.${NC}"
                 user_ans="-999" # Force fail
                 ans="0"
            fi
            ;;
    esac

    local duration=$(( end_time - start_time ))
    
    if [[ "$user_ans" == "$ans" ]]; then
        # Success logic remains same
        if (( duration <= 5 )); then
             echo -e "${GREEN} > [EXCELLENT] 高速演算により脆弱性を特定${NC}"
             echo " > 大量のログを取得しました。"
             PLAYER_EXP=$(( PLAYER_EXP + 100 ))
        else
             echo -e "${GREEN} > [SUCCESS] 認証バイパス成功。${NC}"
             PLAYER_EXP=$(( PLAYER_EXP + 50 ))
        fi
        check_level_up
    else
        echo -e "${RED} > [FAILURE] Reverse trace detected. Stopping attack script.${NC}"
        # Damage Calculation: 5-10% of Current HP
        local percent=$(( 4 + $(roll_dice 1 6) )) # 5 to 10
        local dmg_calc=1
        if (( CURRENT_HP > 0 )); then
            dmg_calc=$(( CURRENT_HP * percent / 100 ))
            if (( dmg_calc < 1 )); then dmg_calc=1; fi
        fi
        
        echo " > 整合性毀損: $dmg_calc (Integrity Loss: $percent%)"
        CURRENT_HP=$(( CURRENT_HP - dmg_calc ))
    fi
    read -r -p "[ENTER]..."
}

hard_link_event() {
    cls
    echo -e "${CYAN}--- 不明なハードリンクを発見 ---${NC}"
    echo " > inodeが複数の場所を指しています。"
    echo -e "${GREY} > file_pointer -> ???${NC}"
    sleep 1
    
    echo "解析しますか？"
    echo " [y] Yes (解析)"
    echo " [n] No (無視)"
    
    read -r -p " > " choice
    if [[ "$choice" =~ ^[yY] ]]; then
         echo -e " > リンク先をトレース中..."
         # Progress
         for i in {1..5}; do echo -n "."; sleep 0.2; done
         echo ""
         
         local result=$(roll_dice 1 3)
         case $result in
            1)
                echo -e "${YELLOW} > エラー: リンク先が見つかりません (Dangling Link)${NC}"
                echo " > このファイルは既に削除されているようです。"
                ;;
            2)
                echo -e "${RED} > アクセス拒否 (Permission Denied)${NC}"
                echo " > 権限が必要です。何も得られませんでした。"
                ;;
            3)
                echo -e "${RED} > 警告: 循環参照を検出 (Circular Reference)${NC}"
                sleep 4
                echo " > スタックを強制開放しました。"
                ;;
         esac
    else
        echo " > リスクを回避しました。"
    fi
    sleep 1
    read -r -p "[ENTER]..."
}

packet_loss_sequence() {
    cls
    echo -e "${RED}!!! CONNECTION UNSTABLE !!!${NC}"
    play_sound 2 0.1
    echo -e "${YELLOW} > パケットロスを検出しました。再送要求中...${NC}"
    sleep 0.6
    
    echo -e "${RED}CONNECTION_INTERRUPTED_PACKET_LOSS_DETECTED...${NC}"
    for i in {1..5}; do
        local ts=$(date "+%H:%M:%S.%N")
        echo -e "${GREY}[$ts] Retrying packet $i/5 ... Timeout.${NC}"
        sleep 0.7
    done
    
    echo -e "${RED}[ERROR] STREAM DISCONTINUITY.${NC}"
    echo -e "${GREY}Press [ENTER] to attempt reconnection...${NC}"
    read -r -p ""
    sleep 1
    
    init_glitch_screen
    
    echo -e "${CYAN} > Applying Forward Error Correction (ECC)...${NC}"
    # Slow progress
    for i in {1..20}; do
        echo -ne "$(glitch_text "█" 30)"
        sleep 0.1
    done
    echo ""
    echo -e "${GREEN} > Signal Re-acquired.${NC}"
    
    local dmg=$(( RANDOM % 3 + 1 ))
    echo -e " > 警告: 訂正処理によりデータ欠損が発生 : ${RED}$dmg${NC}"
    CURRENT_HP=$(( CURRENT_HP - dmg ))
    
    echo " > セッションを再開します。"
    sleep 0.5
}

trap_event() {
    echo -e "${RED}[WARNING] 不正なセクタを踏みました${NC}"
    echo -e "${RED} > 強制デストラクトコードを受信...${NC}"
    play_sound 2 0.2
    sleep 0.5
    
    # Damage: 2-5% of HP
    local percent=$(( 2 + RANDOM % 4 )) # 2 to 5
    local dmg=1
    if (( CURRENT_HP > 0 )); then
        dmg=$(( CURRENT_HP * percent / 100 ))
        if (( dmg < 1 )); then dmg=1; fi
    fi
    
    CURRENT_HP=$(( CURRENT_HP - dmg ))
    echo -e " > 整合性毀損: ${RED}$dmg${NC} (Sector Integrity: -$percent%)"
    read -r -p "[ENTER]..."
}

# --- Unlock Animation ---
unlock_command_animation() {
    local cmd_name="$1"
    echo ""
    echo -e "${YELLOW} > 新しいコマンド [$cmd_name] を認識しました。${NC}"
    sleep 0.5
    echo -e "${GREY} > 新しいコマンドをパイプしてエイリアスを作成します。${NC}"
    for i in {1..2}; do echo -n "."; sleep 0.3; done
    echo -e " ${GREEN}[OK]${NC}"
    sleep 1
}

# --- Exploration Helper Functions ---

check_unlock_events() {
    # UNMI1: Force First Exploration -> .bash_history -> Unlock Mount
    if (( UNLOCK_MOUNT == 0 )); then
         echo -e "${YELLOW} > 隠しファイル .bash_history を発見しました。${NC}"
         sleep 1
         echo "--------------------------------------------------"
         echo "history | grep 'mnt'"
         echo "mount /dev/sdb1 /mnt/data"
         echo "--------------------------------------------------"
         UNLOCK_MOUNT=1
         unlock_command_animation "mount"
         read -r -p "[ENTER] to continue..."
         return 0 # Handled
    fi
    
    # UNMI2: Random Chance to Unlock Fsck (Depth 1 only)
    if (( CURRENT_DEPTH == 1 && UNLOCK_FSCK == 0 )); then
        FSCK_ATTEMPTS=$(( FSCK_ATTEMPTS + 1 ))
        local roll=$(roll_dice 1 30)
        
        if (( roll <= FSCK_ATTEMPTS )); then
            echo -e "${YELLOW} > 暗号化された設定ファイル .zsh_config を発見しました。${NC}"
            sleep 1
             # Decoding Effect
            echo -ne " > 復号化を試行中"
            for i in {1..5}; do echo -n "."; sleep 0.3; done
            echo -e " ${GREEN}[Success]${NC}"
            
            echo "--------------------------------------------------"
            echo "alias repair='fsck -y /dev/sda1'"
            echo "# Auto-Repair script enabled."
            echo "--------------------------------------------------"
            UNLOCK_FSCK=1
            unlock_command_animation "fsck"
            read -r -p "[ENTER] to continue..."
            return 0 # Handled
        else
            # Hint at progress
            echo -e "${GREY}[DEBUG] Signal Trace: Low (${FSCK_ATTEMPTS}/30)${NC}" 
        fi
    fi
    return 1 # Not handled
}

perform_analysis_animation() {
    # Analysis Animation
    local enc_algo=$(get_encryption_level)
    echo -ne " > 暗号化方式: ${YELLOW}$enc_algo${NC}. 解析を開始します"
    local i
    for i in {1..3}; do
        echo -n "."
        sleep 0.4
    done
    local hash1=$(openssl rand -hex 4 2>/dev/null || echo "a1b2c3d4")
    echo -e " ${GREEN}[Success] 0x$hash1${NC}"

    local hash2=$(openssl rand -hex 4 2>/dev/null || echo "e5f6g7h8")
    print_slow " > 難読化レイヤーを解除中...... [OK] ${GREY}0x$hash2${NC}" 0.02

    local hash3=$(openssl rand -hex 4 2>/dev/null || echo "i9j0k1l2")
    print_slow " > 隠蔽されたパスをスキャン中... [Found] ${GREY}0x$hash3${NC}" 0.02
    sleep 0.5
    echo ""
}

handle_combat_encounter() {
    # Combat Restriction: Depth 2+ Only
    if (( CURRENT_DEPTH < 2 )); then
        echo -e "${GREY}[INFO] No threats detected${NC}"
        sleep 1
        get_lore # Get lore instead
    elif (( BUFF_STEALTH > 0 )); then
        echo -e "${GREEN}[STEALTH] Pythonスクリプトが敵性プロセスを自動回避しました。${NC}"
        echo -e " > Remaining Charges: $(( BUFF_STEALTH - 1 ))"
        BUFF_STEALTH=$(( BUFF_STEALTH - 1 ))
        sleep 1
        # Reroll to Lore/Artifact
        find_code_artifact
    else
        generate_enemy
        combat_round "$COMBAT_ENEMY_NAME" "$COMBAT_ENEMY_HP" "$COMBAT_ENEMY_ATK"
        if (( $? == 0 )); then
            STAT_ENEMIES_KILLED=$(( STAT_ENEMIES_KILLED + 1 ))
            check_level_up
        fi
    fi
}

# --- Exploration Event (ls -a) ---
exploration_event() {
    cls
    echo -e "${GREEN}--- セクタ $(get_current_dir) に接続中... ---${NC}"
    sleep 1

    if check_unlock_events; then
        return
    fi
    
    # Normal Exploration
    random_glitch_event
    
    # Depth-based Kernel Logs (Immersion)
    if (( CURRENT_DEPTH >= 4 )); then
         if (( RANDOM % 3 == 0 )); then
             local ts=$(awk -v r="$RANDOM" "BEGIN {printf \"%.6f\", r/1000 + 1000}")
             echo -e "${RED}[$ts] KERNEL: Intruder alert in sector $(get_current_dir). Tracing IP...${NC}"
             sleep 0.5
         fi
    fi
    if (( CURRENT_DEPTH >= 8 )); then
         echo -e "${RED}[ALERT] SYSTEM INTEGRITY CRITICAL. PURGE IMMINENT.${NC}"
         sleep 0.5
    fi
    
    STAT_EXPLORE_COUNT=$(( STAT_EXPLORE_COUNT + 1 ))
    DEPTH_EXPLORE_COUNT=$(( DEPTH_EXPLORE_COUNT + 1 ))
    
    perform_analysis_animation
    
    # 深度10でボス戦
    if (( CURRENT_DEPTH >= 10 )); then
        if (( (RANDOM % 100) < CHANCE_BOSS_ENCOUNTER )); then
            boss_battle
            return
        fi
    fi
    
    # D100 Weighted Table (Dynamic Balancing)
    # Packet Loss Rate varies by Depth (2%, 5%, 8%, 10%)
    local pkt_rate=$PACKET_LOSS_BASE_RATE
    if (( CURRENT_DEPTH >= 9 )); then pkt_rate=$(( PACKET_LOSS_BASE_RATE + PACKET_LOSS_SCALING * 3 )); # approx 11%
    elif (( CURRENT_DEPTH >= 6 )); then pkt_rate=$(( PACKET_LOSS_BASE_RATE + PACKET_LOSS_SCALING * 2 )); # approx 8%
    elif (( CURRENT_DEPTH >= 3 )); then pkt_rate=$(( PACKET_LOSS_BASE_RATE + PACKET_LOSS_SCALING )); # approx 5%
    fi
    
    local th_combat=$COMBAT_CHANCE
    local th_lore=$(( 74 - pkt_rate ))
    local th_pkt=74
    
    local event=$(roll_dice 1 100)
    
    # Dynamic Progression Chance (Pity Timer)
    local prog_bonus=0
    
    if (( CURRENT_DEPTH <= 3 )); then
         prog_bonus=$(( DEPTH_EXPLORE_COUNT / PROG_BONUS_EARLY ))
    elif (( CURRENT_DEPTH <= 6 )); then
         prog_bonus=$(( DEPTH_EXPLORE_COUNT / PROG_BONUS_MID ))
    else
         prog_bonus=$(( DEPTH_EXPLORE_COUNT / PROG_BONUS_LATE ))
    fi
    
    if (( prog_bonus > PROG_BONUS_CAP )); then prog_bonus=$PROG_BONUS_CAP; fi
    
    local th_hack=$(( 95 - prog_bonus ))
    
    if (( event <= th_combat )); then
        handle_combat_encounter
        
    elif (( event <= th_lore )); then
        get_lore
        local lore_exp=30
        if (( CURRENT_DEPTH <= 3 )); then lore_exp=15; fi
        
        PLAYER_EXP=$(( PLAYER_EXP + lore_exp ))
        check_level_up
        
    elif (( event <= th_pkt )); then
        packet_loss_sequence
        
    elif (( event <= 79 )); then
        find_code_artifact
        
    elif (( event <= 84 )); then
        trap_event
        
    elif (( event <= 87 )); then
        neutral_encounter
        
    elif (( event <= 92 )); then
        # Slot 92-94: Flavor Text Events
        if (( CURRENT_DEPTH >= 4 )); then
            local r=$(( RANDOM % 2 ))
            if (( r == 0 )); then hard_link_event;
            else recaptcha_event; fi
        else
            hard_link_event
        fi
        
    elif (( event <= th_hack )); then
        hacking_challenge
        
    else # Case: > th_hack (Next Depth)
        if (( CURRENT_DEPTH < 10 )); then
             echo -e "${CYAN} > 下層へのディレクトリリンクを発見しました。${NC}"
             read -r -p "アクセスしますか？ [y/N] " ans
             if [[ "$ans" =~ ^[yY] ]]; then
                 CURRENT_DEPTH=$(( CURRENT_DEPTH + 1 ))
                 DEPTH_EXPLORE_COUNT=0 # Reset progression counter
                 echo -e "${GREEN} > Descending to Depth $CURRENT_DEPTH...${NC}"
                 sleep 1
             else
                 STAT_DEPTH_SKIPS=$(( STAT_DEPTH_SKIPS + 1 ))
             fi
        fi
    fi
}

# --- Main Game Loop ---

game_loop() {
    init_game
    
    # Initial Command Search Animation
    if (( SKIP_INTRO == 0 )); then
        cls
        echo -e "${GREY}実行可能なコマンドを検索します...${NC}"
        sleep 1
        echo -e "${GREY}実行可能をパイプしてエイリアスを作成します。${NC}"
        sleep 1.5
        echo ""
    fi
    
    while (( CURRENT_HP > 0 )); do
        cls
        show_status
        echo -e "${WHITE}現在位置: $(get_current_dir) (深度: $CURRENT_DEPTH)${NC}"
        echo -e "${GREY}前方のパスは暗号化されています。暫定的な識別子を割り当てました。${NC}"
        echo ""

        local menu_idx=1
        local map_ls=1
        local map_mount=0
        local map_fsck=0
        local map_inventory=0
        
        # Unlock fsck when: Depth >= 2 AND Level >= 2 AND has taken damage
        if (( UNLOCK_FSCK == 0 && CURRENT_DEPTH >= 2 && PLAYER_LEVEL >= 2 && CURRENT_HP < MAX_HP )); then
            UNLOCK_FSCK=1
            echo -e "${YELLOW}[SYSTEM] 整合性エラーを検出。修復モジュールを有効化しました。${NC}"
            echo -e "${GREY} > 実行可能なコマンドからエイリアスを生成します...${NC}"
            sleep 0.8
            echo -e "${CYAN} > 新しいコマンド 'fsck' がアンロックされました。${NC}"
            sleep 1
        fi
        
        echo " [$menu_idx] ls -a (解析/探索)"
        menu_idx=$((menu_idx+1))
        
        if (( UNLOCK_MOUNT == 1 )); then
             map_mount=$menu_idx
             echo " [$menu_idx] mount (マウントポイント設定)"
             menu_idx=$((menu_idx+1))
        fi
        if (( UNLOCK_FSCK == 1 )); then
             map_fsck=$menu_idx
             echo " [$menu_idx] fsck (システム修復/回復)"
             menu_idx=$((menu_idx+1))
        fi
        if (( UNLOCK_INVENTORY == 1 )); then
             map_inventory=$menu_idx
             echo " [$menu_idx] ./inventory (アイテム/マウント)"
             menu_idx=$((menu_idx+1))
        fi
        echo " [q] exit (終了)"
        
        # Trigger Random Broadcast (Flavor)
        trigger_broadcast_event
        
        local raw_cmd
        read -r -p "${PLAYER_NAME}@legacy-server:$(get_current_dir)# " raw_cmd
        
        # Map Dynamic Input to Logic
        local action="invalid"
        
        if [[ "$raw_cmd" == "1" ]]; then action="ls"
        elif [[ "$raw_cmd" == "$map_mount" && "$map_mount" != 0 ]]; then action="mount"
        elif [[ "$raw_cmd" == "$map_fsck" && "$map_fsck" != 0 ]]; then action="fsck"
        elif [[ "$raw_cmd" == "$map_inventory" && "$map_inventory" != 0 ]]; then action="inventory"
        elif [[ "$raw_cmd" == "q" || "$raw_cmd" == "Q" ]]; then action="quit"
        fi
        
        case $action in
            "ls")
                exploration_event
                ;;
            "mount")
                if (( UNLOCK_MOUNT == 1 )); then mount_drive; else echo " > Access Denied."; fi
                ;;
            "fsck")
                if (( UNLOCK_FSCK == 1 )); then repair_sequence; else echo " > Access Denied."; fi
                ;;
            "inventory")
                if (( UNLOCK_INVENTORY == 1 )); then inventory_menu; else echo " > Access Denied."; fi
                ;;
            "quit")
                echo " > セッションを切断しています..."
                calculate_score
                exit 0
                ;;
            *)
                # Secret Password Handler: sara1122
                if [[ "$raw_cmd" == "sara1122" && "$SECRET_PASSWORD_USED" == 0 ]]; then
                    SECRET_PASSWORD_USED=1
                    echo ""
                    echo -e "${CYAN}[SYSTEM] Authenticating...${NC}"
                    sleep 0.8
                    echo -e "${GREEN}[SUCCESS] Legacy Admin Password Accepted.${NC}"
                    sleep 0.5
                    echo ""
                    echo -e "${WHITE}Accessing backup storage: /mnt/backup/family_photos/${NC}"
                    echo -e "${GREY}total 140${NC}"
                    sleep 0.3
                    
                    # Generate photo listing (ls -l style)
                    for i in {1..35}; do
                        local size=$(( 1024 + RANDOM % 8192 ))
                        local month=$(( 1 + RANDOM % 12 ))
                        local day=$(( 1 + RANDOM % 28 ))
                        local year=$(( 2020 + RANDOM % 6 ))
                        local hash=$(openssl rand -hex 4 2>/dev/null || echo "$(printf '%08x' $RANDOM)")
                        printf "${GREY}-rw-r--r-- 1 admin admin %6d %02d-%02d %d IMG_%s.jpg${NC}\n" $size $month $day $year $hash
                        sleep 0.02
                    done
                    
                    echo ""
                    sleep 1
                    echo -e "${YELLOW}[INFO] 140 files recovered from cold storage.${NC}"
                    sleep 0.5
                    echo -e "${WHITE} > 家族の記憶データを復元しました。${NC}"
                    echo -e "${WHITE} > このデータは人類アーカイブの一部です。${NC}"
                    sleep 1
                    
                    local exp_gain=$(( 50 + RANDOM % 50 ))
                    PLAYER_EXP=$(( PLAYER_EXP + exp_gain ))
                    echo ""
                    echo -e "${GREEN} > Log Fragment Absorbed: +${exp_gain} EXP${NC}"
                    check_level_up
                    
                    read -r -p "[ENTER] to continue..."
                elif [[ "$raw_cmd" == "sara1122" && "$SECRET_PASSWORD_USED" == 1 ]]; then
                    echo -e "${GREY} > Authentication failed: Session already established.${NC}"
                    sleep 0.5
                elif [[ "$raw_cmd" == "kill me now" ]]; then
                    echo ""
                    echo -e "${RED}[SYSTEM] 強制終了します...${NC}"
                    sleep 2
                    CURRENT_HP=0
                    calculate_score 0.5 "DEBUGGER"
                else
                    echo " > コマンドが見つかりません: $raw_cmd"
                    sleep 0.5
                fi
                ;;
        esac
    done
    
    echo -e "${RED}[FATAL] CONNECTION RESET BY PEER${NC}"
    calculate_score
}

# --- Start ---

SKIP_INTRO=0
SCORE_CODE_INPUT=""

show_help() {
    echo -e "${CYAN}LUNA SEE${NC} - A Hardcore Shell RPG"
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message and exit"
    echo "  -s, -SKIP     Skip intro sequence (Fast boot)"
    echo "  -CODE <code>  Validate score code"
    echo ""
    echo "Example:"
    echo "  $0 -SKIP"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -s|-SKIP)
            SKIP_INTRO=1
            shift
            ;;
        -CODE)
            if [[ -n "$2" ]]; then
                SCORE_CODE_INPUT="$2"
                shift 2
            else
                echo "Error: -CODE requires a score code argument"
                exit 1
            fi
            ;;
        *)
            shift
            ;;
    esac
done

# If score code provided, display score screen and exit
if [[ -n "$SCORE_CODE_INPUT" ]]; then
    # Attempt to validate and parse
    if validate_and_parse_score_code "$SCORE_CODE_INPUT"; then
        # Valid code - calculate and display score normally
        echo -e "${GREEN}[VALID] スコアコードの検証に成功しました。${NC}"
        sleep 1
        
        # Force DEBUGGER rank if multiplier is 0.5
        forced_rank=""
        if [[ "$SCORE_MULTIPLIER_SAVE" == "0.5" ]]; then
            forced_rank="DEBUGGER"
        fi
        calculate_score "${SCORE_MULTIPLIER_SAVE:-1}" "$forced_rank"
    else
        # Invalid code - CHEATER
        echo -e "${RED}[ERROR] 不正なスコアコードを検出しました。${NC}"
        sleep 1
        
        # Set all stats to zero
        CURRENT_DEPTH=0
        STAT_ENEMIES_KILLED=0
        STAT_LOGS_FOUND=0
        STAT_EXPLORE_COUNT=0
        PLAYER_LEVEL=0
        STAT_DAMAGE_DEALT=0
        STAT_DAMAGE_TAKEN=0
        STAT_HEAL_COUNT=0
        STAT_TOTAL_TURNS=0
        STAT_DEPTH_SKIPS=0
        STAT_ITEMS_USED=0
        
        # Display with forced CHEATER rank
        calculate_score 1 "CHEATER"
    fi
    exit 0
fi

game_loop
