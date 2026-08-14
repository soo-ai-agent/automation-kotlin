# 배포

> **이 문서는 사람이 읽습니다.**

main 에 머지되면 자동으로 돈다: 이미지 빌드 → GHCR 푸시 → 서버에서 교체.

    머지 → build  (backend·frontend 이미지를 ghcr.io 에 푸시)
         → deploy (서버 SSH 접속 → docker compose pull && up -d)

이미지 이름은 `ghcr.io/<owner>/<repo>/backend` · `.../frontend` 이고,
`latest` 와 커밋 SHA 앞 7자리 태그가 함께 붙는다.

## 켜는 법

배포는 기본적으로 꺼져 있다. **변수 `DEPLOY_ENABLED` = `true` 를 등록하는 순간 켜진다** —
레지스트리와 서버가 준비되기 전에는 등록하지 않는다 (main 머지마다 실패가 쌓인다).

1. 서버에 Docker 를 설치하고, 저장소의 [docker-compose.yml](../docker-compose.yml) 을 올려 둔다
   (`<registry>` 를 `ghcr.io/<owner>/<repo>` 로 바꾼다).

2. 서버에서 GHCR 에 로그인한다 — `docker login ghcr.io -u <user> -p <PAT>`
   (PAT 은 `read:packages` 권한이면 된다).

3. Settings → Secrets and variables → Actions 에서 등록한다.

   - **Variables** 탭: `DEPLOY_ENABLED` = `true`

   - **Secrets** 탭: `DEPLOY_HOST` · `DEPLOY_USER` · `DEPLOY_SSH_KEY` · `DEPLOY_PATH`

`DEPLOY_HOST` 가 없으면 이미지 푸시까지만 하고 서버 배포는 건너뛴다.
이미지만 쓰고 배포는 손으로 하겠다면 그대로 두면 된다.

## 알아둘 것

- 백엔드 이미지는 `backend/settings.gradle.kts` 가 있어야 빌드된다
  ([backend/README.md](../backend/README.md) 대로 뼈대를 올린 뒤).
  없으면 그 단계만 건너뛰고 프론트엔드만 올린다.

- 프론트 이미지는 nginx 가 정적 파일을 서빙하고 `/api` 를 backend 컨테이너(8080)로 넘긴다
  ([frontend/nginx.conf](../frontend/nginx.conf)).

- 배포 워크플로는 `push` 로만 돈다 — 디스패처 스케줄과 섞이지 않는다.

- 롤백은 서버에서 이전 SHA 태그로 `docker compose up -d` 하면 된다.
  태그 전략을 바꾸려면 `deploy.yml` 의 태그만 고친다.

- DB 접속 정보처럼 환경마다 달라지는 값은 `docker-compose.yml` 의 `environment` 로 준다.
