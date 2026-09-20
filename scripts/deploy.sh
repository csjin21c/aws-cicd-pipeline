#!/bin/bash
# 실행 중 오류 발생 시 즉시 중단
set -e

# 1. 시크릿 설정 값 기반 변수 정의
AWS_REGION="ap-south-1"
ECR_REPOSITORY="nginx"
CONTAINER_NAME="nginx-app"

# AWS CLI를 이용한 간단한 Account ID 추출 (권장)
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

# Account ID 조회가 실패할 경우를 대비한  fallback 처리
if [ -z "$ACCOUNT_ID" ]; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
fi

ECR_URI="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest"

echo "=========================================="
echo "Starting deployment for $ECR_REPOSITORY..."
echo "ECR URI: $ECR_URI"
echo "=========================================="

# 2. Amazon ECR 인증 로그인
echo "==> [1/5] ECR 로그인 중..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# 3. ECR에서 최신 Docker 이미지 가져오기
echo "==> [2/5] 최신 Docker 이미지 Pull 중..."
docker pull $ECR_URI

# 4. 기존 구동 중인 컨테이너가 있다면 중지 및 삭제
echo "==> [3/5] 기존 실행 중인 컨테이너 확인 및 정리 중..."
if [ $(docker ps -a -q -f name=^/${CONTAINER_NAME}$) ]; then
    echo "기존 $CONTAINER_NAME 컨테이너를 중지하고 제거합니다."
    docker stop $CONTAINER_NAME || true
    docker rm $CONTAINER_NAME || true
fi

# 5. 새 Nginx 컨테이너 실행
echo "==> [4/5] 새 Nginx 컨테이너 실행 중..."
docker run -d \
  --name $CONTAINER_NAME \
  -p 80:80 \
  --restart always \
  $ECR_URI

# 6. 미사용 및 오래된 Docker 이미지/레이어 정리
echo "==> [5/5] 미사용 이미지 정리 중..."
docker image prune -af --filter "until=24h" || true

echo "=========================================="
echo "Deployment completed successfully!"
echo "=========================================="