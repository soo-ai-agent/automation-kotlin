dependencies {
    implementation(project(":core:core-common"))
    implementation(project(":storage:db-core"))

    implementation("org.springframework.boot:spring-boot-starter-webmvc")
    // 신뢰 경계 입력 검증(@Valid·@field:)은 리뷰 규칙의 MUST 다. 요청 DTO 가 이 모듈에 있으므로 여기에 둔다.
    implementation("org.springframework.boot:spring-boot-starter-validation")
}
