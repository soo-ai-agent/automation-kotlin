# backend/README.md 대로 Spring 멀티모듈 뼈대를 올린 뒤에 빌드한다.
# 빌드 산출물은 CI 가 미리 만든다: cd backend && ./gradlew :core:core-api:bootJar -x test
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app
COPY core/core-api/build/libs/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
