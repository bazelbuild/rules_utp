"""Workspace setup macro for rules_android."""

load("@rules_jvm_external//:defs.bzl", "maven_install")

def example_workspace():
    """ Sets up workspace dependencies for rules_android."""

    UTP_VERSION = "0.0.9-alpha01"
    SERVICES_VERSION = "1.4.2"
    androidxLibVersion = "1.0.0"
    coreVersion = "1.6.0-alpha05"
    extJUnitVersion = "1.2.0-alpha03"
    espressoVersion = "3.6.0-alpha03"
    runnerVersion = "1.6.0-alpha06"
    rulesVersion = "1.6.0-alpha03"

    maven_install(
        name = "android_maven",
        artifacts = [
            "com.android.support:multidex:1.0.3",
            "com.android.support.test:runner:1.0.2",
        ],
        fetch_sources = True,
        repositories = [
            "https://maven.google.com",
            "https://repo1.maven.org/maven2",
        ],
    )

    maven_install(
        name = "androidx_maven",
        artifacts = [
            "androidx.test:core:" + coreVersion,
            "androidx.test.espresso:espresso-core:" + espressoVersion,
            "androidx.test.ext:junit:" + extJUnitVersion,
            "androidx.test:runner:" + runnerVersion,
            "androidx.test:rules:" + rulesVersion,
        ],
        fetch_sources = True,
        repositories = [
            "https://maven.google.com",
            "https://repo1.maven.org/maven2",
        ],
    )
