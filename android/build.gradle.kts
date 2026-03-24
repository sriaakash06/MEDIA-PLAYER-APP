allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // 1. Set subproject build directory
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // 2. Fix namespace and toolchain for AGP 8.0+ and Kotlin
    afterEvaluate {
        val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        if (android != null && android.namespace == null) {
            val manifestFile = project.file("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                val manifestXml = manifestFile.readText()
                val packageMatch = Regex("""package="([^"]+)"""").find(manifestXml)
                if (packageMatch != null) {
                    android.namespace = packageMatch.groupValues[1]
                }
            }
            // Fallback if still null
            if (android.namespace == null) {
                android.namespace = "com.example.${project.name.replace(":", ".").replace("-", "_")}"
            }
        }

        // Apply toolchain if Kotlin plugin is present
        if (project.plugins.hasPlugin("org.jetbrains.kotlin.android")) {
            project.extensions.configure<org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension> {
                jvmToolchain(21)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}


