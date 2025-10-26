set -e

BASE_URL="http://localhost:8000"

# 色付きの出力
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 自動フレンド機能テスト ===${NC}\n"

# ユーザー1の作成
echo -e "${GREEN}[1/2] ユーザー1を作成中...${NC}"
USER1_RESPONSE=$(curl -s --location --request POST "${BASE_URL}/signup")
USER1_TOKEN=$(echo $USER1_RESPONSE | jq -r '.access_token')
USER1_ID=$(echo $USER1_RESPONSE | jq -r '.user_id')
echo "User1 ID: $USER1_ID"
echo "User1 Token: ${USER1_TOKEN:0:20}..."

# ユーザー2の作成
echo -e "\n${GREEN}[2/2] ユーザー2を作成中...${NC}"
USER2_RESPONSE=$(curl -s --location --request POST "${BASE_URL}/signup")
USER2_TOKEN=$(echo $USER2_RESPONSE | jq -r '.access_token')
USER2_ID=$(echo $USER2_RESPONSE | jq -r '.user_id')
echo "User2 ID: $USER2_ID"
echo "User2 Token: ${USER2_TOKEN:0:20}..."

# 同じセルに投稿するための座標（横浜駅周辺）
LAT=35.466188
LON=139.622004

echo -e "\n${BLUE}=== テストシナリオ1: 同じセルに5回投稿 ===${NC}"
echo "座標: ($LAT, $LON)"

# 5回投稿して自動フレンドをトリガー
for i in {1..5}; do
    echo -e "\n${YELLOW}--- 投稿 $i/5 ---${NC}"

    # ユーザー1の投稿
    echo "User1が投稿中..."
    USER1_POST=$(curl -s --location "${BASE_URL}/posts" \
        --header "Authorization: Bearer $USER1_TOKEN" \
        --header 'Content-Type: application/json' \
        --data "{
            \"content\": \"User1の投稿 #$i - テストメッセージ\",
            \"lat\": $LAT,
            \"lon\": $LON
        }")
    echo "User1投稿: $(echo $USER1_POST | jq -r '.post.uuid')"

    # 少し待機
    sleep 1

    # ユーザー2の投稿
    echo "User2が投稿中..."
    USER2_POST=$(curl -s --location "${BASE_URL}/posts" \
        --header "Authorization: Bearer $USER2_TOKEN" \
        --header 'Content-Type: application/json' \
        --data "{
            \"content\": \"User2の投稿 #$i - テストメッセージ\",
            \"lat\": $LAT,
            \"lon\": $LON
        }")
    echo "User2投稿: $(echo $USER2_POST | jq -r '.post.uuid')"

    sleep 1
done