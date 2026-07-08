allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Fix namespace untuk compat AGP 8+
// Library lawas (seperti image_gallery_saver) kadang namespace-nya tidak
// terdeteksi oleh AGP 8+ meski sudah di-set di build.gradle-nya.
subprojects {
    plugins.whenPluginAdded {
        if (hasProperty("android")) {
            val ext = extensions.findByName("android")
            if (ext is com.android.build.gradle.LibraryExtension) {
                if (ext.namespace == null) {
                    ext.namespace = "com.${project.name}.malasnulis"
                    logger.warn("{}: namespace di-set ke {}", project.name, ext.namespace)
                }
            }
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}