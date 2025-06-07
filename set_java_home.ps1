$javaPath = "C:\Program Files\Java\jdk-17"

# Vérifier si le chemin existe
if (Test-Path $javaPath) {
    # Configurer JAVA_HOME
    [System.Environment]::SetEnvironmentVariable("JAVA_HOME", $javaPath, "User")
    Write-Host "JAVA_HOME configuré avec succès à $javaPath"
    Write-Host "Redémarrez votre terminal pour que les changements prennent effet"
} else {
    Write-Host "Le chemin $javaPath n'existe pas"
}
