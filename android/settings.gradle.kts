pluginManagement {
    repositories {
        if (providers.gradleProperty("fastmd.useChinaMavenMirror").map(String::toBoolean).getOrElse(false)) {
            maven("https://maven.aliyun.com/repository/google")
            maven("https://maven.aliyun.com/repository/central")
            maven("https://maven.aliyun.com/repository/gradle-plugin")
        }
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        if (providers.gradleProperty("fastmd.useChinaMavenMirror").map(String::toBoolean).getOrElse(false)) {
            maven("https://maven.aliyun.com/repository/google")
            maven("https://maven.aliyun.com/repository/central")
        }
        mavenCentral()
        google()
    }
}

rootProject.name = "fastmd-android"

include(
    ":app",
    ":core",
    ":feature:reader",
    ":feature:library",
    ":feature:settings",
)
