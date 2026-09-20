#!/bin/bash

# 1. 변수 설정
AWS_REGION="ap-south-1"
ECR_REPOSITORY="nginx"
CONTAINER_NAME="nginx-app"

# AWS Account ID 자동 추출
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
ECR_URI="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest"

# 2. ECR 로그인 & 최신 이미지 Pull
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
docker pull $ECR_URI

# 3. 기존 컨테이너 중지 및 삭제 (있을 경우만)
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

# 4. 새 컨테이너 실행
docker run -d --name $CONTAINER_NAME -p 80:80 --restart always $ECR_URI