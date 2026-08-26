tasks.named<Jar>("bootJar").configure {
    enabled = true
}

tasks.named<Jar>("jar").configure {
    enabled = false
}

dependencies {
    implementation(project(":core:core-common"))
    implementation(project(":core:core-example"))
    implementation(project(":support:monitoring"))
    implementation(project(":support:logging"))
    implementation(project(":storage:db-core"))

    implementation("org.springframework.boot:spring-boot-starter-webmvc")
    implementation("org.springframework.boot:spring-boot-starter-validation")
}
