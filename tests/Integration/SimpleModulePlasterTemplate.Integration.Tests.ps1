#region HEADER
$script:projectPath = "$PSScriptRoot\..\.." | Convert-Path
$script:projectName = (Get-ChildItem -Path "$script:projectPath\*\*.psd1" | Where-Object -FilterScript {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try
            {
                Test-ModuleManifest -Path $_.FullName -ErrorAction Stop
            }
            catch
            {
                $false
            })
    }).BaseName

$script:moduleName = Get-Module -Name $script:projectName -ListAvailable | Select-Object -First 1
Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

$importedModule = Import-Module $script:moduleName -Force -PassThru -ErrorAction 'Stop'

#endregion HEADER

Describe 'Simple Module Plaster Template' {
    Context 'When creating a new module project' {
        BeforeAll {
            $mockModuleName = 'ModuleDsc'

            $mockModuleRootPath = Join-Path -Path $TestDrive -ChildPath $mockModuleName
        }

        It 'Should create a new module without throwing' {
            $invokePlasterParameters = @{
                TemplatePath      = Join-Path -Path $importedModule.ModuleBase -ChildPath 'Templates/Sampler'
                DestinationPath   = $TestDrive
                SourceDirectory   = 'source'
                NoLogo            = $true
                Force             = $true

                # Template
                ModuleType        = 'SimpleModule'

                # Template properties
                ModuleName        = $mockModuleName
                ModuleAuthor      = 'SamplerTestUser'
                ModuleDescription = 'Module description'
                ModuleVersion     = '1.0.0'
                CustomRepo        = 'PSGallery'
            }

            { Invoke-Plaster @invokePlasterParameters } | Should -Not -Throw
        }

        It 'Should have the expected folder and file structure' {
            $modulePaths = Get-ChildItem -Path $mockModuleRootPath -Recurse

            # Make the path relative to module root.
            $relativeModulePaths = $modulePaths.FullName -replace [RegEx]::Escape($mockModuleRootPath)

            # Change to slash when testing on Windows.
            $relativeModulePaths = ($relativeModulePaths -replace '\\', '/').TrimStart('/')

            # Folders (relative to module root)

            'source' | Should -BeIn $relativeModulePaths
            'source/DSCResources' | Should -BeIn $relativeModulePaths
            'source/en-US' | Should -BeIn $relativeModulePaths
            'source/Examples' | Should -BeIn $relativeModulePaths
            'source/Private' | Should -BeIn $relativeModulePaths
            'source/Public' | Should -BeIn $relativeModulePaths
            'tests' | Should -BeIn $relativeModulePaths
            'tests/QA' | Should -BeIn $relativeModulePaths
            'output' | Should -BeIn $relativeModulePaths
            'output/RequiredModules' | Should -BeIn $relativeModulePaths

            # Files (relative to module root)

            '.gitattributes' | Should -BeIn $relativeModulePaths
            '.gitignore' | Should -BeIn $relativeModulePaths
            'build.ps1' | Should -BeIn $relativeModulePaths
            'build.yaml' | Should -BeIn $relativeModulePaths
            'CHANGELOG.md' | Should -BeIn $relativeModulePaths
            'README.md' | Should -BeIn $relativeModulePaths
            'RequiredModules.psd1' | Should -BeIn $relativeModulePaths
            'Resolve-Dependency.ps1' | Should -BeIn $relativeModulePaths
            'Resolve-Dependency.psd1' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psd1' | Should -BeIn $relativeModulePaths
            'source/ModuleDsc.psm1' | Should -BeIn $relativeModulePaths
            'source/en-US/about_ModuleDsc.help.txt' | Should -BeIn $relativeModulePaths
            'tests/QA/module.tests.ps1' | Should -BeIn $relativeModulePaths

            $relativeModulePaths | Should -HaveCount 23
        } -ErrorVariable itBlockError

        # Check if previous It-block failed. If so output the module directory tree.
        if ( $itBlockError.Count -ne 0 )
        {
            Write-Verbose -Message (tree /f $mockModuleRootPath | Out-String) -Verbose
        }
    }
}