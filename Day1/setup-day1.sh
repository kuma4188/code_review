#!/usr/bin/env bash
# PATH 환경 변수에서 bash 실행 파일을 찾아 이 스크립트를 해석, 실행하도록 지정하는 셰뱅(Shebang)

set -euo pipefail
# -e: 반환 코드가 0이 아닌 명령이 실패하면 즉시 스크립트 종료
# -u: 선언되지 않은 변수를 참조하면 오류를 내고 즉시 종료
# -o pipefail: 파이프라인(|)으로 연결된 명령 중 하나라도 실패하면 전체를 실패로 처리

echo "[1/5] 시스템 패키지 업데이트 및 필수 유틸 설치"
# 1단계 진행 상황을 터미널에 출력

sudo apt-get update -y
# 관리자 권한(sudo)으로 APT 패키지 저장소 목록을 최신 상태로 갱신(-y: 확인 프롬프트 자동 승인)

sudo apt-get install -y curl unzip jq apt-transport-https ca-certificates gnupg lsb-release
# 이후 설치 과정에 필요한 유틸리티 설치:
# - curl, unzip: 파일 다운로드 및 ZIP 압축 해제
# - jq: JSON 데이터 파싱/처리
# - apt-transport-https, ca-certificates: HTTPS 저장소 통신 및 SSL/TLS 인증서 관리
# - gnupg: GPG 서명 키 검증 및 키링 관리
# - lsb-release: 현재 Linux 배포판 코드네임 확인(lsb_release -cs)

echo "[2/5] AWS CLI v2 설치"
# 2단계 진행 상황을 터미널에 출력

curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
# Linux x86_64용 AWS CLI v2 설치 ZIP 파일을 조용히(-s) 받아 /tmp/awscliv2.zip으로 저장

unzip -oq "/tmp/awscliv2.zip" -d /tmp
# /tmp 디렉터리에 덮어쓰기 확인 없이(-o) 조용히(-q) 압축 해제

sudo /tmp/aws/install --update
# 압축 해제된 설치 스크립트를 관리자 권한으로 실행(기존 설치가 있으면 --update로 갱신)

rm -rf /tmp/aws /tmp/awscliv2.zip
# 설치 완료 후 /tmp에 남은 임시 추출 디렉터리와 ZIP 파일을 삭제해 정리

aws --version
# 설치된 AWS CLI 버전을 출력해 정상 동작 확인

echo "[3/5] Terraform 설치"
# 3단계 진행 상황을 터미널에 출력

wget -qO- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
# HashiCorp 공식 GPG 키를 표준 출력(-qO-)으로 내려받아 gpg --dearmor로 바이너리 키링 변환 후 저장

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
# 현재 배포판 코드네임($(lsb_release -cs))에 맞춘 HashiCorp APT 저장소 설정을 파일에 기록(> /dev/null로 화면 출력 숨김)

sudo apt-get update -y && sudo apt-get install -y terraform
# 추가한 저장소를 반영해 패키지 목록을 갱신한 뒤(&& 앞 명령 성공 시) terraform 설치

terraform -version
# 설치된 Terraform 버전을 출력해 정상 동작 확인

echo "[4/5] kubectl 설치"
# 4단계 진행 상황을 터미널에 출력

KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
# Kubernetes 공식 릴리스 서버에서 최신 안정 버전 문자열(예: v1.31.x)을 받아 변수에 저장(-L: 리다이렉트 추적)

curl -LO -s "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
# 해당 버전의 Linux amd64용 kubectl 바이너리를 현재 디렉터리에 원래 이름(-O)으로 다운로드

sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
# kubectl 바이너리를 /usr/local/bin으로 복사하며 소유자(root:root)와 실행 권한(0755) 설정

rm -f kubectl
# 현재 디렉터리에 남아 있는 다운로드 원본 파일 삭제(-f: 없어도 오류 미발생)

kubectl version --client
# 클러스터 연결 없이 로컬 kubectl 클라이언트 버전을 출력해 정상 설치 확인

echo "[5/5] Helm 및 k6 설치"
# 5단계 진행 상황을 터미널에 출력

curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
# Helm 3 공식 설치 스크립트를 /tmp/get_helm.sh로 다운로드(-f: HTTP 오류 시 실패, -sS: 오류만 출력)

chmod 700 /tmp/get_helm.sh
# 스크립트 소유자만 읽고·쓰고·실행(rwx------)할 수 있도록 권한 부여

/tmp/get_helm.sh
# Helm 설치 스크립트를 실행해 helm 바이너리 설치

rm -f /tmp/get_helm.sh
# 설치가 끝난 임시 설치 스크립트 파일 삭제

helm version
# 설치된 Helm 버전을 출력해 정상 동작 확인

sudo gpg -k
# root 계정의 GPG 키링에 등록된 키 목록을 출력해 상태 확인

sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
# 지정한 키링 파일(/usr/share/keyrings/k6-archive-keyring.gpg)에 Ubuntu 키서버(80포트)에서 k6 서명 키 수신·저장

echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://deb.k6.io stable main" | sudo tee /etc/apt/sources.list.d/k6.list > /dev/null
# 위 키링으로 검증하는 Grafana k6 공식 APT 저장소 설정을 /etc/apt/sources.list.d/k6.list에 기록

sudo apt-get update -y && sudo apt-get install -y k6
# 패키지 목록을 갱신한 뒤 k6 부하 테스트 도구 설치

k6 version
# 설치된 k6 버전을 출력해 정상 동작 확인

echo "Day 1 도구 설치 완료!"
# 모든 설치 및 검증 단계가 완료되었음을 알리는 메시지 출력