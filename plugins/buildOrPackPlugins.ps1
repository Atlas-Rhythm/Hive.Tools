param (
    [string] $Configuration = "Release",
    [parameter(mandatory=$false, ValueFromRemainingArguments=$true)] $args
)

Set-Location "$PSScriptRoot/../../" # Switch to root

$projects = Get-ChildItem -Path "src" -Filter "*.csproj" -Recurse -ErrorAction SilentlyContinue -Force

$libProjects = @()
$exeProjects = @()
foreach ($proj in $projects) {
    $outType = dotnet msbuild --nologo "$proj" -p:SdkPropertyToGet=OutputType -t:SdkPrintProperty
    if ($outType.Trim().ToLower() -eq "library") {
        $libProjects += ,$proj
    } else {
        $exeProjects += ,$proj
    }
}

# Make sure to restore
dotnet restore -p:Configuration=$Configuration @args

$artifactZips = "artifacts/zips"
mkdir $artifactZips -Force

# Build libraries
foreach ($proj in $libProjects) {
    $projName = [IO.Path]::GetFileNameWithoutExtension($proj)
    $artifactBase = dotnet msbuild --nologo "$proj" -p:SdkPropertyToGet=BaseOutputPath -t:SdkPrintProperty
    dotnet build -clp:NoSummary --no-restore --nologo "$proj" -p:Configuration=$Configuration @args
    $dirs = Get-ChildItem -Path "$artifactBase/$Configuration/".Trim() -Force
    foreach ($dir in $dirs) {
        Compress-Archive -Path "$dir/*" -DestinationPath "$artifactZips/$projName.$($dir.Name).zip" -CompressionLevel Optimal -Force
    }
}

$artifactPublishOut = "artifacts/publish"
mkdir $artifactPublishOut -Force

$publishRids = "win-x64","linux-x64","osx-x64"

# Build exes
foreach ($proj in $exeProjects) {
    $projName = [IO.Path]::GetFileNameWithoutExtension($proj)
    $publishDir = "$artifactPublishOut/$projName"

    foreach ($rid in $publishRids) {
        $dir = "$publishDir/$rid"
        dotnet publish -clp:NoSummary --nologo "$proj" -p:Configuration=$Configuration -r $rid "-p:PublishProfileFullPath=$PSScriptRoot/publishProfile.pubxml" @args -o $dir
        Compress-Archive -Path "$dir/*" -DestinationPath "$artifactZips/$projName.$rid.zip" -CompressionLevel Optimal -Force
    }
}