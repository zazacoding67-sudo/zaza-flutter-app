pluginManagement {
    val flutterSdkPath: String = java.io.File(settingsDir.parentFile, "local.properties")
        .readText()
        .lineSequence()
        .map { it.split("=") }
        .firstOrNull { it[0].trim() == "flutter.sdk" }
        ?.get(1)
        ?.trim()
        ?: throw GradleException("Flutter SDK path not defined in local.properties")

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}