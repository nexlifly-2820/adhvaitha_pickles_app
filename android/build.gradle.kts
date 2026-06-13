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
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Global forced dependency versions to prevent mismatch
subprojects {
    project.configurations.all {
        resolutionStrategy {
            force("androidx.core:core-ktx:1.13.1")
            force("androidx.fragment:fragment:1.7.1")
            force("androidx.activity:activity:1.8.1")
            force("androidx.lifecycle:lifecycle-runtime:2.7.0")
        }
    }
}

// Safely override compileSdkVersion and targetSdkVersion for all plugins
gradle.afterProject {
    if (project.hasProperty("android")) {
        val android = project.extensions.findByName("android")
        if (android is com.android.build.gradle.BaseExtension) {
            android.compileSdkVersion(35)
            android.defaultConfig {
                targetSdkVersion(35)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
