allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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
dependencies {
    // Import the BoM for the Firebase platform
    implementation(platform("com.google.firebase:firebase-bom:33.14.0"))

    // Add the dependencies for the Crashlytics and Analytics libraries
    // When using the BoM, you don't specify versions in Firebase library dependencies
    implementation("com.google.firebase:firebase-crashlytics")
    implementation("com.google.firebase:firebase-analytics")
}
plugins {
    // Make sure that you have the AGP plugin 8.1+ dependency
    id("com.android.application") version "8.1.4" apply false
    // ...

    // Make sure that you have the Google services Gradle plugin 4.4.1+ dependency
    id("com.google.gms.google-services") version "4.4.2" apply false

    // Add the dependency for the Crashlytics Gradle plugin
    id("com.google.firebase.crashlytics") version "3.0.3" apply false
}
plugins {
    id("com.android.application")
    // ...
  
    // Make sure that you have the Google services Gradle plugin
    id("com.google.gms.google-services")
  
    // Add the Crashlytics Gradle plugin
    id("com.google.firebase.crashlytics")
  }