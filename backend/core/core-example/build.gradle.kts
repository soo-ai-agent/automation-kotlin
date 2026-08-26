dependencies {
    implementation(project(":core:core-common"))

    implementation("org.springframework.boot:spring-boot-starter-webmvc")

    testImplementation(project(":tests:api-docs"))
}
