rootProject.name = "triplan"

include(
    "api",
    "core:core-common",
    "core:core-enum",
    "core:core-example",
    "storage:db-core",
    "tests:api-docs",
    "support:logging",
    "support:monitoring",
    "clients:client-example",
)

pluginManagement {
    val kotlinVersion: String by settings
    val springBootVersion: String by settings
    val springDependencyManagementVersion: String by settings
    val asciidoctorConvertVersion: String by settings
    val ktlintVersion: String by settings

    resolutionStrategy {
        eachPlugin {
            when (requested.id.id) {
                "org.jetbrains.kotlin.jvm" -> useVersion(kotlinVersion)
                "org.jetbrains.kotlin.plugin.spring" -> useVersion(kotlinVersion)
                "org.jetbrains.kotlin.plugin.jpa" -> useVersion(kotlinVersion)
                "org.springframework.boot" -> useVersion(springBootVersion)
                "io.spring.dependency-management" -> useVersion(springDependencyManagementVersion)
                "org.asciidoctor.jvm.convert" -> useVersion(asciidoctorConvertVersion)
                "org.jlleitschuh.gradle.ktlint" -> useVersion(ktlintVersion)
            }
        }
    }
}

// gradle.properties 의 javaVersion=25 툴체인을 로컬에 없어도 자동으로 내려받게 한다
plugins {
    id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"
}
