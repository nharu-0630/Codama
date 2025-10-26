#!/bin/bash

# mock.jsonのデータを使って1ユーザーが連続投稿するスクリプト

set -e

BASE_URL="http://localhost:8000"
MOCK_FILE="$(dirname "$0")/mock.json"

# 色付きの出力
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Mock データ投稿スクリプト ===${NC}\n"

# mock.jsonの存在確認
if [ ! -f "$MOCK_FILE" ]; then
    echo "Error: $MOCK_FILE が見つかりません"
    exit 1
fi

# ユーザーの作成
echo -e "${GREEN}[1/1] ユーザーを作成中...${NC}"
USER_RESPONSE=$(curl -s --location --request POST "${BASE_URL}/signup")
USER_TOKEN=$(echo $USER_RESPONSE | jq -r '.access_token')
USER_ID=$(echo $USER_RESPONSE | jq -r '.user_id')
echo "User ID: $USER_ID"
echo "User Token: ${USER_TOKEN:0:20}..."

# mock.jsonのエントリー数を取得
TOTAL_POSTS=$(jq 'length' "$MOCK_FILE")
echo -e "\n${BLUE}=== 投稿開始 (全${TOTAL_POSTS}件) ===${NC}\n"

# 各エントリーをループで投稿
for i in $(seq 0 $((TOTAL_POSTS - 1))); do
    # JSONから content と location を取得
    CONTENT=$(jq -r ".[$i].content" "$MOCK_FILE")
    LAT=$(jq -r ".[$i].location[0]" "$MOCK_FILE")
    LON=$(jq -r ".[$i].location[1]" "$MOCK_FILE")

    echo -e "${YELLOW}--- 投稿 $((i + 1))/${TOTAL_POSTS} ---${NC}"
    echo "内容: $CONTENT"
    echo "座標: ($LAT, $LON)"

    # 投稿
    POST_RESPONSE=$(curl -s --location "${BASE_URL}/posts" \
        --header "Authorization: Bearer $USER_TOKEN" \
        --header 'Content-Type: application/json' \
        --data "{
            \"content\": \"$CONTENT\",
            \"lat\": $LAT,
            \"lon\": $LON
        }") 

    POST_UUID=$(echo $POST_RESPONSE | jq -r '.post.uuid')
    echo -e "${GREEN}投稿完了: $POST_UUID${NC}\n"

    # 1秒待機
    sleep 1
done

echo -e "${BLUE}=== 全ての投稿が完了しました ===${NC}"
echo "投稿数: $TOTAL_POSTS"
echo "User ID: $USER_ID"
