<#
.SYNOPSIS
    Uma ferramenta de console para catalogar e consultar rapidamente qualquer item do Arena Breakout Infinite.
.DESCRIPTION
    Este script funciona como uma enciclopédia pessoal para o ABI. Você pode adicionar seus próprios itens, editar estatísticas e usar o menu "Busca com Filtro" para encontrar o melhor equipamento (capacetes, coletes, armas) para sua necessidade, com base em critérios de ordenação complexos.
#>

$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$global:ACTION_BACK = "__BACK__"
$global:ACTION_MAIN_MENU = "__MAIN_MENU__"

if ($Host.Name -eq 'ConsoleHost') {
    Clear-Host
}

$global:databasePath = Join-Path -Path $PSScriptRoot -ChildPath "Database ABI"
$AmmoPath = Join-Path -Path $global:databasePath -ChildPath "Ammo"
$weaponsPath = Join-Path -Path $global:databasePath -ChildPath "Weapons"
$defaultCalibers = @(
    "5.45x39mm", "5.56x45mm", "5.7x28mm", "5.8x42mm",
    "7.62x25mm", "7.62x39mm", "7.62x51mm", "7.62x54mm",
    "9x19mm", "9x39mm", "12x70mm", ".44", ".45", ".338"
)

$global:ScriptVersion = "0.9.4"
$global:GitHubApiUrl = "https://api.github.com/repos/fabiopsyduck/Arena-Breakout-Infinite-Offline-Database/releases/latest"
$global:GitHubReleasePageUrl = "https://github.com/fabiopsyduck/Arena-Breakout-Infinite-Offline-Database/releases/latest"

$weaponClasses = @(
    "ASSAULT RIFLE", "SUBMACHINE GUN", "CARBINE",
    "MARKSMAN RIFLE", "BOLT-ACTION RIFLE", "SHOTGUN",
    "LIGHT MACHINE GUN", "PISTOL"
)

$global:WeaponClassToPortugueseMap = @{
    "ASSAULT RIFLE"     = "Rifle de assalto";
    "SUBMACHINE GUN"    = "Submetralhadora";
    "CARBINE"           = "Carabina";
    "MARKSMAN RIFLE"    = "Fuzil DMR";
    "BOLT-ACTION RIFLE" = "Rifle de ferrolho";
    "SHOTGUN"           = "Escopeta";
    "LIGHT MACHINE GUN" = "Metralhadora leve";
    "PISTOL"            = "Pistola"
}

# Cria o mapa reverso automaticamente para traduzir de volta para o inglês
$global:PortugueseToWeaponClassMap = @{}
$global:WeaponClassToPortugueseMap.GetEnumerator() | ForEach-Object {
    $global:PortugueseToWeaponClassMap[$_.Value] = $_.Key
}

$global:ItemCategoryConfig = @{
    "Ammo" = @{ AddItemMenuName = "Uma nova Municao"; EditViewMenuName = "Municao"; AddFunction = "Add-NewAmmo"; EditFunction = "Add-NewAmmo" }
    "Weapons" = @{ AddItemMenuName = "Uma nova Arma"; EditViewMenuName = "Armas"; PathName = "Weapons"; AddFunction = "Add-NewWeapon"; EditFunction = "Add-NewWeapon"; ViewHeader = "Nome da Arma      Calibre      CRV  CRH  Ergo Prec Stab.SM Dis(m) Vel.bo  ModoDisparo       Cad   Poder.DFG   Melh.Cano"; ViewFormat = "{0,-17} {1,-12} {2,-4} {3,-4} {4,-4} {5,-4} {6,-7} {7,-6} {8,-7} {9,-17} {10,-5} {11,-11} {12,-9}" }
    "Painkillers" = @{ AddItemMenuName = "Um novo Analgesico"; EditViewMenuName = "Analgesicos"; PathName = "Painkillers"; AddFunction = "Add-NewPainkiller"; EditFunction = "Add-NewPainkiller"; ViewHeader = "Nome                    Usos  Duracao  Desidratacao  Tempo de Atraso"; ViewFormat = "{0,-23} {1,-5} {2,-8} {3,-13} {4,-15}"; Properties = @( [PSCustomObject]@{ PropName="Uses"; DisplayName="Usos" }, [PSCustomObject]@{ PropName="Duration"; DisplayName="Duracao" }, [PSCustomObject]@{ PropName="Dehydration"; DisplayName="Desidratacao" }, [PSCustomObject]@{ PropName="Delay"; DisplayName="Tempo de Atraso" } ) }
    "Bandages" = @{ AddItemMenuName = "Uma nova Bandagem"; EditViewMenuName = "Bandagens"; PathName = "Bandages"; AddFunction = "Add-NewBandage"; EditFunction = "Add-NewBandage"; ViewHeader = "Nome                Usos  Tempo de Atraso Custo Durabilidade"; ViewFormat = "{0,-19} {1,-5} {2,-15} {3,-5}"; Properties = @( [PSCustomObject]@{ PropName="Uses"; DisplayName="Usos" }, [PSCustomObject]@{ PropName="Delay"; DisplayName="Tempo de Atraso" }, [PSCustomObject]@{ PropName="DurabilityCost"; DisplayName="Custo Durabilidade" } ) }
    "Surgicalkit" = @{ AddItemMenuName = "Um novo Kit cirurgico"; EditViewMenuName = "Kit cirurgico"; PathName = "Surgicalkit"; AddFunction = "Add-NewSurgicalKit"; EditFunction = "Add-NewSurgicalKit"; ViewHeader = "Nome                             Usos  Tempo de Atraso Desidratacao   Rec. HP  Custo Dur.  Espaco(HxV)"; ViewFormat = "{0,-32} {1,-5} {2,-15} {3,-14} {4,-8} {5,-11} {6,-12}"; Properties = @( [PSCustomObject]@{ PropName="Uses"; DisplayName="Usos" }, [PSCustomObject]@{ PropName="Delay"; DisplayName="Tempo de Atraso" }, [PSCustomObject]@{ PropName="Dehydration"; DisplayName="Desidratacao" }, [PSCustomObject]@{ PropName="HPRecovery"; DisplayName="Recuperacao HP" }, [PSCustomObject]@{ PropName="DurabilityCost"; DisplayName="Custo Durabilidade" }, [PSCustomObject]@{ PropName="Space"; DisplayName="Espaco" } ) }
    "Nebulizers" = @{ AddItemMenuName = "Um novo Nebulizador"; EditViewMenuName = "Nebulizador"; PathName = "Nebulizers"; AddFunction = "Add-NewNebulizer"; EditFunction = "Add-NewNebulizer"; ViewHeader = "Nome                Usos  Tempo de Atraso  Custo Durabilidade"; ViewFormat = "{0,-18}  {1,-4}  {2,-15}  {3,-19}"; Properties = @( [PSCustomObject]@{ PropName="Uses"; DisplayName="Usos" }, [PSCustomObject]@{ PropName="Delay"; DisplayName="Tempo de Atraso" }, [PSCustomObject]@{ PropName="DurabilityCost"; DisplayName="Custo Durabilidade" } ) }
    "Medicalkit" = @{ AddItemMenuName = "Um novo Kit medico"; EditViewMenuName = "Kit medico"; PathName = "Medicalkit"; AddFunction = "Add-NewMedicalKit"; EditFunction = "Add-NewMedicalKit"; ViewHeader = "Nome                     Durabilidade  Desidratacao  Vel. Cura  Delay  Custo Dur.  Espaco(HxV)"; ViewFormat = "{0,-24} {1,-13} {2,-13} {3,-10} {4,-6} {5,-11} {6,-12}"; Properties = @( [PSCustomObject]@{ PropName="Durability"; DisplayName="Durabilidade" }, [PSCustomObject]@{ PropName="Dehydration"; DisplayName="Desidratacao" }, [PSCustomObject]@{ PropName="CureSpeed"; DisplayName="Velocidade Cura" }, [PSCustomObject]@{ PropName="Delay"; DisplayName="Delay" }, [PSCustomObject]@{ PropName="DurabilityCost"; DisplayName="Custo Durabilidade" }, [PSCustomObject]@{ PropName="Space"; DisplayName="Espaco" } ) }
    "Stimulants" = @{ AddItemMenuName = "Um novo Estimulante"; EditViewMenuName = "Estimulantes"; PathName = "Stimulants"; AddFunction = "Add-NewStimulant"; EditFunction = "Add-NewStimulant"; ViewHeader = "Nome                 Efeito Principal  Duracao  Desidratacao  Red. Energia  Delay"; ViewFormat = "{0,-20} {1,-17} {2,-8} {3,-13} {4,-13} {5,-5}"; Properties = @( [PSCustomObject]@{ PropName="MainEffect"; DisplayName="Efeito Principal" }, [PSCustomObject]@{ PropName="Duration"; DisplayName="Duracao" }, [PSCustomObject]@{ PropName="Dehydration"; DisplayName="Desidratacao" }, [PSCustomObject]@{ PropName="EnergyReduction"; DisplayName="Reducao Energia" }, [PSCustomObject]@{ PropName="Delay"; DisplayName="Delay" } ) }
    "Throwables" = @{ AddItemMenuName = "Um novo Arremessavel"; EditViewMenuName = "Arremessaveis"; PathName = "Throwables"; AddFunction = "Add-NewThrowable"; EditFunction = "Add-NewThrowable"; ViewHeader = "Nome                      Delay Explosao  Alcance     Dano Blind  Penetracao   Fragmentos   Tipo Frags.     Tempo Efeito"; ViewFormat = "{0,-23}   {1,-14}  {2,-10}  {3,-10}  {4,-11}  {5,-11}  {6,-14}  {7,-12}"; }
    "Beverages" = @{ AddItemMenuName = "Uma nova Bebida"; EditViewMenuName = "Bebidas"; PathName = "Beverages"; AddFunction = "Add-NewBeverage"; EditFunction = "Add-NewBeverage"; ViewHeader = "Nome                                Hidratacao  Energia  Delay  Rec. Stamina  Espaco(HxV)"; ViewFormat = "{0,-34}  {1,-10}  {2,-7}  {3,-5}  {4,-12}  {5,-6}"; Properties = @( [PSCustomObject]@{ PropName="Hydration"; DisplayName="Hidratacao" }, [PSCustomObject]@{ PropName="Energy"; DisplayName="Energia" }, [PSCustomObject]@{ PropName="Delay"; DisplayName="Delay" }, [PSCustomObject]@{ PropName="StaminaRecovery"; DisplayName="Recuperacao Stamina" }, [PSCustomObject]@{ PropName="Space"; DisplayName="Espaco" } ) }
    "Food" = @{ AddItemMenuName = "Uma nova Comida"; EditViewMenuName = "Comidas"; PathName = "Food"; AddFunction = "Add-NewFood"; EditFunction = "Add-NewFood"; ViewHeader = "Nome                                Hidratacao  Energia  Delay  Rec. Stamina  Espaco(HxV)"; ViewFormat = "{0,-34}  {1,-10}  {2,-7}  {3,-5}  {4,-12}  {5,-6}"; Properties = @( [PSCustomObject]@{ PropName="Hydration"; DisplayName="Hidratacao" }, [PSCustomObject]@{ PropName="Energy"; DisplayName="Energia" }, [PSCustomObject]@{ PropName="Delay"; DisplayName="Delay" }, [PSCustomObject]@{ PropName="StaminaRecovery"; DisplayName="Recuperacao Stamina" }, [PSCustomObject]@{ PropName="Space"; DisplayName="Espaco" } ) }
    "Helmets" = @{ AddItemMenuName = "Um novo Capacete"; EditViewMenuName = "Capacetes"; PathName = "Helmets"; AddFunction = "Add-NewHelmet"; EditFunction = "Add-NewHelmet"; ViewHeader = "Nome do Capacete             Peso  Dur.  Cl  Material        Bloqueio  Vel.M  Ergo   Area Protegida    Ricoch  Captad  Red.Ru  Acessorio"; ViewFormat = "{0,-28} {1,-5} {2,-5} {3,-3} {4,-15} {5,-9} {6,-6} {7,-6} {8,-17} {9,-7} {10,-7} {11,-7} {12,-9}"; }
    "Bodyarmors" = @{ AddItemMenuName = "Um novo colete balistico"; EditViewMenuName = "Coletes Balisticos"; PathName = "Bodyarmors"; AddFunction = "Add-NewBodyArmor"; EditFunction = "Add-NewBodyArmor"; ViewHeader = "Nome do Colete                             Peso   Cl Dur.    Material        Vel.M  Ergo   Area Protegida"; ViewFormat = "{0,-42} {1,-6} {2,-2} {3,-7} {4,-15} {5,-6} {6,-6} {7,-41}"; }
    "Armoredrigs" = @{ AddItemMenuName = "Um novo colete blindado"; EditViewMenuName = "Coletes Blindados"; PathName = "Armoredrigs"; AddFunction = "Add-NewArmoredRig"; EditFunction = "Add-NewArmoredRig"; ViewHeader = "Nome do colete blindado          Peso   Cl Dur.    Material        Vel.M  Ergo   Esp  Area Protegida                                 Conj d. blocos(HxV)"; ViewFormat = "{0,-32} {1,-6} {2,-2} {3,-7} {4,-15} {5,-6} {6,-6} {7,-4} {8,-46} {9,-20}"; }
    "Masks" = @{ AddItemMenuName = "Uma nova mascara"; EditViewMenuName = "Mascaras"; PathName = "Masks"; AddFunction = "Add-NewMask"; EditFunction = "Add-NewMask"; ViewHeader = "Nome da mascara                        Peso   Dur.   Cl   Material        Chance de Ricochete"; ViewFormat = "{0,-38} {1,-6} {2,-6} {3,-4} {4,-15} {5,-19}"; }
    "Gasmasks" = @{ AddItemMenuName = "Uma nova mascara de gas"; EditViewMenuName = "Mascaras de Gas"; PathName = "Gasmasks"; AddFunction = "Add-NewGasMask"; EditFunction = "Add-NewGasMask"; ViewHeader = "Nome da mascara de gas                 Peso   Dur.   Anti-Veneno   Anti-Flash"; ViewFormat = "{0,-36} {1,-6} {2,-6} {3,-13} {4,-12}"; }
    "Headsets" = @{ AddItemMenuName = "Um novo fone de ouvido"; EditViewMenuName = "Fones de Ouvido"; PathName = "Headsets"; AddFunction = "Add-NewHeadset"; EditFunction = "Add-NewHeadset"; ViewHeader = "Nome do fone de ouvido            Peso   Captador de Som   Reducao de Ruido"; ViewFormat = "{0,-32} {1,-6} {2,-17} {3,-16}"; }
    "Unarmoredrigs" = @{ AddItemMenuName = "Um novo colete nao blindado"; EditViewMenuName = "Coletes Nao Blindados"; PathName = "Unarmoredrigs"; AddFunction = "Add-NewUnarmoredRig"; EditFunction = "Add-NewUnarmoredRig"; ViewHeader = "Nome do colete nao blindado                Peso   Espaco Desdobrada Dobrada Conj d. blocos(HxV)"; ViewFormat = "{0,-42} {1,-6} {2,-6} {3,-10} {4,-7} {5,-20}"; }
    "Backpacks" = @{ AddItemMenuName = "Uma nova mochila"; EditViewMenuName = "Mochilas"; PathName = "Backpacks"; AddFunction = "Add-NewBackpack"; EditFunction = "Add-NewBackpack"; ViewHeader = "Nome da mochila                      Peso   Espaco Desdobrada Dobrada Conj d. blocos"; ViewFormat = "{0,-36} {1,-6} {2,-6} {3,-10} {4,-7} {5,-20}"; }
}

$global:AddItemMenuOrder = @(
    "Ammo", "Bandages", "Beverages", "Food", "Helmets", "Medicalkit", 
    "Nebulizers", "Painkillers", "Stimulants", "Surgicalkit", "Throwables", "Weapons"
)

$global:EditViewMenuOrder = @(
    "Painkillers", "Weapons", "Throwables", "Bandages", "Beverages", "Helmets",
    "Food", "Stimulants", "Surgicalkit", "Medicalkit", "Nebulizers"
)
$global:criterioOrdenacao = "Alfabetico"
$global:ordemAtual = "Decrescente"

function Initialize-Database {
    if (-not (Test-Path -Path $global:databasePath)) { New-Item -Path $global:databasePath -ItemType Directory | Out-Null }
    $allFolders = @(
        "Ammo", "Weapons", "Painkillers", "Bandages", "Surgicalkit", "Nebulizers", "Medicalkit", 
        "Stimulants", "Throwables", "Beverages", "Food", "Helmets", "Bodyarmors", "Armoredrigs", "Masks", "Gasmasks", "Headsets", "Unarmoredrigs", "Backpacks"
    )
    foreach ($folder in $allFolders) {
        $path = Join-Path -Path $global:databasePath -ChildPath $folder
        if (-not (Test-Path -Path $path)) { New-Item -Path $path -ItemType Directory | Out-Null }
    }
    foreach ($caliber in $defaultCalibers) {
        $caliberPath = Join-Path -Path $AmmoPath -ChildPath $caliber
        if (-not (Test-Path -Path $caliberPath)) { New-Item -Path $caliberPath -ItemType Directory | Out-Null }
    }
}

function Get-ClipboardText {
    try {
        if ($PSVersionTable.PSVersion.Major -ge 5) { return Get-Clipboard -Raw -Format Text }
        else { Add-Type -AssemblyName System.Windows.Forms; return [System.Windows.Forms.Clipboard]::GetText() }
    } catch { return $null }
}

function Read-InputWithPaste {
    param ([string]$Prompt, [string]$Title, [string]$AdditionalInfo = "", [switch]$EnableStandardNav, [int]$MaxLength = 0)
    
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize; (Get-Host).UI.RawUI.CursorSize = 0
    $inputText = ""; $position = 0
    do {
        Clear-Host; Write-Host "=== $Title ==="; Write-Host; Write-Host $Prompt
        if (-not [string]::IsNullOrEmpty($AdditionalInfo)) { Write-Host $AdditionalInfo }
        Write-Host; Write-Host "> $inputText" -NoNewline
        if ($position -le $inputText.Length) { Write-Host (" " * ($inputText.Length - $position)) -NoNewline }
        Write-Host "_" -ForegroundColor Yellow; Write-Host; Write-Host "Pressione " -NoNewline
        Write-Host "F1" -ForegroundColor Blue -NoNewline; Write-Host " para colar o texto"
        if ($EnableStandardNav) {
            Write-Host "Pressione " -NoNewline; Write-Host "F2" -ForegroundColor Yellow -NoNewline; Write-Host " para voltar"
            Write-Host "Pressione " -NoNewline; Write-Host "F3" -ForegroundColor Red -NoNewline; Write-Host " para voltar ao menu principal"
        } else { Write-Host "Pressione " -NoNewline; Write-Host "F2" -ForegroundColor Red -NoNewline; Write-Host " para cancelar" }
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        switch ($key.VirtualKeyCode) {
            112 { $clipText = Get-ClipboardText; if ($clipText) { $inputText = $inputText.Insert($position, $clipText); $position += $clipText.Length }; continue }
            113 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; if ($EnableStandardNav) { return $global:ACTION_BACK } else { return $null } }
            114 { if ($EnableStandardNav) { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $global:ACTION_MAIN_MENU } }
            13 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $inputText }
            8 { if ($position -gt 0) { $inputText = $inputText.Remove($position - 1, 1); $position-- } }
            default {
                if ($MaxLength -gt 0 -and $inputText.Length -ge $MaxLength) { continue }
                if ($key.Character -gt 0) { $inputText = $inputText.Insert($position, $key.Character); $position++ }
            }
        }
    } while ($true)
}

function Get-InputWithFilter {
    param ([string]$Prompt, [string]$Title, [string]$Mode, [switch]$EnableStandardNav, [int]$MaxLength = 0, [int]$MaxValue = 0) 
    
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize; (Get-Host).UI.RawUI.CursorSize = 0
    $inputText = ""; $position = 0; $allowEnter = $false
    do {
        Clear-Host; Write-Host "=== $Title ==="; Write-Host; Write-Host $Prompt; Write-Host
        Write-Host "> $inputText" -NoNewline; Write-Host "_" -ForegroundColor Yellow; Write-Host
        Write-Host "Pressione " -NoNewline; Write-Host "F1" -ForegroundColor Blue -NoNewline; Write-Host " para colar texto"
        if ($EnableStandardNav) { Write-Host "Pressione " -NoNewline; Write-Host "F2" -ForegroundColor Yellow -NoNewline; Write-Host " para voltar"; Write-Host "Pressione " -NoNewline; Write-Host "F3" -ForegroundColor Red -NoNewline; Write-Host " para voltar ao menu principal" }
        else { Write-Host "Pressione " -NoNewline; Write-Host "F2" -ForegroundColor Red -NoNewline; Write-Host " para cancelar" }
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        switch ($key.VirtualKeyCode) {
            112 { 
                $clipText = Get-ClipboardText
                if ($clipText) { $inputText = $clipText; $position = $inputText.Length }
            }
            113 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; if ($EnableStandardNav) { return $global:ACTION_BACK } else { return $null } }
            114 { if ($EnableStandardNav) { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $global:ACTION_MAIN_MENU } }
            13 { if ($allowEnter) { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $inputText }; continue }
            8 { 
                if ($position -gt 0) { $inputText = $inputText.Remove($position - 1, 1); $position-- }
            }
            default {
                if ($MaxLength -gt 0 -and $inputText.Length -ge $MaxLength) { continue }
                $char = $key.Character; $newText = $inputText.Insert($position, $char); $isValid = $false
                
                switch ($Mode) {
                    'numeric_2-9_max_value' {
                        if ($inputText.Length -eq 0) { if ($char -match '[2-9]') { $isValid = $true } } 
                        else { if ($char -match '[0-9]') { $isValid = $true } }
                        if ($isValid -and $MaxValue -gt 0) { if ([int]$newText -gt $MaxValue) { $isValid = $false } }
                    }
                    'precision' { if ($char -eq '+') { $isValid = ($inputText.Length -eq 0) } elseif ($char -match '[0-9]') { $isValid = ($inputText -match '^\+$' -or $inputText -match '^\+[0-9]+$') } }
                    'recoil' { if ($char -match '[+-]') { $isValid = ($inputText.Length -eq 0) } elseif ($char -eq '0') { $isValid = ($inputText.Length -eq 0) } elseif ($char -match '[0-9]') { $isValid = ($inputText -match '^[+-]$' -or $inputText -match '^[+-][0-9]+$') } }
                    'numeric' { $isValid = ($char -match '[0-9]') }
                    'penetration' { $isValid = ($char -match '[0-7]' -and $inputText.Length -eq 0) }
                    'armor' { if ($char -eq '.') { $isValid = ($inputText -match '^[0-9]+$' -and $inputText -notmatch '\.') } else { $isValid = ($char -match '[0-9]') } }
                    'numeric_1_9' { if ($char -match '[1-9]') { $isValid = $true } }
                    'numeric_1_4' { if ($char -match '[1-4]') { $isValid = $true } }
                    'numeric_1_6' { if ($char -match '[1-6]') { $isValid = $true } }
                    'numeric_no_leading_zero' { if ($inputText.Length -eq 0) { if ($char -match '[1-9]') { $isValid = $true } } else { if ($char -match '[0-9]') { $isValid = $true } } }
                    'numeric_allow_zero_single' { if ($inputText.Length -eq 0) { if ($char -match '[0-9]') { $isValid = $true } } elseif ($inputText -eq '0') { $isValid = $false } else { if ($char -match '[0-9]') { $isValid = $true } } }
                    'dehydration_strict' { if ($inputText.Length -eq 0) { if ($char -eq '-') { $isValid = $true } } else { if ($inputText.StartsWith('-') -and $char -match '[0-9]') { $numericPart = $inputText.Substring(1) + $char; if ([int]$numericPart -le 100) { $isValid = $true } } } }
                    'energy_negative_only' { if ($inputText.Length -eq 0) { if ($char -eq '-') { $isValid = $true } } else { if ($inputText.StartsWith('-') -and $char -match '[0-9]') { $isValid = $true } } }
                    'decimal_fixed' { if ($char -eq '.' -and $inputText.Length -gt 0 -and $inputText -notmatch '\.') { $isValid = $true } elseif ($char -match '[0-9]') { if ($newText -match '^\d{1,2}\.\d$' -or $newText -match '^\d{1,2}$') { $isValid = $true } } }
                    'hydration_strict' { if ($newText -eq '0') { $isValid = $true } elseif ($newText -match '^[+-]$') { $isValid = $true } elseif ($newText -match '^[+-][1-9][0-9]*$') { $numericPart = [int]$newText.Substring(1); if ($numericPart -le 100) { $isValid = $true } } }
                    'decimal_1_2' { if ($inputText.Length -eq 0) { if ($char -match '[0-9]') { $isValid = $true } } elseif ($inputText.Length -eq 1) { if ($char -eq '.') { $isValid = $true } } elseif ($inputText.Length -in 2,3) { if ($char -match '[0-9]') { $isValid = $true } } }
                    'decimal_2_1_fixed' { if ($inputText.Length -eq 0) { if ($char -match '[1-9]') { $isValid = $true } } elseif ($inputText.Length -eq 1) { if ($char -match '[0-9]') { $isValid = $true } } elseif ($inputText.Length -eq 2) { if ($char -eq '.') { $isValid = $true } } elseif ($inputText.Length -eq 3) { if ($char -eq '0') { $isValid = $true } } }
                    'percentage_negative' { if ($inputText.Length -eq 0) { if ($char -eq '-') { $isValid = $true } } elseif ($inputText.Length -eq 1) { if ($char -match '[1-9]') { $isValid = $true } } elseif ($inputText.Length -eq 2) { if ($char -match '[0-9]') { $isValid = $true } } }
                    'numeric_negative_no_leading_zero' { if ($inputText.Length -eq 0) { if ($char -eq '-') { $isValid = $true } } elseif ($inputText.Length -eq 1) { if ($char -match '[1-9]') { $isValid = $true } } elseif ($inputText.Length -eq 2) { if ($char -match '[0-9]') { $isValid = $true } } }
                    'decimal_2_2' { if ($char -eq '.' -and $inputText.Length -gt 0 -and $inputText -notmatch '\.') { $isValid = $true } elseif ($char -match '[0-9]') { if ($newText -match '^\d{1,2}(\.\d{0,2})?$') { $isValid = $true } } }
                    'decimal_3_1_fixed' { if ($newText -match '^\d{1,3}(\.0?)?$') { $isValid = $true } }
                    'decimal_3_2' { if ($char -eq '.' -and $inputText.Length -gt 0 -and $inputText -notmatch '\.') { $isValid = $true } elseif ($char -match '[0-9]') { if ($newText -match '^\d{1,3}(\.\d{0,2})?$') { $isValid = $true } } }
                    'decimal_durability_fixed' { if ($inputText.Length -eq 0 -and $char -match '[1-9]') { $isValid = $true } elseif ($inputText.Length -in 1,2 -and $char -match '[0-9]' -and $inputText -notmatch '\.') { $isValid = $true } elseif ($inputText.Length -in 2,3 -and $char -eq '.' -and $inputText -notmatch '\.') { $isValid = $true } elseif ($inputText -match '^\d{2,3}\.$' -and $char -eq '0') { $isValid = $true } }
                    'decimal_weight' { if ($newText -match '^[1-9]\d{0,1}(\.\d{0,2})?$') { $isValid = $true } }
                    'decimal_mask_weight' {
                        switch ($inputText.Length) {
                            0 { if ($char -match '[0-9]') { $isValid = $true } }
                            1 { if ($char -eq '.') { $isValid = $true } }
                            2 { if ($char -match '[0-9]') { $isValid = $true } }
                            3 { if ($char -eq '0') { $isValid = $true } }
                        }
                    }
                    'decimal_mask_durability' {
                        switch ($inputText.Length) {
                            0 { if ($char -match '[0-9]') { $isValid = $true } }
                            1 { if ($char -match '[0-9]') { $isValid = $true } }
                            2 { if ($char -eq '.') { $isValid = $true } }
                            3 { if ($char -eq '0') { $isValid = $true } }
                        }
                    }
                    'numeric_2_digits_no_leading_zero' { if ($inputText.Length -eq 0) { if ($char -match '[1-9]') { $isValid = $true } } elseif ($inputText.Length -eq 1) { if ($char -match '[0-9]') { $isValid = $true } } }
                    'decimal_gasmask_weight' { if ($newText -match '^0(\.\d{0,2})?$') { $isValid = $true } }
                    'decimal_headset_weight' { if ($newText -match '^0(\.\d{0,2})?$') { $isValid = $true } }
                    'decimal_unarmored_weight' { if ($newText -match '^\d(\.\d{0,2})?$') { $isValid = $true } }
                    'decimal_backpack_weight' { if ($newText -match '^\d{1,2}(\.\d{0,2})?$') { $isValid = $true } }
                }
                if ($isValid) { $inputText = $newText; $position++ }
            }
        }
        
        $allowEnter = $false
        switch ($Mode) {
            'numeric_2-9_max_value' { if ($inputText -match '^[2-9]\d*$') { $allowEnter = $true } }
            'precision' { $allowEnter = ($inputText -match '^\+[0-9]+$' -and $inputText -ne '+') }
            'recoil' { $allowEnter = ($inputText -match '^([+-][0-9]+|0)$' -and $inputText -notmatch '^[+-]$') }
            'numeric' { $allowEnter = ($inputText -match '^[0-9]+$') }
            'penetration' { $allowEnter = ($inputText -match '^[0-7]$') }
            'armor' { $allowEnter = ($inputText -match '^[0-9]+(\.[0-9]*)?$' -and $inputText -ne '.') }
            'numeric_1_9' { if ($inputText -match '^[1-9]$') { $allowEnter = $true } }
            'numeric_1_4' { if ($inputText -match '^[1-4]$') { $allowEnter = $true } }
            'numeric_1_6' { if ($inputText -match '^[1-6]$') { $allowEnter = $true } }
            'numeric_no_leading_zero' { if ($inputText -match '^[1-9][0-9]*$') { $allowEnter = $true } }
            'numeric_allow_zero_single' { if ($inputText -match '^0$|^[1-9]\d?$') { $allowEnter = $true } }
            'dehydration_strict' { if ($inputText -match '^-[0-9]+$') { $allowEnter = $true } }
            'energy_negative_only' { if ($inputText -match '^-[0-9]+$') { $allowEnter = $true } }
            'decimal_fixed' { if ($inputText -match '^\d{1,2}\.\d$') { $allowEnter = $true } }
            'hydration_strict' { if ($inputText -eq '0' -or $inputText -match '^[+-][1-9][0-9]*$') { $allowEnter = $true } }
            'decimal_1_2' { if ($inputText -match '^\d\.\d{2}$') { $allowEnter = $true } }
            'decimal_2_1_fixed' { if ($inputText -match '^[1-9]\d\.[0]$') { $allowEnter = $true } }
            'percentage_negative' { if ($inputText -match '^-[1-9]\d?$') { $allowEnter = $true } }
            'numeric_negative_no_leading_zero' { if ($inputText -match '^-[1-9]\d?$') { $allowEnter = $true } }
            'decimal_2_2' { $allowEnter = ($inputText -match '^\d{1,2}(\.\d{1,2})?$' -and $inputText -notmatch '\.$') }
            'decimal_3_1_fixed' { $allowEnter = ($inputText -match '^\d{1,3}\.0$') }
            'decimal_3_2' { $allowEnter = ($inputText -match '^\d{1,3}(\.\d{1,2})?$' -and $inputText -notmatch '\.$') }
            'decimal_durability_fixed' { $allowEnter = ($inputText -match '^[1-9]\d{1,2}\.0$') }
            'decimal_weight' { $allowEnter = ($inputText -match '^[1-9]\d{0,1}\.\d{2}$') }
            'decimal_mask_weight' { $allowEnter = ($inputText -match '^\d\.\d0$') }
            'decimal_mask_durability' { $allowEnter = ($inputText -match '^[0-9]{2}\.0$') }
            'numeric_2_digits_no_leading_zero' { $allowEnter = ($inputText -match '^[1-9]\d$') }
            'decimal_gasmask_weight' { $allowEnter = ($inputText -match '^0\.\d{2}$') }
            'decimal_headset_weight' { $allowEnter = ($inputText -match '^0\.\d{2}$') }
            'decimal_unarmored_weight' { $allowEnter = ($inputText -match '^\d\.\d{2}$' -and $inputText -notmatch '\.$') }
            'decimal_backpack_weight' { $allowEnter = ($inputText -match '^\d{1,2}\.\d{2}$' -and $inputText -notmatch '\.$') }
        }
    } while ($true)
}

function Get-DanoBase {
    param ([switch]$EnableStandardNav)
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize; (Get-Host).UI.RawUI.CursorSize = 0; $inputString = ""; $position = 0; $allowEnter = $false
    do {
        Clear-Host; Write-Host "=== Adicionar Nova Municao ==="; Write-Host; Write-Host "Qual e o dano base?"; Write-Host "(Formatos: 274 ou 26x8)"; Write-Host
        Write-Host "> $inputString" -NoNewline; if ($inputString.Length -ge $position) { Write-Host (" " * ($inputString.Length - $position)) -NoNewline }; Write-Host "_" -ForegroundColor Yellow; Write-Host
        Write-Host "Pressione " -NoNewline; Write-Host "F1" -ForegroundColor Blue -NoNewline; Write-Host " para colar o texto"
        if ($EnableStandardNav) { Write-Host "Pressione " -NoNewline; Write-Host "F2" -ForegroundColor Yellow -NoNewline; Write-Host " para voltar"; Write-Host "Pressione " -NoNewline; Write-Host "F3" -ForegroundColor Red -NoNewline; Write-Host " para voltar ao menu principal" }
        else { Write-Host "Pressione " -NoNewline; Write-Host "F2" -ForegroundColor Red -NoNewline; Write-Host " para cancelar" }
        $allowEnter = $false
        if ($inputString -match '^\d{1,3}$' -or $inputString -match '^\d{2}[xX]\d$') {
            $allowEnter = $true
        }
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        switch ($key.VirtualKeyCode) {
            13 { # Enter
                if ($allowEnter) {
                    if ($inputString -match '(\d+)\s*[xX×]\s*(\d+)') { $resultado = [int]$Matches[1] * [int]$Matches[2]; $inputString = "$inputString ($resultado)" }
                    (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $inputString
                }
                # Se não for permitido, o Enter é ignorado e o loop continua
            }
            112 { # F1 - Colar (Nota: a colagem não será validada pelas novas regras)
                $clipText = Get-ClipboardText; if (-not [string]::IsNullOrEmpty($clipText)) { if ($clipText -match '^[\dxX]+$') { $inputString = $inputString.Insert($position, $clipText); $position += $clipText.Length } }; continue 
            }
            113 { # F2
                 if ($EnableStandardNav) { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $global:ACTION_BACK }
                 else { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $null }
            }
            114 { # F3
                if ($EnableStandardNav) { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $global:ACTION_MAIN_MENU }
            }
            8 { if ($position -gt 0) { $inputString = $inputString.Remove($position - 1, 1); $position-- } }
            37 { if ($position -gt 0) { $position-- } }
            39 { if ($position -lt $inputString.Length) { $position++ } }
            default {
                if ($key.Character -gt 0) {
                    $char = $key.Character
                    $isValid = $false
                    if ($char -match '[0-9]') {
                        if ($inputString -like '*[xX]*') {
                            # Se já tem 'x', só permite 1 dígito depois
                            $parts = $inputString -split '[xX]'
                            if ($parts[1].Length -lt 1) { $isValid = $true }
                        } else {
                            # Se não tem 'x', permite até 3 dígitos no total
                            if ($inputString.Length -lt 3) { $isValid = $true }
                        }
                    } elseif ($char -match '[xX]') {
                        # Só permite 'x' se não houver outro 'x' e se for o 3º caractere
                        if (-not ($inputString -like '*[xX]*') -and $inputString.Length -eq 2) {
                            $isValid = $true
                        }
                    }
                    if ($isValid) {
                        $inputString = $inputString.Insert($position, $char)
                        $position++
                    }
                }
            }
        }
    } while ($true)
}

function Get-SpaceUsage {
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize
    (Get-Host).UI.RawUI.CursorSize = 0
    :spaceLoop while ($true) {
        $horizontal = Get-InputWithFilter -Prompt "Quantos blocos horizontais o item ocupa? (1-4)" -Title "Espaco Horizontal" -Mode 'numeric_1_4' -MaxLength 1 -EnableStandardNav
        if ($horizontal -eq $global:ACTION_BACK) { 
            (Get-Host).UI.RawUI.CursorSize = $originalCursorSize
            return $global:ACTION_BACK 
        }
        if ($horizontal -eq $global:ACTION_MAIN_MENU) { 
            (Get-Host).UI.RawUI.CursorSize = $originalCursorSize
            return $global:ACTION_MAIN_MENU 
        }
        if (-not $horizontal) { continue spaceLoop }
        $vertical = Get-InputWithFilter -Prompt "Quantos blocos verticais o item ocupa? (1-4)" -Title "Espaco Vertical" -Mode 'numeric_1_4' -MaxLength 1 -EnableStandardNav
        if ($vertical -eq $global:ACTION_BACK) { continue spaceLoop }
        if ($vertical -eq $global:ACTION_MAIN_MENU) { 
            (Get-Host).UI.RawUI.CursorSize = $originalCursorSize
            return $global:ACTION_MAIN_MENU 
        }
        if (-not $vertical) { continue spaceLoop }
        (Get-Host).UI.RawUI.CursorSize = $originalCursorSize
        return "${horizontal}x${vertical}"
    }
}

function Get-SizeInput {
    param ([string]$Title)
    $step = 1
    $horizontal = $null
    while ($true) {
        $result = $null
        switch ($step) {
            1 { $result = Get-InputWithFilter -Prompt "Quantos blocos horizontais o item ocupa? (1-9)" -Title "$Title (1/2)" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav }
            2 { $result = Get-InputWithFilter -Prompt "Quantos blocos verticais o item ocupa? (1-9)" -Title "$Title (2/2)" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav }
        }
        if ($result -eq $global:ACTION_MAIN_MENU) { return $global:ACTION_MAIN_MENU }
        if ($result -eq $global:ACTION_BACK) {
            if ($step -gt 1) {
                $step-- # Volta do passo 2 (vertical) para o 1 (horizontal)
                continue
            } else {
                return $global:ACTION_BACK # Se estiver no passo 1, sai da função
            }
        }
        if (-not $result) { continue }
        switch ($step) {
            1 { $horizontal = $result }
            2 { return "${horizontal}x${result}" } # Conclui e retorna o valor final
        }
        $step++
    }
}

function Get-InternalSetLayout {
    param ([string]$ItemTypeName)
    $step = 1
    $totalSets = 0
    $setsCompleted = 0
    $setLayouts = @()
    $temp_h = $null
    $currentLayout = ""
    while ($true) {
        if ($step -gt 1 -and $setsCompleted -ge $totalSets) {
            return $setLayouts -join ", "
        }
        $result = $null
        switch ($step) {
            1 { $result = Get-InputWithFilter -Prompt "Quantos conjuntos de blocos internos o $ItemTypeName possui?" -Title "Conjuntos de Blocos" -Mode 'numeric' -MaxLength 2 -EnableStandardNav }
            2 { $result = Get-InputWithFilter -Prompt "Conjunto $($setsCompleted+1)/$($totalSets): Medida horizontal?" -Title "Definindo Blocos" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav }
            3 { $result = Get-InputWithFilter -Prompt "Conjunto $($setsCompleted+1)/$($totalSets): Medida vertical?" -Title "Definindo Blocos" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav }
            4 {
                if (($setsCompleted + 1) -lt $totalSets) {
                    $result = Show-Menu -Title "Existem outros conjuntos com essa mesma medida ($currentLayout)?" -Options @("Sim", "Nao") -EnableBackButton -EnableMainMenuButton
                } else {
                    $result = "ULTIMO_ITEM" 
                }
            }
            5 {
                $remainingSets = $totalSets - $setsCompleted
                $result = Get-InputWithFilter -Prompt "Quantas vezes no total aparece esse conjunto? (Conj. restantes: $remainingSets)" -Title "Repetir Conjunto" -Mode 'numeric_2-9_max_value' -MaxLength 2 -EnableStandardNav -MaxValue $remainingSets
            }
        }
        if ($result -eq $global:ACTION_MAIN_MENU) { return $global:ACTION_MAIN_MENU }
        if ($result -eq $global:ACTION_BACK) {
            if ($step -gt 1) {
                if ($step -eq 2 -and $setsCompleted -gt 0) { $setsCompleted-- } 
                $step--
            } else { return $global:ACTION_BACK }
            continue
        }
        if (-not $result) { continue }
        switch ($step) {
            1 { $totalSets = [int]$result }
            2 { $temp_h = $result }
            3 { $currentLayout = "${temp_h}x${result}" }
            4 {
                if ($result -eq 'Nao' -or $result -eq "ULTIMO_ITEM") {
                    $setLayouts += $currentLayout
                    $setsCompleted++
                    $step = 1 
                }
            }
            5 {
                $repeatCount = [int]$result
                $remainingSets = $totalSets - $setsCompleted
                if ($repeatCount -gt 1 -and $repeatCount -le $remainingSets) {
                    $setLayouts += "($($repeatCount))$currentLayout"
                    $setsCompleted += $repeatCount
                } else { 
                    $setLayouts += $currentLayout
                    $setsCompleted++
                }
                $step = 1 
            }
        }
        $step++
    }
}

function Show-Menu {
    param (
        [string]$Title,
        [array]$Options,
        [string]$PromptText = "",
        [switch]$FilterEmpty = $false,
        [string]$Footer = "",
        [switch]$EnableBackButton = $false,
        [switch]$EnableMainMenuButton = $false,
        [switch]$FlickerFree = $false,
        [int]$InitialSelectedIndex = 0,
        [switch]$EnableF1BackButton = $false,
        [switch]$F1HelpOnTop = $false
    )
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize; (Get-Host).UI.RawUI.CursorSize = 0; $selectedIndex = $InitialSelectedIndex
    if ($FilterEmpty) {
        $validOptions = @(); foreach ($option in $Options) { $pathToCheck = Join-Path -Path $AmmoPath -ChildPath $option; if ((Get-ChildItem -Path $pathToCheck -Filter "*.txt" -File).Count -gt 0) { $validOptions += $option } }
        $Options = if ($validOptions.Count -eq 0) { @("Nenhum item encontrado", "Voltar") } else { $validOptions + "Voltar" }
    }
    if ($FlickerFree) {
        Clear-Host
        Write-Host "=== $Title ==="; Write-Host
        if (-not [string]::IsNullOrEmpty($PromptText)) {
            Write-Host $PromptText
            Write-Host
        }
        if ($EnableF1BackButton -and $F1HelpOnTop) {
            Write-Host "Pressione " -NoNewline; Write-Host "F1" -ForegroundColor Red -NoNewline; Write-Host " para voltar"; Write-Host
        }
        $startY = [Console]::CursorTop
        for ($i = 0; $i -lt $Options.Count; $i++) {
            if ($i -eq $selectedIndex) { Write-Host "> $($Options[$i])" -ForegroundColor Green } else { Write-Host "  $($Options[$i])" }
        }
        if ($Footer) { Write-Host; Write-Host $Footer }
        
        if ($EnableF1BackButton -and -not $F1HelpOnTop) {
            Write-Host; Write-Host "Pressione " -NoNewline; Write-Host "F1" -ForegroundColor Red -NoNewline; Write-Host " para voltar"
        }
        if ($EnableBackButton -or $EnableMainMenuButton) { Write-Host }
        if ($EnableBackButton) { Write-Host "Pressione " -NoNewline; Write-Host "F2" -ForegroundColor Yellow -NoNewline; Write-Host " para voltar" }
        if ($EnableMainMenuButton) { Write-Host "Pressione " -NoNewline; Write-Host "F3" -ForegroundColor Red -NoNewline; Write-Host " para voltar ao menu principal" }
        do {
            if (($startY + $selectedIndex) -ge [Console]::WindowHeight) {
                Clear-Host; Write-Host "=== $Title ==="; Write-Host
                if (-not [string]::IsNullOrEmpty($PromptText)) { Write-Host $PromptText; Write-Host }
                if ($EnableF1BackButton -and $F1HelpOnTop) { Write-Host "Pressione F1 para voltar"; Write-Host }
                $startY = [Console]::CursorTop
                for ($i = 0; $i -lt $Options.Count; $i++) { if ($i -eq $selectedIndex) { Write-Host "> $($Options[$i])" -ForegroundColor Green } else { Write-Host "  $($Options[$i])" } }
                if ($Footer) { Write-Host; Write-Host $Footer }
                if ($EnableF1BackButton -and -not $F1HelpOnTop) { Write-Host; Write-Host "Pressione F1 para voltar" }
                if ($EnableBackButton) { Write-Host "Pressione F2 para voltar" }
                if ($EnableMainMenuButton) { Write-Host "Pressione F3 para voltar ao menu principal" }
            }
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
            $oldIndex = $selectedIndex
            switch ($key) {
                38 { if ($selectedIndex -gt 0) { $selectedIndex-- } else { continue } }
                40 { if ($selectedIndex -lt ($Options.Count - 1)) { $selectedIndex++ } else { continue } }
                13 { 
                    (Get-Host).UI.RawUI.CursorSize = $originalCursorSize
                    if ($Options[$selectedIndex] -eq "Voltar" -or $Options[$selectedIndex] -eq "Nenhum item encontrado") { return $null }
                    return $Options[$selectedIndex]
                }
                112 { 
                    if ($EnableF1BackButton) { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $global:ACTION_BACK }
                    if ($Footer -like "*F1*") { Add-NewCaliber } 
                }
                113 { 
                    if ($EnableBackButton) { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $global:ACTION_BACK }
                    if ($Footer -like "*F2*") { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $null }
                }
                114 { 
                    if ($EnableMainMenuButton) { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $global:ACTION_MAIN_MENU }
                }
                default { continue } 
            }
            if (($startY + $oldIndex) -lt [Console]::WindowHeight -and ($startY + $selectedIndex) -lt [Console]::WindowHeight) {
                [Console]::SetCursorPosition(0, $startY + $oldIndex)
                Write-Host "  $($Options[$oldIndex])"
                [Console]::SetCursorPosition(0, $startY + $selectedIndex)
                Write-Host "> $($Options[$selectedIndex])" -ForegroundColor Green
            }
        } while ($true)
    } else { 
        do {
            Clear-Host; Write-Host "=== $Title ==="; Write-Host
            if (-not [string]::IsNullOrEmpty($PromptText)) {
                Write-Host $PromptText
                Write-Host
            }
            if ($EnableF1BackButton -and $F1HelpOnTop) {
                Write-Host "Pressione " -NoNewline; Write-Host "F1" -ForegroundColor Red -NoNewline; Write-Host " para voltar"; Write-Host
            }
            for ($i = 0; $i -lt $Options.Count; $i++) { if ($i -eq $selectedIndex) { Write-Host "> $($Options[$i])" -ForegroundColor Green } else { Write-Host "  $($Options[$i])" } }
            if ($Footer) { Write-Host; Write-Host $Footer }
            if ($EnableF1BackButton -and -not $F1HelpOnTop) {
                Write-Host; Write-Host "Pressione " -NoNewline; Write-Host "F1" -ForegroundColor Red -NoNewline; Write-Host " para voltar"
            }
            if ($EnableBackButton -or $EnableMainMenuButton) { Write-Host }
            if ($EnableBackButton) { Write-Host "Pressione " -NoNewline; Write-Host "F2" -ForegroundColor Yellow -NoNewline; Write-Host " para voltar" }
            if ($EnableMainMenuButton) { Write-Host "Pressione " -NoNewline; Write-Host "F3" -ForegroundColor Red -NoNewline; Write-Host " para voltar ao menu principal" }
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
            switch ($key) {
                38 { if ($selectedIndex -gt 0) { $selectedIndex-- } }; 40 { if ($selectedIndex -lt ($Options.Count - 1)) { $selectedIndex++ } }
                13 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; if ($Options[$selectedIndex] -eq "Voltar" -or $Options[$selectedIndex] -eq "Nenhum item encontrado") { return $null } return $Options[$selectedIndex] }
                112 { if ($EnableF1BackButton) { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $global:ACTION_BACK }; if ($Footer -like "*F1*") { Add-NewCaliber } }
                113 { if ($EnableBackButton) { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $global:ACTION_BACK }; if ($Footer -like "*F2*") { return $null } }
                114 { if ($EnableMainMenuButton) { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $global:ACTION_MAIN_MENU } }
            }
        } while ($true)
    }
}

function Ordenar-Dados {
    param ($dados)
    $propriedadePrimaria = switch ($global:criterioOrdenacao) {
        "Alfabetico"                   { "Nome" }; "Dano Base" { "DanoBaseNum" }; "Nivel de penetracao" { "Lv" }; "Chance de Ferir" { "ChanceFerirNum" }
        "Velocidade inicial"           { "Velocidade" }; "Precisao" { "PrecisaoNum" }; "Penetracao" { "PenetracaoNum" }; "Dano de blindagem" { "DanoArmaduraNum" }
        "Controle de recuo vertical"   { "RecuoVertNum" }; "Controle de recuo horizontal" { "RecuoHorizNum" }
    }
    
    $isDescending = ($global:ordemAtual -eq "Decrescente")
    $ordenacaoParams = @( @{ Expression = { $_."$propriedadePrimaria" }; Descending = $isDescending } )
    switch ($global:criterioOrdenacao) {
        "Alfabetico"                   { $ordenacaoParams += @{ Expression = { $_.Lv }; Descending = $true }; $ordenacaoParams += @{ Expression = { $_.DanoBaseNum }; Descending = $true } }
        "Dano Base"                    { $ordenacaoParams += @{ Expression = { $_.Lv }; Descending = $isDescending }; $ordenacaoParams += @{ Expression = { $_.PenetracaoNum }; Descending = $isDescending } }
        "Nivel de penetracao"          { $ordenacaoParams += @{ Expression = { $_.DanoBaseNum }; Descending = $isDescending }; $ordenacaoParams += @{ Expression = { $_.PenetracaoNum }; Descending = $isDescending } }
        "Chance de Ferir"              { $ordenacaoParams += @{ Expression = { $_.DanoBaseNum }; Descending = $isDescending }; $ordenacaoParams += @{ Expression = { $_.Lv }; Descending = $isDescending }; $ordenacaoParams += @{ Expression = { $_.PenetracaoNum }; Descending = $isDescending } }
        "Precisao"                     { $ordenacaoParams += @{ Expression = { $_.Lv }; Descending = $isDescending }; $ordenacaoParams += @{ Expression = { $_.DanoBaseNum }; Descending = $isDescending }; $ordenacaoParams += @{ Expression = { $_.PenetracaoNum }; Descending = $isDescending } }
        "Penetracao"                   { $ordenacaoParams += @{ Expression = { $_.Lv }; Descending = $isDescending }; $ordenacaoParams += @{ Expression = { $_.DanoBaseNum }; Descending = $isDescending } }
        "Velocidade inicial"           { $ordenacaoParams += @{ Expression = { $_.Lv }; Descending = $isDescending }; $ordenacaoParams += @{ Expression = { $_.DanoBaseNum }; Descending = $isDescending } }
        "Dano de blindagem"            { $ordenacaoParams += @{ Expression = { $_.Lv }; Descending = $isDescending }; $ordenacaoParams += @{ Expression = { $_.PenetracaoNum }; Descending = $isDescending } }
        "Controle de recuo vertical"   { $ordenacaoParams += @{ Expression = { $_.Lv }; Descending = $isDescending }; $ordenacaoParams += @{ Expression = { $_.DanoBaseNum }; Descending = $isDescending }; $ordenacaoParams += @{ Expression = { $_.PenetracaoNum }; Descending = $isDescending } }
        "Controle de recuo horizontal" { $ordenacaoParams += @{ Expression = { $_.Lv }; Descending = $isDescending }; $ordenacaoParams += @{ Expression = { $_.DanoBaseNum }; Descending = $isDescending }; $ordenacaoParams += @{ Expression = { $_.PenetracaoNum }; Descending = $isDescending } }
    }
    $dados | Sort-Object -Property $ordenacaoParams
}

function Ordenar-WeaponData {
    param ($dados, $criterio, $ordem)
    # Mapas para converter texto em valores numéricos para ordenação especial
    $poderFogoMap = @{ "Low" = 1; "Mid-Low" = 2; "Medium" = 3; "Mid-High" = 4; "High" = 5 }
    $canoMap = @{ "D+ R+" = 7; "R+" = 6; "Default +" = 5; "FB D+" = 4; "FB" = 3; "Custom" = 2; "FB D-" = 1 }
    foreach ($item in $dados) {
        $item | Add-Member -MemberType NoteProperty -Name 'PoderFogoNum' -Value $poderFogoMap[$item.PoderFogo] -ErrorAction SilentlyContinue -Force
        $item | Add-Member -MemberType NoteProperty -Name 'CanoNum' -Value $canoMap[$item.Cano] -ErrorAction SilentlyContinue -Force
    }
    $propriedadePrimaria = switch ($criterio) {
        "Alfabetico"                   { "Nome" }
        "Calibre"                      { "Calibre" }
        "Controle de recuo vertical"   { "VerticalRecoil" }
        "Controle de recuo horizontal" { "HorizontalRecoil" }
        "Ergonomia"                    { "Ergonomia" }
        "Estabilidade de arma"         { "EstabilidadeArma" }
        "Precisao"                     { "Precisao" }
        "Estabilidade sem mirar"       { "Estabilidade" }
        "Distancia Efetiva"            { "Alcance" }
        "Velocidade de Saida"          { "Velocidade" }
        "Modo de disparo"              { "ModoDisparo" }
        "Cadencia"                     { "Cadencia" }
        "Poder de fogo"                { "PoderFogoNum" }
        "Melhoria de cano"             { "CanoNum" }
    }
    
    $isDescending = ($ordem -eq "Decrescente")
    $ordenacaoParams = @( @{ Expression = { $_."$propriedadePrimaria" }; Descending = $isDescending } )
    switch ($criterio) {
        "Calibre"      { 
            $ordenacaoParams += @{ Expression = 'PoderFogoNum'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'HorizontalRecoil'; Descending = $isDescending }
        }
        "Controle de recuo vertical" { 
            $ordenacaoParams += @{ Expression = 'Precisao'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'HorizontalRecoil'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'Cadencia'; Descending = $isDescending }
        }
        "Controle de recuo horizontal" { 
            $ordenacaoParams += @{ Expression = 'Precisao'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'VerticalRecoil'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'Cadencia'; Descending = $isDescending }
        }
        "Ergonomia"         { 
            $ordenacaoParams += @{ Expression = 'Precisao'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'Cadencia'; Descending = $isDescending }
        }
        "Estabilidade de arma" {
            $ordenacaoParams += @{ Expression = 'Precisao'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'HorizontalRecoil'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'Cadencia'; Descending = $isDescending }
        }
        "Precisao"         {
            $ordenacaoParams += @{ Expression = 'Cadencia'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'HorizontalRecoil'; Descending = $isDescending }
        }
        "Estabilidade sem mirar" {
            $ordenacaoParams += @{ Expression = 'Precisao'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'Cadencia'; Descending = $isDescending }
        }
        "Distancia Efetiva" {
            $ordenacaoParams += @{ Expression = 'Velocidade'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'Cadencia'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'HorizontalRecoil'; Descending = $isDescending }
        }
        "Velocidade de Saida" { $ordenacaoParams += @{ Expression = 'Alcance'; Descending = $isDescending } }
        "Modo de disparo"  { $ordenacaoParams += @{ Expression = 'PoderFogoNum'; Descending = $isDescending } }
        "Cadencia"          { $ordenacaoParams += @{ Expression = 'PoderFogoNum'; Descending = $isDescending } }
        "Poder de fogo"    { 
            $ordenacaoParams += @{ Expression = 'Velocidade'; Descending = $isDescending } 
            $ordenacaoParams += @{ Expression = 'Cadencia'; Descending = $isDescending }
        }
        "Melhoria de cano"    { 
            $ordenacaoParams += @{ Expression = 'PoderFogoNum'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'Alcance'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'Cadencia'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'HorizontalRecoil'; Descending = $isDescending }
        }
    }
    
    $dados | Sort-Object -Property $ordenacaoParams
}

function Ordenar-GastronomyData {
    param ($dados, $criterio, $ordem)
    # Define a propriedade primária para ordenação
    $propriedadePrimaria = switch ($criterio) {
        "Alfabetico"         { "Nome" }
        "Hidratacao"         { "HidratacaoNum" }
        "Energia"            { "EnergiaNum" }
        "Hidratacao por slot" { "HidratSlot" }
        "Energia por slot"    { "EnergSlot" }
    }
    
    $isDescending = ($ordem -eq "Decrescente")
    $isAscending = -not $isDescending 
    # Define os parâmetros de ordenação, começando pelo critério primário
    $ordenacaoParams = @( @{ Expression = { $_."$propriedadePrimaria" }; Descending = $isDescending } )
    # Adiciona os múltiplos critérios de desempate
    switch ($criterio) {
        "Hidratacao" {
            $ordenacaoParams += @{ Expression = 'HidratSlot'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'TotalSlots'; Descending = $isAscending } 
            $ordenacaoParams += @{ Expression = 'EnergiaNum'; Descending = $isDescending }
        }
        "Energia" {
            $ordenacaoParams += @{ Expression = 'EnergSlot'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'TotalSlots'; Descending = $isAscending } 
            $ordenacaoParams += @{ Expression = 'HidratacaoNum'; Descending = $isDescending }
        }
        "Hidratacao por slot" {
            $ordenacaoParams += @{ Expression = 'TotalSlots'; Descending = $isAscending }      
            $ordenacaoParams += @{ Expression = 'HidratacaoNum'; Descending = $isDescending } 
            $ordenacaoParams += @{ Expression = 'EnergSlot'; Descending = $isDescending }     
        }
        "Energia por slot"  {
            $ordenacaoParams += @{ Expression = 'TotalSlots'; Descending = $isAscending }      
            $ordenacaoParams += @{ Expression = 'EnergiaNum'; Descending = $isDescending }     
            $ordenacaoParams += @{ Expression = 'HidratSlot'; Descending = $isDescending }     
        }
    }
    $dados | Sort-Object -Property $ordenacaoParams
}

function Ordenar-PharmaceuticalData {
    param ($dados, $criterio, $ordem, $categoria)
    $propriedadePrimaria = ""
    $ordenacaoParams = @()
    switch ($categoria) {
        "Analgesico" {
            $propriedadePrimaria = switch($criterio){"Usos"{"UsosNum"};"Duracao"{"DuracaoNum"};"Desidratacao"{"DesidratacaoNum"};"Duracao maxima"{"DurMaxNum"};}
            
            # 1. Define a ordem natural (melhor -> pior)
            $naturalDirectionIsDescending = $true # Para Usos, Duracao, Duracao maxima
            if ($criterio -eq "Desidratacao") { $naturalDirectionIsDescending = $false } 
            # 2. Determina a direção final baseada na escolha do usuário (Decrescente = padrão, Crescente = inverter)
            $finalDirectionIsDescending = $naturalDirectionIsDescending
            if ($ordem -eq "Crescente") { $finalDirectionIsDescending = -not $naturalDirectionIsDescending }
            $ordenacaoParams += @{ Expression = { $_.$propriedadePrimaria }; Descending = $finalDirectionIsDescending }
            if ($criterio -in @("Usos", "Duracao", "Desidratacao")) { $ordenacaoParams += @{ Expression = 'DuracaoNum'; Descending = $finalDirectionIsDescending } }
        }
        "Bandagem" {
            $isDescending = ($ordem -eq "Decrescente")
            $ordenacaoParams += @{ Expression = 'UsosNum'; Descending = $isDescending }
        }
        "Kit cirurgico" {
            $propriedadePrimaria = switch($criterio){"Usos"{"UsosNum"};"Recuperacao por uso"{"RecHPNum"};"Desidratacao"{"DesidratacaoNum"};"Tempo de Atraso"{"TempoAtrasoNum"};"Espaco(HxV)"{"TotalSlots"};}
            $naturalDirectionIsDescending = $true # Para Usos, Recuperacao por uso
            if ($criterio -in @("Desidratacao", "Tempo de Atraso", "Espaco(HxV)")) { $naturalDirectionIsDescending = $false }
            $finalDirectionIsDescending = $naturalDirectionIsDescending
            if ($ordem -eq "Crescente") { $finalDirectionIsDescending = -not $naturalDirectionIsDescending }
            $ordenacaoParams += @{ Expression = { $_.$propriedadePrimaria }; Descending = $finalDirectionIsDescending }
        }
        "Nebulizador" {
            $isDescending = ($ordem -eq "Decrescente")
            $ordenacaoParams += @{ Expression = 'UsosNum'; Descending = $isDescending }
        }
        "Kit medico" {
            $propriedadePrimaria = switch($criterio){"Durabilidade"{"DurabilidadeNum"};"Desidratacao"{"DesidratacaoNum"};"Velocidade de cura"{"VelCuraNum"};"Delay"{"DelayNum"};"Durabilidade por slot"{"DurabSlot"};"Espaco(HxV)"{"TotalSlots"};}
            $naturalDirectionIsDescending = $true # Para Durabilidade, Velocidade de cura, Durabilidade por slot
            if ($criterio -in @("Desidratacao", "Delay", "Espaco(HxV)")) { $naturalDirectionIsDescending = $false }
            $finalDirectionIsDescending = $naturalDirectionIsDescending
            if ($ordem -eq "Crescente") { $finalDirectionIsDescending = -not $naturalDirectionIsDescending }
            $ordenacaoParams += @{ Expression = { $_.$propriedadePrimaria }; Descending = $finalDirectionIsDescending }
            if ($criterio -in @("Delay", "Espaco(HxV)", "Desidratacao")) { $ordenacaoParams += @{ Expression = 'DurabilidadeNum'; Descending = $finalDirectionIsDescending } }
        }
        "Estimulantes" {
            $isDescending = ($ordem -eq "Decrescente")
            $ordenacaoParams += @{ Expression = 'EfeitoPrincipal'; Descending = $isDescending } 
            $ordenacaoParams += @{ Expression = 'DuracaoNum'; Descending = $isDescending } 
        }
    }
    
    $dados | Sort-Object -Property $ordenacaoParams
}

function Ordenar-ThrowableData {
    param ($dados, $criterio, $ordem)
    # Mapas para converter texto em valores numéricos para ordenação
    $alcanceMap    = @{ "/////" = 0; "Standard" = 1; "Large" = 2; "Very Large" = 3 }
    $danoBlindMap  = @{ "/////" = 0; "Standard" = 1; "Mid-High" = 2 }
    $penetracaoMap = @{ "/////" = 0; "Standard" = 1; "Mid-High" = 2 }
    $fragmentosMap = @{ "/////" = 0; "Small" = 1; "Large" = 2 }
    $tipoFragsMap  = @{ "/////" = 0; "Iron Piece" = 1; "Steel Piece" = 2 }
    # Adiciona propriedades numéricas para ordenação
    foreach ($item in $dados) {
        $item | Add-Member -MemberType NoteProperty -Name 'AlcanceNum' -Value $alcanceMap[$item.AlcanceRaw] -Force
        $item | Add-Member -MemberType NoteProperty -Name 'DanoBlindNum' -Value $danoBlindMap[$item.DanoBlindRaw] -Force
        $item | Add-Member -MemberType NoteProperty -Name 'PenetracaoNum' -Value $penetracaoMap[$item.PenetracaoRaw] -Force
        $item | Add-Member -MemberType NoteProperty -Name 'FragmentosNum' -Value $fragmentosMap[$item.FragmentosRaw] -Force
        $item | Add-Member -MemberType NoteProperty -Name 'TipoFragsNum' -Value $tipoFragsMap[$item.TipoFragsRaw] -Force
    }
    $isDescending = ($ordem -eq "Decrescente")
    $isAscending = -not $isDescending
    $ordenacaoParams = @()
    # Define a ordenação com base no critério
    switch ($criterio) {
        "Alfabetico" { $ordenacaoParams += @{ Expression = 'Nome'; Descending = $isDescending } }
        "Delay Explosao" {
            $ordenacaoParams += @{ Expression = 'DelayNum1'; Descending = $isAscending } # Menor primeiro
            $ordenacaoParams += @{ Expression = 'DelayNum2'; Descending = $isAscending } # Menor segundo
            $ordenacaoParams += @{ Expression = 'AlcanceNum'; Descending = $isDescending }
        }
        "Alcance" {
            $ordenacaoParams += @{ Expression = 'AlcanceNum'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'DelayNum1'; Descending = $isAscending }
            $ordenacaoParams += @{ Expression = 'DelayNum2'; Descending = $isAscending }
        }
        "Dano Blind" {
            $ordenacaoParams += @{ Expression = 'DanoBlindNum'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'AlcanceNum'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'DelayNum1'; Descending = $isAscending }
            $ordenacaoParams += @{ Expression = 'DelayNum2'; Descending = $isAscending }
        }
        "Penetracao" {
            $ordenacaoParams += @{ Expression = 'PenetracaoNum'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'DanoBlindNum'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'AlcanceNum'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'DelayNum1'; Descending = $isAscending }
            $ordenacaoParams += @{ Expression = 'DelayNum2'; Descending = $isAscending }
        }
        "Fragmentos" {
            $ordenacaoParams += @{ Expression = 'FragmentosNum'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'PenetracaoNum'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'DanoBlindNum'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'AlcanceNum'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'DelayNum1'; Descending = $isAscending }
            $ordenacaoParams += @{ Expression = 'DelayNum2'; Descending = $isAscending }
        }
        "Tipo Frags." {
            $ordenacaoParams += @{ Expression = 'TipoFragsNum'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'FragmentosNum'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'PenetracaoNum'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'DanoBlindNum'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'AlcanceNum'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'DelayNum1'; Descending = $isAscending }
            $ordenacaoParams += @{ Expression = 'DelayNum2'; Descending = $isAscending }
        }
        "Tempo Efeito" {
            $ordenacaoParams += @{ Expression = 'TempoEfeito'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'AlcanceNum'; Descending = $isDescending }
            $ordenacaoParams += @{ Expression = 'DelayNum1'; Descending = $isAscending }
            $ordenacaoParams += @{ Expression = 'DelayNum2'; Descending = $isAscending }
        }
    }
    
    $dados | Sort-Object -Property $ordenacaoParams
}

function Ordenar-HelmetData {
    param ($dados, $criterio) 
    
    $bloqueioMap = @{ "/////" = 0; "Low" = 1; "Moderate" = 2; "Severe" = 3 }
    $areaMap = @{ "Head" = 1; "Head, Ears" = 2; "Head, Ears, Face" = 3 }
    $ricocheteMap = @{ "/////" = 0; "Low" = 1; "Medium" = 2; "High" = 3 }
    $captadorMap = @{ "/////" = 0; "Bad" = 1; "Medium" = 2 }
    $reducaoMap = @{ "/////" = 0; "Bad" = 1; "Medium" = 2; "Strong" = 3 }
    $acessorioMap = @{ "/////" = 0; "TE" = 1; "Mask" = 2; "Mask, TE" = 3 }
    
    foreach ($item in $dados) {
        $item | Add-Member -MemberType NoteProperty -Name 'BloqueioNum' -Value $bloqueioMap[$item.SoundBlocking] -Force
        $item | Add-Member -MemberType NoteProperty -Name 'AreaNum' -Value $areaMap[$item.ProtectedArea] -Force
        $item | Add-Member -MemberType NoteProperty -Name 'RicocheteNum' -Value $ricocheteMap[$item.RicochetChance] -Force
        $item | Add-Member -MemberType NoteProperty -Name 'CaptadorNum' -Value $captadorMap[$item.SoundPickup] -Force
        $item | Add-Member -MemberType NoteProperty -Name 'ReducaoNum' -Value $reducaoMap[$item.NoiseReduction] -Force
        $item | Add-Member -MemberType NoteProperty -Name 'AcessorioNum' -Value $acessorioMap[$item.Accessory] -Force
        $clMaxMascNumValue = if ($item.ClMaxMascValue -eq '/////') { 0 } else { [int]$item.ClMaxMascValue }
        $item | Add-Member -MemberType NoteProperty -Name 'ClMaxMascNum' -Value $clMaxMascNumValue -Force
    }
    $propriedadePrimaria = switch ($criterio) {
        "Alfabetico"              { "Nome" }
        "Peso"                    { "Weight" }
        "Durabilidade"            { "Durability" }
        "Classe de Blindagem"     { "ArmorClass" }
        "Cl Max Masc"             { "ClMaxMascNum" }
        "Material"                { "Material" }
        "Bloqueio"                { "BloqueioNum" }
        "Penalidade de movimento" { "MovementSpeedNum" }
        "Ergonomia"               { "ErgonomicsNum" }
        "Area Protegida"          { "AreaNum" }
        "Chance de Ricochete"     { "RicocheteNum" }
        "Captura de som"          { "CaptadorNum" }
        "Reducao de ruido"        { "ReducaoNum" }
        "Acessorio"               { "AcessorioNum" }
    }
    
    $isDescending = $true
    if ($criterio -in @("Peso", "Bloqueio")) { $isDescending = $false }
    $ordenacaoParams = @( @{ Expression = { $_."$propriedadePrimaria" }; Descending = $isDescending } )
    switch ($criterio) {
        "Peso"           { 
            $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'BloqueioNum'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'RicocheteNum'; Descending = $true }
        }
        "Durabilidade"   { 
            $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'BloqueioNum'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'RicocheteNum'; Descending = $true }
        }
        "Classe de Blindagem" { 
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'BloqueioNum'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
        }
        "Cl Max Masc" { 
            $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'BloqueioNum'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
        }
        "Material"       { 
            $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'BloqueioNum'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'RicocheteNum'; Descending = $true }
        }
        "Bloqueio"       { 
            $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'RicocheteNum'; Descending = $true }
        }
        "Penalidade de movimento" {
            $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'BloqueioNum'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'RicocheteNum'; Descending = $true }
        }
        "Ergonomia"      {
            $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'BloqueioNum'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'RicocheteNum'; Descending = $true }
        }
        "Area Protegida" { 
            $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'BloqueioNum'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'RicocheteNum'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
        }
        "Chance de Ricochete" { 
            $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'BloqueioNum'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
        }
        "Captura de som" { 
            $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'BloqueioNum'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'RicocheteNum'; Descending = $true }
        }
        "Reducao de ruido" { 
            $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'BloqueioNum'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'RicocheteNum'; Descending = $true }
        }
        "Acessorio"      { 
            $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'BloqueioNum'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'RicocheteNum'; Descending = $true }
        }
    }
    
    $dados | Sort-Object -Property $ordenacaoParams
}

function Ordenar-BodyArmorData {
    param ($dados, $criterio)
    $areaMap = @{
        "Chest" = 1
        "Chest, Upper Abdomen" = 2
        "Chest, Shoulder, Upper Abdomen" = 3
        "Chest, Upper Abdomen, Lower Abdomen" = 4
        "Chest, Shoulder, Upper Abdomen, Lower Abdomen" = 5
    }
    foreach ($item in $dados) {
        $item | Add-Member -MemberType NoteProperty -Name 'AreaNum' -Value $areaMap[$item.ProtectedAreaRaw] -Force
        $velNum = if ($item.MovementSpeed -eq '/////') { 0 } else { [int]($item.MovementSpeed -replace '%', '') }
        $ergoNum = if ($item.Ergonomics -eq '/////') { 0 } else { [int]$item.Ergonomics }
        $item | Add-Member -MemberType NoteProperty -Name 'MovementSpeedNum' -Value $velNum -Force
        $item | Add-Member -MemberType NoteProperty -Name 'ErgonomicsNum' -Value $ergoNum -Force
    }
    $propriedadePrimaria = switch ($criterio) {
        "Alfabetico"              { "Nome" }
        "Peso"                    { "Weight" }
        "Durabilidade"            { "Durability" }
        "Classe de Blindagem"     { "ArmorClass" }
        "Material"                { "Material" }
        "Penalidade de movimento" { "MovementSpeedNum" }
        "Ergonomia"               { "ErgonomicsNum" }
        "Area Protegida"          { "AreaNum" }
    }
    
    $isDescending = $true
    if ($criterio -eq "Peso") { $isDescending = $false } 
    
    $ordenacaoParams = @( @{ Expression = { $_."$propriedadePrimaria" }; Descending = $isDescending } )
    switch ($criterio) {
        "Peso"           { 
            $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'MovementSpeedNum'; Descending = $true }
        }
        "Durabilidade"   { 
            $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'MovementSpeedNum'; Descending = $true }
        }
        "Classe de Blindagem" { 
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'MovementSpeedNum'; Descending = $true }
        }
        "Material"       { 
            $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'MovementSpeedNum'; Descending = $true }
        }
        "Penalidade de movimento" {
            $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true } 
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
        }
        "Ergonomia"      {
            $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'MovementSpeedNum'; Descending = $true }
        }
        "Area Protegida" { 
            $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'MovementSpeedNum'; Descending = $true }
        }
    }
    
    $dados | Sort-Object -Property $ordenacaoParams
}

function Ordenar-ArmoredRigData {
    param ($dados, $criterio, $ordem)
    $areaMap = @{ "Chest" = 1; "Chest, Upper Abdomen" = 2; "Chest, Upper Abdomen, Lower Abdomen" = 3; "Chest, Shoulder, Upper Abdomen, Lower Abdomen" = 4 }
    foreach ($item in $dados) {
        $item | Add-Member -MemberType NoteProperty -Name 'AreaNum' -Value $areaMap[$item.ProtectedAreaRaw] -Force
        $velNum = if ($item.MovementSpeed -eq '/////') { 0 } else { [int]($item.MovementSpeed -replace '%', '') }
        $ergoNum = if ($item.Ergonomics -eq '/////') { 0 } else { [int]$item.Ergonomics }
        $item | Add-Member -MemberType NoteProperty -Name 'MovementSpeedNum' -Value $velNum -Force
        $item | Add-Member -MemberType NoteProperty -Name 'ErgonomicsNum' -Value $ergoNum -Force
    }
    $propriedadePrimaria = switch ($criterio) {
        "Alfabetico"              { "Nome" }
        "Peso"                    { "Weight" }
        "Durabilidade"            { "Durability" }
        "Classe de Blindagem"     { "ArmorClass" }
        "Material"                { "Material" }
        "Penalidade de movimento" { "MovementSpeedNum" }
        "Ergonomia"               { "ErgonomicsNum" }
        "Armazenamento"           { "Storage" }
        "Area Protegida"          { "AreaNum" }
    }
    
    $isDescending = $true 
    if ($criterio -eq "Peso") { $isDescending = $false }
    
    $ordenacaoParams = @( @{ Expression = { $_."$propriedadePrimaria" }; Descending = $isDescending } )
    switch ($criterio) {
        "Armazenamento"  { 
            $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
        }
        "Peso"           { $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }; $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true } }
        "Durabilidade"   { 
            $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
        }
        "Classe de Blindagem" { 
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
        }
        "Material"       { $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }; $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }; $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false } }
        "Penalidade de movimento" { $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true } }
        "Ergonomia"      { 
            $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
        }
        "Area Protegida" { $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }; $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }; $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false } }
    }
    
    $dados | Sort-Object -Property $ordenacaoParams
}

function Ordenar-MaskData {
    param ($dados, $criterio)
    $ricocheteMap = @{ "/////" = 0; "Low" = 1; "Medium" = 2; "High" = 3 }
    foreach ($item in $dados) {
        $item | Add-Member -MemberType NoteProperty -Name 'RicocheteNum' -Value $ricocheteMap[$item.RicochetChanceRaw] -Force
    }
    $propriedadePrimaria = switch ($criterio) {
        "Alfabetico"          { "Nome" }
        "Peso"                { "Weight" }
        "Durabilidade"        { "Durability" }
        "Classe de Blindagem" { "ArmorClass" }
        "Material"            { "Material" }
        "Chance de Ricochete" { "RicocheteNum" }
    }
    
    $isDescending = $true
    if ($criterio -eq "Peso") { $isDescending = $false }
    
    $ordenacaoParams = @( @{ Expression = { $_."$propriedadePrimaria" }; Descending = $isDescending } )
    switch ($criterio) {
        "Peso"           { 
            $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'RicocheteNum'; Descending = $true }
        }
        "Durabilidade"   { 
            $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'RicocheteNum'; Descending = $true }
        }
        "Classe de Blindagem" { 
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'RicocheteNum'; Descending = $true }
        }
        "Material"       { 
            $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'RicocheteNum'; Descending = $true }
        }
        "Chance de Ricochete" { 
            $ordenacaoParams += @{ Expression = 'ArmorClass'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
        }
    }
    
    $dados | Sort-Object -Property $ordenacaoParams
}

function Ordenar-GasMaskData {
    param ($dados, $criterio)
    $effectMap = @{ "/////" = 0; "Bad" = 1; "Medium" = 2; "Strong" = 3 }
    foreach ($item in $dados) {
        $item | Add-Member -MemberType NoteProperty -Name 'AntiVenenoNum' -Value $effectMap[$item.AntiVenenoRaw] -Force
        $item | Add-Member -MemberType NoteProperty -Name 'AntiFlashNum' -Value $effectMap[$item.AntiFlashRaw] -Force
    }
    $propriedadePrimaria = switch ($criterio) {
        "Alfabetico"   { "Nome" }
        "Peso"         { "Weight" }
        "Durabilidade" { "Durability" }
        "Anti-Veneno"  { "AntiVenenoNum" }
        "Anti-Flash"   { "AntiFlashNum" }
    }
    
    $isDescending = $true
    if ($criterio -eq "Peso") { $isDescending = $false }
    
    $ordenacaoParams = @( @{ Expression = { $_."$propriedadePrimaria" }; Descending = $isDescending } )
    switch ($criterio) {
        "Peso"        { 
            $ordenacaoParams += @{ Expression = 'AntiVenenoNum'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'AntiFlashNum'; Descending = $true }
        }
        "Durabilidade" { 
            $ordenacaoParams += @{ Expression = 'AntiVenenoNum'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'AntiFlashNum'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
        }
        "Anti-Veneno" { 
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'AntiFlashNum'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
        }
        "Anti-Flash"  { 
            $ordenacaoParams += @{ Expression = 'AntiVenenoNum'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Durability'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
        }
    }
    
    $dados | Sort-Object -Property $ordenacaoParams
}

function Ordenar-HeadsetData {
    param ($dados, $criterio)
    $effectMap = @{ "Bad" = 1; "Medium" = 2; "Strong" = 3 }
    foreach ($item in $dados) {
        $item | Add-Member -MemberType NoteProperty -Name 'CaptadorNum' -Value $effectMap[$item.SoundPickupRaw] -Force
        $item | Add-Member -MemberType NoteProperty -Name 'ReducaoNum' -Value $effectMap[$item.NoiseReductionRaw] -Force
    }
    $propriedadePrimaria = switch ($criterio) {
        "Alfabetico"      { "Nome" }
        "Peso"            { "Weight" }
        "Captador de Som" { "CaptadorNum" }
        "Reducao de Ruido"  { "ReducaoNum" }
    }
    
    $isDescending = $true
    if ($criterio -eq "Peso") { $isDescending = $false }
    
    $ordenacaoParams = @( @{ Expression = { $_."$propriedadePrimaria" }; Descending = $isDescending } )
    
    switch ($criterio) {
        "Captador de Som" { 
            $ordenacaoParams += @{ Expression = 'ReducaoNum'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
        }
        "Reducao de Ruido" { 
            $ordenacaoParams += @{ Expression = 'CaptadorNum'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
        }
    }
    
    $dados | Sort-Object -Property $ordenacaoParams
}

function Ordenar-UnarmoredRigData {
    param ($dados, $criterio)
    $propriedadePrimaria = switch ($criterio) {
        "Alfabetico" { "Nome" }
        "Peso"       { "Weight" }
        "Espaco"     { "Storage" }
        "+Espaco p/armaz -Espaco consumido" { "Efficiency" }
    }
    
    $isDescending = $true
    if ($criterio -eq "Peso") { $isDescending = $false }
    
    $ordenacaoParams = @( @{ Expression = { $_."$propriedadePrimaria" }; Descending = $isDescending } )
    switch ($criterio) {
        "Peso"   { $ordenacaoParams += @{ Expression = 'Storage'; Descending = $true } }
        "Espaco" { 
            $ordenacaoParams += @{ Expression = 'SetCount'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
        }
        "+Espaco p/armaz -Espaco consumido" { 
            $ordenacaoParams += @{ Expression = 'Storage'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'SetCount'; Descending = $false }
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
        }
    }
    
    $dados | Sort-Object -Property $ordenacaoParams
}

function Ordenar-BackpackData {
    param ($dados, $criterio)
    $propriedadePrimaria = switch ($criterio) {
        "Alfabetico" { "Nome" }
        "Peso"       { "Weight" }
        "Espaco"     { "Storage" }
        "+Espaco p/armaz -Espaco consumido" { "Efficiency" }
    }
    
    $isDescending = $true
    if ($criterio -eq "Peso") { $isDescending = $false }
    
    $ordenacaoParams = @( @{ Expression = { $_."$propriedadePrimaria" }; Descending = $isDescending } )
    switch ($criterio) {
        "Peso"   { $ordenacaoParams += @{ Expression = 'Storage'; Descending = $true } }
        "Espaco" { 
            $ordenacaoParams += @{ Expression = 'SetCount'; Descending = $false } # 1º Desempate: Menor número de conjuntos
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }  # 2º Desempate: Menor peso
        }
        "+Espaco p/armaz -Espaco consumido" { 
            $ordenacaoParams += @{ Expression = 'Storage'; Descending = $true }
            $ordenacaoParams += @{ Expression = 'SetCount'; Descending = $false } # Desempate por MENOR número de conjuntos
            $ordenacaoParams += @{ Expression = 'Weight'; Descending = $false }
        }
    }
    
    $dados | Sort-Object -Property $ordenacaoParams
}

function Show-GenericConfirmation {
    param(
        [Parameter(Mandatory=$true)][PSCustomObject]$ItemData,
        [Parameter(Mandatory=$true)][string]$CategoryKey,
        [int]$InitialSelectedIndex = 0
    )
    
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize; (Get-Host).UI.RawUI.CursorSize = 0
    # Usa o parâmetro recebido para definir o item selecionado
    $selectedIndex = $InitialSelectedIndex
    $config = $global:ItemCategoryConfig[$CategoryKey]
    do {
        Clear-Host; Write-Host "=== Confirmacao: $($ItemData.Nome) ($($config.EditViewMenuName)) ==="; Write-Host
        
        # A propriedade "Properties" não existe na configuração de todos os itens (ex: Armas)
        # Vamos verificar se ela existe antes de usar.
        if (-not $config.Properties) {
            Write-Host "ERRO: A categoria '$CategoryKey' não está configurada para edição genérica." -ForegroundColor Red
            Start-Sleep -Seconds 3
            return "CANCEL"
        }
        $displayFields = @([PSCustomObject]@{DisplayName="Nome"; PropName="Nome"}) + $config.Properties
        
        for ($i = 0; $i -lt $displayFields.Count; $i++) {
            $fieldName = $displayFields[$i].DisplayName
            $propName = $displayFields[$i].PropName
            $fieldValue = $ItemData.$propName
            $line = "  $fieldName`: $fieldValue"
            if ($i -eq $selectedIndex) { Write-Host (">" + $line.Substring(1)) -ForegroundColor Green } else { Write-Host $line }
        }
        Write-Host; Write-Host "- Nota: Se algum dado apresentado nao estiver correto, use Setas para navegar e Enter para editar"; Write-Host
        Write-Host "Pressione " -NoNewline; Write-Host "F1" -ForegroundColor Blue -NoNewline; Write-Host " para Confirmar"
        Write-Host "Pressione " -NoNewline; Write-Host "F2" -ForegroundColor Red -NoNewline; Write-Host " para Cancelar"
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
        switch ($key) {
            38 { if ($selectedIndex -gt 0) { $selectedIndex-- } }; 40 { if ($selectedIndex -lt ($displayFields.Count - 1)) { $selectedIndex++ } }
            112 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return "CONFIRM" }
            113 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return "CANCEL" }
            13 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $selectedIndex }
        }
    } while ($true)
}

function Show-AmmoConfirmation {
    param ([Parameter(Mandatory=$true)][PSCustomObject]$AmmoData, [Parameter(Mandatory=$true)][string]$Caliber, [int]$InitialSelectedIndex = 0)
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize; (Get-Host).UI.RawUI.CursorSize = 0; $selectedIndex = $InitialSelectedIndex
    
    $displayFields = @("Nome", "Nivel de Penetracao", "Penetracao", "Dano Base", "Dano de blindagem", "Velocidade (m/s)", "Precisao", "Recuo Vertical", "Recuo Horizontal", "Chance Ferir")
    $propertyMap = @{
        "Nome"                  = "Nome";
        "Nivel de Penetracao"   = "NiveldePenetracao";
        "Penetracao"            = "Penetracao";
        "Dano Base"             = "DanoBase";
        "Dano de blindagem"     = "Danodeblindagem";
        "Velocidade (m/s)"      = "Velocidade";
        "Precisao"              = "Precisao";
        "Recuo Vertical"        = "RecuoVertical";
        "Recuo Horizontal"      = "RecuoHorizontal";
        "Chance Ferir"          = "ChanceFerir"
    }
    do {
        Clear-Host; Write-Host "=== Confirmacao: $($AmmoData.Nome) ($Caliber) ==="; Write-Host
        for ($i = 0; $i -lt $displayFields.Count; $i++) {
            $fieldName = $displayFields[$i]
            $propName = $propertyMap[$fieldName]
            $fieldValue = $AmmoData.$propName
            $line = "  $fieldName`: $fieldValue"
            if ($i -eq $selectedIndex) { Write-Host (">" + $line.Substring(1)) -ForegroundColor Green } else { Write-Host $line }
        }
        Write-Host; Write-Host "- Nota: Se algum dado apresentado nao estiver correto, use Setas para navegar e Enter para editar"; Write-Host
        Write-Host "Pressione " -NoNewline; Write-Host "F1" -ForegroundColor Blue -NoNewline; Write-Host " para Confirmar"
        Write-Host "Pressione " -NoNewline; Write-Host "F2" -ForegroundColor Red -NoNewline; Write-Host " para Cancelar"
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
        switch ($key) {
            38 { if ($selectedIndex -gt 0) { $selectedIndex-- } }; 40 { if ($selectedIndex -lt ($displayFields.Count - 1)) { $selectedIndex++ } }
            112 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return "CONFIRM" }
            113 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return "CANCEL" }
            13 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $selectedIndex }
        }
    } while ($true)
}

function Show-WeaponConfirmation {
    param ([Parameter(Mandatory=$true)][PSCustomObject]$WeaponData, [int]$InitialSelectedIndex = 0)
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize; (Get-Host).UI.RawUI.CursorSize = 0; $selectedIndex = $InitialSelectedIndex
    $displayFields = @("Nome", "Classe", "Calibre", "Controle de recuo vertical", "Controle de recuo horizontal", "Ergonomia", "Estabilidade de arma", "Precisao", "Estabilidade sem mirar", "Distancia Efetiva", "Velocidade do Bocal", "Modos de disparo", "Cadencia", "Poder de fogo", "Cano")
    $propertyMap = @{
        "Controle de recuo vertical" = "VerticalRecoil"; 
        "Controle de recuo horizontal" = "HorizontalRecoil";
        "Estabilidade de arma" = "EstabilidadeArma";
        "Estabilidade sem mirar" = "Estabilidade"; 
        "Distancia Efetiva" = "Alcance"; 
        "Velocidade do Bocal" = "Velocidade"; 
        "Modos de disparo" = "ModoDisparo"; 
        "Poder de fogo" = "PoderFogo"
    }
    
    do {
        Clear-Host; Write-Host "=== Confirmacao: $($WeaponData.Nome) ($($WeaponData.Calibre)) ==="; Write-Host
        for ($i = 0; $i -lt $displayFields.Count; $i++) {
            $fieldName = $displayFields[$i]; $propertyNameToGet = if ($propertyMap.ContainsKey($fieldName)) { $propertyMap[$fieldName] } else { $fieldName.Replace(" ", "") }
            $fieldValue = if ([string]::IsNullOrEmpty($WeaponData.$propertyNameToGet)) { "FALTANDO" } else { $WeaponData.$propertyNameToGet }
            $line = "  $fieldName`: "; if ($i -eq $selectedIndex) { Write-Host ">" -NoNewline -ForegroundColor Green; Write-Host $line.Substring(1) -NoNewline } else { Write-Host $line -NoNewline }
            if ($fieldValue -eq "FALTANDO") { Write-Host $fieldValue -ForegroundColor Red } else { Write-Host $fieldValue }
        }
        Write-Host; Write-Host "- Nota: Se algum dado apresentado nao estiver correto, use Setas para navegar e Enter para editar"; Write-Host
        Write-Host "Pressione " -NoNewline; Write-Host "F1" -ForegroundColor Blue -NoNewline; Write-Host " para Confirmar"
        Write-Host "Pressione " -NoNewline; Write-Host "F2" -ForegroundColor Red -NoNewline; Write-Host " para Cancelar"
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
        switch ($key) {
            38 { if ($selectedIndex -gt 0) { $selectedIndex-- } }; 40 { if ($selectedIndex -lt ($displayFields.Count - 1)) { $selectedIndex++ } }
            112 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return "CONFIRM" }
            113 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return "CANCEL" }
            13 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $selectedIndex }
        }
    } while ($true)
}

function Show-ThrowableConfirmation {
    param ([Parameter(Mandatory=$true)][PSCustomObject]$ItemData, [int]$InitialSelectedIndex = 0)
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize; (Get-Host).UI.RawUI.CursorSize = 0; $selectedIndex = $InitialSelectedIndex
    $displayFields = @("Nome", "Delay Explosao", "Alcance", "Dano Blindagem", "Penetracao", "Fragmentos", "Tipo Fragmentos", "Tempo Efeito")
    $propertyMap = @{"Nome"="Nome";"Delay Explosao"="ExplosionDelay";"Alcance"="Range";"Dano Blindagem"="ArmorDamage";"Penetracao"="Penetration";"Fragmentos"="Fragments";"Tipo Fragmentos"="FragmentType";"Tempo Efeito"="EffectTime"}
    do {
        Clear-Host; Write-Host "=== Confirmacao: $($ItemData.Nome) ==="; Write-Host
        for ($i = 0; $i -lt $displayFields.Count; $i++) {
            $fieldName = $displayFields[$i]; $propName = $propertyMap[$fieldName]; $fieldValue = $ItemData.$propName
            $line = "  $fieldName`: $fieldValue"; if ($i -eq $selectedIndex) { Write-Host (">" + $line.Substring(1)) -ForegroundColor Green } else { Write-Host $line }
        }
        Write-Host; Write-Host "- Nota: Use Setas para navegar e Enter para editar"; Write-Host
        Write-Host "Pressione " -NoNewline; Write-Host "F1" -ForegroundColor Blue -NoNewline; Write-Host " para Confirmar"
        Write-Host "Pressione " -NoNewline; Write-Host "F2" -ForegroundColor Red -NoNewline; Write-Host " para Cancelar"
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
        switch ($key) {
            38 { if ($selectedIndex -gt 0) { $selectedIndex-- } }; 40 { if ($selectedIndex -lt ($displayFields.Count - 1)) { $selectedIndex++ } }
            112 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return "CONFIRM" }
            113 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return "CANCEL" }
            13 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $selectedIndex }
        }
    } while ($true)
}

function Show-HelmetConfirmation {
    param ([Parameter(Mandatory=$true)][PSCustomObject]$ItemData, [int]$InitialSelectedIndex = 0)
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize; (Get-Host).UI.RawUI.CursorSize = 0; $selectedIndex = $InitialSelectedIndex
    $displayFields = @("Nome", "Peso", "Durabilidade", "Classe de Blindagem", "Material", "Bloqueio Sonoro", "Velocidade de Movimento", "Ergonomia", "Area Protegida", "Chance de Ricochete", "Fone de Ouvido Embutido", "Captador de Som", "Reducao de Ruido", "Acessorio Funcional")
    $propertyMap = @{
        "Nome"                      = "Nome"; "Peso" = "Weight"; "Durabilidade" = "Durability"; "Classe de Blindagem" = "ArmorClass"
        "Material"                  = "Material"; "Bloqueio Sonoro" = "SoundBlocking"; "Velocidade de Movimento" = "MovementSpeed"
        "Ergonomia"                 = "Ergonomics"; "Area Protegida" = "ProtectedArea"; "Chance de Ricochete" = "RicochetChance"
        "Fone de Ouvido Embutido"   = "Headset"; "Captador de Som" = "SoundPickup"; "Reducao de Ruido" = "NoiseReduction"
        "Acessorio Funcional"       = "Accessory"
    }
    do {
        Clear-Host; Write-Host "=== Confirmacao: $($ItemData.Nome) ==="; Write-Host
        for ($i = 0; $i -lt $displayFields.Count; $i++) {
            $fieldName = $displayFields[$i]; $propName = $propertyMap[$fieldName]; $fieldValue = $ItemData.$propName
            $line = "  $fieldName`: $fieldValue"; if ($i -eq $selectedIndex) { Write-Host (">" + $line.Substring(1)) -ForegroundColor Green } else { Write-Host $line }
        }
        Write-Host; Write-Host "- Nota: Use Setas para navegar e Enter para editar"; Write-Host
        Write-Host "Pressione " -NoNewline; Write-Host "F1" -ForegroundColor Blue -NoNewline; Write-Host " para Confirmar"
        Write-Host "Pressione " -NoNewline; Write-Host "F2" -ForegroundColor Red -NoNewline; Write-Host " para Cancelar"
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
        switch ($key) {
            38 { if ($selectedIndex -gt 0) { $selectedIndex-- } }; 40 { if ($selectedIndex -lt ($displayFields.Count - 1)) { $selectedIndex++ } }
            112 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return "CONFIRM" }
            113 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return "CANCEL" }
            13 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $selectedIndex }
        }
    } while ($true)
}

function Show-BodyArmorConfirmation {
    param ([Parameter(Mandatory=$true)][PSCustomObject]$ItemData, [int]$InitialSelectedIndex = 0)
    
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize; (Get-Host).UI.RawUI.CursorSize = 0
    $selectedIndex = $InitialSelectedIndex
    $displayFields = @("Nome", "Peso", "Durabilidade", "Classe de Blindagem", "Material", "Velocidade de Movimento", "Ergonomia", "Area Protegida")
    
    do {
        Clear-Host; Write-Host "=== Confirmacao: $($ItemData.Nome) ==="; Write-Host
        for ($i = 0; $i -lt $displayFields.Count; $i++) {
            $fieldName = $displayFields[$i]; $propName = $fieldName.Replace(" ", "").Replace("(", "").Replace(")", "")
            $fieldValue = $ItemData.$propName
            $line = "  $fieldName`: $fieldValue"; if ($i -eq $selectedIndex) { Write-Host (">" + $line.Substring(1)) -ForegroundColor Green } else { Write-Host $line }
        }
        Write-Host; Write-Host "- Nota: Use Setas para navegar e Enter para editar"; Write-Host
        Write-Host "Pressione " -NoNewline; Write-Host "F1" -ForegroundColor Blue -NoNewline; Write-Host " para Confirmar"
        Write-Host "Pressione " -NoNewline; Write-Host "F2" -ForegroundColor Red -NoNewline; Write-Host " para Cancelar"
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
        switch ($key) {
            38 { if ($selectedIndex -gt 0) { $selectedIndex-- } }; 40 { if ($selectedIndex -lt ($displayFields.Count - 1)) { $selectedIndex++ } }
            112 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return "CONFIRM" }
            113 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return "CANCEL" }
            13 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $selectedIndex }
        }
    } while ($true)
}

function Show-ArmoredRigConfirmation {
    param ([Parameter(Mandatory=$true)][PSCustomObject]$ItemData, [int]$InitialSelectedIndex = 0)
    
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize; (Get-Host).UI.RawUI.CursorSize = 0
    $selectedIndex = $InitialSelectedIndex
    $displayFields = @("Nome", "Peso", "Durabilidade", "Classe de Blindagem", "Material", "Velocidade de Movimento", "Ergonomia", "Espaco de Armazenamento", "Area Protegida", "Conjuntos de Blocos")
    
    do {
        Clear-Host; Write-Host "=== Confirmacao: $($ItemData.Nome) ==="; Write-Host
        for ($i = 0; $i -lt $displayFields.Count; $i++) {
            $fieldName = $displayFields[$i]; $propName = $fieldName.Replace(" ", "").Replace("(", "").Replace(")", "")
            $fieldValue = $ItemData.$propName
            $line = "  $fieldName`: $fieldValue"; if ($i -eq $selectedIndex) { Write-Host (">" + $line.Substring(1)) -ForegroundColor Green } else { Write-Host $line }
        }
        Write-Host; Write-Host "- Nota: Use Setas para navegar e Enter para editar"; Write-Host
        Write-Host "Pressione " -NoNewline; Write-Host "F1" -ForegroundColor Blue -NoNewline; Write-Host " para Confirmar"
        Write-Host "Pressione " -NoNewline; Write-Host "F2" -ForegroundColor Red -NoNewline; Write-Host " para Cancelar"
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
        switch ($key) {
            38 { if ($selectedIndex -gt 0) { $selectedIndex-- } }; 40 { if ($selectedIndex -lt ($displayFields.Count - 1)) { $selectedIndex++ } }
            112 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return "CONFIRM" }
            113 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return "CANCEL" }
            13 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $selectedIndex }
        }
    } while ($true)
}

function Show-MaskConfirmation {
    param ([Parameter(Mandatory=$true)][PSCustomObject]$ItemData, [int]$InitialSelectedIndex = 0)
    
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize; (Get-Host).UI.RawUI.CursorSize = 0
    $selectedIndex = $InitialSelectedIndex
    $displayFields = @("Nome", "Peso", "Durabilidade", "Classe", "Material", "Chance de Ricochete")
    
    do {
        Clear-Host; Write-Host "=== Confirmacao: $($ItemData.Nome) ==="; Write-Host
        for ($i = 0; $i -lt $displayFields.Count; $i++) {
            $fieldName = $displayFields[$i]; $propName = $fieldName.Replace(" ", "").Replace("(", "").Replace(")", "")
            $fieldValue = $ItemData.$propName
            $line = "  $fieldName`: $fieldValue"; if ($i -eq $selectedIndex) { Write-Host (">" + $line.Substring(1)) -ForegroundColor Green } else { Write-Host $line }
        }
        Write-Host; Write-Host "- Nota: Use Setas para navegar e Enter para editar"; Write-Host
        Write-Host "Pressione " -NoNewline; Write-Host "F1" -ForegroundColor Blue -NoNewline; Write-Host " para Confirmar"
        Write-Host "Pressione " -NoNewline; Write-Host "F2" -ForegroundColor Red -NoNewline; Write-Host " para Cancelar"
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
        switch ($key) {
            38 { if ($selectedIndex -gt 0) { $selectedIndex-- } }; 40 { if ($selectedIndex -lt ($displayFields.Count - 1)) { $selectedIndex++ } }
            112 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return "CONFIRM" }
            113 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return "CANCEL" }
            13 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $selectedIndex }
        }
    } while ($true)
}

function Show-GasMaskConfirmation {
    param ([Parameter(Mandatory=$true)][PSCustomObject]$ItemData, [int]$InitialSelectedIndex = 0)
    
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize; (Get-Host).UI.RawUI.CursorSize = 0
    $selectedIndex = $InitialSelectedIndex
    $displayFields = @("Nome", "Peso", "Durabilidade", "Anti-Veneno", "Anti-Flash")
    
    do {
        Clear-Host; Write-Host "=== Confirmacao: $($ItemData.Nome) ==="; Write-Host
        for ($i = 0; $i -lt $displayFields.Count; $i++) {
            $fieldName = $displayFields[$i]; $propName = $fieldName.Replace(" ", "").Replace("-", "")
            $fieldValue = $ItemData.$propName
            $line = "  $fieldName`: $fieldValue"; if ($i -eq $selectedIndex) { Write-Host (">" + $line.Substring(1)) -ForegroundColor Green } else { Write-Host $line }
        }
        Write-Host; Write-Host "- Nota: Use Setas para navegar e Enter para editar"; Write-Host
        Write-Host "Pressione " -NoNewline; Write-Host "F1" -ForegroundColor Blue -NoNewline; Write-Host " para Confirmar"
        Write-Host "Pressione " -NoNewline; Write-Host "F2" -ForegroundColor Red -NoNewline; Write-Host " para Cancelar"
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
        switch ($key) {
            38 { if ($selectedIndex -gt 0) { $selectedIndex-- } }; 40 { if ($selectedIndex -lt ($displayFields.Count - 1)) { $selectedIndex++ } }
            112 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return "CONFIRM" }
            113 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return "CANCEL" }
            13 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $selectedIndex }
        }
    } while ($true)
}

function Show-HeadsetConfirmation {
    param ([Parameter(Mandatory=$true)][PSCustomObject]$ItemData, [int]$InitialSelectedIndex = 0)
    
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize; (Get-Host).UI.RawUI.CursorSize = 0
    $selectedIndex = $InitialSelectedIndex
    $displayFields = @("Nome", "Peso", "Captador de Som", "Reducao de Ruido")
    
    do {
        Clear-Host; Write-Host "=== Confirmacao: $($ItemData.Nome) ==="; Write-Host
        for ($i = 0; $i -lt $displayFields.Count; $i++) {
            $fieldName = $displayFields[$i]; $propName = $fieldName.Replace(" ", "")
            $fieldValue = $ItemData.$propName
            $line = "  $fieldName`: $fieldValue"; if ($i -eq $selectedIndex) { Write-Host (">" + $line.Substring(1)) -ForegroundColor Green } else { Write-Host $line }
        }
        Write-Host; Write-Host "- Nota: Use Setas para navegar e Enter para editar"; Write-Host
        Write-Host "Pressione " -NoNewline; Write-Host "F1" -ForegroundColor Blue -NoNewline; Write-Host " para Confirmar"
        Write-Host "Pressione " -NoNewline; Write-Host "F2" -ForegroundColor Red -NoNewline; Write-Host " para Cancelar"
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
        switch ($key) {
            38 { if ($selectedIndex -gt 0) { $selectedIndex-- } }; 40 { if ($selectedIndex -lt ($displayFields.Count - 1)) { $selectedIndex++ } }
            112 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return "CONFIRM" }
            113 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return "CANCEL" }
            13 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $selectedIndex }
        }
    } while ($true)
}

function Show-UnarmoredRigConfirmation {
    param ([Parameter(Mandatory=$true)][PSCustomObject]$ItemData, [int]$InitialSelectedIndex = 0)
    
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize; (Get-Host).UI.RawUI.CursorSize = 0
    $selectedIndex = $InitialSelectedIndex
    $displayFields = @("Nome", "Peso", "Espaco", "Tamanho Desdobrado", "Tamanho Dobrado", "Conjuntos de Blocos")
    
    do {
        Clear-Host; Write-Host "=== Confirmacao: $($ItemData.Nome) ==="; Write-Host
        for ($i = 0; $i -lt $displayFields.Count; $i++) {
            $fieldName = $displayFields[$i]; $propName = $fieldName.Replace(" ", "")
            $fieldValue = $ItemData.$propName
            $line = "  $fieldName`: $fieldValue"; if ($i -eq $selectedIndex) { Write-Host (">" + $line.Substring(1)) -ForegroundColor Green } else { Write-Host $line }
        }
        Write-Host; Write-Host "- Nota: Use Setas para navegar e Enter para editar"; Write-Host
        Write-Host "Pressione " -NoNewline; Write-Host "F1" -ForegroundColor Blue -NoNewline; Write-Host " para Confirmar"
        Write-Host "Pressione " -NoNewline; Write-Host "F2" -ForegroundColor Red -NoNewline; Write-Host " para Cancelar"
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
        switch ($key) {
            38 { if ($selectedIndex -gt 0) { $selectedIndex-- } }; 40 { if ($selectedIndex -lt ($displayFields.Count - 1)) { $selectedIndex++ } }
            112 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return "CONFIRM" }
            113 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return "CANCEL" }
            13 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $selectedIndex }
        }
    } while ($true)
}

function Show-BackpackConfirmation {
    param ([Parameter(Mandatory=$true)][PSCustomObject]$ItemData, [int]$InitialSelectedIndex = 0)
    
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize; (Get-Host).UI.RawUI.CursorSize = 0
    $selectedIndex = $InitialSelectedIndex
    $displayFields = @("Nome", "Peso", "Espaco", "Tamanho Desdobrado", "Tamanho Dobrado", "Conjuntos de Blocos")
    
    do {
        Clear-Host; Write-Host "=== Confirmacao: $($ItemData.Nome) ==="; Write-Host
        for ($i = 0; $i -lt $displayFields.Count; $i++) {
            $fieldName = $displayFields[$i]; $propName = $fieldName.Replace(" ", "")
            $fieldValue = $ItemData.$propName
            $line = "  $fieldName`: $fieldValue"; if ($i -eq $selectedIndex) { Write-Host (">" + $line.Substring(1)) -ForegroundColor Green } else { Write-Host $line }
        }
        Write-Host; Write-Host "- Nota: Use Setas para navegar e Enter para editar"; Write-Host
        Write-Host "Pressione " -NoNewline; Write-Host "F1" -ForegroundColor Blue -NoNewline; Write-Host " para Confirmar"
        Write-Host "Pressione " -NoNewline; Write-Host "F2" -ForegroundColor Red -NoNewline; Write-Host " para Cancelar"
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
        switch ($key) {
            38 { if ($selectedIndex -gt 0) { $selectedIndex-- } }; 40 { if ($selectedIndex -lt ($displayFields.Count - 1)) { $selectedIndex++ } }
            112 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return "CONFIRM" }
            113 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return "CANCEL" }
            13 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $selectedIndex }
        }
    } while ($true)
}

function Show-AmmoLegend {
    Clear-Host
    Write-Host "=== Legenda das Colunas (Municao) ==="; Write-Host
    
    Write-Host "Lv:              O nivel de penetracao da municao (escala de 0 a 7)."
    Write-Host "Pen:             O valor exato de penetracao. Quanto maior, melhor contra blindagem."
    Write-Host "Dano Base:       O dano causado diretamente a vida do alvo (carne)."
    Write-Host "Dano blindag:    A porcentagem do dano que e aplicada diretamente na durabilidade da blindagem."
    Write-Host "Vel(m/s):        A velocidade inicial do projetil em metros por segundo."
    Write-Host "Prec:            O bonus ou penalidade de precisao que a municao aplica na arma."
    Write-Host "CRV:             O modificador no Controle de Recuo Vertical da arma."
    Write-Host "CRH:             O modificador no Controle de Recuo Horizontal da arma."
    Write-Host "Chance Ferir:    A probabilidade da municao causar um ferimento grave (debuff)."
    Write-Host "Calibre:         O calibre da municao, que define a compatibilidade com as armas."
    Write-Host; Write-Host "Pressione qualquer tecla para voltar..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}

function Show-WeaponLegend {
    Clear-Host
    Write-Host "=== Legenda dos Atributos de Armas ==="; Write-Host
    
    Write-Host "CRV:            Controle de recuo vertical"
    Write-Host "CRH:            Controle de recuo horizontal"
    Write-Host "Ergo:           Ergonomia"
    Write-Host "Prec:           Precisao"
    Write-Host "Esta.DA:        Estabilidade de Arma. Impacta o atraso do balanco da"
    Write-Host "                respiracao, a intensidade do balanco, a intensidade do"
    Write-Host "                balanco do movimento e a estabilidade quando atingido."
    Write-Host "Esta.SM:        Controla a dispersao dos tiros quando se atira sem mirar (hip-fire)."
    Write-Host "Dis(m):         Distancia Efetiva (Metros): Alcance onde o projetil tem maxima eficacia antes de perder dano."
    Write-Host "Vel.bo:         Velocidade de Saida (m/s): A velocidade do projetil ao deixar o cano da arma."
    Write-Host "Poder.DFG:      Poder de fogo"
    Write-Host "Cad:            Cadencia"
    Write-Host "ModoDisparo:    Os modos de disparo que a arma possui (Ex: Semi, Auto, A.Ferrolho)."
    Write-Host
    Write-Host "Melh.Cano:      Indica a disponibilidade de customizacao do cano e suas melhorias."
    Write-Host "                Custom:  Os canos disponiveis para essa arma possuem apenas o beneficio de customizacao"
    Write-Host "                CF:      Cano Fixo, nao pode ser trocado."
    Write-Host "                CF D-:   Cano Fixo com penalidade de dano."
    Write-Host "                CF D+:   Cano Fixo com melhoria de dano."
    Write-Host "                Padrao+: O cano de padrao e o melhor; customizacoes podem piorar o Dano ou Alcance."
    Write-Host "                A+:      Possui disponibilidade de cano que oferece melhoria de Alcance."
    Write-Host "                D+:      Possui disponibilidade de cano que oferece melhoria de Dano."
    Write-Host "                D+ A+:   Possui disponibilidade de cano que oferece melhoria de Dano e Alcance."
    Write-Host
    Write-Host "Pressione qualquer tecla para voltar..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}

function Show-GastronomyLegend {
    Clear-Host
    Write-Host "=== Legenda das Colunas ==="; Write-Host
    
    Write-Host "Nome:               O nome do item."; Write-Host
    Write-Host "Hidratacao:         Pontos de hidratacao que o item recupera (pode ser negativo)."; Write-Host
    Write-Host "Energia:            Pontos de energia que o item recupera (pode ser negativo)."; Write-Host
    Write-Host "Rec.Stamina:        Nivel de recuperacao de estamina (folego)."; Write-Host
    Write-Host "Espaco(HxV):        Formato 'Horizontal x Vertical' que indica o numero de slots"; Write-Host "                    ocupados pelo item no inventario."; Write-Host
    Write-Host "Hidrat.Slot:        Custo-beneficio de HIDRATACAO POR SLOT."; Write-Host "                    Calculado como: (Hidratacao / Total de Slots)."; Write-Host
    Write-Host "Energ.Slot:         Custo-beneficio de ENERGIA POR SLOT."; Write-Host "                    Calculado como: (Energia / Total de Slots)."; Write-Host
    Write-Host "Delay:              Tempo em segundos para consumir completamente o item."; Write-Host
    Write-Host "Pressione qualquer tecla para voltar..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}

function Show-PharmaceuticalLegend {
    param ([string]$Category)
    Clear-Host
    Write-Host "=== Legenda das Colunas ($Category) ==="; Write-Host
    
    switch ($Category) {
        "Analgesico" {
            Write-Host "Usos:               Quantidade de vezes que o item pode ser usado."; Write-Host
            Write-Host "Duracao:            Tempo do efeito em segundos para um unico uso."; Write-Host
            Write-Host "Desidratacao:       Pontos de hidratacao perdidos por uso."; Write-Host
            Write-Host "Tempo de Atraso:    Tempo em segundos para consumir o item."; Write-Host
            Write-Host "Dur. Max:           Duracao maxima total do efeito."; Write-Host "                    Calculado como: (Usos * Duracao)."; Write-Host
            Write-Host "Des. Max:           Desidratacao maxima total apos todos os usos."; Write-Host "                    Calculado como: (Usos * Desidratacao)."
        }
        "Bandagem" {
            Write-Host "Usos:               Quantidade de vezes que o item pode ser usado."; Write-Host
            Write-Host "Tempo de Atraso:    Tempo em segundos para aplicar o item."; Write-Host
            Write-Host "Custo Durabilidade: Pontos de durabilidade gastos por uso em um kit medico."
        }
        "Kit cirurgico" {
            Write-Host "Usos:               Quantidade de vezes que o item pode ser usado."; Write-Host
            Write-Host "Tempo de Atraso:    Tempo em segundos para aplicar o item."; Write-Host
            Write-Host "Desidratacao:       Pontos de hidratacao perdidos ao usar o item."; Write-Host
            Write-Host "Rec. HP:            Pontos de vida (HP) recuperados por uso."; Write-Host
            Write-Host "Custo Dur.:         Pontos de durabilidade gastos por uso em um kit medico."; Write-Host
            Write-Host "Espaco(HxV):        Formato 'Horizontal x Vertical' dos slots ocupados."
        }
        "Nebulizador" {
            Write-Host "Usos:               Quantidade de vezes que o item pode ser usado."; Write-Host
            Write-Host "Tempo de Atraso:    Tempo em segundos para aplicar o item."; Write-Host
            Write-Host "Custo Durabilidade: Pontos de durabilidade gastos por uso em um kit medico."
        }
        "Kit medico" {
            Write-Host "Durabilidade:       Pontos totais de durabilidade do kit."; Write-Host
            Write-Host "Desidratacao:       Pontos de hidratacao perdidos ao usar o kit."; Write-Host
            Write-Host "Vel. Cura:          Velocidade com que o kit cura ferimentos."; Write-Host
            Write-Host "Delay:              Tempo em segundos para aplicar o item."; Write-Host
            Write-Host "Custo Dur.:         Quantidade de durabilidade gasta por uso."; Write-Host
            Write-Host "Espaco(HxV):        Formato 'Horizontal x Vertical' dos slots ocupados."; Write-Host
            Write-Host "Durab. Slot:        Custo-beneficio de DURABILIDADE POR SLOT."; Write-Host "                    Calculado como: (Durabilidade / Total de Slots)."
        }
        "Estimulantes" {
            Write-Host "Efeito Principal:   O principal bonus fornecido pelo estimulante."; Write-Host
            Write-Host "Duracao:            Tempo do efeito em segundos."; Write-Host
            Write-Host "Desidratacao:       Pontos de hidratacao perdidos ao usar o item."; Write-Host
            Write-Host "Red. Energia:       Pontos de energia perdidos ao usar o item."; Write-Host
            Write-Host "Delay:              Tempo em segundos para aplicar o item."
        }
    }
    Write-Host; Write-Host "Pressione qualquer tecla para voltar..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}

function Show-GrenadeLegend {
    Clear-Host
    Write-Host "=== Legenda das Colunas (Granadas) ==="; Write-Host
    
    Write-Host "Delay Explosao:   O tempo minimo e maximo em segundos para a detonacao."; Write-Host
    Write-Host "Alcance:          O raio efetivo da granada (Muito Longo > Longo > Padrao)."; Write-Host
    Write-Host "Dano Blind.:      O potencial de dano contra blindagem (Superior > Padrao)."; Write-Host
    Write-Host "Penetracao:       A capacidade de penetrar blindagens (Superior > Padrao)."; Write-Host
    Write-Host "Fragmentos:       A quantidade de fragmentos gerados (Grande > Pequeno)."; Write-Host
    Write-Host "Tipo Frags.:      O tipo de material dos fragmentos (Peca de Aco > Peca de Ferro)."; Write-Host
    Write-Host "Tempo Efeito:     A duracao em segundos de efeitos continuos (fumaca, gas, fogo)."; Write-Host
    Write-Host "Pressione qualquer tecla para voltar..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}

function Show-HelmetLegend {
    Clear-Host
    Write-Host "=== Legenda das Colunas (Capacetes) ==="; Write-Host
    
    Write-Host "Nome do Capacete:   O nome do item."; Write-Host
    Write-Host "Peso:               O peso do capacete em quilogramas (kg)."; Write-Host
    Write-Host "Dur.:               Pontos totais de durabilidade do capacete."; Write-Host
    Write-Host "Cl:                 A Classe de Blindagem do capacete (de 1 a 6)."; Write-Host
    Write-Host "Material:           O material principal de fabricacao do capacete."; Write-Host
    Write-Host "Bloqueio:           O nivel de bloqueio sonoro que o capacete causa."; Write-Host "                    (Severe > Moderate > Low > /////)."; Write-Host
    Write-Host "Vel.M:              A porcentagem de penalidade na velocidade de movimento."; Write-Host
    Write-Host "Ergo:               A penalidade nos pontos de ergonomia."; Write-Host
    Write-Host "Area Protegida:     As partes da cabeca que o capacete protege."; Write-Host "                    (Head, Ears, Face > Head, Ears > Head)."; Write-Host
    Write-Host "Ricoch:             A chance de um projetil ricochetear no capacete."; Write-Host "                    (High > Medium > Low)."; Write-Host
    Write-Host "Captad:             A potencia do fone de ouvido para captar sons do ambiente."; Write-Host "                    (Medium > Bad)."; Write-Host
    Write-Host "Red.Ru:             A potencia do fone de ouvido para reduzir ruidos altos."; Write-Host "                    (Strong > Medium > Bad)."; Write-Host
    Write-Host "Acessorio:          Indica a compatibilidade com acessorios taticos (TE) e mascaras."; Write-Host
    Write-Host "Cl Max Masc:       Mostra a Classe (Cl) maxima da mascara compativel ou da protecao facial embutida (indicada com *)."
    Write-Host "                   Obs: Esta coluna e bastante dependente da adicao de dados de mascaras e suas compatibilidades."
    Write-Host
    Write-Host "Pressione qualquer tecla para voltar..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}

function Show-BodyArmorLegend {
    Clear-Host
    Write-Host "=== Legenda das Colunas (Coletes) ==="; Write-Host
    
    Write-Host "Nome do Colete:   O nome do item."
    Write-Host "Peso:             O peso do colete em quilogramas (kg)."
    Write-Host "Cl:               A Classe de Blindagem do colete (de 1 a 6)."
    Write-Host "Dur.:             Pontos totais de durabilidade do colete."
    Write-Host "Material:         O material principal de fabricacao do colete."
    Write-Host "Vel.M:            A porcentagem de penalidade na velocidade de movimento."
    Write-Host "Ergo:             A penalidade nos pontos de ergonomia."
    Write-Host "Area Protegida:   As partes do corpo que o colete protege."
    Write-Host; Write-Host "Pressione qualquer tecla para voltar..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}

function Show-ArmoredRigLegend {
    Clear-Host
    Write-Host "=== Legenda das Colunas (Coletes Blindados) ==="; Write-Host
    
    Write-Host "Nome do Colete:      O nome do item."
    Write-Host "Peso:                O peso do colete em quilogramas (kg)."
    Write-Host "Cl:                  A Classe de Blindagem do colete (de 1 a 6)."
    Write-Host "Dur.:                Pontos totais de durabilidade do colete."
    Write-Host "Material:            O material principal de fabricacao do colete."
    Write-Host "Vel.M:               A porcentagem de penalidade na velocidade de movimento."
    Write-Host "Ergo:                A penalidade nos pontos de ergonomia."
    Write-Host "Esp:                 A quantidade de slots de armazenamento que o colete oferece."
    Write-Host "Area Protegida:      As partes do corpo que o colete protege."
    Write-Host "Conj d. blocos(HxV): O layout e o tamanho dos slots internos (Formato: Horizontal x Vertical)"
    Write-Host; Write-Host "Pressione qualquer tecla para voltar..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}
function Show-MaskLegend {
    Clear-Host
    Write-Host "=== Legenda das Colunas (Mascaras) ==="; Write-Host
    
    Write-Host "Nome da mascara:      O nome do item."
    Write-Host "Peso:                 O peso da mascara em quilogramas (kg)."
    Write-Host "Dur.:                 Pontos totais de durabilidade da mascara."
    Write-Host "Cl:                   A Classe de Blindagem da mascara (de 1 a 6)."
    Write-Host "Material:             O material principal de fabricacao da mascara."
    Write-Host "Chance de Ricochete:  A chance de um projetil ricochetear na mascara (Alto > Medio > Baixo)."
    Write-Host; Write-Host "Pressione qualquer tecla para voltar..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}

function Show-GasMaskLegend {
    Clear-Host
    Write-Host "=== Legenda das Colunas (Mascaras de Gas) ==="; Write-Host
    
    Write-Host "Nome da mascara de gas: O nome do item."
    Write-Host "Peso:                   O peso da mascara (nao em kg)."
    Write-Host "Dur.:                   Pontos totais de durabilidade da mascara."
    Write-Host "Anti-Veneno:            O nivel de protecao contra gas venenoso (Forte > Medio > Fraco)."
    Write-Host "Anti-Flash:             O nivel de protecao contra granadas de luz (Forte > Medio > Fraco > Nao possui)."
    Write-Host; Write-Host "Pressione qualquer tecla para voltar..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}

function Show-HeadsetLegend {
    Clear-Host
    Write-Host "=== Legenda das Colunas (Fones de Ouvido) ==="; Write-Host
    
    Write-Host "Nome do fone de ouvido: O nome do item."
    Write-Host "Peso:                   O peso do fone de ouvido em quilogramas (kg)."
    Write-Host "Captador de Som:        O nivel de amplificacao de sons do ambiente (Forte > Medio > Fraco)."
    Write-Host "Reducao de Ruido:       O nivel de reducao de ruidos altos, como tiros (Forte > Medio > Fraco)."
    Write-Host; Write-Host "Pressione qualquer tecla para voltar..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}

function Show-UnarmoredRigLegend {
    Clear-Host
    Write-Host "=== Legenda das Colunas (Coletes Nao Blindados) ==="; Write-Host
    Write-Host "Peso:               O peso do colete em quilogramas (kg)."
    Write-Host "Espaco:             A quantidade de slots de armazenamento que o colete oferece."
    Write-Host "Desdobrada:         O espaco que o item ocupa no inventario no formato 'Horizontal x Vertical'."
    Write-Host "Dobrada:            O espaco que o item ocupa quando dobrado, tambem no formato 'HxV'."
    Write-Host "Conj d. blocos(HxV): O layout e o tamanho dos bolsos/compartimentos internos."
    Write-Host "+Armaz -Espaco:      Calculo de eficiencia: (Total de Slots de Armazenamento - Espaco Ocupado Desdobrado)."
    Write-Host; Write-Host "Pressione qualquer tecla para voltar..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}

function Show-BackpackLegend {
    Clear-Host
    Write-Host "=== Legenda das Colunas (Mochilas) ==="; Write-Host
    Write-Host "Peso:               O peso da mochila em quilogramas (kg)."
    Write-Host "Espaco:             A quantidade de slots de armazenamento que a mochila oferece."
    Write-Host "Desdobrada:         O espaco que o item ocupa no inventario no formato 'Horizontal x Vertical'."
    Write-Host "Dobrada:            O espaco que o item ocupa quando dobrado, tambem no formato 'HxV'."
    Write-Host "Conj d. blocos(HxV): O layout e o tamanho dos bolsos/compartimentos internos."
    Write-Host "+Armaz -Espaco:      Calculo de eficiencia: (Total de Slots de Armazenamento - Espaco Ocupado Desdobrado)."
    Write-Host; Write-Host "Pressione qualquer tecla para voltar..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}

function Show-HelpCriteriaTemplate {
    param(
        [string]$Title,
        [array]$HelpData,
        [switch]$WideHeader
    )
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize
    (Get-Host).UI.RawUI.CursorSize = 0
    do {
        Clear-Host
        Write-Host "=== $Title ==="; Write-Host
        if ($WideHeader) {
            Write-Host "Criterio Primario                       1 Desempate           2 Desempate                   3 Desempate"
            Write-Host "--------------------------------------  --------------------  ----------------------------  ----------------"
        } else {
            Write-Host "Criterio Primario     1 Desempate       2 Desempate                   3 Desempate"
            Write-Host "--------------------  ----------------  ----------------------------  ----------------"
        }
        
        foreach ($item in $HelpData) {
            if ($WideHeader) {
                $line = ("{0,-38}  {1,-20}  {2,-28}  {3,-16}" -f $item.'Criterio Primario', $item.'1 Desempate', $item.'2 Desempate', $item.'3 Desempate')
            } else {
                $line = ("{0,-20}  {1,-16}  {2,-28}  {3,-16}" -f $item.'Criterio Primario', $item.'1 Desempate', $item.'2 Desempate', $item.'3 Desempate')
            }
            Write-Host $line
        }
        Write-Host @"
`nExplicacao:
1. O sistema ordena primeiro pelo Criterio Primario selecionado.
2. Em caso de empate, usa o 1 Desempate, depois o 2 e 3 se necessario.
3. A ordem (maior para menor ou menor para maior) depende do criterio e da sua
   selecao na tela de busca.
"@
        Write-Host; Write-Host "Pressione " -NoNewline; Write-Host "F1" -ForegroundColor Yellow -NoNewline; Write-Host " para voltar..."
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
    } while ($key -ne 112)
    (Get-Host).UI.RawUI.CursorSize = $originalCursorSize
}

function Show-AmmoHelpCriteria {
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize
    (Get-Host).UI.RawUI.CursorSize = 0
    $helpData = @(
        [PSCustomObject]@{'Criterio Primario' = 'Alfabetico'; '1 Desempate' = 'Nivel (Lv)'; '2 Desempate' = 'Dano Base'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = 'Dano Base'; '1 Desempate' = 'Nivel (Lv)'; '2 Desempate' = 'Penetracao'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = 'Nivel de penetracao'; '1 Desempate' = 'Dano Base'; '2 Desempate' = 'Penetracao'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = 'Chance de Ferir'; '1 Desempate' = 'Dano Base'; '2 Desempate' = 'Nivel (Lv)'; '3 Desempate' = 'Penetracao'},
        [PSCustomObject]@{'Criterio Primario' = 'Velocidade inicial'; '1 Desempate' = 'Nivel (Lv)'; '2 Desempate' = 'Dano Base'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = 'Precisao'; '1 Desempate' = 'Nivel (Lv)'; '2 Desempate' = 'Dano Base'; '3 Desempate' = 'Penetracao'},
        [PSCustomObject]@{'Criterio Primario' = 'Penetracao'; '1 Desempate' = 'Nivel (Lv)'; '2 Desempate' = 'Dano Base'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = 'Dano de blindagem'; '1 Desempate' = 'Nivel (Lv)'; '2 Desempate' = 'Penetracao'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = 'Controle de recuo vertical'; '1 Desempate' = 'Nivel (Lv)'; '2 Desempate' = 'Dano Base'; '3 Desempate' = 'Penetracao'},
        [PSCustomObject]@{'Criterio Primario' = 'Controle de recuo horizontal'; '1 Desempate' = 'Nivel (Lv)'; '2 Desempate' = 'Dano Base'; '3 Desempate' = 'Penetracao'}
    )
    do {
        Clear-Host
        Write-Host "=== Como Funcionam os Criterios (Busca de Municao) ==="; Write-Host
        Write-Host "Criterio Primario                  1 Desempate       2 Desempate       3 Desempate"
        Write-Host "---------------------------------  ----------------  ----------------  ----------------"
        foreach ($item in $helpData) {
            $line = ("{0,-33}  {1,-16}  {2,-16}  {3,-16}" -f $item.'Criterio Primario', $item.'1 Desempate', $item.'2 Desempate', $item.'3 Desempate')
            Write-Host $line
        }
        Write-Host @"
`nExplicacao:
1. O sistema ordena primeiro pelo Criterio Primario selecionado.
2. Em caso de empate, usa o 1 Desempate, depois o 2 e 3 se necessario.
3. A ordem padrao e Decrescente (maior para menor), exceto para 'Alfabetico'.
"@
        Write-Host; Write-Host "Pressione " -NoNewline; Write-Host "F1" -ForegroundColor Yellow -NoNewline; Write-Host " para voltar..."
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
    } while ($key -ne 112)
    (Get-Host).UI.RawUI.CursorSize = $originalCursorSize
}

function Show-WeaponHelpCriteria {
    $helpData = @(
        [PSCustomObject]@{'Criterio Primario' = 'Calibre'; '1 Desempate' = 'Poder de fogo'; '2 Desempate' = 'Controle de recuo horizontal'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = 'Controle de recuo vertical'; '1 Desempate' = 'Precisao'; '2 Desempate' = 'Controle de recuo horizontal'; '3 Desempate' = 'Cadencia'},
        [PSCustomObject]@{'Criterio Primario' = 'Controle de recuo horizontal'; '1 Desempate' = 'Precisao'; '2 Desempate' = 'Controle de recuo vertical'; '3 Desempate' = 'Cadencia'},
        [PSCustomObject]@{'Criterio Primario' = 'Ergonomia'; '1 Desempate' = 'Precisao'; '2 Desempate' = 'Cadencia'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = 'Estabilidade de arma'; '1 Desempate' = 'Precisao'; '2 Desempate' = 'Controle de recuo horizontal'; '3 Desempate' = 'Cadencia'},
        [PSCustomObject]@{'Criterio Primario' = 'Precisao'; '1 Desempate' = 'Cadencia'; '2 Desempate' = 'Controle de recuo horizontal'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = 'Estabilidade sem mirar'; '1 Desempate' = 'Precisao'; '2 Desempate' = 'Cadencia'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = 'Distancia Efetiva'; '1 Desempate' = 'Velocidade de Saida'; '2 Desempate' = 'Cadencia'; '3 Desempate' = 'Controle de recuo horizontal'},
        [PSCustomObject]@{'Criterio Primario' = 'Velocidade de Saida'; '1 Desempate' = 'Distancia Efetiva'; '2 Desempate' = '-'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = 'Modo de disparo'; '1 Desempate' = 'Poder de fogo'; '2 Desempate' = '-'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = 'Cadencia'; '1 Desempate' = 'Poder de fogo'; '2 Desempate' = '-'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = 'Poder de fogo'; '1 Desempate' = 'Velocidade de Saida'; '2 Desempate' = 'Cadencia'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = 'Melhoria de cano'; '1 Desempate' = 'Poder de fogo'; '2 Desempate' = 'Distancia Efetiva'; '3 Desempate' = 'Cadencia'}
    )
    Show-HelpCriteriaTemplate -Title "Como Funcionam os Criterios (Busca de Armas)" -HelpData $helpData -WideHeader
}

function Show-GastronomyHelpCriteria {
    $helpData = @(
        [PSCustomObject]@{'Criterio Primario' = 'Hidratacao'; '1 Desempate' = 'Hidrat. por Slot'; '2 Desempate' = 'Espaco Ocupado'; '3 Desempate' = 'Energia'},
        [PSCustomObject]@{'Criterio Primario' = 'Energia'; '1 Desempate' = 'Energ. por Slot'; '2 Desempate' = 'Espaco Ocupado'; '3 Desempate' = 'Hidratacao'},
        [PSCustomObject]@{'Criterio Primario' = 'Hidrat. por Slot'; '1 Desempate' = 'Espaco Ocupado'; '2 Desempate' = 'Hidratacao'; '3 Desempate' = 'Energ. por Slot'},
        [PSCustomObject]@{'Criterio Primario' = 'Energ. por Slot'; '1 Desempate' = 'Espaco Ocupado'; '2 Desempate' = 'Energia'; '3 Desempate' = 'Hidrat. por Slot'}
    )
    Show-HelpCriteriaTemplate -Title "Como Funcionam os Criterios (Busca Gastronomica)" -HelpData $helpData
}

function Show-PharmaceuticalHelpCriteria {
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize
    (Get-Host).UI.RawUI.CursorSize = 0
    
    $helpData = @(
        [PSCustomObject]@{'Criterio Primario' = 'Analgesico'; 'Descricao' = 'Ordena por Usos e depois por Duracao.'},
        [PSCustomObject]@{'Criterio Primario' = 'Bandagem'; 'Descricao' = 'Ordena apenas por Usos.'},
        [PSCustomObject]@{'Criterio Primario' = 'Kit Cirurgico'; 'Descricao' = 'Ordenacao simples por criterio unico.'},
        [PSCustomObject]@{'Criterio Primario' = 'Nebulizador'; 'Descricao' = 'Ordena apenas por Usos.'},
        [PSCustomObject]@{'Criterio Primario' = 'Kit Medico'; 'Descricao' = 'Ordenacao simples por criterio unico.'},
        [PSCustomObject]@{'Criterio Primario' = 'Estimulantes'; 'Descricao' = 'Ordena por Efeito e depois por Duracao.'}
    )
    do {
        Clear-Host
        Write-Host "=== Como Funcionam os Criterios (Busca Farmaceutica) ==="; Write-Host
        foreach ($item in $helpData) {
            Write-Host ("{0,-18} - {1}" -f $item.'Criterio Primario', $item.Descricao)
        }
        Write-Host; Write-Host "Pressione " -NoNewline; Write-Host "F1" -ForegroundColor Yellow -NoNewline; Write-Host " para voltar..."
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
    } while ($key -ne 112)
    (Get-Host).UI.RawUI.CursorSize = $originalCursorSize
}

function Show-ThrowableHelpCriteria {
    $helpData = @(
        [PSCustomObject]@{'Criterio Primario' = 'Delay Explosao'; '1 Desempate' = 'Alcance'; '2 Desempate' = '-'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = 'Alcance'; '1 Desempate' = 'Delay Explosao'; '2 Desempate' = '-'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = 'Dano Blindagem'; '1 Desempate' = 'Alcance'; '2 Desempate' = 'Delay Explosao'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = 'Penetracao'; '1 Desempate' = 'Dano Blindagem'; '2 Desempate' = 'Alcance'; '3 Desempate' = 'Delay Explosao'},
        [PSCustomObject]@{'Criterio Primario' = 'Fragmentos'; '1 Desempate' = 'Penetracao'; '2 Desempate' = 'Dano Blindagem'; '3 Desempate' = 'Alcance'},
        [PSCustomObject]@{'Criterio Primario' = 'Tipo Frags.'; '1 Desempate' = 'Fragmentos'; '2 Desempate' = 'Penetracao'; '3 Desempate' = 'Dano Blindagem'},
        [PSCustomObject]@{'Criterio Primario' = 'Tempo Efeito'; '1 Desempate' = 'Alcance'; '2 Desempate' = 'Delay Explosao'; '3 Desempate' = '-'}
    )
    Show-HelpCriteriaTemplate -Title "Como Funcionam os Criterios (Busca de Granadas)" -HelpData $helpData
}

function Show-HelmetHelpCriteria {
    $helpData = @(
        [PSCustomObject]@{'Criterio Primario' = 'Peso'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Durabilidade'; '3 Desempate' = 'Bloqueio Sonoro'},
        [PSCustomObject]@{'Criterio Primario' = 'Durabilidade'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Bloqueio Sonoro'; '3 Desempate' = 'Peso'},
        [PSCustomObject]@{'Criterio Primario' = 'Classe (Cl)'; '1 Desempate' = 'Durabilidade'; '2 Desempate' = 'Bloqueio Sonoro'; '3 Desempate' = 'Peso'},
        [PSCustomObject]@{'Criterio Primario' = 'Cl Max Masc'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Durabilidade'; '3 Desempate' = 'Bloqueio Sonoro'},
        [PSCustomObject]@{'Criterio Primario' = 'Material'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Durabilidade'; '3 Desempate' = 'Bloqueio Sonoro'},
        [PSCustomObject]@{'Criterio Primario' = 'Bloqueio Sonoro'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Durabilidade'; '3 Desempate' = 'Peso'},
        [PSCustomObject]@{'Criterio Primario' = 'Velocidade (Vel.M)'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Bloqueio Sonoro'; '3 Desempate' = 'Peso'},
        [PSCustomObject]@{'Criterio Primario' = 'Ergonomia'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Bloqueio Sonoro'; '3 Desempate' = 'Peso'},
        [PSCustomObject]@{'Criterio Primario' = 'Area Protegida'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Bloqueio Sonoro'; '3 Desempate' = 'Durabilidade'},
        [PSCustomObject]@{'Criterio Primario' = 'Ricochete (Ricoch)'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Bloqueio Sonoro'; '3 Desempate' = 'Durabilidade'},
        [PSCustomObject]@{'Criterio Primario' = 'Captador de Som'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Durabilidade'; '3 Desempate' = 'Bloqueio Sonoro'},
        [PSCustomObject]@{'Criterio Primario' = 'Reducao de Ruido'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Durabilidade'; '3 Desempate' = 'Bloqueio Sonoro'},
        [PSCustomObject]@{'Criterio Primario' = 'Acessorio'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Durabilidade'; '3 Desempate' = 'Bloqueio Sonoro'}
    )
    Show-HelpCriteriaTemplate -Title "Como Funcionam os Criterios (Busca de Capacetes)" -HelpData $helpData
}

function Show-BodyArmorHelpCriteria {
    $helpData = @(
        [PSCustomObject]@{'Criterio Primario' = 'Peso'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Durabilidade'; '3 Desempate' = 'Velocidade (Vel.M)'},
        [PSCustomObject]@{'Criterio Primario' = 'Durabilidade'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Peso'; '3 Desempate' = 'Velocidade (Vel.M)'},
        [PSCustomObject]@{'Criterio Primario' = 'Classe (Cl)'; '1 Desempate' = 'Durabilidade'; '2 Desempate' = 'Peso'; '3 Desempate' = 'Velocidade (Vel.M)'},
        [PSCustomObject]@{'Criterio Primario' = 'Material'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Durabilidade'; '3 Desempate' = 'Peso'},
        [PSCustomObject]@{'Criterio Primario' = 'Velocidade (Vel.M)'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Durabilidade'; '3 Desempate' = 'Peso'},
        [PSCustomObject]@{'Criterio Primario' = 'Ergonomia'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Durabilidade'; '3 Desempate' = 'Peso'},
        [PSCustomObject]@{'Criterio Primario' = 'Area Protegida'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Durabilidade'; '3 Desempate' = 'Peso'}
    )
    Show-HelpCriteriaTemplate -Title "Como Funcionam os Criterios (Busca de Coletes Balisticos)" -HelpData $helpData
}

function Show-ArmoredRigHelpCriteria {
    $helpData = @(
        [PSCustomObject]@{'Criterio Primario' = 'Peso'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Durabilidade'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = 'Durabilidade'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Peso'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = 'Classe (Cl)'; '1 Desempate' = 'Durabilidade'; '2 Desempate' = 'Peso'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = 'Material'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Durabilidade'; '3 Desempate' = 'Peso'},
        [PSCustomObject]@{'Criterio Primario' = 'Velocidade (Vel.M)'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = '-'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = 'Ergonomia'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Durabilidade'; '3 Desempate' = 'Peso'},
        [PSCustomObject]@{'Criterio Primario' = 'Armazenamento'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Durabilidade'; '3 Desempate' = 'Peso'},
        [PSCustomObject]@{'Criterio Primario' = 'Area Protegida'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Durabilidade'; '3 Desempate' = 'Peso'}
    )
    Show-HelpCriteriaTemplate -Title "Como Funcionam os Criterios (Busca de Coletes Blindados)" -HelpData $helpData
}

function Show-MaskHelpCriteria {
    $helpData = @(
        [PSCustomObject]@{'Criterio Primario' = 'Peso'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Durabilidade'; '3 Desempate' = 'Chance de Ricochete'},
        [PSCustomObject]@{'Criterio Primario' = 'Durabilidade'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Peso'; '3 Desempate' = 'Chance de Ricochete'},
        [PSCustomObject]@{'Criterio Primario' = 'Classe (Cl)'; '1 Desempate' = 'Durabilidade'; '2 Desempate' = 'Peso'; '3 Desempate' = 'Chance de Ricochete'},
        [PSCustomObject]@{'Criterio Primario' = 'Material'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Durabilidade'; '3 Desempate' = 'Peso'},
        [PSCustomObject]@{'Criterio Primario' = 'Chance de Ricochete'; '1 Desempate' = 'Classe (Cl)'; '2 Desempate' = 'Durabilidade'; '3 Desempate' = 'Peso'}
    )
    Show-HelpCriteriaTemplate -Title "Como Funcionam os Criterios (Busca de Mascaras)" -HelpData $helpData
}

function Show-GasMaskHelpCriteria {
    $helpData = @(
        [PSCustomObject]@{'Criterio Primario' = 'Peso'; '1 Desempate' = 'Anti-Veneno'; '2 Desempate' = 'Durabilidade'; '3 Desempate' = 'Anti-Flash'},
        [PSCustomObject]@{'Criterio Primario' = 'Durabilidade'; '1 Desempate' = 'Anti-Veneno'; '2 Desempate' = 'Anti-Flash'; '3 Desempate' = 'Peso'},
        [PSCustomObject]@{'Criterio Primario' = 'Anti-Veneno'; '1 Desempate' = 'Durabilidade'; '2 Desempate' = 'Anti-Flash'; '3 Desempate' = 'Peso'},
        [PSCustomObject]@{'Criterio Primario' = 'Anti-Flash'; '1 Desempate' = 'Anti-Veneno'; '2 Desempate' = 'Durabilidade'; '3 Desempate' = 'Peso'}
    )
    Show-HelpCriteriaTemplate -Title "Como Funcionam os Criterios (Busca de Mascaras de Gas)" -HelpData $helpData
}

function Show-HeadsetHelpCriteria {
    $helpData = @(
        [PSCustomObject]@{'Criterio Primario' = 'Captador de Som'; '1 Desempate' = 'Reducao de Ruido'; '2 Desempate' = 'Peso'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = 'Reducao de Ruido'; '1 Desempate' = 'Captador de Som'; '2 Desempate' = 'Peso'; '3 Desempate' = '-'}
    )
    Show-HelpCriteriaTemplate -Title "Como Funcionam os Criterios (Busca de Fones de Ouvido)" -HelpData $helpData
}

function Show-UnarmoredRigHelpCriteria {
    $helpData = @(
        [PSCustomObject]@{'Criterio Primario' = 'Peso'; '1 Desempate' = 'Espaco'; '2 Desempate' = '-'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = 'Espaco'; '1 Desempate' = 'Peso'; '2 Desempate' = '-'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = '+Espaco p/armaz -Espaco consumido'; '1 Desempate' = 'Espaco'; '2 Desempate' = 'Peso'; '3 Desempate' = '-'}
    )
    # Requer um cabeçalho maior para o nome do critério
    Show-HelpCriteriaTemplate -Title "Como Funcionam os Criterios (Busca de Coletes Nao Blindados)" -HelpData $helpData -WideHeader
}

function Show-BackpackHelpCriteria {
    $helpData = @(
        [PSCustomObject]@{'Criterio Primario' = 'Peso'; '1 Desempate' = 'Espaco'; '2 Desempate' = '-'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = 'Espaco'; '1 Desempate' = 'Peso'; '2 Desempate' = '-'; '3 Desempate' = '-'},
        [PSCustomObject]@{'Criterio Primario' = '+Espaco p/armaz -Espaco consumido'; '1 Desempate' = 'Espaco'; '2 Desempate' = 'Peso'; '3 Desempate' = '-'}
    )
    # Requer um cabeçalho maior para o nome do critério
    Show-HelpCriteriaTemplate -Title "Como Funcionam os Criterios (Busca de Mochilas)" -HelpData $helpData -WideHeader
}

function Show-ItemFilterScreen {
    param(
        [string]$Title,
        [array]$AllItems,
        [array]$FilterDefinitions,
        [hashtable]$CurrentFilters
    )
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize; (Get-Host).UI.RawUI.CursorSize = 0
    $tempFilters = @{
        SelectedValues = $CurrentFilters.SelectedValues.Clone()
        SelectionMethod = $CurrentFilters.SelectionMethod.Clone()
    }
    $columns = @()
    $maxRows = 0
    foreach ($def in $FilterDefinitions) {
        $uniqueValues = $AllItems | Select-Object -ExpandProperty $def.Property -Unique | ForEach-Object { if ([string]::IsNullOrWhiteSpace($_)) { "/////" } else { $_ } }
        $sortedValues = if ($def.ContainsKey('CustomSortOrder')) {
            # Usa a ordem customizada se ela for fornecida
            $def.CustomSortOrder | Where-Object { $_ -in $uniqueValues }
        } else {
            # Caso contrário, usa a ordem alfabética/numérica padrão
            $uniqueValues | Sort-Object
        }
        $columns += @{
            Definition = $def
            Values = $sortedValues
            SelectedIndex = 0
        }
        if ($sortedValues.Count -gt $maxRows) { $maxRows = $sortedValues.Count }
    }
    $currentColumnIndex = 0
    Clear-Host 
    :filterLoop while ($true) {
        # Lógica de filtro "inteligente"
        $filteredItems = $AllItems; $manualFiltersApplied = $false
        if ($tempFilters.SelectedValues.Keys.Count -gt 0) {
            foreach ($propName in $tempFilters.SelectedValues.Keys) {
                $valuesToHide = $tempFilters.SelectedValues[$propName]
                if ($valuesToHide) {
                    $manualValuesToHide = $valuesToHide | Where-Object { $tempFilters.SelectionMethod["${propName}_$_"] -eq "Manual" }
                    if ($manualValuesToHide) {
                        $manualFiltersApplied = $true
                        $filteredItems = $filteredItems | Where-Object { $_.$propName -notin $manualValuesToHide }
                    }
                }
            }
        }
        if(-not $manualFiltersApplied){ $filteredItems = $AllItems }
        foreach ($col in $columns) {
            $propName = $col.Definition.Property; $possibleValues = $filteredItems | Select-Object -ExpandProperty $propName -Unique; $itemsToRemoveFromSelection = [System.Collections.ArrayList]@()
            if ($tempFilters.SelectedValues.ContainsKey($propName)) { foreach($selectedValue in $tempFilters.SelectedValues[$propName]){ if($tempFilters.SelectionMethod["${propName}_${selectedValue}"] -eq 'Auto' -and $selectedValue -in $possibleValues){ $itemsToRemoveFromSelection.Add($selectedValue) | Out-Null } } }
            if($itemsToRemoveFromSelection.Count -gt 0){ $itemsToRemoveFromSelection | ForEach-Object { $tempFilters.SelectedValues[$propName].Remove($_); $tempFilters.SelectionMethod.Remove("${propName}_${_}") } }
            foreach ($val in $col.Values) { if ($val -notin $possibleValues) { if (-not $tempFilters.SelectedValues.ContainsKey($propName)) { $tempFilters.SelectedValues[$propName] = [System.Collections.ArrayList]@() }; if ($val -notin $tempFilters.SelectedValues[$propName]) { $tempFilters.SelectedValues[$propName].Add($val) | Out-Null; $tempFilters.SelectionMethod["${propName}_${val}"] = "Auto" } } }
        }
        
        [Console]::SetCursorPosition(0, 0)
        # Redesenha o cabeçalho
        $header = ""; $separator = ""
        foreach ($col in $columns) {
            $width = $col.Definition.Width; $formatString = ("{{0,-{0}}}" -f $width)
            if ($columns.IndexOf($col) -eq 0) { $header += "  "; $separator += "  "}
            $header += $formatString -f $col.Definition.Label
            $separator += $formatString -f ('-' * $col.Definition.Label.Length)
        }
        Write-Host "=== $Title (Marque o que deseja OCULTAR) ===" -ForegroundColor Yellow
        Write-Host; Write-Host $header; Write-Host $separator
        # Redesenha a tabela
        for ($i = 0; $i -lt $maxRows; $i++) {
            Write-Host "  " -NoNewline
            for ($colIdx = 0; $colIdx -lt $columns.Count; $colIdx++) {
                $col = $columns[$colIdx]
                $width = $col.Definition.Width
                
                if ($i -lt $col.Values.Count) {
                    $value = $col.Values[$i]
                    $propName = $col.Definition.Property
                    $isManual = $tempFilters.SelectionMethod["${propName}_${value}"] -eq "Manual"
                    $isAuto = $tempFilters.SelectionMethod["${propName}_${value}"] -eq "Auto"
                    $isSelected = $isManual -or $isAuto
                    $prefix = if ($colIdx -eq $currentColumnIndex -and $i -eq $col.SelectedIndex) { ">" } else { " " }
                    $check = if ($isSelected) { "X" } else { " " }
                    $cellContent = "$prefix [$check] $value"
                    
                    $bgColor = if ($colIdx -eq $currentColumnIndex -and $i -eq $col.SelectedIndex) { 'DarkGray' } else { $Host.UI.RawUI.BackgroundColor }
                    $fgColor = if ($isAuto) { 'DarkGray' } elseif ($isManual) { 'DarkYellow' } else { $Host.UI.RawUI.ForegroundColor }
                    
                    Write-Host "$($prefix) [" -NoNewline -BackgroundColor $bgColor
                    Write-Host $check -NoNewline -BackgroundColor $bgColor -ForegroundColor $fgColor
                    Write-Host "] $value" -NoNewline -BackgroundColor $bgColor
                    $padding = [Math]::Max(0, $width - $cellContent.Length)
                    Write-Host (' ' * $padding) -NoNewline -BackgroundColor $Host.UI.RawUI.BackgroundColor
                } else {
                    Write-Host (' ' * $width) -NoNewline -BackgroundColor $Host.UI.RawUI.BackgroundColor
                }
            }
            Write-Host
        }
        # Redesenha o rodapé
        Write-Host; Write-Host "[Cima/Baixo] Move | [Esq/Dir] Troca Coluna | [Enter] Marca/Desmarca"
        Write-Host "Pressione " -NoNewline; Write-Host "F1" -ForegroundColor Blue -NoNewline; Write-Host " para Salvar e Voltar"
        Write-Host "Pressione " -NoNewline; Write-Host "F2" -ForegroundColor Red -NoNewline; Write-Host " para Cancelar/Resetar e Voltar"
        Write-Host (" " * ([Console]::WindowWidth -1))
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
        switch ($key) {
            37 { if ($currentColumnIndex -gt 0) { $currentColumnIndex-- } }
            39 { if ($currentColumnIndex -lt ($columns.Count - 1)) { $currentColumnIndex++ } }
            38 { if ($columns[$currentColumnIndex].SelectedIndex -gt 0) { $columns[$currentColumnIndex].SelectedIndex-- } }
            40 { if ($columns[$currentColumnIndex].SelectedIndex -lt ($columns[$currentColumnIndex].Values.Count - 1)) { $columns[$currentColumnIndex].SelectedIndex++ } }
            13 { 
                $selectedCol = $columns[$currentColumnIndex]; $propName = $selectedCol.Definition.Property; $valueToToggle = $selectedCol.Values[$selectedCol.SelectedIndex]
                if (-not $tempFilters.SelectedValues.ContainsKey($propName)) { $tempFilters.SelectedValues[$propName] = [System.Collections.ArrayList]@() }
                if ($tempFilters.SelectedValues[$propName].Contains($valueToToggle)) {
                    if ($tempFilters.SelectionMethod["${propName}_${valueToToggle}"] -eq "Manual") { $tempFilters.SelectedValues[$propName].Remove($valueToToggle); $tempFilters.SelectionMethod.Remove("${propName}_${valueToToggle}") }
                } else { $tempFilters.SelectedValues[$propName].Add($valueToToggle) | Out-Null; $tempFilters.SelectionMethod["${propName}_${valueToToggle}"] = "Manual" }
            }
            112 { # F1 - Salvar
                $CurrentFilters.SelectedValues = $tempFilters.SelectedValues; $CurrentFilters.SelectionMethod = $tempFilters.SelectionMethod
                (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $CurrentFilters
            }
            113 { # F2 - Cancelar
                (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $null
            }
        }
    }
}

function Show-AmmoFilterScreen {
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize; (Get-Host).UI.RawUI.CursorSize = 0
    
    $allCalibers = Get-ChildItem -Path $AmmoPath -Directory | Select-Object -ExpandProperty Name | Sort-Object
    $woundOptions = @("//////", "Baixo", "Medio", "Alto")
    $penetrationLevels = 0..7
    
    # --- PRE-CARREGAMENTO ---
    $allAmmoCache = @()
    foreach ($caliber in $allCalibers) {
        $ammoFiles = Get-ChildItem -Path (Join-Path $AmmoPath $caliber) -Filter "*.txt" -File
        if ($ammoFiles) {
            foreach ($file in $ammoFiles) {
                $c = @(Get-Content $file.FullName -TotalCount 9)
                if ($c.Count -ge 9) {
                    $lvl = [int]$c[0]
                    $chanceRaw = $c[8].Trim()
                    $chanceDisplay = switch ($chanceRaw) { 'Low' {'Baixo'}; 'Medium' {'Medio'}; 'High' {'Alto'}; default {'//////'} }
                    $allAmmoCache += [PSCustomObject]@{ Caliber = $caliber; Level = $lvl; Wound = $chanceDisplay }
                }
            }
        }
    }
    
    if (-not $script:ammoFilters.ContainsKey('SelectedLevels')) {
        $script:ammoFilters = @{ SelectedLevels = [System.Collections.ArrayList]@(); SelectedCalibers = [System.Collections.ArrayList]@(); SelectedWoundChances = [System.Collections.ArrayList]@(); SelectionMethod = @{} }
    }
    if (-not $script:ammoFilters.ContainsKey('SelectedWoundChances')) { $script:ammoFilters['SelectedWoundChances'] = [System.Collections.ArrayList]@() }

    $tempFilters = @{
        SelectedLevels = [System.Collections.ArrayList]@($script:ammoFilters.SelectedLevels)
        SelectedCalibers = [System.Collections.ArrayList]@($script:ammoFilters.SelectedCalibers)
        SelectedWoundChances = [System.Collections.ArrayList]@($script:ammoFilters.SelectedWoundChances)
        SelectionMethod = $script:ammoFilters.SelectionMethod.Clone()
    }
    
    $selLevels = $tempFilters.SelectedLevels
    $selCalibers = $tempFilters.SelectedCalibers
    $selWounds = $tempFilters.SelectedWoundChances
    $selMethod = $tempFilters.SelectionMethod

    $currentColumn = 0; $levelIndex = 0; $caliberIndex = 0; $woundIndex = 0
    $maxRows = [math]::Max($penetrationLevels.Count, [math]::Max($allCalibers.Count, $woundOptions.Count))
    
    Clear-Host
    Write-Host "=== Filtro de Municoes (Marque o que deseja OCULTAR) ===" -ForegroundColor Yellow; Write-Host
    Write-Host ("  {0,-25}   {1,-25}   {2,-25}" -f "Niveis de Penetracao", "Calibres", "Chance de Ferir")
    Write-Host ("  {0,-25}   {1,-25}   {2,-25}" -f ("-"*24), ("-"*24), ("-"*24))
    $startY = [Console]::CursorTop
    
    # --- NOVA LOGICA 'ANTI-DEADLOCK' ---
    $function:UpdateAutoSelection = {
        # 1. Atualizar Niveis (Auto)
        foreach ($lvl in $penetrationLevels) {
            $items = $allAmmoCache | Where-Object { $_.Level -eq $lvl }
            $shouldHide = $false
            if ($items.Count -eq 0) { $shouldHide = $true } # Se nao existe no DB, esconde
            else {
                # So esconde AUTO se estiver coberto por MANUAL nas outras colunas
                $allHiddenByManual = $true
                foreach ($i in $items) {
                    $calManual = $selMethod["C:$($i.Caliber)"] -eq "Manual"
                    $wndManual = $selMethod["W:$($i.Wound)"] -eq "Manual"
                    if (-not ($calManual -or $wndManual)) { $allHiddenByManual = $false; break }
                }
                $shouldHide = $allHiddenByManual
            }
            
            if ($shouldHide) { if ($lvl -notin $selLevels) { $selLevels.Add($lvl)|Out-Null; $selMethod["L:$lvl"] = "Auto" } }
            else { if ($selMethod["L:$lvl"] -eq "Auto") { $selLevels.Remove($lvl); $selMethod.Remove("L:$lvl") } }
        }

        # 2. Atualizar Calibres (Auto)
        foreach ($cal in $allCalibers) {
            $items = $allAmmoCache | Where-Object { $_.Caliber -eq $cal }
            $shouldHide = $false
            if ($items.Count -eq 0) { $shouldHide = $true }
            else {
                $allHiddenByManual = $true
                foreach ($i in $items) {
                    $lvlManual = $selMethod["L:$($i.Level)"] -eq "Manual"
                    $wndManual = $selMethod["W:$($i.Wound)"] -eq "Manual"
                    if (-not ($lvlManual -or $wndManual)) { $allHiddenByManual = $false; break }
                }
                $shouldHide = $allHiddenByManual
            }

            if ($shouldHide) { if ($cal -notin $selCalibers) { $selCalibers.Add($cal)|Out-Null; $selMethod["C:$cal"] = "Auto" } }
            else { if ($selMethod["C:$cal"] -eq "Auto") { $selCalibers.Remove($cal); $selMethod.Remove("C:$cal") } }
        }

        # 3. Atualizar Chance de Ferir (Auto)
        foreach ($wound in $woundOptions) {
            $items = $allAmmoCache | Where-Object { $_.Wound -eq $wound }
            $shouldHide = $false
            if ($items.Count -eq 0) { $shouldHide = $true }
            else {
                $allHiddenByManual = $true
                foreach ($i in $items) {
                    $lvlManual = $selMethod["L:$($i.Level)"] -eq "Manual"
                    $calManual = $selMethod["C:$($i.Caliber)"] -eq "Manual"
                    if (-not ($lvlManual -or $calManual)) { $allHiddenByManual = $false; break }
                }
                $shouldHide = $allHiddenByManual
            }

            if ($shouldHide) { if ($wound -notin $selWounds) { $selWounds.Add($wound)|Out-Null; $selMethod["W:$wound"] = "Auto" } }
            else { if ($selMethod["W:$wound"] -eq "Auto") { $selWounds.Remove($wound); $selMethod.Remove("W:$wound") } }
        }
    }

    $function:DrawRow = {
        param($i)
        [Console]::SetCursorPosition(0, $startY + $i)
        
        # Coluna 1: Niveis
        $bg1 = if ($currentColumn -eq 0 -and $i -eq $levelIndex) { 'DarkGray' } else { $Host.UI.RawUI.BackgroundColor }
        if ($i -lt $penetrationLevels.Count) {
            $val = $penetrationLevels[$i]; $chk = if ($val -in $selLevels) { "X" } else { " " }
            $color = if ($selMethod["L:$val"] -eq "Manual") { "DarkYellow" } elseif ($chk -eq "X") { "Gray" } else { $Host.UI.RawUI.ForegroundColor }
            $pre = if ($currentColumn -eq 0 -and $i -eq $levelIndex) { ">" } else { " " }
            Write-Host "$pre [" -NoNewline -BackgroundColor $bg1; Write-Host $chk -ForegroundColor $color -NoNewline -BackgroundColor $bg1; Write-Host "] $val" -NoNewline -BackgroundColor $bg1
            Write-Host (" " * (22 - "$val".Length)) -NoNewline -BackgroundColor $Host.UI.RawUI.BackgroundColor
        } else { Write-Host (" " * 28) -NoNewline }
        
        # Coluna 2: Calibres
        $bg2 = if ($currentColumn -eq 1 -and $i -eq $caliberIndex) { 'DarkGray' } else { $Host.UI.RawUI.BackgroundColor }
        if ($i -lt $allCalibers.Count) {
            $val = $allCalibers[$i]; $chk = if ($val -in $selCalibers) { "X" } else { " " }
            $color = if ($selMethod["C:$val"] -eq "Manual") { "DarkYellow" } elseif ($chk -eq "X") { "Gray" } else { $Host.UI.RawUI.ForegroundColor }
            $pre = if ($currentColumn -eq 1 -and $i -eq $caliberIndex) { ">" } else { " " }
            Write-Host "$pre [" -NoNewline -BackgroundColor $bg2; Write-Host $chk -ForegroundColor $color -NoNewline -BackgroundColor $bg2; Write-Host "] $val" -NoNewline -BackgroundColor $bg2
            $pad = 22 - $val.Length; if($pad-lt 0){$pad=0}; Write-Host (" " * $pad) -NoNewline -BackgroundColor $Host.UI.RawUI.BackgroundColor
        } else { Write-Host (" " * 28) -NoNewline }

        # Coluna 3: Chance
        $bg3 = if ($currentColumn -eq 2 -and $i -eq $woundIndex) { 'DarkGray' } else { $Host.UI.RawUI.BackgroundColor }
        if ($i -lt $woundOptions.Count) {
            $val = $woundOptions[$i]; $chk = if ($val -in $selWounds) { "X" } else { " " }
            $color = if ($selMethod["W:$val"] -eq "Manual") { "DarkYellow" } elseif ($chk -eq "X") { "Gray" } else { $Host.UI.RawUI.ForegroundColor }
            $pre = if ($currentColumn -eq 2 -and $i -eq $woundIndex) { ">" } else { " " }
            Write-Host "$pre [" -NoNewline -BackgroundColor $bg3; Write-Host $chk -ForegroundColor $color -NoNewline -BackgroundColor $bg3; Write-Host "] $val" -NoNewline -BackgroundColor $bg3
        }
        $padding = [Console]::WindowWidth - [Console]::CursorLeft - 1; if ($padding -gt 0) { Write-Host (' ' * $padding) -NoNewline }
    }
    
    & $function:UpdateAutoSelection
    for ($i = 0; $i -lt $maxRows; $i++) { & $function:DrawRow $i }
    $footerY = $startY + $maxRows; [Console]::SetCursorPosition(0, $footerY)
    Write-Host; Write-Host; Write-Host "[Cima/Baixo] Move | [Esq/Dir] Troca Coluna | [Enter] Marca"
    Write-Host "Aperte F1 para salvar | Aperte F2 para cancelar"
    
    do {
        $oldL = $levelIndex; $oldC = $caliberIndex; $oldW = $woundIndex; $oldCol = $currentColumn
        [Console]::SetCursorPosition(0, $footerY + 4)
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
        $update = $false
        switch ($key) {
            38 { if ($currentColumn -eq 0 -and $levelIndex -gt 0) { $levelIndex-- }; if ($currentColumn -eq 1 -and $caliberIndex -gt 0) { $caliberIndex-- }; if ($currentColumn -eq 2 -and $woundIndex -gt 0) { $woundIndex-- } }
            40 { if ($currentColumn -eq 0 -and $levelIndex -lt ($penetrationLevels.Count - 1)) { $levelIndex++ }; if ($currentColumn -eq 1 -and $caliberIndex -lt ($allCalibers.Count - 1)) { $caliberIndex++ }; if ($currentColumn -eq 2 -and $woundIndex -lt ($woundOptions.Count - 1)) { $woundIndex++ } }
            37 { if ($currentColumn -gt 0) { $currentColumn-- } }
            39 { if ($currentColumn -lt 2) { $currentColumn++ } }
            13 {
                if ($currentColumn -eq 0) { $v = $penetrationLevels[$levelIndex]; $k = "L:$v"; if ($selMethod[$k] -ne "Auto") { if ($v -in $selLevels) { $selLevels.Remove($v); $selMethod.Remove($k) } else { $selLevels.Add($v)|Out-Null; $selMethod[$k] = "Manual" } } }
                elseif ($currentColumn -eq 1) { $v = $allCalibers[$caliberIndex]; $k = "C:$v"; if ($selMethod[$k] -ne "Auto") { if ($v -in $selCalibers) { $selCalibers.Remove($v); $selMethod.Remove($k) } else { $selCalibers.Add($v)|Out-Null; $selMethod[$k] = "Manual" } } }
                else { $v = $woundOptions[$woundIndex]; $k = "W:$v"; if ($selMethod[$k] -ne "Auto") { if ($v -in $selWounds) { $selWounds.Remove($v); $selMethod.Remove($k) } else { $selWounds.Add($v)|Out-Null; $selMethod[$k] = "Manual" } } }
                $update = $true
            }
            112 { $script:ammoFilters = @{ SelectedLevels = $selLevels; SelectedCalibers = $selCalibers; SelectedWoundChances = $selWounds; SelectionMethod = $selMethod }; (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return }
            113 { $script:ammoFilters = @{ SelectedLevels = [System.Collections.ArrayList]@(); SelectedCalibers = [System.Collections.ArrayList]@(); SelectedWoundChances = [System.Collections.ArrayList]@(); SelectionMethod = @{} }; (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return }
        }
        if ($update) { & $function:UpdateAutoSelection; for ($i = 0; $i -lt $maxRows; $i++) { & $function:DrawRow $i } }
        else {
            if ($oldCol -eq 0) { & $function:DrawRow $oldL } elseif ($oldCol -eq 1) { & $function:DrawRow $oldC } else { & $function:DrawRow $oldW }
            if ($currentColumn -eq 0) { & $function:DrawRow $levelIndex } elseif ($currentColumn -eq 1) { & $function:DrawRow $caliberIndex } else { & $function:DrawRow $woundIndex }
        }
    } while ($true)
}

function Search-WithFilters {
    $global:criterioOrdenacao = "Alfabetico"
    $global:ordemAtual = "Crescente"
    $filtroArma = "Desligado"
    $filtroCategoriaDisplay = "Todas"
    $filtroCategoria = "Todas"
    
    if (-not $script:ammoFilters) { 
        $script:ammoFilters = @{ 
            SelectedLevels = [System.Collections.ArrayList]@()
            SelectedCalibers = [System.Collections.ArrayList]@()
            SelectedWoundChances = [System.Collections.ArrayList]@()
            SelectionMethod = @{} 
        } 
    }
    
    $caliberToClassesMap = @{}
    $weaponFiles = Get-ChildItem -Path $weaponsPath -Filter "*.txt" -File
    foreach ($wf in $weaponFiles) {
        $content = Get-Content -Path $wf.FullName
        if ($content.Count -ge 2) {
            $wClassRaw = $content[0].Trim(); $wCaliber = $content[1].Trim()
            if (-not $caliberToClassesMap.ContainsKey($wCaliber)) { $caliberToClassesMap[$wCaliber] = [System.Collections.ArrayList]@() }
            if ($wClassRaw -notin $caliberToClassesMap[$wCaliber]) { $caliberToClassesMap[$wCaliber].Add($wClassRaw) | Out-Null }
        }
    }

    $criterios = @("Alfabetico", "Dano Base", "Nivel de penetracao", "Chance de Ferir", "Velocidade inicial", "Precisao", "Penetracao", "Dano de blindagem", "Controle de recuo vertical", "Controle de recuo horizontal")
    
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize; (Get-Host).UI.RawUI.CursorSize = 0
    do {
        $ammoData = @()
        $calibresToScan = [System.Collections.ArrayList]@()
        
        if ($filtroArma -ne "Desligado") {
            $wFile = Join-Path $weaponsPath "$filtroArma.txt"
            if (Test-Path $wFile) { $c = @(Get-Content $wFile); if ($c.Count -ge 2) { $calibresToScan.Add($c[1].Trim()) | Out-Null } }
        }
        elseif ($filtroCategoria -ne "Todas") {
            $validCalibers = Get-ChildItem -Path $weaponsPath -Filter "*.txt" -File | ForEach-Object {
                $c = @(Get-Content $_.FullName -TotalCount 2)
                if ($c.Count -ge 2) { if ($c[0].Trim() -eq $filtroCategoria) { $c[1].Trim() } }
            } | Select-Object -Unique
            if ($validCalibers) { $calibresToScan.AddRange($validCalibers) }
        }
        else { $calibresToScan.AddRange((Get-ChildItem -Path $AmmoPath -Directory | Select-Object -ExpandProperty Name)) }

        foreach ($calibre in $calibresToScan) {
            $ammoFiles = Get-ChildItem -Path (Join-Path $AmmoPath $calibre) -Filter "*.txt" -File -ErrorAction SilentlyContinue
            foreach ($file in $ammoFiles) { 
                $content = @(Get-Content -Path $file.FullName)
                if ($content.Count -ge 9) {
                    $chanceRaw = $content[8].Trim()
                    $chanceDisplay = switch ($chanceRaw) { 'Low' {'Baixo'}; 'Medium' {'Medio'}; 'High' {'Alto'}; default {'//////'} }
                    $chanceNum = switch ($chanceRaw) { 'Low' {1}; 'Medium' {2}; 'High' {3}; default {0} }
                    
                    $classesCompativeis = if ($caliberToClassesMap.ContainsKey($calibre)) { $caliberToClassesMap[$calibre] | ForEach-Object { $global:WeaponClassToPortugueseMap[$_] } } else { @("Desconhecida") }
                    
                    $ammoData += [PSCustomObject]@{ 
                        Nome = $file.BaseName; Lv = [int]$content[0]; Penetracao = $content[1]; PenetracaoNum = [int]$content[1]
                        DanoBase = $content[2]; DanoBaseNum = if ($content[2] -match '\((\d+)\)') { [int]$Matches[1] } else { [int]($content[2] -replace '[^\d]', '') }
                        DanoArmadura = $content[3]; Velocidade = [int]$content[4]; Precisao = $content[5]; RecuoVert = $content[6]; RecuoHoriz = $content[7]
                        ChanceFerir = $chanceRaw; ChanceFerirDisplay = $chanceDisplay; ChanceFerirNum = $chanceNum; Calibre = $calibre; ClassesList = $classesCompativeis
                    }
                }
            }
        }

        $filteredData = $ammoData
        $isFilterActive = $false
        
        if ($filtroArma -eq "Desligado" -and $filtroCategoria -eq "Todas") {
            if ($script:ammoFilters.SelectedLevels.Count -gt 0 -or $script:ammoFilters.SelectedCalibers.Count -gt 0 -or ($script:ammoFilters.ContainsKey('SelectedWoundChances') -and $script:ammoFilters.SelectedWoundChances.Count -gt 0)) {
                $isFilterActive = $true
                $filteredData = $filteredData | Where-Object { 
                    ($_.Lv -notin $script:ammoFilters.SelectedLevels) -and 
                    ($_.Calibre -notin $script:ammoFilters.SelectedCalibers) -and
                    ($_.ChanceFerirDisplay -notin $script:ammoFilters.SelectedWoundChances)
                }
            }
        }

        $sortedData = Ordenar-Dados -dados $filteredData
        (Get-Host).UI.RawUI.CursorSize = 0
        Clear-Host
        Write-Host "=== Busca de municao com filtro ==="; Write-Host
        Write-Host "Botoes: " -NoNewline
        Write-Host "F1" -ForegroundColor Cyan -NoNewline; Write-Host " - Mudar Criterio ($global:criterioOrdenacao) | " -NoNewline
        Write-Host "F2" -ForegroundColor Yellow -NoNewline; Write-Host " - Mudar Ordem ($global:ordemAtual)"
        Write-Host "Botoes: " -NoNewline
        if ($filtroArma -ne "Desligado" -or $filtroCategoria -ne "Todas") {
            Write-Host "F3" -ForegroundColor DarkGray -NoNewline; Write-Host " - Ocultar municoes (Bloqueado) | " -NoNewline
        } else {
            $statusF3 = if ($isFilterActive) { "(Ligado)" } else { "(Desligado)" }
            $colorF3 = if ($isFilterActive) { "Magenta" } else { "DarkGray" }
            Write-Host "F3" -ForegroundColor $colorF3 -NoNewline; Write-Host " - Ocultar municoes $statusF3 | " -NoNewline
        }
        $textF4 = if ($filtroCategoria -eq "Todas") { "Categoria (Todas)" } else { "Categoria: ($filtroCategoriaDisplay)" }
        $colorF4 = if ($filtroCategoria -eq "Todas") { if ($filtroArma -ne "Desligado") { "DarkGray" } else { "Green" } } else { "Green" }
        
        if ($filtroArma -ne "Desligado" -and $filtroCategoria -eq "Todas") { Write-Host "F4" -ForegroundColor $colorF4 -NoNewline; Write-Host " - Categoria (Bloqueado) | " -NoNewline } 
        else { Write-Host "F4" -ForegroundColor $colorF4 -NoNewline; Write-Host " - $textF4 | " -NoNewline }

        $textF5 = if ($filtroArma -eq "Desligado") { "Arma (Todas)" } else { "Arma: ($filtroArma)" }
        $colorF5 = if ($filtroArma -eq "Desligado") { "Gray" } else { "Blue" }
        Write-Host "F5" -ForegroundColor $colorF5 -NoNewline; Write-Host " - $textF5"
        
        Write-Host "Botoes: " -NoNewline
        Write-Host "F6" -ForegroundColor Yellow -NoNewline; Write-Host " - Ver Legenda | " -NoNewline
        Write-Host "F7" -ForegroundColor Red -NoNewline; Write-Host " - Voltar ao menu" -NoNewline
        
        $msgAviso = ""
        if ($filtroArma -ne "Desligado" -and $filtroCategoria -ne "Todas") { $msgAviso = "Aviso: (Aperte novamente F4 ou F5 p/ desativar Ambas)" }
        elseif ($filtroArma -ne "Desligado") { $msgAviso = "Aviso: (Aperte novamente F5 p/ desativar Arma)" }
        elseif ($filtroCategoria -ne "Todas") { $msgAviso = "Aviso: (Aperte novamente F4 p/ desativar Categoria)" }
        
        if ($msgAviso -ne "") { Write-Host " | " -NoNewline; Write-Host $msgAviso -ForegroundColor Red }
        Write-Host ""; Write-Host "" 

        if ($global:criterioOrdenacao -eq "Alfabetico") { Write-Host ("{0,-19}" -f "Nome da Municao") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-19}" -f "Nome da Municao") -NoNewline }
        Write-Host "   " -NoNewline; if ($global:criterioOrdenacao -eq "Nivel de penetracao") { Write-Host ("{0,-2}" -f "Lv") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-2}" -f "Lv") -NoNewline }
        Write-Host " " -NoNewline; if ($global:criterioOrdenacao -eq "Penetracao") { Write-Host ("{0,-3}" -f "Pen") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-3}" -f "Pen") -NoNewline }
        Write-Host " " -NoNewline; if ($global:criterioOrdenacao -eq "Dano Base") { Write-Host ("{0,-14}" -f "Dano Base") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-14}" -f "Dano Base") -NoNewline }
        Write-Host " " -NoNewline; if ($global:criterioOrdenacao -eq "Dano de blindagem") { Write-Host ("{0,-12}" -f "Dano blindag") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-12}" -f "Dano blindag") -NoNewline }
        Write-Host " " -NoNewline; if ($global:criterioOrdenacao -eq "Velocidade inicial") { Write-Host ("{0,-8}" -f "Vel(m/s)") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-8}" -f "Vel(m/s)") -NoNewline }
        Write-Host " " -NoNewline; if ($global:criterioOrdenacao -eq "Precisao") { Write-Host ("{0,-4}" -f "Prec") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-4}" -f "Prec") -NoNewline }
        Write-Host " " -NoNewline; if ($global:criterioOrdenacao -eq "Controle de recuo vertical") { Write-Host ("{0,-3}" -f "CRV") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-3}" -f "CRV") -NoNewline }
        Write-Host " " -NoNewline; if ($global:criterioOrdenacao -eq "Controle de recuo horizontal") { Write-Host ("{0,-3}" -f "CRH") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-3}" -f "CRH") -NoNewline }
        Write-Host " " -NoNewline; if ($global:criterioOrdenacao -eq "Chance de Ferir") { Write-Host ("{0,-12}" -f "Chance Ferir") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-12}" -f "Chance Ferir") -NoNewline }
        Write-Host "  " -NoNewline; Write-Host ("{0,-9}" -f "Calibre")
        Write-Host "-------------------   -- --- -------------- ------------ -------- ---- --- --- ------------  ---------"
        
        foreach ($item in $sortedData) {
            Write-Host ("{0,-19}" -f $item.Nome) -NoNewline -ForegroundColor $(if ($global:criterioOrdenacao -eq "Alfabetico") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host "   " -NoNewline
            Write-Host ("{0,-2}" -f $item.Lv) -NoNewline -ForegroundColor $(if ($global:criterioOrdenacao -eq "Nivel de penetracao") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-3}" -f $item.Penetracao) -NoNewline -ForegroundColor $(if ($global:criterioOrdenacao -eq "Penetracao") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-14}" -f $item.DanoBase) -NoNewline -ForegroundColor $(if ($global:criterioOrdenacao -eq "Dano Base") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-12}" -f $item.DanoArmadura) -NoNewline -ForegroundColor $(if ($global:criterioOrdenacao -eq "Dano de blindagem") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-8}" -f $item.Velocidade) -NoNewline -ForegroundColor $(if ($global:criterioOrdenacao -eq "Velocidade inicial") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-4}" -f $item.Precisao) -NoNewline -ForegroundColor $(if ($global:criterioOrdenacao -eq "Precisao") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-3}" -f $item.RecuoVert) -NoNewline -ForegroundColor $(if ($global:criterioOrdenacao -eq "Controle de recuo vertical") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-3}" -f $item.RecuoHoriz) -NoNewline -ForegroundColor $(if ($global:criterioOrdenacao -eq "Controle de recuo horizontal") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-12}" -f $item.ChanceFerirDisplay) -NoNewline -ForegroundColor $(if ($global:criterioOrdenacao -eq "Chance de Ferir") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host "  " -NoNewline
            Write-Host ("{0,-9}" -f $item.Calibre)
        }
        
        if ($global:criterioOrdenacao -ne "Alfabetico" -and $filtroArma -eq "Desligado" -and $filtroCategoria -eq "Todas" -and -not $isFilterActive -and $sortedData.Count -gt 0) {
            $ammoList = if ($global:ordemAtual -eq "Crescente") { $sortedData[-1..-$sortedData.Count] } else { $sortedData }
            $topCalibres = @(); $calibresUnicos = @{}
            foreach ($item in $ammoList) { if (-not $calibresUnicos.ContainsKey($item.Calibre)) { $calibresUnicos[$item.Calibre] = $true; $topCalibres += $item; if ($topCalibres.Count -ge 5) { break } } }
            if ($topCalibres.Count -gt 0) {
                Write-Host; Write-Host "== Top 5 Calibres (Melhores Municoes) ==" -ForegroundColor Green; $posicao = 1
                foreach ($calibreInfo in $topCalibres) {
                    $armasCompativeis = Get-ChildItem -Path $weaponsPath -Filter "*.txt" -File | Where-Object { (Get-Content -Path $_.FullName)[1] -eq $calibreInfo.Calibre } | Select-Object -ExpandProperty BaseName | Sort-Object
                    Write-Host "$posicao posicao: $($calibreInfo.Calibre)" -ForegroundColor Yellow; Write-Host "Nome da municao: $($calibreInfo.Nome)"; Write-Host "Armas compativeis: $($armasCompativeis -join ', ')"; Write-Host; $posicao++
                }
            }
        }
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        switch ($key.VirtualKeyCode) {
            112 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; $novoCriterio = Show-Menu -Title "Selecione o criterio" -Options $criterios -FlickerFree; (Get-Host).UI.RawUI.CursorSize = 0; if ($novoCriterio) { $global:criterioOrdenacao = $novoCriterio } }
            113 { $global:ordemAtual = if ($global:ordemAtual -eq "Decrescente") { "Crescente" } else { "Decrescente" } }
            114 { if ($filtroArma -ne "Desligado" -or $filtroCategoria -ne "Todas") { continue }; Show-AmmoFilterScreen }
            115 { 
                if ($filtroArma -ne "Desligado" -and $filtroCategoria -eq "Todas") { continue }
                if ($filtroCategoria -ne "Todas") { $filtroCategoria = "Todas"; $filtroCategoriaDisplay = "Todas"; $filtroArma = "Desligado"; $script:ammoFilters = @{ SelectedLevels = [System.Collections.ArrayList]@(); SelectedCalibers = [System.Collections.ArrayList]@(); SelectedWoundChances = [System.Collections.ArrayList]@(); SelectionMethod = @{} } } 
                else {
                    (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; $translatedClasses = $weaponClasses | ForEach-Object { $global:WeaponClassToPortugueseMap[$_] } | Sort-Object; $categoriaDisplay = Show-Menu -Title "Selecione a categoria da arma" -Options $translatedClasses -FlickerFree -EnableF1BackButton
                    if ($categoriaDisplay -and $categoriaDisplay -ne $global:ACTION_BACK) { $filtroCategoriaDisplay = $categoriaDisplay; $filtroCategoria = $global:PortugueseToWeaponClassMap[$categoriaDisplay]; $script:ammoFilters = @{ SelectedLevels = [System.Collections.ArrayList]@(); SelectedCalibers = [System.Collections.ArrayList]@(); SelectedWoundChances = [System.Collections.ArrayList]@(); SelectionMethod = @{} } }
                    (Get-Host).UI.RawUI.CursorSize = 0
                }
            }
            116 { 
                if ($filtroArma -ne "Desligado") { $filtroArma = "Desligado"; $filtroCategoria = "Todas"; $filtroCategoriaDisplay = "Todas"; $script:ammoFilters = @{ SelectedLevels = [System.Collections.ArrayList]@(); SelectedCalibers = [System.Collections.ArrayList]@(); SelectedWoundChances = [System.Collections.ArrayList]@(); SelectionMethod = @{} } } 
                else {
                    (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; $categoriaParaFiltrar = $null
                    if ($filtroCategoria -ne "Todas") { $categoriaParaFiltrar = $filtroCategoria } 
                    else {
                        $translatedClasses = $weaponClasses | ForEach-Object { $global:WeaponClassToPortugueseMap[$_] } | Sort-Object; $catDisplay = Show-Menu -Title "Selecione a categoria para ver as armas" -Options $translatedClasses -FlickerFree -EnableF1BackButton
                        if ($catDisplay -and $catDisplay -ne $global:ACTION_BACK) { $categoriaParaFiltrar = $global:PortugueseToWeaponClassMap[$catDisplay] }
                    }
                    if ($categoriaParaFiltrar) {
                        $armas = Get-ChildItem -Path $weaponsPath -Filter "*.txt" -File | Where-Object { $c = @(Get-Content $_.FullName -TotalCount 1); if ($c.Count -ge 1) { $c[0].Trim() -eq $categoriaParaFiltrar } } | Select-Object -ExpandProperty BaseName | Sort-Object
                        if ($armas.Count -gt 0) { $novaArma = Show-Menu -Title "Selecione a arma" -Options $armas -FlickerFree -EnableF1BackButton; if ($novaArma -and $novaArma -ne $global:ACTION_BACK) { $filtroArma = $novaArma; $script:ammoFilters = @{ SelectedLevels = [System.Collections.ArrayList]@(); SelectedCalibers = [System.Collections.ArrayList]@(); SelectedWoundChances = [System.Collections.ArrayList]@(); SelectionMethod = @{} } } } 
                        else { Write-Host "Nenhuma arma encontrada nesta categoria." -ForegroundColor Yellow; Start-Sleep -Seconds 2 }
                    }
                    (Get-Host).UI.RawUI.CursorSize = 0
                }
            }
            117 { Show-AmmoLegend; continue } 
            118 { $script:ammoFilters = @{ SelectedLevels = [System.Collections.ArrayList]@(); SelectedCalibers = [System.Collections.ArrayList]@(); SelectedWoundChances = [System.Collections.ArrayList]@(); SelectionMethod = @{} }; (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return }
        }
    } while ($true)
}

function Search-WeaponsWithFilters {
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize
    (Get-Host).UI.RawUI.CursorSize = 0
    $criterioOrdenacao = "Alfabetico"
    $ordemAtual = "Crescente"
    
    # Inicializa o estado do filtro se não existir
    if (-not $script:weaponFilters) {
        $script:weaponFilters = @{ SelectedValues = @{}; SelectionMethod = @{} }
    }

    $criterios = @("Alfabetico", "Calibre", "Controle de recuo vertical", "Controle de recuo horizontal", "Ergonomia", "Estabilidade de arma", "Precisao", "Estabilidade sem mirar", "Distancia Efetiva", "Velocidade de Saida", "Modo de disparo", "Cadencia", "Poder de fogo", "Melhoria de cano")
    
    # Mapas de tradução para o filtro ficar bonito
    $poderFogoMapDisplay = @{ "Low"="Baixo";"Mid-Low"="Medio-Baixo";"Medium"="Medio";"Mid-High"="Medio-Alto";"High"="Alto" }
    $canoMapDisplay = @{ "Default +"="Padrao +";"FB"="CF";"R+"="A+";"FB D+"="CF D+";"FB D-"="CF D-";"D+ R+"="D+ A+";"Custom"="Custom" }

    do {
        $weaponData = @()
        # Pega todas as armas
        $weaponDataFiles = Get-ChildItem -Path $weaponsPath -Filter "*.txt" -File
        
        foreach ($file in $weaponDataFiles) {
            $content = Get-Content -Path $file.FullName
            if ($content.Count -ge 13) {
                $estabilidadeArmaValue = 0
                if ($content.Count -ge 14) { $estabilidadeArmaValue = [int]$content[13] }
                
                # Prepara valores de exibição para o filtro
                $classePT = $global:WeaponClassToPortugueseMap[$content[0]]
                $modoDisparoDisplay = $content[9].Replace('Bolt-Action', 'A.Ferrolho').Replace('Pump-Action', 'A.Bombeamento').Replace('Full', 'Auto')
                $poderDisplay = if ($poderFogoMapDisplay.ContainsKey($content[11])) { $poderFogoMapDisplay[$content[11]] } else { $content[11] }
                $canoDisplay = if ($canoMapDisplay.ContainsKey($content[12])) { $canoMapDisplay[$content[12]] } else { $content[12] }

                $weaponData += [PSCustomObject]@{
                    Nome             = $file.BaseName
                    Classe           = $content[0]
                    ClasseDisplay    = $classePT # Propriedade para o Filtro
                    Calibre          = $content[1]
                    VerticalRecoil   = [int]$content[2]
                    HorizontalRecoil = [int]$content[3]
                    Ergonomia        = [int]$content[4]
                    EstabilidadeArma = $estabilidadeArmaValue
                    Precisao         = [int]$content[5]
                    Estabilidade     = [int]$content[6]
                    Alcance          = [int]$content[7]
                    Velocidade       = [int]$content[8]
                    ModoDisparo      = $content[9]
                    ModoDisparoDisplay = $modoDisparoDisplay # Propriedade para o Filtro
                    Cadencia         = [int]$content[10]
                    PoderFogo        = $content[11]
                    PoderFogoDisplay = $poderDisplay # Propriedade para o Filtro
                    Cano             = $content[12]
                    CanoDisplay      = $canoDisplay # Propriedade para o Filtro
                }
            }
        }
        
        # Aplica o Filtro Avançado (Ocultar armas)
        $filteredData = $weaponData
        $isAdvancedFilterActive = $false
        if ($script:weaponFilters.SelectedValues.Keys.Count -gt 0) {
            $isAdvancedFilterActive = $true
            foreach($key in $script:weaponFilters.SelectedValues.Keys){
                $valuesToHide = $script:weaponFilters.SelectedValues[$key]
                if($valuesToHide -and $valuesToHide.Count -gt 0){
                    # Filtra removendo itens que tenham o valor na lista de ocultos
                    $filteredData = $filteredData | Where-Object { $_.$key -notin $valuesToHide }
                }
            }
        }

        $sortedData = Ordenar-WeaponData -dados $filteredData -criterio $criterioOrdenacao -ordem $ordemAtual
        
        Clear-Host
        Write-Host "=== Busca de armas com filtro ==="; Write-Host
        
        # Linha 1 de botões
        Write-Host "Botoes: " -NoNewline
        Write-Host "F1" -ForegroundColor Cyan -NoNewline; Write-Host " - Mudar Criterio ($criterioOrdenacao) | " -NoNewline
        Write-Host "F2" -ForegroundColor Yellow -NoNewline; Write-Host " - Mudar Ordem ($ordemAtual)"
        
        # Linha 2 de botões (Novos botões)
        $statusF3 = if ($isAdvancedFilterActive) { "(Ligado)" } else { "(Desligado)" }
        Write-Host "Botoes: " -NoNewline
        Write-Host "F3" -ForegroundColor $(if ($isAdvancedFilterActive) {'Magenta'} else {'DarkGray'}) -NoNewline; Write-Host " - Ocultar armas $statusF3 | " -NoNewline
        Write-Host "F4" -ForegroundColor Yellow -NoNewline; Write-Host " - Ver legenda | " -NoNewline
        Write-Host "F5" -ForegroundColor Red -NoNewline; Write-Host " - Voltar ao menu"; Write-Host

        # Cabeçalho da Tabela
        if ($criterioOrdenacao -eq "Alfabetico") { Write-Host ("{0,-17}" -f "Nome da Arma") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-17}" -f "Nome da Arma") -NoNewline }
        Write-Host " " -NoNewline; if ($criterioOrdenacao -eq "Calibre") { Write-Host ("{0,-12}" -f "Calibre") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-12}" -f "Calibre") -NoNewline }
        Write-Host " " -NoNewline; if ($criterioOrdenacao -eq "Controle de recuo vertical") { Write-Host ("{0,-4}" -f "CRV") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-4}" -f "CRV") -NoNewline }
        Write-Host " " -NoNewline; if ($criterioOrdenacao -eq "Controle de recuo horizontal") { Write-Host ("{0,-4}" -f "CRH") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-4}" -f "CRH") -NoNewline }
        Write-Host " " -NoNewline; if ($criterioOrdenacao -eq "Ergonomia") { Write-Host ("{0,-4}" -f "Ergo") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-4}" -f "Ergo") -NoNewline }
        Write-Host " " -NoNewline; if ($criterioOrdenacao -eq "Estabilidade de arma") { Write-Host ("{0,-7}" -f "Esta.DA") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-7}" -f "Esta.DA") -NoNewline }
        Write-Host " " -NoNewline; if ($criterioOrdenacao -eq "Precisao") { Write-Host ("{0,-4}" -f "Prec") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-4}" -f "Prec") -NoNewline }
        Write-Host " " -NoNewline; if ($criterioOrdenacao -eq "Estabilidade sem mirar") { Write-Host ("{0,-7}" -f "Esta.SM") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-7}" -f "Esta.SM") -NoNewline }
        Write-Host " " -NoNewline; if ($criterioOrdenacao -eq "Distancia Efetiva") { Write-Host ("{0,-6}" -f "Dis(m)") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-6}" -f "Dis(m)") -NoNewline }
        Write-Host " " -NoNewline; if ($criterioOrdenacao -eq "Velocidade de Saida") { Write-Host ("{0,-7}" -f "Vel.bo") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-7}" -f "Vel.bo") -NoNewline }
        Write-Host " " -NoNewline; if ($criterioOrdenacao -eq "Modo de disparo") { Write-Host ("{0,-17}" -f "ModoDisparo") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-17}" -f "ModoDisparo") -NoNewline }
        Write-Host " " -NoNewline; if ($criterioOrdenacao -eq "Cadencia") { Write-Host ("{0,-5}" -f "Cad") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-5}" -f "Cad") -NoNewline }
        Write-Host " " -NoNewline; if ($criterioOrdenacao -eq "Poder de fogo") { Write-Host ("{0,-11}" -f "Poder.DFG") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-11}" -f "Poder.DFG") -NoNewline }
        Write-Host " " -NoNewline; if ($criterioOrdenacao -eq "Melhoria de cano") { Write-Host ("{0,-9}" -f "Melh.Cano") -ForegroundColor Green } else { Write-Host ("{0,-9}" -f "Melh.Cano") }
        
        Write-Host "----------------- ------------ ---- ---- ---- ------- ---- ------- ------ ------- ----------------- ---   ----------- ---------"
        
        # Loop de Exibição dos Dados
        foreach ($item in $sortedData) {
            Write-Host ("{0,-17}" -f $item.Nome) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Alfabetico") { 'Green' } else { $Host.UI.RawUI.ForegroundColor }); Write-Host " " -NoNewline
            Write-Host ("{0,-12}" -f $item.Calibre) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Calibre") { 'Green' } else { $Host.UI.RawUI.ForegroundColor }); Write-Host " " -NoNewline
            Write-Host ("{0,-4}" -f $item.VerticalRecoil) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Controle de recuo vertical") { 'Green' } else { $Host.UI.RawUI.ForegroundColor }); Write-Host " " -NoNewline
            Write-Host ("{0,-4}" -f $item.HorizontalRecoil) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Controle de recuo horizontal") { 'Green' } else { $Host.UI.RawUI.ForegroundColor }); Write-Host " " -NoNewline
            Write-Host ("{0,-4}" -f $item.Ergonomia) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Ergonomia") { 'Green' } else { $Host.UI.RawUI.ForegroundColor }); Write-Host " " -NoNewline
            Write-Host ("{0,-7}" -f $item.EstabilidadeArma) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Estabilidade de arma") { 'Green' } else { $Host.UI.RawUI.ForegroundColor }); Write-Host " " -NoNewline
            Write-Host ("{0,-4}" -f $item.Precisao) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Precisao") { 'Green' } else { $Host.UI.RawUI.ForegroundColor }); Write-Host " " -NoNewline
            Write-Host ("{0,-7}" -f $item.Estabilidade) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Estabilidade sem mirar") { 'Green' } else { $Host.UI.RawUI.ForegroundColor }); Write-Host " " -NoNewline
            Write-Host ("{0,-6}" -f $item.Alcance) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Distancia Efetiva") { 'Green' } else { $Host.UI.RawUI.ForegroundColor }); Write-Host " " -NoNewline
            Write-Host ("{0,-7}" -f $item.Velocidade) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Velocidade de Saida") { 'Green' } else { $Host.UI.RawUI.ForegroundColor }); Write-Host " " -NoNewline
            Write-Host ("{0,-17}" -f $item.ModoDisparoDisplay) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Modo de disparo") { 'Green' } else { $Host.UI.RawUI.ForegroundColor }); Write-Host " " -NoNewline
            Write-Host ("{0,-5}" -f $item.Cadencia) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Cadencia") { 'Green' } else { $Host.UI.RawUI.ForegroundColor }); Write-Host " " -NoNewline
            Write-Host ("{0,-11}" -f $item.PoderFogoDisplay) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Poder de fogo") { 'Green' } else { $Host.UI.RawUI.ForegroundColor }); Write-Host " " -NoNewline
            Write-Host ("{0,-9}" -f $item.CanoDisplay) -ForegroundColor $(if ($criterioOrdenacao -eq "Melhoria de cano") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
        }
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        switch ($key.VirtualKeyCode) {
            112 { # F1
                (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; $novoCriterio = Show-Menu -Title "Selecione o criterio" -Options $criterios -FlickerFree; (Get-Host).UI.RawUI.CursorSize = 0; if ($novoCriterio) { $criterioOrdenacao = $novoCriterio }
            }
            113 { # F2
                $ordemAtual = if ($ordemAtual -eq "Decrescente") { "Crescente" } else { "Decrescente" } 
            }
            114 { # F3 - Ocultar Armas (Novo)
                # Definição das colunas com espaçamento e nomes CORRIGIDOS
                $filterDefs = @(
                    @{ Label = "Categoria";        Property = "ClasseDisplay";      Width = 27 },
                    @{ Label = "Calibre";          Property = "Calibre";            Width = 18 },
                    @{ Label = "Modo de disparo";  Property = "ModoDisparoDisplay"; Width = 24 },
                    @{ Label = "Poder de fogo";    Property = "PoderFogoDisplay";   Width = 20; CustomSortOrder = @("Baixo", "Medio-Baixo", "Medio", "Medio-Alto", "Alto") },
                    @{ Label = "Melhoria de Cano"; Property = "CanoDisplay";        Width = 22; CustomSortOrder = @("CF D-", "Custom", "CF", "CF D+", "Padrao +", "A+", "D+", "D+ A+") }
                )
                
                $updatedFilters = Show-ItemFilterScreen -Title "Filtro de Armas" -AllItems $weaponData -FilterDefinitions $filterDefs -CurrentFilters $script:weaponFilters
                if ($updatedFilters) {
                    $script:weaponFilters = $updatedFilters
                } else { 
                    # Se cancelar (F2), limpa os filtros
                    $script:weaponFilters = @{ SelectedValues = @{}; SelectionMethod = @{} }
                }
                (Get-Host).UI.RawUI.CursorSize = 0
            }
            115 { # F4 - Ver Legenda (Antigo F5)
                Show-WeaponLegend; continue 
            }
            116 { # F5 - Voltar (Antigo F6)
                $script:weaponFilters = @{ SelectedValues = @{}; SelectionMethod = @{} } # Limpa filtro ao sair
                (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return 
            }
        }
    } while ($true)
}

function Search-GastronomyWithFilters {
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize
    (Get-Host).UI.RawUI.CursorSize = 0
    $criterioOrdenacao = "Alfabetico"
    $ordemAtual = "Crescente"
    $filtroCategoria = "Todas as comidas e bebidas"
    $criterios = @("Alfabetico", "Hidratacao", "Energia", "Hidratacao por slot", "Energia por slot")
    $categorias = @("Todas as comidas e bebidas", "Bebida", "Comida")
    do {
        $gastronomyData = @()
        $foldersToSearch = @()
        if ($filtroCategoria -eq "Todas as comidas e bebidas") {
            $foldersToSearch = "Beverages", "Food"
        } elseif ($filtroCategoria -eq "Bebida") {
            $foldersToSearch = "Beverages"
        } else {
            $foldersToSearch = "Food"
        }
        foreach ($folder in $foldersToSearch) {
            $itemFiles = Get-ChildItem -Path (Join-Path $global:databasePath $folder) -Filter "*.txt" -File
            foreach ($file in $itemFiles) {
                $content = Get-Content -Path $file.FullName
                
                $slots = 1
                if ($content[4] -match '(\d+)x(\d+)') {
                    $hSlots = [int]$Matches[1]; $vSlots = [int]$Matches[2]
                    if (($hSlots * $vSlots) -gt 0) { $slots = $hSlots * $vSlots }
                }
                $hidratacaoNum = [int]($content[0].Replace('+', ''))
                $energiaNum = [int]($content[1].Replace('+', ''))
                $gastronomyData += [PSCustomObject]@{
                    Nome            = $file.BaseName
                    Hidratacao      = $content[0]
                    Energia         = $content[1]
                    Delay           = $content[2]
                    RecStamina      = $content[3]
                    EspacoHV        = $content[4]
                    HidratacaoNum   = $hidratacaoNum
                    EnergiaNum      = $energiaNum
                    HidratSlot      = [math]::Round(($hidratacaoNum / $slots), 1)
                    EnergSlot       = [math]::Round(($energiaNum / $slots), 1)
                    TotalSlots      = $slots
                }
            }
        }
        
        $gastronomyData = Ordenar-GastronomyData -dados $gastronomyData -criterio $criterioOrdenacao -ordem $ordemAtual
        Clear-Host
        Write-Host "=== Busca gastronomica com filtro ==="; Write-Host
        
        Write-Host "Botoes: " -NoNewline
        Write-Host "F1" -ForegroundColor Cyan -NoNewline
        Write-Host " - Mudar Criterio ($criterioOrdenacao) | " -NoNewline
        Write-Host "F2" -ForegroundColor Gray -NoNewline
        Write-Host " - Mudar Ordem ($ordemAtual) | " -NoNewline
        Write-Host "F4" -ForegroundColor Yellow -NoNewline
        Write-Host " - Ver legenda"
        Write-Host "Filtro: " -NoNewline
        Write-Host "F3" -ForegroundColor Green -NoNewline
        Write-Host " - Categoria ($filtroCategoria) | " -NoNewline
        Write-Host "F5" -ForegroundColor Red -NoNewline
        Write-Host " - Voltar ao menu"; Write-Host
        if ($criterioOrdenacao -eq "Alfabetico") { Write-Host ("{0,-35}" -f "Nome") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-35}" -f "Nome") -NoNewline }
        if ($criterioOrdenacao -eq "Hidratacao") { Write-Host ("{0,-11}" -f "Hidratacao") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-11}" -f "Hidratacao") -NoNewline }
        if ($criterioOrdenacao -eq "Energia") { Write-Host ("{0,-8}" -f "Energia") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-8}" -f "Energia") -NoNewline }
        Write-Host ("{0,-12}" -f "Rec.Stamina") -NoNewline # Coluna sem ordenação, cor padrão
        Write-Host ("{0,-12}" -f "Espaco(HxV)") -NoNewline # Coluna sem ordenação, cor padrão
        if ($criterioOrdenacao -eq "Hidratacao por slot") { Write-Host ("{0,-12}" -f "Hidrat.Slot") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-12}" -f "Hidrat.Slot") -NoNewline }
        if ($criterioOrdenacao -eq "Energia por slot") { Write-Host ("{0,-11}" -f "Energ.Slot") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-11}" -f "Energ.Slot") -NoNewline }
        Write-Host ("{0,-5}" -f "Delay") # Coluna sem ordenação, cor padrão
        
        Write-Host "---------------------------------  ---------- ------- ----------- ----------- ----------- ---------- -----"
        foreach ($item in $gastronomyData) {
            # Traduz "None" para "/////" antes de exibir
            $recStaminaDisplay = $item.RecStamina
            if ($recStaminaDisplay -eq 'None') {
                $recStaminaDisplay = '/////'
            }
            if ($criterioOrdenacao -eq "Alfabetico") { Write-Host ("{0,-35}" -f $item.Nome) -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-35}" -f $item.Nome) -NoNewline }
            if ($criterioOrdenacao -eq "Hidratacao") { Write-Host ("{0,-11}" -f $item.Hidratacao) -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-11}" -f $item.Hidratacao) -NoNewline }
            if ($criterioOrdenacao -eq "Energia") { Write-Host ("{0,-8}" -f $item.Energia) -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-8}" -f $item.Energia) -NoNewline }
            Write-Host ("{0,-12}" -f $recStaminaDisplay) -NoNewline
            Write-Host ("{0,-12}" -f $item.EspacoHV) -NoNewline
            if ($criterioOrdenacao -eq "Hidratacao por slot") { Write-Host ("{0,-12}" -f $item.HidratSlot) -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-12}" -f $item.HidratSlot) -NoNewline }
            if ($criterioOrdenacao -eq "Energia por slot") { Write-Host ("{0,-11}" -f $item.EnergSlot) -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-11}" -f $item.EnergSlot) -NoNewline }
            Write-Host ("{0,-5}" -f $item.Delay)
        }
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        switch ($key.VirtualKeyCode) {
            112 { # F1 - Mudar critério
                (Get-Host).UI.RawUI.CursorSize = $originalCursorSize
                $novoCriterio = Show-Menu -Title "Selecione o criterio" -Options $criterios -FlickerFree
                (Get-Host).UI.RawUI.CursorSize = 0
                if ($novoCriterio) { $criterioOrdenacao = $novoCriterio }
            }
            113 { # F2 - Mudar ordem
                $ordemAtual = if ($ordemAtual -eq "Decrescente") { "Crescente" } else { "Decrescente" }
            }
            114 { # F3 - Mudar categoria
                (Get-Host).UI.RawUI.CursorSize = $originalCursorSize
                $novaCategoria = Show-Menu -Title "Selecione a categoria" -Options $categorias -FlickerFree
                (Get-Host).UI.RawUI.CursorSize = 0
                if ($novaCategoria) { $filtroCategoria = $novaCategoria }
            }
            115 { # F4 - Ver legenda
                Show-GastronomyLegend
                continue 
            }
            116 { # F5 - Voltar ao menu
                (Get-Host).UI.RawUI.CursorSize = $originalCursorSize
                return
            }
        }
    } while ($true)
}

function Search-PharmaceuticalWithFilters {
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize
    (Get-Host).UI.RawUI.CursorSize = 0
    $filtroCategoria = "Analgesico"
    $criterioOrdenacao = "Usos"
    $ordemAtual = "Decrescente" 
    
    $categorias = @("Analgesico", "Bandagem", "Kit cirurgico", "Nebulizador", "Kit medico", "Estimulantes")
    do {
        $categoryMap = @{
            "Analgesico"    = @{ Folder="Painkillers";   Criteria=@("Usos","Duracao","Desidratacao","Duracao maxima") }
            "Bandagem"      = @{ Folder="Bandages";      Criteria=@("Usos") }
            "Kit cirurgico" = @{ Folder="Surgicalkit";   Criteria=@("Usos","Recuperacao por uso","Desidratacao","Tempo de Atraso","Espaco(HxV)") }
            "Nebulizador"   = @{ Folder="Nebulizers";    Criteria=@("Usos") }
            "Kit medico"    = @{ Folder="Medicalkit";    Criteria=@("Durabilidade","Desidratacao","Velocidade de cura","Delay","Durabilidade por slot","Espaco(HxV)") }
            "Estimulantes"  = @{ Folder="Stimulants";    Criteria=@("Efeito Principal") }
        }
        $config = $categoryMap[$filtroCategoria]
        $criteriosDisponiveis = $config.Criteria
        if ($criterioOrdenacao -notin $criteriosDisponiveis) { $criterioOrdenacao = $criteriosDisponiveis[0] }
        $pharmaData = @()
        $itemFiles = Get-ChildItem -Path (Join-Path $global:databasePath $config.Folder) -Filter "*.txt" -File
        foreach ($file in $itemFiles) {
            $content = Get-Content -Path $file.FullName; $obj = [PSCustomObject]@{ Nome = $file.BaseName }
            switch ($filtroCategoria) {
                "Analgesico" {
                    $usosNum=[int]$content[0]; $durNum=0; if($content[1] -ne '/////'){$durNum=[int]$content[1]}; $desidratacaoNum=0; if($content[2] -ne '/////'){$desidratacaoNum=[int]$content[2]}; $durMaxNum=$usosNum*$durNum
                    $duracaoDisplay=$content[1]; if($durNum -gt 0){$min=[math]::Floor($durNum/60);$sec=$durNum%60;if($min -gt 0 -and $sec -gt 0){$duracaoDisplay="$durNum ($($min)min/$($sec)seg)"}elseif($min -gt 0){$duracaoDisplay="$durNum ($($min)min)"}elseif($durNum -gt 0){$duracaoDisplay="$durNum ($($sec)seg)"}}
                    $durMaxDisplay=$durMaxNum; if($durMaxNum -gt 0){$min=[math]::Floor($durMaxNum/60);$sec=$durMaxNum%60;if($min -gt 0 -and $sec -gt 0){$durMaxDisplay="$durMaxNum ($($min)min/$($sec)seg)"}elseif($min -gt 0){$durMaxDisplay="$durMaxNum ($($min)min)"}elseif($durMaxNum -gt 0){$durMaxDisplay="$durMaxNum ($($sec)seg)"}}
                    $obj | Add-Member -MemberType NoteProperty -Name Usos -Value $content[0]; $obj | Add-Member -MemberType NoteProperty -Name UsosNum -Value $usosNum; $obj | Add-Member -MemberType NoteProperty -Name Duracao -Value $duracaoDisplay; $obj | Add-Member -MemberType NoteProperty -Name DuracaoNum -Value $durNum; $obj | Add-Member -MemberType NoteProperty -Name Desidratacao -Value $content[2]; $obj | Add-Member -MemberType NoteProperty -Name DesidratacaoNum -Value $desidratacaoNum; $obj | Add-Member -MemberType NoteProperty -Name TempoAtraso -Value $content[3]; $obj | Add-Member -MemberType NoteProperty -Name DurMax -Value $durMaxDisplay; $obj | Add-Member -MemberType NoteProperty -Name DesMax -Value ($usosNum*$desidratacaoNum); $obj | Add-Member -MemberType NoteProperty -Name DurMaxNum -Value $durMaxNum
                }
                "Bandagem"{$obj | Add-Member -MemberType NoteProperty -Name Usos -Value $content[0]; $obj | Add-Member -MemberType NoteProperty -Name UsosNum -Value ([int]$content[0]); $obj | Add-Member -MemberType NoteProperty -Name TempoAtraso -Value $content[1]; $obj | Add-Member -MemberType NoteProperty -Name CustoDurabilidade -Value $content[2]}
                "Kit cirurgico"{$slots=1;if($content[5] -match '(\d+)x(\d+)'){$h=[int]$Matches[1];$v=[int]$Matches[2];if(($h*$v)-gt 0){$slots=$h*$v}};$desidratacaoNum=0;if($content[2] -ne '/////'){$desidratacaoNum=[int]$content[2]};$obj | Add-Member -MemberType NoteProperty -Name Usos -Value $content[0]; $obj | Add-Member -MemberType NoteProperty -Name UsosNum -Value ([int]$content[0]); $obj | Add-Member -MemberType NoteProperty -Name TempoAtraso -Value $content[1]; $obj | Add-Member -MemberType NoteProperty -Name TempoAtrasoNum -Value ([double]$content[1]); $obj | Add-Member -MemberType NoteProperty -Name Desidratacao -Value $content[2]; $obj | Add-Member -MemberType NoteProperty -Name DesidratacaoNum -Value $desidratacaoNum; $obj | Add-Member -MemberType NoteProperty -Name RecHP -Value $content[3]; $obj | Add-Member -MemberType NoteProperty -Name RecHPNum -Value ([int]$content[3]); $obj | Add-Member -MemberType NoteProperty -Name CustoDur -Value $content[4]; $obj | Add-Member -MemberType NoteProperty -Name EspacoHV -Value $content[5]; $obj | Add-Member -MemberType NoteProperty -Name TotalSlots -Value $slots}
                "Nebulizador"{$obj | Add-Member -MemberType NoteProperty -Name Usos -Value $content[0]; $obj | Add-Member -MemberType NoteProperty -Name UsosNum -Value ([int]$content[0]); $obj | Add-Member -MemberType NoteProperty -Name TempoAtraso -Value $content[1]; $obj | Add-Member -MemberType NoteProperty -Name CustoDurabilidade -Value $content[2]}
                "Kit medico"{$slots=1;if($content[5] -match '(\d+)x(\d+)'){$h=[int]$Matches[1];$v=[int]$Matches[2];if(($h*$v)-gt 0){$slots=$h*$v}};$durabNum=0;if($content[0] -ne '/////'){$durabNum=[int]$content[0]};$desidratacaoNum=0;if($content[1] -ne '/////'){$desidratacaoNum=[int]$content[1]};$obj | Add-Member -MemberType NoteProperty -Name Durabilidade -Value $content[0]; $obj | Add-Member -MemberType NoteProperty -Name DurabilidadeNum -Value $durabNum; $obj | Add-Member -MemberType NoteProperty -Name Desidratacao -Value $content[1]; $obj | Add-Member -MemberType NoteProperty -Name DesidratacaoNum -Value $desidratacaoNum; $obj | Add-Member -MemberType NoteProperty -Name VelCura -Value $content[2]; $obj | Add-Member -MemberType NoteProperty -Name VelCuraNum -Value ([int]$content[2]); $obj | Add-Member -MemberType NoteProperty -Name Delay -Value $content[3]; $obj | Add-Member -MemberType NoteProperty -Name DelayNum -Value ([double]$content[3]); $obj | Add-Member -MemberType NoteProperty -Name CustoDur -Value $content[4]; $obj | Add-Member -MemberType NoteProperty -Name EspacoHV -Value $content[5]; $obj | Add-Member -MemberType NoteProperty -Name TotalSlots -Value $slots; $obj | Add-Member -MemberType NoteProperty -Name DurabSlot -Value ([math]::Round(($durabNum/$slots),1))}
                "Estimulantes"{$durNum=0;if($content[1] -ne '/////'){$durNum=[int]$content[1]};$duracaoDisplay=$content[1];if($durNum -gt 0){$min=[math]::Floor($durNum/60);$sec=$durNum%60;if($min -gt 0 -and $sec -gt 0){$duracaoDisplay="$durNum ($($min)min/$($sec)seg)"}elseif($min -gt 0){$duracaoDisplay="$durNum ($($min)min)"}elseif($durNum -gt 0){$duracaoDisplay="$durNum ($($sec)seg)"}};$obj | Add-Member -MemberType NoteProperty -Name EfeitoPrincipal -Value $content[0]; $obj | Add-Member -MemberType NoteProperty -Name Duracao -Value $duracaoDisplay; $obj | Add-Member -MemberType NoteProperty -Name DuracaoNum -Value ([int]$content[1]); $obj | Add-Member -MemberType NoteProperty -Name Desidratacao -Value $content[2]; $obj | Add-Member -MemberType NoteProperty -Name RedEnergia -Value $content[3]; $obj | Add-Member -MemberType NoteProperty -Name Delay -Value $content[4]}
            }
            $pharmaData += $obj
        }
        
        $pharmaData = Ordenar-PharmaceuticalData -dados $pharmaData -criterio $criterioOrdenacao -ordem $ordemAtual -categoria $filtroCategoria
        
        Clear-Host
        Write-Host "=== Busca farmaceutica com filtro ==="; Write-Host
        
        Write-Host "Botoes: " -NoNewline
        Write-Host "F1" -ForegroundColor Cyan -NoNewline; Write-Host " - Mudar Categoria ($filtroCategoria) | " -NoNewline
        if ($criteriosDisponiveis.Count -gt 1) {
            Write-Host "F2" -ForegroundColor Yellow -NoNewline; Write-Host " - Mudar Criterio ($criterioOrdenacao) | " -NoNewline
        } else {
            Write-Host "F2" -ForegroundColor Gray -NoNewline; Write-Host " - Mudar Criterio (BLOQUEADO) | " -NoNewline
        }
        Write-Host "F3" -ForegroundColor Gray -NoNewline; Write-Host " - Mudar Ordem ($ordemAtual)"
        Write-Host "Botoes: " -NoNewline
        Write-Host "F4" -ForegroundColor Magenta -NoNewline; Write-Host " - Ver legenda | " -NoNewline
        Write-Host "F5" -ForegroundColor Red -NoNewline; Write-Host " - Voltar ao menu"; Write-Host
        switch ($filtroCategoria) {
            "Analgesico" {
                $header = "{0,-25}  {1,-5}  {2,-18}  {3,-13}  {4,-17}  {5,-18}  {6,-10}" -f "Nome", "Usos", "Duracao", "Desidratacao", "Tempo de Atraso", "Dur. Max", "Des. Max"
                $separator = "-------------------------  -----  ------------------  -------------  -----------------  ------------------  --------"
                Write-Host $header; Write-Host $separator
                
                foreach ($item in $pharmaData) {
                    $line = "{0,-25}  {1,-5}  {2,-18}  {3,-13}  {4,-17}  {5,-18}  {6,-10}" -f $item.Nome, $item.Usos, $item.Duracao, $item.Desidratacao, $item.TempoAtraso, $item.DurMax, $item.DesMax
                    Write-Host $line
                }
            }
            "Bandagem" {
                $header = "{0,-25}  {1,-5}  {2,-16}  {3,-20}" -f "Nome", "Usos", "Tempo de Atraso", "Custo Durabilidade"
                $separator = "-------------------------  -----  ----------------  --------------------"
                Write-Host $header; Write-Host $separator
                foreach ($item in $pharmaData) {
                    $line = "{0,-25}  {1,-5}  {2,-16}  {3,-20}" -f $item.Nome, $item.Usos, $item.TempoAtraso, $item.CustoDurabilidade
                    Write-Host $line
                }
            }
            "Kit cirurgico" {
                $header = "{0,-32}  {1,-5}  {2,-15}  {3,-13}  {4,-9}  {5,-11}  {6,-12}" -f "Nome", "Usos", "Tempo de Atraso", "Desidratacao", "Rec. HP", "Custo Dur.", "Espaco(HxV)"
                $separator = "--------------------------------  -----  ---------------  -------------  ---------  -----------  -----------"
                Write-Host $header; Write-Host $separator
                
                foreach ($item in $pharmaData) {
                    $line = "{0,-32}  {1,-5}  {2,-15}  {3,-13}  {4,-9}  {5,-11}  {6,-12}" -f $item.Nome, $item.Usos, $item.TempoAtraso, $item.Desidratacao, $item.RecHP, $item.CustoDur, $item.EspacoHV
                    Write-Host $line
                }
            }
            "Nebulizador" {
                $header = "{0,-25}  {1,-5}  {2,-16}  {3,-20}" -f "Nome", "Usos", "Tempo de Atraso", "Custo Durabilidade"
                $separator = "-------------------------  -----  ----------------  --------------------"
                Write-Host $header; Write-Host $separator
                foreach ($item in $pharmaData) {
                    $line = "{0,-25}  {1,-5}  {2,-16}  {3,-20}" -f $item.Nome, $item.Usos, $item.TempoAtraso, $item.CustoDurabilidade
                    Write-Host $line
                }
            }
            "Kit medico" {
                $header = "{0,-26}  {1,-13}  {2,-13}  {3,-10}  {4,-6}  {5,-11}  {6,-12}  {7,-16}" -f "Nome", "Durabilidade", "Desidratacao", "Vel. Cura", "Delay", "Custo Dur.", "Espaco(HxV)", "Durab. p/ Slot"
                $separator = "--------------------------  -------------  -------------  ----------  ------  -----------  ------------  --------------"
                Write-Host $header; Write-Host $separator
                
                foreach ($item in $pharmaData) {
                    $line = "{0,-26}  {1,-13}  {2,-13}  {3,-10}  {4,-6}  {5,-11}  {6,-12}  {7,-16}" -f $item.Nome, $item.Durabilidade, $item.Desidratacao, $item.VelCura, $item.Delay, $item.CustoDur, $item.EspacoHV, $item.DurabSlot
                    Write-Host $line
                }
            }
            "Estimulantes" {
                $header = "{0,-25}  {1,-17}  {2,-18}  {3,-13}  {4,-13}  {5,-6}" -f "Nome", "Efeito Principal", "Duracao", "Desidratacao", "Red. Energia", "Delay"
                $separator = "-------------------------  -----------------  ------------------  -------------  -------------  -----"
                Write-Host $header; Write-Host $separator
                foreach ($item in $pharmaData) {
                    $line = "{0,-25}  {1,-17}  {2,-18}  {3,-13}  {4,-13}  {5,-6}" -f $item.Nome, $item.EfeitoPrincipal, $item.Duracao, $item.Desidratacao, $item.RedEnergia, $item.Delay
                    Write-Host $line
                }
            }
        }
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        switch ($key.VirtualKeyCode) {
            112 { 
                (Get-Host).UI.RawUI.CursorSize = $originalCursorSize
                $novaCategoria = Show-Menu -Title "Selecione a categoria" -Options $categorias -FlickerFree
                (Get-Host).UI.RawUI.CursorSize = 0
                if ($novaCategoria) { $filtroCategoria = $novaCategoria }
            }
            113 { 
                if ($criteriosDisponiveis.Count -gt 1) {
                    (Get-Host).UI.RawUI.CursorSize = $originalCursorSize
                    $novoCriterio = Show-Menu -Title "Selecione o criterio" -Options $criteriosDisponiveis -FlickerFree
                    (Get-Host).UI.RawUI.CursorSize = 0
                    if ($novoCriterio) { $criterioOrdenacao = $novoCriterio }
                }
            }
            114 { 
                $ordemAtual = if ($ordemAtual -eq "Decrescente") { "Crescente" } else { "Decrescente" }
            }
            115 { 
                Show-PharmaceuticalLegend -Category $filtroCategoria
                continue
            }
            116 { 
                (Get-Host).UI.RawUI.CursorSize = $originalCursorSize
                return
            }
        }
    } while ($true)
}

function Search-ThrowablesWithFilters {
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize
    (Get-Host).UI.RawUI.CursorSize = 0
    # Estado inicial dos filtros
    $criterioOrdenacao = "Alfabetico"
    $ordemAtual = "Crescente"
    
    $criterios = @("Alfabetico", "Delay Explosao", "Alcance", "Dano Blind", "Penetracao", "Fragmentos", "Tipo Frags.", "Tempo Efeito")
    
    # Mapas para tradução
    $alcanceMap    = @{ "Standard" = "Padrao"; "Large" = "Longo"; "Very Large" = "Muito longo"; "/////" = "/////" }
    $danoBlindMap  = @{ "Standard" = "Padrao"; "Mid-High" = "Superior"; "/////" = "/////" }
    $penetracaoMap = @{ "Standard" = "Padrao"; "Mid-High" = "Superior"; "/////" = "/////" }
    $fragmentosMap = @{ "Small" = "Pequeno"; "Large" = "Grande"; "/////" = "/////" }
    $tipoFragsMap  = @{ "Steel Piece" = "Peca de aco"; "Iron Piece" = "Peca de ferro"; "/////" = "/////" }
    do {
        $throwableData = @()
        $itemFiles = Get-ChildItem -Path (Join-Path $global:databasePath "Throwables") -Filter "*.txt" -File
        foreach ($file in $itemFiles) {
            $content = Get-Content -Path $file.FullName
            $delayParts = $content[0] -split ' - '
            
            $throwableData += [PSCustomObject]@{
                Nome           = $file.BaseName
                DelayExplosao  = $content[0]
                DelayNum1      = [double]$delayParts[0]
                DelayNum2      = [double]$delayParts[1]
                Alcance        = $alcanceMap[$content[1]]
                AlcanceRaw     = $content[1]
                DanoBlind      = $danoBlindMap[$content[2]]
                DanoBlindRaw   = $content[2]
                Penetracao     = $penetracaoMap[$content[3]]
                PenetracaoRaw  = $content[3]
                Fragmentos     = $fragmentosMap[$content[4]]
                FragmentosRaw  = $content[4]
                TipoFrags      = $tipoFragsMap[$content[5]]
                TipoFragsRaw   = $content[5]
                TempoEfeito    = [double]$content[6]
            }
        }
        
        $throwableData = Ordenar-ThrowableData -dados $throwableData -criterio $criterioOrdenacao -ordem $ordemAtual
        
        Clear-Host
        Write-Host "=== Busca de granadas com filtro ==="; Write-Host
        
        Write-Host "Botoes: " -NoNewline
        Write-Host "F1" -ForegroundColor Cyan -NoNewline; Write-Host " - Mudar Criterio ($criterioOrdenacao) | " -NoNewline
        Write-Host "F2" -ForegroundColor Gray -NoNewline; Write-Host " - Mudar Ordem ($ordemAtual)"
        Write-Host "Botoes: " -NoNewline
        Write-Host "F3" -ForegroundColor Yellow -NoNewline; Write-Host " - Ver legenda | " -NoNewline
        Write-Host "F4" -ForegroundColor Red -NoNewline; Write-Host " - Voltar ao menu"; Write-Host
        Write-Host "Nome                      Delay Explosao  Alcance       Dano Blind  Penetracao  Fragmentos  Tipo Frags.     Tempo Efeito"
        Write-Host "-----------------------   --------------  -----------   ----------  ----------  ----------  -------------   ------------"
        foreach ($item in $throwableData) {
            $line = ("{0,-23}   {1,-14}  {2,-11}   {3,-9}   {4,-9}   {5,-9}   {6,-13}   {7,-12}" -f 
                $item.Nome, $item.DelayExplosao, $item.Alcance, $item.DanoBlind, $item.Penetracao,
                $item.Fragmentos, $item.TipoFrags, $item.TempoEfeito)
            Write-Host $line
        }
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        switch ($key.VirtualKeyCode) {
            112 { # F1 - Mudar critério
                (Get-Host).UI.RawUI.CursorSize = $originalCursorSize
                $novoCriterio = Show-Menu -Title "Selecione o criterio" -Options $criterios -FlickerFree
                (Get-Host).UI.RawUI.CursorSize = 0
                if ($novoCriterio) { $criterioOrdenacao = $novoCriterio }
            }
            113 { # F2 - Mudar ordem
                $ordemAtual = if ($ordemAtual -eq "Decrescente") { "Crescente" } else { "Decrescente" }
            }
            114 { # F3 - Ver legenda
                Show-GrenadeLegend
                continue
            }
            115 { # F4 - Voltar ao menu principal
                (Get-Host).UI.RawUI.CursorSize = $originalCursorSize
                return
            }
        }
    } while ($true)
}

function Search-HelmetsWithFilters {
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize
    (Get-Host).UI.RawUI.CursorSize = 0
    $criterioOrdenacao = "Alfabetico"
    $ordemAtual = "Crescente"
    
    $compatibilityPath = Join-Path -Path $global:databasePath -ChildPath "Maskcompatibility"
    $masksPath = Join-Path -Path $global:databasePath -ChildPath "Masks"
    
    $helmetToMasks = @{} 
    $allCompFiles = Get-ChildItem -Path $compatibilityPath -Filter "*.txt" -File -ErrorAction SilentlyContinue
    
    foreach ($compFile in $allCompFiles) {
        $compContent = Get-Content -Path $compFile.FullName -ErrorAction SilentlyContinue
        if ($compContent.Count -lt 2) { continue } 
        
        $maskName = $compContent[0]
        $compatibleHelmets = $compContent | Select-Object -Skip 1
        
        foreach ($helmet in $compatibleHelmets) {
            if (-not $helmetToMasks.ContainsKey($helmet)) {
                $helmetToMasks[$helmet] = [System.Collections.ArrayList]@()
            }
            $helmetToMasks[$helmet].Add($maskName) | Out-Null
        }
    }

    $maskClasses = @{}
    $allMaskFiles = Get-ChildItem -Path $masksPath -Filter "*.txt" -File -ErrorAction SilentlyContinue
    foreach ($maskFile in $allMaskFiles) {
        try {
            $maskContent = Get-Content -Path $maskFile.FullName
            if ($maskContent.Count -ge 3) {
                $maskClasses[$maskFile.BaseName] = [int]$maskContent[2]
            }
        } catch {
        }
    }

    if (-not $script:helmetFilters) {
        $script:helmetFilters = @{ SelectedValues = @{}; SelectionMethod = @{} }
    }
    $criterios = @("Alfabetico", "Peso", "Durabilidade", "Classe de Blindagem", "Cl Max Masc", "Material", "Bloqueio", "Penalidade de movimento", "Ergonomia", "Area Protegida", "Chance de Ricochete", "Captura de som", "Reducao de ruido", "Acessorio")
    $materialMap = @{ "Aramid"="Aramida";"Polyethylene"="Polietileno";"Hardened Steel"="Aco endurecido";"Composite"="Composto";"Aluminum"="Aluminio";"Titanium"="Titanio" }
    $bloqueioMap = @{ "Low"="Baixo"; "Moderate"="Moderado"; "Severe"="Grave" }
    $areaMap = @{ "Head"="Cabeca";"Head, Ears"="Cabeca, Ouvidos";"Head, Ears, Face"="Cabeca, Ouvidos, Rosto" }
    $ricocheteMap = @{ "Low"="Baixo";"Medium"="Medio";"High"="Alto" }
    $captadorMap = @{ "Bad"="Fraco";"Medium"="Medio" }
    $reducaoMap = @{ "Bad"="Fraco";"Medium"="Medio";"Strong"="Forte" }
    $acessorioMap = @{ "TE"="TE"; "Mask"="Mascara"; "Mask, TE"="Mascara, TE" }
    do {
        $helmetData = @()
        $itemFiles = Get-ChildItem -Path (Join-Path $global:databasePath "Helmets") -Filter "*.txt" -File
        foreach ($file in $itemFiles) {
            $content = Get-Content -Path $file.FullName
            $weightValue = ([double]$content[0]).ToString("F2", [System.Globalization.CultureInfo]::InvariantCulture)
            $durabilityValue = ([double]$content[1]).ToString("F1", [System.Globalization.CultureInfo]::InvariantCulture)
            
            $helmetName = $file.BaseName
            $clMaxMascValue = "/////"
            
            if ($helmetToMasks.ContainsKey($helmetName)) {
                $compatibleMaskNames = $helmetToMasks[$helmetName]
                $maxMaskClass = 0
                
                foreach ($maskName in $compatibleMaskNames) {
                    if ($maskClasses.ContainsKey($maskName)) {
                        $maskClass = $maskClasses[$maskName]
                        if ($maskClass -gt $maxMaskClass) {
                            $maxMaskClass = $maskClass
                        }
                    }
                }
                
                if ($maxMaskClass -gt 0) {
                    $clMaxMascValue = $maxMaskClass.ToString()
                }
            }

            if ($clMaxMascValue -eq "/////" -and $content[7] -eq "Head, Ears, Face") {
                $clMaxMascValue = "$($content[2])*"
            }

            $clMaxMascFilterValue = $clMaxMascValue.Replace("*", "")

            $helmetData += [PSCustomObject]@{
                Nome = $file.BaseName; Weight = $weightValue; Durability = $durabilityValue; ArmorClass = [int]$content[2]; Material = $content[3]; SoundBlocking = $content[4]; MovementSpeed = $content[5]; MovementSpeedNum = if ($content[5] -eq '/////') { 0 } else { [int]($content[5] -replace '%', '') }; Ergonomics = $content[6]; ErgonomicsNum = if ($content[6] -eq '/////') { 0 } else { [int]$content[6] }; ProtectedArea = $content[7]; RicochetChance = $content[8]; SoundPickup = $content[10]; NoiseReduction = $content[11]; Accessory = $content[12];
                MaterialDisplay = if ($materialMap.ContainsKey($content[3])) { $materialMap[$content[3]] } else { $content[3] }; BloqueioDisplay = if ($bloqueioMap.ContainsKey($content[4])) { $bloqueioMap[$content[4]] } else { $content[4] }; AreaDisplay = if ($areaMap.ContainsKey($content[7])) { $areaMap[$content[7]] } else { $content[7] }; RicochDisplay = if ($ricocheteMap.ContainsKey($content[8])) { $ricocheteMap[$content[8]] } else { $content[8] }; CaptadDisplay = if ($captadorMap.ContainsKey($content[10])) { $captadorMap[$content[10]] } else { $content[10] }; ReduRuDisplay = if ($reducaoMap.ContainsKey($content[11])) { $reducaoMap[$content[11]] } else { $content[11] }; AcessorioDisplay = if ($acessorioMap.ContainsKey($content[12])) { $acessorioMap[$content[12]] } else { $content[12] }
                ClMaxMasc = $clMaxMascValue
                ClMaxMascValue = $clMaxMascFilterValue
            }
        }
        
        $filteredData = $helmetData
        $isAdvancedFilterActive = $false
        if ($script:helmetFilters.SelectedValues.Keys.Count -gt 0) {
            $isAdvancedFilterActive = $true
            foreach($key in $script:helmetFilters.SelectedValues.Keys){
                $valuesToHide = $script:helmetFilters.SelectedValues[$key]
                if($valuesToHide -and $valuesToHide.Count -gt 0){
                    $filteredData = $filteredData | Where-Object { $_.$key -notin $valuesToHide }
                }
            }
        }
        
        $sortedData = Ordenar-HelmetData -dados $filteredData -criterio $criterioOrdenacao
        if ($ordemAtual -eq "Crescente") { [array]::Reverse($sortedData) }
        
        Clear-Host
        Write-Host "=== Busca de capacete com filtro ==="; Write-Host
        
        Write-Host "Botoes: " -NoNewline
        Write-Host "F1" -ForegroundColor Cyan -NoNewline; Write-Host " - Mudar Criterio ($criterioOrdenacao) | " -NoNewline
        Write-Host "F2" -ForegroundColor Gray -NoNewline; Write-Host " - Mudar Ordem ($ordemAtual)"
        
        $statusF3 = if ($isAdvancedFilterActive) { "(Ligado)" } else { "(Desligado)" }
        Write-Host "Botoes: " -NoNewline
        Write-Host "F3" -ForegroundColor $(if ($isAdvancedFilterActive) {'Magenta'} else {'DarkGray'}) -NoNewline; Write-Host " - Ocultar capacetes $statusF3 | " -NoNewline
        Write-Host "F4" -ForegroundColor Yellow -NoNewline; Write-Host " - Ver legenda | " -NoNewline
        Write-Host "F5" -ForegroundColor Red -NoNewline; Write-Host " - Voltar ao menu"; Write-Host
        if ($criterioOrdenacao -eq "Alfabetico") { Write-Host ("{0,-32}" -f "Nome do Capacete") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-32}" -f "Nome do Capacete") -NoNewline }
        if ($criterioOrdenacao -eq "Peso") { Write-Host ("{0,-6}" -f "Peso") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-6}" -f "Peso") -NoNewline }
        if ($criterioOrdenacao -eq "Durabilidade") { Write-Host ("{0,-7}" -f "Dur.") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-7}" -f "Dur.") -NoNewline }
        if ($criterioOrdenacao -eq "Classe de Blindagem") { Write-Host ("{0,-4}" -f "Cl") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-4}" -f "Cl") -NoNewline }
        if ($criterioOrdenacao -eq "Material") { Write-Host ("{0,-15}" -f "Material") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-15}" -f "Material") -NoNewline }
        if ($criterioOrdenacao -eq "Bloqueio") { Write-Host ("{0,-9}" -f "Bloqueio") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-9}" -f "Bloqueio") -NoNewline }
        if ($criterioOrdenacao -eq "Penalidade de movimento") { Write-Host ("{0,-6}" -f "Vel.M") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-6}" -f "Vel.M") -NoNewline }
        if ($criterioOrdenacao -eq "Ergonomia") { Write-Host ("{0,-6}" -f "Ergo") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-6}" -f "Ergo") -NoNewline }
        if ($criterioOrdenacao -eq "Area Protegida") { Write-Host ("{0,-23}" -f "Area Protegida") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-23}" -f "Area Protegida") -NoNewline }
        if ($criterioOrdenacao -eq "Chance de Ricochete") { Write-Host ("{0,-7}" -f "Ricoch") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-7}" -f "Ricoch") -NoNewline }
        if ($criterioOrdenacao -eq "Captura de som") { Write-Host ("{0,-7}" -f "Captad") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-7}" -f "Captad") -NoNewline }
        if ($criterioOrdenacao -eq "Reducao de ruido") { Write-Host ("{0,-7}" -f "Red.Ru") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-7}" -f "Red.Ru") -NoNewline }
        
        if ($criterioOrdenacao -eq "Acessorio") { Write-Host ("{0,-13}" -f "Acessorio") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-13}" -f "Acessorio") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Cl Max Masc") { Write-Host ("{0,-11}" -f "Cl Max Masc") -ForegroundColor Green } else { Write-Host ("{0,-11}" -f "Cl Max Masc") }
        
        Write-Host "------------------------------  ----  ----   --  -------------- -------- ----- ----- ---------------------- ------ ------ ------ ------------- -----------"
        
        foreach ($item in $sortedData) {
            Write-Host ("{0,-32}" -f $item.Nome) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Alfabetico") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host ("{0,-6}" -f $item.Weight) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Peso") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host ("{0,-7}" -f $item.Durability) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Durabilidade") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host ("{0,-4}" -f $item.ArmorClass) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Classe de Blindagem") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host ("{0,-15}" -f $item.MaterialDisplay) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Material") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host ("{0,-9}" -f $item.BloqueioDisplay) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Bloqueio") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host ("{0,-6}" -f $item.MovementSpeed) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Penalidade de movimento") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host ("{0,-6}" -f $item.Ergonomics) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Ergonomia") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host ("{0,-23}" -f $item.AreaDisplay) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Area Protegida") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host ("{0,-7}" -f $item.RicochDisplay) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Chance de Ricochete") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host ("{0,-7}" -f $item.CaptadDisplay) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Captura de som") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host ("{0,-7}" -f $item.ReduRuDisplay) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Reducao de ruido") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            
            Write-Host ("{0,-13}" -f $item.AcessorioDisplay) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Acessorio") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-11}" -f $item.ClMaxMasc) -ForegroundColor $(if ($criterioOrdenacao -eq "Cl Max Masc") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
        }
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        switch ($key.VirtualKeyCode) {
            112 { # F1
                $novoCriterio = Show-Menu -Title "Selecione o criterio" -Options $criterios -FlickerFree
                (Get-Host).UI.RawUI.CursorSize = 0 
                if ($novoCriterio) { $criterioOrdenacao = $novoCriterio }
            }
            113 { # F2
                $ordemAtual = if ($ordemAtual -eq "Decrescente") { "Crescente" } else { "Decrescente" }
            }
            114 { # F3
                $headerLayout = "  Classe (Cl)  Bloqueio         Area Protegida                 Ricochete     Acessorio          Cl Max Masc"
                
                $columnLabels = ($headerLayout -split '\s{2,}' | Where-Object {$_})
                $startPositions = @(); foreach ($label in $columnLabels) { $startPositions += $headerLayout.IndexOf($label) }
                $startPositions += $headerLayout.Length + 5 
                $filterDefs = @(
                    @{ Label = $columnLabels[0]; Property = "ArmorClass";       Width = $startPositions[1] - $startPositions[0] },
                    @{ Label = $columnLabels[1]; Property = "BloqueioDisplay";  Width = $startPositions[2] - $startPositions[1]; CustomSortOrder = @("/////", "Baixo", "Moderado", "Grave") },
                    @{ Label = $columnLabels[2]; Property = "AreaDisplay";      Width = $startPositions[3] - $startPositions[2] },
                    @{ Label = $columnLabels[3]; Property = "RicochDisplay";    Width = $startPositions[4] - $startPositions[3]; CustomSortOrder = @("Baixo", "Medio", "Alto") },
                    @{ Label = $columnLabels[4]; Property = "AcessorioDisplay"; Width = $startPositions[5] - $startPositions[4]; CustomSortOrder = @("/////", "TE", "Mascara", "Mascara, TE") },
                    @{ Label = $columnLabels[5]; Property = "ClMaxMascValue";   Width = $startPositions[6] - $startPositions[5]; CustomSortOrder = @("/////", "2", "3", "4", "5", "6") }
                )
                
                $updatedFilters = Show-ItemFilterScreen -Title "Filtro de Capacetes" -AllItems $helmetData -FilterDefinitions $filterDefs -CurrentFilters $script:helmetFilters
                if ($updatedFilters) {
                    $script:helmetFilters = $updatedFilters
                } else { 
                    $script:helmetFilters = @{ SelectedValues = @{}; SelectionMethod = @{} }
                }
                (Get-Host).UI.RawUI.CursorSize = 0
            }
            115 { # F4
                Show-HelmetLegend
                continue
            }
            116 { # F5
                $script:helmetFilters = @{ SelectedValues = @{}; SelectionMethod = @{} }
                (Get-Host).UI.RawUI.CursorSize = $originalCursorSize
                return
            }
        }
    } while ($true)
}

function Search-BodyArmorsWithFilters {
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize
    (Get-Host).UI.RawUI.CursorSize = 0
    $criterioOrdenacao = "Alfabetico"
    $ordemAtual = "Crescente"
    if (-not $script:bodyArmorFilters) {
        $script:bodyArmorFilters = @{ SelectedValues = @{}; SelectionMethod = @{} }
    }
    
    $criterios = @("Alfabetico", "Peso", "Durabilidade", "Classe de Blindagem", "Material", "Penalidade de movimento", "Ergonomia", "Area Protegida")
    $materialMapDisplay = @{ "Aramid"="Aramida"; "Polyethylene"="Polietileno"; "Hardened Steel"="Aco endurecido"; "Composite"="Composto"; "Aluminum"="Aluminio"; "Titanium"="Titanio"; "Ceramic"="Ceramica" }
    $areaMapDisplay = @{ "Chest"="Torax"; "Chest, Upper Abdomen"="Torax, Abdomen Superior"; "Chest, Shoulder, Upper Abdomen"="Torax, Ombro, Abdomen Superior"; "Chest, Upper Abdomen, Lower Abdomen"="Torax, Abdomen Superior e Inferior"; "Chest, Shoulder, Upper Abdomen, Lower Abdomen"="Torax, Ombro, Abdomen Superior e Inferior" }
    do {
        $bodyArmorData = @()
        $itemFiles = Get-ChildItem -Path (Join-Path $global:databasePath "Bodyarmors") -Filter "*.txt" -File
        foreach ($file in $itemFiles) {
            $content = Get-Content -Path $file.FullName
            
            $bodyArmorData += [PSCustomObject]@{
                Nome                 = $file.BaseName
                Weight               = [double]$content[0]
                Durability           = [double]$content[1]
                ArmorClass           = [int]$content[2]
                Material             = $materialMapDisplay[$content[3]]
                MovementSpeed        = $content[4]
                Ergonomics           = $content[5]
                ProtectedArea        = $areaMapDisplay[$content[6]]
                ProtectedAreaRaw     = $content[6]
            }
        }
        $filteredData = $bodyArmorData
        $isAdvancedFilterActive = $false
        if ($script:bodyArmorFilters.SelectedValues.Keys.Count -gt 0) {
            $isAdvancedFilterActive = $true
            foreach($key in $script:bodyArmorFilters.SelectedValues.Keys){
                $valuesToHide = $script:bodyArmorFilters.SelectedValues[$key]
                if($valuesToHide -and $valuesToHide.Count -gt 0){
                    $filteredData = $filteredData | Where-Object { $_.$key -notin $valuesToHide }
                }
            }
        }
        $sortedData = Ordenar-BodyArmorData -dados $filteredData -criterio $criterioOrdenacao
        
        if ($ordemAtual -eq "Crescente") {
            [array]::Reverse($sortedData)
        }
        
        Clear-Host
        Write-Host "=== Busca de colete balistico com filtro ==="; Write-Host
        Write-Host "Botoes: " -NoNewline
        Write-Host "F1" -ForegroundColor Cyan -NoNewline; Write-Host " - Mudar Criterio ($criterioOrdenacao) | " -NoNewline
        Write-Host "F2" -ForegroundColor Gray -NoNewline; Write-Host " - Mudar Ordem ($ordemAtual)"
        $statusF3 = if ($isAdvancedFilterActive) { "(Ligado)" } else { "(Desligado)" }
        Write-Host "Botoes: " -NoNewline
        Write-Host "F3" -ForegroundColor $(if ($isAdvancedFilterActive) {'Magenta'} else {'DarkGray'}) -NoNewline; Write-Host " - Ocultar coletes $statusF3 | " -NoNewline
        Write-Host "F4" -ForegroundColor Yellow -NoNewline; Write-Host " - Ver legenda | " -NoNewline
        Write-Host "F5" -ForegroundColor Red -NoNewline; Write-Host " - Voltar ao menu"; Write-Host
        if ($criterioOrdenacao -eq "Alfabetico") { Write-Host ("{0,-42}" -f "Nome do Colete") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-42}" -f "Nome do Colete") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Peso") { Write-Host ("{0,-6}" -f "Peso") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-6}" -f "Peso") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Classe de Blindagem") { Write-Host ("{0,-2}" -f "Cl") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-2}" -f "Cl") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Durabilidade") { Write-Host ("{0,-7}" -f "Dur.") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-7}" -f "Dur.") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Material") { Write-Host ("{0,-15}" -f "Material") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-15}" -f "Material") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Penalidade de movimento") { Write-Host ("{0,-6}" -f "Vel.M") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-6}" -f "Vel.M") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Ergonomia") { Write-Host ("{0,-6}" -f "Ergo") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-6}" -f "Ergo") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Area Protegida") { Write-Host ("{0,-41}" -f "Area Protegida") -ForegroundColor Green } else { Write-Host ("{0,-41}" -f "Area Protegida") }
        Write-Host "------------------------------------------ ------ -- ------- --------------- ------ ------ -----------------------------------------"
        foreach ($item in $sortedData) {
            $pesoFormatado = $item.Weight.ToString("F2", [System.Globalization.CultureInfo]::InvariantCulture)
            $durabilidadeFormatada = $item.Durability.ToString("F1", [System.Globalization.CultureInfo]::InvariantCulture)
            Write-Host ("{0,-42}" -f $item.Nome) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Alfabetico") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-6}" -f $pesoFormatado) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Peso") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-2}" -f $item.ArmorClass) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Classe de Blindagem") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-7}" -f $durabilidadeFormatada) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Durabilidade") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-15}" -f $item.Material) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Material") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-6}" -f $item.MovementSpeed) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Penalidade de movimento") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-6}" -f $item.Ergonomics) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Ergonomia") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-41}" -f $item.ProtectedArea) -ForegroundColor $(if ($criterioOrdenacao -eq "Area Protegida") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
        }
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        switch ($key.VirtualKeyCode) {
            112 { # F1
                $novoCriterio = Show-Menu -Title "Selecione o criterio" -Options $criterios -FlickerFree
                (Get-Host).UI.RawUI.CursorSize = 0 
                if ($novoCriterio) { 
                    $criterioOrdenacao = $novoCriterio
                    if ($criterioOrdenacao -eq 'Alfabetico') { $ordemAtual = 'Crescente' } else { $ordemAtual = 'Decrescente' }
                }
            }
            113 { # F2
                $ordemAtual = if ($ordemAtual -eq "Decrescente") { "Crescente" } else { "Decrescente" }
            }
            114 { # F3
                $headerLayout = "  Cl        Area Protegida"
                
                $columnLabels = ($headerLayout -split '\s{2,}' | Where-Object {$_})
                $startPositions = @(); foreach ($label in $columnLabels) { $startPositions += $headerLayout.IndexOf($label) }
                $startPositions += $headerLayout.Length + 5
                
                $filterDefs = @(
                    @{ Label = $columnLabels[0]; Property = "ArmorClass";    Width = $startPositions[1] - $startPositions[0] },
                    @{ Label = $columnLabels[1]; Property = "ProtectedArea"; Width = $startPositions[2] - $startPositions[1] }
                )
                
                $updatedFilters = Show-ItemFilterScreen -Title "Filtro de Coletes Balisticos" -AllItems $bodyArmorData -FilterDefinitions $filterDefs -CurrentFilters $script:bodyArmorFilters
                if ($updatedFilters) {
                    $script:bodyArmorFilters = $updatedFilters
                } else { 
                    $script:bodyArmorFilters = @{ SelectedValues = @{}; SelectionMethod = @{} }
                }
                (Get-Host).UI.RawUI.CursorSize = 0
            }
            115 { # F4
                Show-BodyArmorLegend
                continue
            }
            116 { # F5
                $script:bodyArmorFilters = @{ SelectedValues = @{}; SelectionMethod = @{} }
                (Get-Host).UI.RawUI.CursorSize = $originalCursorSize
                return
            }
        }
    } while ($true)
}

function Search-ArmoredRigsWithFilters {
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize
    (Get-Host).UI.RawUI.CursorSize = 0
    $criterioOrdenacao = "Alfabetico"
    $ordemAtual = "Decrescente"
    if (-not $script:armoredRigFilters) {
        $script:armoredRigFilters = @{ SelectedValues = @{}; SelectionMethod = @{} }
    }
    $criterios = @("Alfabetico", "Peso", "Durabilidade", "Classe de Blindagem", "Material", "Penalidade de movimento", "Ergonomia", "Armazenamento", "Area Protegida")
    $materialMapDisplay = @{ "Aramid"="Aramida"; "Polyethylene"="Polietileno"; "Hardened Steel"="Aco endurecido"; "Composite"="Composto"; "Aluminum"="Aluminio"; "Titanium"="Titanio"; "Ceramic"="Ceramica" }
    $areaMapDisplay = @{ "Chest"="Torax"; "Chest, Upper Abdomen"="Torax, Abdomen Sup."; "Chest, Upper Abdomen, Lower Abdomen"="Torax, Abd. Sup. e Inf."; "Chest, Shoulder, Upper Abdomen, Lower Abdomen"="Torax, Ombro, Abd. Sup. e Inf." }
    do {
        $divisor =     "-------------------------------- ------ -- ------- --------------- ------ ------ ---  -------------------------------  --------------------"
        
        $armoredRigData = @()
        $itemFiles = Get-ChildItem -Path (Join-Path $global:databasePath "Armoredrigs") -Filter "*.txt" -File
        foreach ($file in $itemFiles) {
            $content = Get-Content -Path $file.FullName
            while ($content.Count -lt 9) { $content += "/////" }
            $armoredRigData += [PSCustomObject]@{
                Nome                 = $file.BaseName
                Weight               = [double]$content[0]
                Durability           = [double]$content[1]
                ArmorClass           = [int]$content[2]
                Material             = $materialMapDisplay[$content[3]]
                MovementSpeed        = $content[4]
                Ergonomics           = $content[5]
                Storage              = [int]$content[6]
                ProtectedArea        = $areaMapDisplay[$content[7]]
                ProtectedAreaRaw     = $content[7]
                InternalLayout       = $content[8]
            }
        }
        $filteredData = $armoredRigData
        $isAdvancedFilterActive = $false
        if ($script:armoredRigFilters.SelectedValues.Keys.Count -gt 0) {
            $isAdvancedFilterActive = $true
            foreach($key in $script:armoredRigFilters.SelectedValues.Keys){
                $valuesToHide = $script:armoredRigFilters.SelectedValues[$key]
                if($valuesToHide -and $valuesToHide.Count -gt 0){
                    $filteredData = $filteredData | Where-Object { $_.$key -notin $valuesToHide }
                }
            }
        }
        $sortedData = Ordenar-ArmoredRigData -dados $filteredData -criterio $criterioOrdenacao
        if ($ordemAtual -eq "Crescente") { [array]::Reverse($sortedData) }
        
        Clear-Host
        Write-Host "=== Busca de colete blindado com filtro ==="; Write-Host
        Write-Host "Botoes: " -NoNewline
        Write-Host "F1" -ForegroundColor Cyan -NoNewline; Write-Host " - Mudar Criterio ($criterioOrdenacao) | " -NoNewline
        Write-Host "F2" -ForegroundColor Gray -NoNewline; Write-Host " - Mudar Ordem ($ordemAtual)"
        $statusF3 = if ($isAdvancedFilterActive) { "(Ligado)" } else { "(Desligado)" }
        Write-Host "Botoes: " -NoNewline
        Write-Host "F3" -ForegroundColor $(if ($isAdvancedFilterActive) {'Magenta'} else {'DarkGray'}) -NoNewline; Write-Host " - Ocultar coletes $statusF3 | " -NoNewline
        Write-Host "F4" -ForegroundColor Yellow -NoNewline; Write-Host " - Ver legenda | " -NoNewline
        Write-Host "F5" -ForegroundColor Red -NoNewline; Write-Host " - Voltar ao menu"; Write-Host
        if ($criterioOrdenacao -eq "Alfabetico") { Write-Host ("{0,-32}" -f "Nome do colete blindado") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-32}" -f "Nome do colete blindado") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Peso") { Write-Host ("{0,-6}" -f "Peso") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-6}" -f "Peso") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Classe de Blindagem") { Write-Host ("{0,-2}" -f "Cl") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-2}" -f "Cl") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Durabilidade") { Write-Host ("{0,-7}" -f "Dur.") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-7}" -f "Dur.") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Material") { Write-Host ("{0,-15}" -f "Material") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-15}" -f "Material") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Penalidade de movimento") { Write-Host ("{0,-6}" -f "Vel.M") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-6}" -f "Vel.M") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Ergonomia") { Write-Host ("{0,-6}" -f "Ergo") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-6}" -f "Ergo") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Armazenamento") { Write-Host ("{0,-4}" -f "Esp") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-4}" -f "Esp") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Area Protegida") { Write-Host ("{0,-32}" -f "Area Protegida") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-32}" -f "Area Protegida") -NoNewline }
        Write-Host " " -NoNewline
        Write-Host ("{0,-20}" -f "Conj d. blocos(HxV)")
        Write-Host $divisor
        foreach ($item in $sortedData) {
            $pesoFormatado = $item.Weight.ToString("F2", [System.Globalization.CultureInfo]::InvariantCulture)
            $durabilidadeFormatada = $item.Durability.ToString("F1", [System.Globalization.CultureInfo]::InvariantCulture)
            Write-Host ("{0,-32}" -f $item.Nome) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Alfabetico") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-6}" -f $pesoFormatado) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Peso") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-2}" -f $item.ArmorClass) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Classe de Blindagem") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-7}" -f $durabilidadeFormatada) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Durabilidade") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-15}" -f $item.Material) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Material") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-6}" -f $item.MovementSpeed) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Penalidade de movimento") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-6}" -f $item.Ergonomics) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Ergonomia") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-4}" -f $item.Storage) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Armazenamento") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-32}" -f $item.ProtectedArea) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Area Protegida") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-20}" -f $item.InternalLayout)
        }
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        switch ($key.VirtualKeyCode) {
            112 { # F1
                $novoCriterio = Show-Menu -Title "Selecione o criterio" -Options $criterios -FlickerFree
                (Get-Host).UI.RawUI.CursorSize = 0
                if ($novoCriterio) { 
                    $criterioOrdenacao = $novoCriterio
                    if ($criterioOrdenacao -eq 'Alfabetico') { $ordemAtual = 'Crescente' } else { $ordemAtual = 'Decrescente' }
                }
            }
            113 { # F2
                $ordemAtual = if ($ordemAtual -eq "Decrescente") { "Crescente" } else { "Decrescente" }
            }
            114 { # F3
                $headerLayout = "  Cl        Area Protegida"
                
                $columnLabels = ($headerLayout -split '\s{2,}' | Where-Object {$_})
                $startPositions = @(); foreach ($label in $columnLabels) { $startPositions += $headerLayout.IndexOf($label) }
                $startPositions += $headerLayout.Length + 5
                
                $filterDefs = @(
                    @{ Label = $columnLabels[0]; Property = "ArmorClass";    Width = $startPositions[1] - $startPositions[0] },
                    @{ Label = $columnLabels[1]; Property = "ProtectedArea"; Width = $startPositions[2] - $startPositions[1] }
                )
                
                $updatedFilters = Show-ItemFilterScreen -Title "Filtro de Coletes Blindados" -AllItems $armoredRigData -FilterDefinitions $filterDefs -CurrentFilters $script:armoredRigFilters
                if ($updatedFilters) {
                    $script:armidRigFilters = $updatedFilters
                } else { 
                    $script:armoredRigFilters = @{ SelectedValues = @{}; SelectionMethod = @{} }
                }
                (Get-Host).UI.RawUI.CursorSize = 0
            }
            115 { # F4
                Show-ArmoredRigLegend; continue
            }
            116 { # F5
                $script:armoredRigFilters = @{ SelectedValues = @{}; SelectionMethod = @{} }
                (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return
            }
        }
    } while ($true)
}

function Search-MasksWithFilters {
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize
    (Get-Host).UI.RawUI.CursorSize = 0
    $criterioOrdenacao = "Alfabetico"
    $ordemAtual = "Crescente"
    $criterios = @("Alfabetico", "Peso", "Durabilidade", "Classe de Blindagem", "Material", "Chance de Ricochete")
    
    $materialMapDisplay = @{ "Glass"="Vidro"; "Hardened Steel"="Aco endurecido"; "Composite"="Composto"; "Aluminum"="Aluminio" }
    $ricocheteMapDisplay = @{ "Low"="Baixo"; "Medium"="Medio"; "High"="Alto" }
    do {
        $maskData = @()
        $itemFiles = Get-ChildItem -Path (Join-Path $global:databasePath "Masks") -Filter "*.txt" -File
        foreach ($file in $itemFiles) {
            $content = Get-Content -Path $file.FullName
            
            $maskData += [PSCustomObject]@{
                Nome                 = $file.BaseName
                Weight               = [double]$content[0]
                Durability           = [double]$content[1]
                ArmorClass           = [int]$content[2]
                Material             = $materialMapDisplay[$content[3]]
                RicochetChance       = $ricocheteMapDisplay[$content[4]]
                RicochetChanceRaw    = $content[4]
            }
        }
        
        $sortedData = Ordenar-MaskData -dados $maskData -criterio $criterioOrdenacao
        if ($ordemAtual -eq "Crescente") { [array]::Reverse($sortedData) }
        
        Clear-Host
        Write-Host "=== Busca de mascara com filtro ==="; Write-Host
        
        Write-Host "Botoes: " -NoNewline
        Write-Host "F1" -ForegroundColor Cyan -NoNewline; Write-Host " - Mudar Criterio ($criterioOrdenacao) | " -NoNewline
        Write-Host "F2" -ForegroundColor Gray -NoNewline; Write-Host " - Mudar Ordem ($ordemAtual)"
        Write-Host "Botoes: " -NoNewline
        Write-Host "F3" -ForegroundColor Yellow -NoNewline; Write-Host " - Ver legenda | " -NoNewline
        Write-Host "F4" -ForegroundColor Red -NoNewline; Write-Host " - Voltar ao menu"; Write-Host
        $config = $global:ItemCategoryConfig["Masks"]
        if ($criterioOrdenacao -eq "Alfabetico") { Write-Host ("{0,-38}" -f "Nome da mascara") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-38}" -f "Nome da mascara") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Peso") { Write-Host ("{0,-6}" -f "Peso") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-6}" -f "Peso") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Durabilidade") { Write-Host ("{0,-6}" -f "Dur.") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-6}" -f "Dur.") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Classe de Blindagem") { Write-Host ("{0,-4}" -f "Cl") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-4}" -f "Cl") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Material") { Write-Host ("{0,-15}" -f "Material") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-15}" -f "Material") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Chance de Ricochete") { Write-Host ("{0,-19}" -f "Chance de Ricochete") -ForegroundColor Green } else { Write-Host ("{0,-19}" -f "Chance de Ricochete") }
        
        Write-Host "------------------------------------   -----  -----  ---  --------------  -------------------"
        foreach ($item in $sortedData) {
            $pesoFormatado = $item.Weight.ToString("F2", [System.Globalization.CultureInfo]::InvariantCulture)
            $durabilidadeFormatada = $item.Durability.ToString("F1", [System.Globalization.CultureInfo]::InvariantCulture)
            
            Write-Host ("{0,-38}" -f $item.Nome) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Alfabetico") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-6}" -f $pesoFormatado) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Peso") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-6}" -f $durabilidadeFormatada) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Durabilidade") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-4}" -f $item.ArmorClass) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Classe de Blindagem") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-15}" -f $item.Material) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Material") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-19}" -f $item.RicochetChance) -ForegroundColor $(if ($criterioOrdenacao -eq "Chance de Ricochete") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
        }
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        switch ($key.VirtualKeyCode) {
            112 { # F1 - Mudar critério
                $novoCriterio = Show-Menu -Title "Selecione o criterio" -Options $criterios -FlickerFree
                (Get-Host).UI.RawUI.CursorSize = 0 # Garante que o cursor fique escondido
                if ($novoCriterio) { 
                    $criterioOrdenacao = $novoCriterio
                    if ($novoCriterio -eq 'Alfabetico' -or $novoCriterio -eq 'Peso') { $ordemAtual = 'Crescente' } else { $ordemAtual = 'Decrescente' } 
                }
            }
            113 { # F2 - Mudar ordem
                $ordemAtual = if ($ordemAtual -eq "Decrescente") { "Crescente" } else { "Decrescente" }
            }
            114 { # F3 - Ver legenda
                Show-MaskLegend; continue
            }
            115 { # F4 - Voltar ao menu principal
                (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return
            }
        }
    } while ($true)
}

function Search-GasMasksWithFilters {
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize
    (Get-Host).UI.RawUI.CursorSize = 0
    $criterioOrdenacao = "Alfabetico"
    $ordemAtual = "Crescente"
    $criterios = @("Alfabetico", "Peso", "Durabilidade", "Anti-Veneno", "Anti-Flash")
    
    $effectMapDisplay = @{ "/////"="/////"; "Bad"="Fraco"; "Medium"="Medio"; "Strong"="Forte" }
    do {
        $gasMaskData = @()
        $itemFiles = Get-ChildItem -Path (Join-Path $global:databasePath "Gasmasks") -Filter "*.txt" -File
        foreach ($file in $itemFiles) {
            $content = Get-Content -Path $file.FullName
            
            $gasMaskData += [PSCustomObject]@{
                Nome          = $file.BaseName
                Weight        = [double]$content[0]
                WeightRaw     = $content[0]
                Durability    = [int]$content[1] 
                DurabilityRaw = $content[1]
                AntiVeneno    = $effectMapDisplay[$content[2]]
                AntiVenenoRaw = $content[2]
                AntiFlash     = $effectMapDisplay[$content[3]]
                AntiFlashRaw  = $content[3]
            }
        }
        
        $sortedData = Ordenar-GasMaskData -dados $gasMaskData -criterio $criterioOrdenacao
        if ($ordemAtual -eq "Crescente") { [array]::Reverse($sortedData) }
        
        Clear-Host
        Write-Host "=== Busca de mascara de gas com filtro ==="; Write-Host
        
        Write-Host "Botoes: " -NoNewline
        Write-Host "F1" -ForegroundColor Cyan -NoNewline; Write-Host " - Mudar Criterio ($criterioOrdenacao) | " -NoNewline
        Write-Host "F2" -ForegroundColor Gray -NoNewline; Write-Host " - Mudar Ordem ($ordemAtual)"
        Write-Host "Botoes: " -NoNewline
        Write-Host "F3" -ForegroundColor Yellow -NoNewline; Write-Host " - Ver legenda | " -NoNewline
        Write-Host "F4" -ForegroundColor Red -NoNewline; Write-Host " - Voltar ao menu"; Write-Host
        $config = $global:ItemCategoryConfig["Gasmasks"]
        if ($criterioOrdenacao -eq "Alfabetico") { Write-Host ("{0,-36}" -f "Nome da mascara de gas") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-36}" -f "Nome da mascara de gas") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Peso") { Write-Host ("{0,-6}" -f "Peso") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-6}" -f "Peso") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Durabilidade") { Write-Host ("{0,-6}" -f "Dur.") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-6}" -f "Dur.") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Anti-Veneno") { Write-Host ("{0,-13}" -f "Anti-Veneno") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-13}" -f "Anti-Veneno") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Anti-Flash") { Write-Host ("{0,-12}" -f "Anti-Flash") -ForegroundColor Green } else { Write-Host ("{0,-12}" -f "Anti-Flash") }
        Write-Host "----------------------------------   ----   ----   -----------   ----------"
        foreach ($item in $sortedData) {
            Write-Host ("{0,-36}" -f $item.Nome) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Alfabetico") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-6}" -f $item.WeightRaw) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Peso") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-6}" -f $item.DurabilityRaw) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Durabilidade") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-13}" -f $item.AntiVeneno) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Anti-Veneno") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-12}" -f $item.AntiFlash) -ForegroundColor $(if ($criterioOrdenacao -eq "Anti-Flash") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
        }
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        switch ($key.VirtualKeyCode) {
            112 { # F1 - Mudar critério
                $novoCriterio = Show-Menu -Title "Selecione o criterio" -Options $criterios -FlickerFree
                (Get-Host).UI.RawUI.CursorSize = 0 # Garante que o cursor fique escondido
                if ($novoCriterio) { 
                    $criterioOrdenacao = $novoCriterio
                    if ($criterioOrdenacao -eq 'Alfabetico') {
                        $ordemAtual = 'Crescente'
                    } else {
                        $ordemAtual = 'Decrescente'
                    }
                }
            }
            113 { # F2 - Mudar ordem
                $ordemAtual = if ($ordemAtual -eq "Decrescente") { "Crescente" } else { "Decrescente" }
            }
            114 { # F3 - Ver legenda
                Show-GasMaskLegend; continue
            }
            115 { # F4 - Voltar ao menu principal
                (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return
            }
        }
    } while ($true)
}

function Search-HeadsetsWithFilters {
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize
    (Get-Host).UI.RawUI.CursorSize = 0
    $criterioOrdenacao = "Alfabetico"
    $ordemAtual = "Crescente"
    
    $criterios = @("Alfabetico", "Peso", "Captador de Som", "Reducao de Ruido")
    
    $effectMapDisplay = @{ "Bad"="Fraco"; "Medium"="Medio"; "Strong"="Forte" }
    do {
        $headsetData = @()
        $itemFiles = Get-ChildItem -Path (Join-Path $global:databasePath "Headsets") -Filter "*.txt" -File
        foreach ($file in $itemFiles) {
            $content = Get-Content -Path $file.FullName
            
            $headsetData += [PSCustomObject]@{
                Nome                 = $file.BaseName
                Weight               = [double]$content[0]
                SoundPickup          = $effectMapDisplay[$content[1]]
                SoundPickupRaw       = $content[1]
                NoiseReduction       = $effectMapDisplay[$content[2]]
                NoiseReductionRaw    = $content[2]
            }
        }
        
        $sortedData = Ordenar-HeadsetData -dados $headsetData -criterio $criterioOrdenacao
        if ($ordemAtual -eq "Crescente") { [array]::Reverse($sortedData) }
        
        Clear-Host
        Write-Host "=== Busca de fone de ouvido com filtro ==="; Write-Host
        
        Write-Host "Botoes: " -NoNewline
        Write-Host "F1" -ForegroundColor Cyan -NoNewline; Write-Host " - Mudar Criterio ($criterioOrdenacao) | " -NoNewline
        Write-Host "F2" -ForegroundColor Gray -NoNewline; Write-Host " - Mudar Ordem ($ordemAtual)"
        Write-Host "Botoes: " -NoNewline
        Write-Host "F3" -ForegroundColor Yellow -NoNewline; Write-Host " - Ver legenda | " -NoNewline
        Write-Host "F4" -ForegroundColor Red -NoNewline; Write-Host " - Voltar ao menu"; Write-Host
        if ($criterioOrdenacao -eq "Alfabetico") { Write-Host ("{0,-32}" -f "Nome do fone de ouvido") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-32}" -f "Nome do fone de ouvido") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Peso") { Write-Host ("{0,-6}" -f "Peso") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-6}" -f "Peso") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Captador de Som") { Write-Host ("{0,-17}" -f "Captador de Som") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-17}" -f "Captador de Som") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Reducao de Ruido") { Write-Host ("{0,-16}" -f "Reducao de Ruido") -ForegroundColor Green } else { Write-Host ("{0,-16}" -f "Reducao de Ruido") }
        
        Write-Host "-------------------------------- -----  ---------------   ----------------"
        foreach ($item in $sortedData) {
            $pesoFormatado = $item.Weight.ToString("F2", [System.Globalization.CultureInfo]::InvariantCulture)
            
            Write-Host ("{0,-32}" -f $item.Nome) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Alfabetico") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-6}" -f $pesoFormatado) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Peso") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-17}" -f $item.SoundPickup) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Captador de Som") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-16}" -f $item.NoiseReduction) -ForegroundColor $(if ($criterioOrdenacao -eq "Reducao de Ruido") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
        }
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        switch ($key.VirtualKeyCode) {
            112 { # F1 - Mudar critério
                $novoCriterio = Show-Menu -Title "Selecione o criterio" -Options $criterios -FlickerFree
                (Get-Host).UI.RawUI.CursorSize = 0 # Garante que o cursor fique escondido
                if ($novoCriterio) { 
                    $criterioOrdenacao = $novoCriterio
                    if ($criterioOrdenacao -eq 'Alfabetico') {
                        $ordemAtual = 'Crescente'
                    } else {
                        $ordemAtual = 'Decrescente'
                    }
                }
            }
            113 { # F2 - Mudar ordem
                $ordemAtual = if ($ordemAtual -eq "Decrescente") { "Crescente" } else { "Decrescente" }
            }
            114 { # F3 - Ver legenda
                Show-HeadsetLegend; continue
            }
            115 { # F4 - Voltar ao menu principal
                (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return
            }
        }
    } while ($true)
}

function Search-UnarmoredRigsWithFilters {
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize
    (Get-Host).UI.RawUI.CursorSize = 0
    $criterioOrdenacao = "Alfabetico"
    $ordemAtual = "Crescente"
    $criterios = @("Alfabetico", "Peso", "Espaco", "+Espaco p/armaz -Espaco consumido")
    
    do {
        $localHeader = "Nome do colete nao blindado                Peso   Espaco Desdobrada  Dobrada Conj d. blocos          +Armaz -Espaco"
        $divisor =     "------------------------------------------ ------ ------ ---------- ------- ----------------------- --------------"
        
        $unarmoredRigData = @()
        $itemFiles = Get-ChildItem -Path (Join-Path $global:databasePath "Unarmoredrigs") -Filter "*.txt" -File
        foreach ($file in $itemFiles) {
            $content = Get-Content -Path $file.FullName
            while ($content.Count -lt 5) { $content += "/////" }
            $efficiency = -9999
            if ($content[2] -ne '/////' -and $content[2] -match '(\d+)x(\d+)') {
                $occupied = [int]$Matches[1] * [int]$Matches[2]
                $efficiency = [int]$content[1] - $occupied
            }
            $setCount = 0
            $internalLayoutString = $content[4]
            if ($internalLayoutString -ne '/////') {
                $sets = $internalLayoutString -split ',\s*'
                foreach ($set in $sets) {
                    if ($set -match '^\((\d+)\)') {
                        $setCount += [int]$Matches[1]
                    } else {
                        $setCount += 1
                    }
                }
            } else {
                $setCount = 999
            }
            $unarmoredRigData += [PSCustomObject]@{
                Nome            = $file.BaseName
                Weight          = [double]$content[0]
                Storage         = [int]$content[1]
                WeightRaw       = $content[0]
                SizeUnfolded    = $content[2]
                SizeFolded      = $content[3]
                InternalLayout  = $content[4]
                Efficiency      = $efficiency
                SetCount        = $setCount # Nova propriedade adicionada
            }
        }
        
        $sortedData = Ordenar-UnarmoredRigData -dados $unarmoredRigData -criterio $criterioOrdenacao
        if ($ordemAtual -eq "Crescente") { [array]::Reverse($sortedData) }
        
        Clear-Host
        Write-Host "=== Busca de colete nao blindado com filtro ==="; Write-Host
        
        Write-Host "Botoes: " -NoNewline
        Write-Host "F1" -ForegroundColor Cyan -NoNewline; Write-Host " - Mudar Criterio ($criterioOrdenacao) | " -NoNewline
        Write-Host "F2" -ForegroundColor Gray -NoNewline; Write-Host " - Mudar Ordem ($ordemAtual)"
        Write-Host "Botoes: " -NoNewline
        Write-Host "F3" -ForegroundColor Yellow -NoNewline; Write-Host " - Ver legenda | " -NoNewline
        Write-Host "F4" -ForegroundColor Red -NoNewline; Write-Host " - Voltar ao menu"; Write-Host
        if ($criterioOrdenacao -eq "Alfabetico") { Write-Host ("{0,-42}" -f "Nome do colete nao blindado") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-42}" -f "Nome do colete nao blindado") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Peso") { Write-Host ("{0,-6}" -f "Peso") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-6}" -f "Peso") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Espaco") { Write-Host ("{0,-6}" -f "Espaco") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-6}" -f "Espaco") -NoNewline }
        Write-Host " " -NoNewline
        Write-Host ("{0,-10}" -f "Desdobrada") -NoNewline
        Write-Host " " -NoNewline
        Write-Host ("{0,-7}" -f "Dobrada") -NoNewline
        Write-Host " " -NoNewline
        Write-Host ("{0,-23}" -f "Conj d. blocos") -NoNewline
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "+Espaco p/armaz -Espaco consumido") { Write-Host ("{0,-14}" -f "+Armaz -Espaco") -ForegroundColor Green } else { Write-Host ("{0,-14}" -f "+Armaz -Espaco") }
        Write-Host $divisor
        foreach ($item in $sortedData) {
            $efficiencyDisplay = if($item.Efficiency -eq -9999) { "/////" } else { "{0:+#;-#;0}" -f $item.Efficiency }
            
            Write-Host ("{0,-42}" -f $item.Nome) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Alfabetico") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-6}" -f $item.WeightRaw) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Peso") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-6}" -f $item.Storage) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Espaco") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-10}" -f $item.SizeUnfolded) -NoNewline
            Write-Host " " -NoNewline
            Write-Host ("{0,-7}" -f $item.SizeFolded) -NoNewline
            Write-Host " " -NoNewline
            Write-Host ("{0,-23}" -f $item.InternalLayout) -NoNewline
            Write-Host " " -NoNewline
            Write-Host ("{0,-14}" -f $efficiencyDisplay) -ForegroundColor $(if ($criterioOrdenacao -eq "+Espaco p/armaz -Espaco consumido") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
        }
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        switch ($key.VirtualKeyCode) {
            112 { # F1 - Mudar critério
                $novoCriterio = Show-Menu -Title "Selecione o criterio" -Options $criterios -FlickerFree
                (Get-Host).UI.RawUI.CursorSize = 0 
                if ($novoCriterio) { 
                    $criterioOrdenacao = $novoCriterio
                    if ($novoCriterio -eq 'Alfabetico') { $ordemAtual = 'Crescente' } else { $ordemAtual = 'Decrescente' } 
                }
            }
            113 { # F2 - Mudar ordem
                $ordemAtual = if ($ordemAtual -eq "Decrescente") { "Crescente" } else { "Decrescente" }
            }
            114 { # F3 - Ver legenda
                Show-UnarmoredRigLegend; continue
            }
            115 { # F4 - Voltar ao menu principal
                (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return
            }
        }
    } while ($true)
}

function Search-BackpacksWithFilters {
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize
    (Get-Host).UI.RawUI.CursorSize = 0
    $criterioOrdenacao = "Alfabetico"
    $ordemAtual = "Crescente"
    $criterios = @("Alfabetico", "Peso", "Espaco", "+Espaco p/armaz -Espaco consumido")
    
    do {
        $localHeader = "Nome da mochila                      Peso   Espaco Desdobrada  Dobrada Conj d. blocos       +Armaz -Espaco"
        $divisor =     "----------------------------------   -----  ------ ---------- ------- -------------------  --------------"
        $localFormat = "{0,-36} {1,-6} {2,-6} {3,-11} {4,-7} {5,-20} {6,-14}"
        $backpackData = @()
        $itemFiles = Get-ChildItem -Path (Join-Path $global:databasePath "Backpacks") -Filter "*.txt" -File
        foreach ($file in $itemFiles) {
            $content = Get-Content -Path $file.FullName
            while ($content.Count -lt 5) { $content += "/////" }
            $efficiency = -9999
            if ($content[2] -ne '/////' -and $content[2] -match '(\d+)x(\d+)') {
                $occupied = [int]$Matches[1] * [int]$Matches[2]
                $efficiency = [int]$content[1] - $occupied
            }
            $setCount = 0
            $internalLayoutString = $content[4]
            if ($internalLayoutString -ne '/////') {
                $sets = $internalLayoutString -split ',\s*'
                foreach ($set in $sets) {
                    if ($set -match '^\((\d+)\)') {
                        $setCount += [int]$Matches[1]
                    } else {
                        $setCount += 1
                    }
                }
            } else {
                $setCount = 999 
            }
            $backpackData += [PSCustomObject]@{
                Nome            = $file.BaseName
                Weight          = [double]$content[0]
                Storage         = [int]$content[1]
                WeightRaw       = $content[0]
                SizeUnfolded    = $content[2]
                SizeFolded      = $content[3]
                InternalLayout  = $content[4]
                Efficiency      = $efficiency
                SetCount        = $setCount 
            }
        }
        
        $sortedData = Ordenar-BackpackData -dados $backpackData -criterio $criterioOrdenacao
        if ($ordemAtual -eq "Crescente") { [array]::Reverse($sortedData) }
        
        Clear-Host
        Write-Host "=== Busca de mochila com filtro ==="; Write-Host
        
        Write-Host "Botoes: " -NoNewline
        Write-Host "F1" -ForegroundColor Cyan -NoNewline; Write-Host " - Mudar Criterio ($criterioOrdenacao) | " -NoNewline
        Write-Host "F2" -ForegroundColor Gray -NoNewline; Write-Host " - Mudar Ordem ($ordemAtual)"
        Write-Host "Botoes: " -NoNewline
        Write-Host "F3" -ForegroundColor Yellow -NoNewline; Write-Host " - Ver legenda | " -NoNewline
        Write-Host "F4" -ForegroundColor Red -NoNewline; Write-Host " - Voltar ao menu"; Write-Host
        if ($criterioOrdenacao -eq "Alfabetico") { Write-Host ("{0,-36}" -f "Nome da mochila") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-36}" -f "Nome da mochila") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Peso") { Write-Host ("{0,-6}" -f "Peso") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-6}" -f "Peso") -NoNewline }
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "Espaco") { Write-Host ("{0,-6}" -f "Espaco") -ForegroundColor Green -NoNewline } else { Write-Host ("{0,-6}" -f "Espaco") -NoNewline }
        Write-Host " " -NoNewline
        Write-Host ("{0,-10}" -f "Desdobrada") -NoNewline
        Write-Host " " -NoNewline
        Write-Host ("{0,-7}" -f "Dobrada") -NoNewline
        Write-Host " " -NoNewline
        Write-Host ("{0,-20}" -f "Conj d. blocos") -NoNewline
        Write-Host " " -NoNewline
        if ($criterioOrdenacao -eq "+Espaco p/armaz -Espaco consumido") { Write-Host ("{0,-14}" -f "+Armaz -Espaco") -ForegroundColor Green } else { Write-Host ("{0,-14}" -f "+Armaz -Espaco") }
        
        Write-Host $divisor
        foreach ($item in $sortedData) {
            $efficiencyDisplay = if($item.Efficiency -eq -9999) { "/////" } else { "{0:+#;-#;0}" -f $item.Efficiency }
            
            Write-Host ("{0,-36}" -f $item.Nome) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Alfabetico") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-6}" -f $item.WeightRaw) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Peso") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-6}" -f $item.Storage) -NoNewline -ForegroundColor $(if ($criterioOrdenacao -eq "Espaco") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
            Write-Host " " -NoNewline
            Write-Host ("{0,-10}" -f $item.SizeUnfolded) -NoNewline
            Write-Host " " -NoNewline
            Write-Host ("{0,-7}" -f $item.SizeFolded) -NoNewline
            Write-Host " " -NoNewline
            Write-Host ("{0,-20}" -f $item.InternalLayout) -NoNewline
            Write-Host " " -NoNewline
            Write-Host ("{0,-14}" -f $efficiencyDisplay) -ForegroundColor $(if ($criterioOrdenacao -eq "+Espaco p/armaz -Espaco consumido") { 'Green' } else { $Host.UI.RawUI.ForegroundColor })
        }
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        switch ($key.VirtualKeyCode) {
            112 { # F1 - Mudar critério
                $novoCriterio = Show-Menu -Title "Selecione o criterio" -Options $criterios -FlickerFree
                (Get-Host).UI.RawUI.CursorSize = 0
                if ($novoCriterio) { 
                    $criterioOrdenacao = $novoCriterio
                    if ($novoCriterio -eq 'Alfabetico') { $ordemAtual = 'Crescente' } else { $ordemAtual = 'Decrescente' } 
                }
            }
            113 { # F2 - Mudar ordem
                $ordemAtual = if ($ordemAtual -eq "Decrescente") { "Crescente" } else { "Decrescente" }
            }
            114 { # F3 - Ver legenda
                Show-BackpackLegend; continue
            }
            115 { # F4 - Voltar ao menu principal
                (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return
            }
        }
    } while ($true)
}

function Compare-Weapons {
    # Mapas para comparar e traduzir atributos não-numéricos
    $poderFogoMap = @{ "Low" = 1; "Mid-Low" = 2; "Medium" = 3; "Mid-High" = 4; "High" = 5 }
    $canoMap = @{ "FB D-" = 1; "Custom" = 2; "FB" = 3; "FB D+" = 4; "Default +" = 5; "R+" = 6; "D+" = 6; "D+ R+" = 7 }
    :mainCompareLoop while ($true) {
        $weaponCountSelection = Show-Menu -Title "Comparar Armas" -Options @("2", "3") -PromptText "Voce gostaria de comparar quantas armas?" -FlickerFree -EnableF1BackButton
        
        if (-not $weaponCountSelection -or $weaponCountSelection -eq $global:ACTION_BACK) { return }
        $weaponCount = [int]$weaponCountSelection
        $selectedWeapons = @()
        for ($i = 1; $i -le $weaponCount; $i++) {
            $weaponFile = $null
            while (-not $weaponFile) {
                $weaponFile = Select-WeaponForComparison -Title "Comparar Armas ($i/$weaponCount)" -Prompt "Selecione a $($i) ARMA"
                if ($weaponFile -eq $global:ACTION_BACK) { continue mainCompareLoop }
            }
            $selectedWeapons += $weaponFile
        }
        # Carregar dados das armas em um array
        $weaponDataArray = @()
        foreach ($weapon in $selectedWeapons) {
            $content = Get-Content -Path $weapon.FullName
            
            if ($content.Count -ge 13) {
                $estabilidadeArmaValue = 0
                if ($content.Count -ge 14) {
                    $estabilidadeArmaValue = [int]$content[13]
                }
                $weaponDataArray += [PSCustomObject]@{
                    Nome             = $weapon.BaseName
                    Classe           = $content[0]
                    Calibre          = $content[1]
                    VerticalRecoil   = [int]$content[2]
                    HorizontalRecoil = [int]$content[3]
                    Ergonomia        = [int]$content[4]
                    EstabilidadeArma = $estabilidadeArmaValue
                    Precisao         = [int]$content[5]
                    Estabilidade     = [int]$content[6]
                    Alcance          = [int]$content[7]
                    Velocidade       = [int]$content[8]
                    ModoDisparo      = $content[9]
                    Cadencia         = [int]$content[10]
                    PoderFogo        = $content[11]
                    Cano             = $content[12]
                }
            }
        }
        
        (Get-Host).UI.RawUI.CursorSize = 0
        Clear-Host
        Write-Host "=== Tela de Comparacao ==="; Write-Host
        
        $columnWidth = -28
        $headerLine = "{0,-30}" -f "Atributo"
        $dividerLine = "{0,-30}" -f "------------------------------"
        
        foreach ($weaponData in $weaponDataArray) {
            $headerLine += " {0,$columnWidth}" -f $weaponData.Nome
            $dividerLine += " {0,$columnWidth}" -f ("-" * 28)
        }
        Write-Host $headerLine
        Write-Host $dividerLine
        
        $attributes = @(
            @{ Label = "Nome da Arma"; Prop = "Nome" },
            @{ Label = "Calibre"; Prop = "Calibre" },
            @{ Label = "Controle de recuo vertical"; Prop = "VerticalRecoil" },
            @{ Label = "Controle de recuo horizontal"; Prop = "HorizontalRecoil" },
            @{ Label = "Ergonomia"; Prop = "Ergonomia" },
            @{ Label = "Estabilidade de arma"; Prop = "EstabilidadeArma" },
            @{ Label = "Precisao"; Prop = "Precisao" },
            @{ Label = "Estabilidade sem mirar"; Prop = "Estabilidade" },
            @{ Label = "Distancia Efetiva"; Prop = "Alcance" },
            @{ Label = "Velocidade de Saida"; Prop = "Velocidade" },
            @{ Label = "Modo de disparo"; Prop = "ModoDisparo" },
            @{ Label = "Cadencia"; Prop = "Cadencia" },
            @{ Label = "Poder de fogo"; Prop = "PoderFogo" },
            @{ Label = "Melhoria de cano"; Prop = "Cano" }
        )
        foreach ($attr in $attributes) {
            $values = $weaponDataArray | ForEach-Object { $_.($attr.Prop) }
            $comparableValues = $values
            
            $isNumeric = $false
            if ($attr.Prop -notin "Nome", "Calibre", "ModoDisparo") {
                $isNumeric = $true
                if ($attr.Prop -eq "PoderFogo") { $comparableValues = $values | ForEach-Object { $poderFogoMap[$_] } }
                if ($attr.Prop -eq "Cano") { $comparableValues = $values | ForEach-Object { $canoMap[$_] } }
            }
            $maxVal = $null; $minVal = $null
            if ($isNumeric) {
                $numericValues = $comparableValues | Where-Object { $_ -ne $null }
                if ($numericValues) {
                    $sorted = $numericValues | Sort-Object
                    $minVal = $sorted[0]
                    $maxVal = $sorted[-1]
                }
            }
            Write-Host ("{0,-30}" -f $attr.Label) -NoNewline
            
            for ($i = 0; $i -lt $weaponDataArray.Count; $i++) {
                $val = $values[$i]
                $comparableVal = $comparableValues[$i]
                $color = $Host.UI.RawUI.ForegroundColor
                if ($isNumeric -and $maxVal -ne $minVal) {
                    if ($comparableVal -eq $maxVal) { $color = "Green" }
                    if ($comparableVal -eq $minVal) { $color = "Red" }
                }
                if ($attr.Prop -in @("PoderFogo", "Cano", "ModoDisparo")) {
                    $tempVal = switch ($val) { "Low"{"Baixo"};"Mid-Low"{"Medio-Baixo"};"Medium"{"Medio"};"Mid-High"{"Medio-Alto"};"High"{"Alto"};"Default +"{ "Padrao +" };"FB"{"CF"};"R+"{"A+"};"FB D+"{"CF D+"};"FB D-"{"CF D-"};"D+ R+"{"D+ A+"};default{$val} }
                    $val = $tempVal.Replace('Bolt-Action', 'A.Ferrolho').Replace('Pump-Action', 'A.Bombeamento').Replace('Full', 'Auto')
                }
                
                Write-Host (" {0,$columnWidth}" -f $val) -ForegroundColor $color -NoNewline
            }
            Write-Host
        }
        Write-Host
        $uniqueCalibers = $weaponDataArray.Calibre | Sort-Object -Unique
        foreach ($caliber in $uniqueCalibers) {
            $weaponNames = ($weaponDataArray | Where-Object { $_.Calibre -eq $caliber }).Nome -join ' / '
            Write-Host ("--- MUNICOES PARA {0} ({1}) ---" -f $weaponNames, $caliber)
            Show-AmmoTableForCaliber -Caliber $caliber
            Write-Host
        }
        Write-Host "Pressione " -NoNewline
        Write-Host "F1" -ForegroundColor Blue -NoNewline
        Write-Host " para comparar outras armas ou " -NoNewline
        Write-Host "F2" -ForegroundColor Red -NoNewline
        Write-Host " para voltar ao menu..."
        
        do {
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
        } while ($key -ne 112 -and $key -ne 113)
        
        if ($key -eq 113) { return }
    }
}

function Select-WeaponForComparison {
    param (
        [string]$Title,
        [string]$Prompt
    )
    
    # 1. Traduz as classes para português para exibir no menu
    $translatedClasses = $weaponClasses | ForEach-Object { $global:WeaponClassToPortugueseMap[$_] } | Sort-Object
    $selectedClassDisplay = Show-Menu -Title $Title -Options $translatedClasses -FlickerFree -EnableF1BackButton -F1HelpOnTop
    
    if (-not $selectedClassDisplay -or $selectedClassDisplay -eq $global:ACTION_BACK) { return $global:ACTION_BACK }
    # 2. Traduz a seleção de volta para o inglês para usar na lógica interna
    $selectedClass = $global:PortugueseToWeaponClassMap[$selectedClassDisplay]
    # 3. Usa o nome em inglês para filtrar os arquivos
    $weaponFiles = Get-ChildItem -Path $weaponsPath -Filter "*.txt" -File | Where-Object { (Get-Content $_.FullName -TotalCount 1) -eq $selectedClass }
    if (-not $weaponFiles) {
        Write-Host "Nenhuma arma encontrada nesta classe." -ForegroundColor Yellow; Start-Sleep -Seconds 2; return $null
    }
    
    $weaponOptions = $weaponFiles | Select-Object -ExpandProperty BaseName | Sort-Object
    $selectedWeaponName = Show-Menu -Title "$Prompt ($selectedClassDisplay)" -Options $weaponOptions -FlickerFree -EnableF1BackButton -F1HelpOnTop
    
    if (-not $selectedWeaponName -or $selectedWeaponName -eq $global:ACTION_BACK) { return $null }
    return Get-Item -Path (Join-Path $weaponsPath "$selectedWeaponName.txt")
}

function Show-AmmoTableForCaliber {
    param ([string]$Caliber)
    $ammoFiles = Get-ChildItem -Path (Join-Path $AmmoPath $Caliber) -Filter "*.txt" -File -ErrorAction SilentlyContinue
    if (-not $ammoFiles) {
        Write-Host "Nenhuma municao encontrada para este calibre." -ForegroundColor Yellow
        return
    }
    # Cabeçalho idêntico ao da busca de munição
    Write-Host "Nome da Municao     Lv Pen Dano Base      Dano blindag Vel(m/s) Prec CRV CRH Chance Ferir  Calibre"
    Write-Host "------------------- -- --- -------------- ------------ -------- ---- --- --- ------------  ---------"
    # Carrega e exibe cada munição
    $ammoData = @()
    foreach ($file in $ammoFiles) {
        $content = Get-Content -Path $file.FullName
        if ($content.Count -lt 9) { continue }
        
        $ammoData += [PSCustomObject]@{
            Nome = $file.BaseName; Lv = [int]$content[0]; Penetracao = $content[1]; DanoBase = $content[2]; DanoArmadura = $content[3];
            Velocidade = $content[4]; Precisao = $content[5]; RecuoVert = $content[6]; RecuoHoriz = $content[7]; ChanceFerir = $content[8]
        }
    }
    
    # Ordena os dados antes de exibir
    foreach ($item in ($ammoData | Sort-Object Lv, Penetracao -Descending)) {
        $chanceFerirDisplay = switch ($item.ChanceFerir) { "Low"{"Baixo"}; "Medium"{"Medio"}; "High"{"Alto"}; default{$item.ChanceFerir} }
        $params = @($item.Nome, $item.Lv, $item.Penetracao, $item.DanoBase, $item.DanoArmadura, $item.Velocidade, $item.Precisao, $item.RecuoVert, $item.RecuoHoriz, $chanceFerirDisplay, $Caliber)
        Write-Host ("{0,-19} {1,-2} {2,-3} {3,-14} {4,-12} {5,-8} {6,-4} {7,-3} {8,-3} {9,-12}  {10,-9}" -f $params)
    }
}

function List-MaskCompatibility {
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize; (Get-Host).UI.RawUI.CursorSize = 0
    $compatibilityPath = Join-Path -Path $global:databasePath -ChildPath "Maskcompatibility"
    $masksPath = Join-Path -Path $global:databasePath -ChildPath "Masks"
    $helmetsPath = Join-Path -Path $global:databasePath -ChildPath "Helmets"

    do {
        Clear-Host
        Write-Host "Pressione " -NoNewline; Write-Host "F1" -ForegroundColor Red -NoNewline; Write-Host " para voltar ao menu principal"; Write-Host
        
        $allCompFiles = Get-ChildItem -Path $compatibilityPath -Filter "*.txt" -File
        if (-not $allCompFiles) {
             Write-Host "`nNenhum registro de compatibilidade encontrado." -ForegroundColor Yellow
        }
        
        $allCompData = @()
        foreach ($file in $allCompFiles) {
            $content = Get-Content -Path $file.FullName
            if ($content.Count -gt 0) {
                $maskName = $content[0]
                $armorClass = "N/A"
                $armorClassNum = 0
                
                $maskDataFile = Join-Path -Path $masksPath -ChildPath "$maskName.txt"
                if (Test-Path $maskDataFile) {
                    try {
                        $maskContent = Get-Content -Path $maskDataFile
                        if ($maskContent.Count -ge 3) {
                            $armorClass = $maskContent[2]
                            if ($armorClass -match '\d') {
                                $armorClassNum = [int]$armorClass
                            }
                        }
                    } catch {}
                }
                
                $rawHelmets = $content | Select-Object -Skip 1
                $formattedHelmets = @()
                
                foreach ($hName in $rawHelmets) {
                    $hClass = "?"
                    $hPath = Join-Path -Path $helmetsPath -ChildPath "$hName.txt"
                    if (Test-Path $hPath) {
                        try {
                            $hData = Get-Content -Path $hPath -ErrorAction SilentlyContinue
                            if ($hData.Count -ge 3) {
                                $hClass = $hData[2]
                            }
                        } catch {}
                    }
                    $formattedHelmets += "$hName (Cl. $hClass)"
                }
                
                $allCompData += [PSCustomObject]@{
                    MaskName = $maskName
                    ArmorClass = $armorClass
                    ArmorClassNum = $armorClassNum
                    Helmets = $formattedHelmets
                    HelmetCount = $formattedHelmets.Count
                }
            }
        }
        
        $allCompData = $allCompData | Sort-Object -Property @{ Expression = "ArmorClassNum"; Descending = $true }, @{ Expression = "HelmetCount"; Ascending = $true }
        
        $i = 0
        while ($i -lt $allCompData.Count) {
            $item1 = $allCompData[$i]
            $item2 = if (($i + 1) -lt $allCompData.Count) { $allCompData[$i + 1] } else { $null }
            $colWidth = 55 
            
            $maskName1 = "$($item1.MaskName):"
            $classDisplay1 = " (Cl. $($item1.ArmorClass))"
            Write-Host $maskName1 -ForegroundColor Blue -NoNewline
            Write-Host $classDisplay1 -ForegroundColor DarkYellow -NoNewline
            
            $padding1 = [Math]::Max(0, $colWidth - ($maskName1.Length + $classDisplay1.Length))
            Write-Host (' ' * $padding1) -NoNewline
            
            if ($item2) {
                $maskName2 = "$($item2.MaskName):"
                $classDisplay2 = " (Cl. $($item2.ArmorClass))"
                Write-Host $maskName2 -ForegroundColor Blue -NoNewline
                Write-Host $classDisplay2 -ForegroundColor DarkYellow -NoNewline
            }
            Write-Host
            
            $maxHelmets = [math]::Max($item1.Helmets.Count, $(if ($item2) { $item2.Helmets.Count } else { 0 }))
            for ($j = 0; $j -lt $maxHelmets; $j++) {
                $helmet1 = if ($j -lt $item1.Helmets.Count) { "  " + $item1.Helmets[$j] } else { "" }
                $helmet2 = if ($item2 -and $j -lt $item2.Helmets.Count) { "  " + $item2.Helmets[$j] } else { "" }
                
                $line = ("{0,-$colWidth}{1,-$colWidth}" -f $helmet1, $helmet2)
                Write-Host $line
            }
            
            Write-Host; Write-Host
            $i += 2
        }
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
    } while ($key -ne 112) 
    (Get-Host).UI.RawUI.CursorSize = $originalCursorSize
}

function View-Database {
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize
    (Get-Host).UI.RawUI.CursorSize = 0
    :categoryLoop while ($true) {
        $menuOptions = ($global:ItemCategoryConfig.Values.EditViewMenuName | Sort-Object)
        
        $selectedDisplayName = Show-Menu -Title "Selecione a categoria para visualizar" -Options $menuOptions -FlickerFree -EnableF1BackButton
        
        if ($selectedDisplayName -eq $global:ACTION_BACK) { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return }
        if (-not $selectedDisplayName) { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return }
        $selectedCategoryKey = ($global:ItemCategoryConfig.GetEnumerator() | Where-Object { $_.Value.EditViewMenuName -eq $selectedDisplayName }).Name
        $config = $global:ItemCategoryConfig[$selectedCategoryKey]
        
        if ($selectedCategoryKey -eq "Ammo") {
            :caliberLoop while ($true) {
                $calibers = Get-ChildItem -Path $AmmoPath -Directory | Select-Object -ExpandProperty Name | Sort-Object
                $caliberMenuOptions = @("Voltar para categorias") + $calibers
                $selectedCaliber = Show-Menu -Title "Selecione o calibre" -Options $caliberMenuOptions -FlickerFree
                if (-not $selectedCaliber -or $selectedCaliber -eq "Voltar para categorias") { continue categoryLoop }
                
                $ammoFiles = Get-ChildItem -Path (Join-Path $AmmoPath $selectedCaliber) -Filter "*.txt" -File
                if (-not $ammoFiles) { Write-Host "Nenhuma municao encontrada." -ForegroundColor Yellow; Start-Sleep -Seconds 2; continue caliberLoop }
                :ammoTableLoop while ($true) {
                    (Get-Host).UI.RawUI.CursorSize = 0
                    Clear-Host; Write-Host "=== Dados de Ammo > $selectedCaliber ==="; Write-Host
                    $header = "Nome da Municao     Lv Penetracao Dano Base      Dano blindag  Vel (m/s) Precisao CtlRecVert  CtlRecHoriz  Chance Ferir"
                    Write-Host $header
                    Write-Host ($header -replace '\S', '-')
                    
                    foreach ($file in $ammoFiles) {
                        $content = Get-Content -Path $file.FullName
                        if ($content.Count -lt 9) { Write-Host ("AVISO: O arquivo de municao '$($file.Name)' esta incompleto.") -ForegroundColor Yellow; continue }
                        $params = @($file.BaseName) + $content[0..8]
                        Write-Host ("{0,-19} {1,-2} {2,-10} {3,-14} {4,-13} {5,-9} {6,-8} {7,-11} {8,-12} {9,-12}" -f $params)
                    }
                    
                    Write-Host; Write-Host "Pressione F1 para voltar (Selecionar calibre)" -ForegroundColor Yellow; Write-Host "Pressione F2 para voltar ao menu principal" -ForegroundColor Red
                    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
                    switch ($key) { 112 { continue caliberLoop } 113 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return } }
                }
            }
        } elseif ($selectedCategoryKey -eq "Weapons") {
            :classLoop while ($true) {
                # Traduz as classes para o menu de visualização
                $translatedClasses = $weaponClasses | ForEach-Object { $global:WeaponClassToPortugueseMap[$_] } | Sort-Object
                $classMenuOptions = @("Voltar para categorias") + $translatedClasses
                $selectedWeaponClassDisplay = Show-Menu -Title "Selecione a classe da arma" -Options $classMenuOptions -FlickerFree
                
                if (-not $selectedWeaponClassDisplay -or $selectedWeaponClassDisplay -eq "Voltar para categorias") { continue categoryLoop }
                
                # Traduz de volta para o inglês para a lógica de filtro
                $selectedWeaponClass = $global:PortugueseToWeaponClassMap[$selectedWeaponClassDisplay]
                $itemPath = Join-Path -Path $global:databasePath -ChildPath $config.PathName
                $weaponFiles = Get-ChildItem -Path $itemPath -Filter "*.txt" -File | Where-Object { (Get-Content -Path $_.FullName -TotalCount 1) -eq $selectedWeaponClass }
                if (-not $weaponFiles) { Write-Host "Nenhuma arma encontrada nesta classe." -ForegroundColor Yellow; Start-Sleep -Seconds 2; continue classLoop }
                
                :weaponsTableLoop while ($true) {
                    (Get-Host).UI.RawUI.CursorSize = 0
                    Clear-Host
                    # Exibe o nome da classe em português
                    Write-Host "=== Dados de Weapons > $selectedWeaponClassDisplay ==="; Write-Host
                    Write-Host $config.ViewHeader
                    $separator = [regex]::Replace($config.ViewHeader, '\S', '-')
                    Write-Host $separator
                    
                    foreach ($file in $weaponFiles) {
                        $content = Get-Content -Path $file.FullName
                        if ($content.Count -lt 13) { Write-Host ("AVISO: O arquivo de arma '$($file.Name)' esta incompleto.") -ForegroundColor Yellow; continue }
                        $params = @($file.BaseName) + $content[1..12]
                        Write-Host ($config.ViewFormat -f $params)
                    }
                    
                    Write-Host; Write-Host "Pressione F1 para voltar (Selecionar classe)" -ForegroundColor Yellow; Write-Host "Pressione F2 para Ver legenda"; Write-Host "Pressione F3 para voltar ao menu principal" -ForegroundColor Red
                    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
                    switch ($key) { 112 { continue classLoop } 113 { Show-WeaponLegend } 114 { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return } }
                }
            }
        } else {
            $itemPath = Join-Path -Path $global:databasePath -ChildPath $config.PathName
            :displayLoop while($true) {
                (Get-Host).UI.RawUI.CursorSize = 0
                Clear-Host
                Write-Host "=== Dados de $($config.EditViewMenuName) ==="; Write-Host
                $items = Get-ChildItem -Path $itemPath -Filter "*.txt" -File
                if (-not $items) { Write-Host "Nenhum item encontrado nesta categoria." -ForegroundColor Yellow; Start-Sleep -Seconds 2; continue categoryLoop }
                Write-Host $config.ViewHeader
                $separator = [regex]::Replace($config.ViewHeader, '\S', '-')
                Write-Host $separator
                switch ($selectedCategoryKey) {
                    "Painkillers" { foreach ($item in $items) { $content = Get-Content -Path $item.FullName; if ($content.Count -ne 4) { Write-Host ("AVISO: '$($item.Name)' esta incompleto.") -ForegroundColor Yellow; continue }; Write-Host ($config.ViewFormat -f $item.BaseName, $content[0], $content[1], $content[2], $content[3]) } }
                    "Bandages" { foreach ($item in $items) { $content = Get-Content -Path $item.FullName; if ($content.Count -ne 3) { Write-Host ("AVISO: '$($item.Name)' esta incompleto.") -ForegroundColor Yellow; continue }; Write-Host ($config.ViewFormat -f $item.BaseName, $content[0], $content[1], $content[2]) } }
                    "Surgicalkit" { foreach ($item in $items) { $content = Get-Content -Path $item.FullName; if ($content.Count -ne 6) { Write-Host ("AVISO: '$($item.Name)' esta incompleto.") -ForegroundColor Yellow; continue }; Write-Host ($config.ViewFormat -f $item.BaseName, $content[0], $content[1], $content[2], $content[3], $content[4], $content[5]) } }
                    "Nebulizers" { foreach ($item in $items) { $content = Get-Content -Path $item.FullName; if ($content.Count -ne 3) { Write-Host ("AVISO: '$($item.Name)' esta incompleto.") -ForegroundColor Yellow; continue }; Write-Host ($config.ViewFormat -f $item.BaseName, $content[0], $content[1], $content[2]) } }
                    "Medicalkit" { foreach ($item in $items) { $content = Get-Content -Path $item.FullName; if ($content.Count -ne 6) { Write-Host ("AVISO: '$($item.Name)' esta incompleto.") -ForegroundColor Yellow; continue }; Write-Host ($config.ViewFormat -f $item.BaseName, $content[0], $content[1], $content[2], $content[3], $content[4], $content[5]) } }
                    "Stimulants" { foreach ($item in $items) { $content = Get-Content -Path $item.FullName; if ($content.Count -ne 5) { Write-Host ("AVISO: '$($item.Name)' esta incompleto.") -ForegroundColor Yellow; continue }; Write-Host ($config.ViewFormat -f $item.BaseName, $content[0], $content[1], $content[2], $content[3], $content[4]) } }
                    "Throwables" { foreach ($item in $items) { $content = Get-Content -Path $item.FullName; if ($content.Count -ne 7) { Write-Host ("AVISO: '$($item.Name)' esta incompleto.") -ForegroundColor Yellow; continue }; Write-Host ($config.ViewFormat -f $item.BaseName, $content[0], $content[1], $content[2], $content[3], $content[4], $content[5], $content[6]) } }
                    "Beverages" { foreach ($item in $items) { $content = Get-Content -Path $item.FullName; if ($content.Count -ne 5) { Write-Host ("AVISO: '$($item.Name)' esta incompleto.") -ForegroundColor Yellow; continue }; Write-Host ($config.ViewFormat -f $item.BaseName, $content[0], $content[1], $content[2], $content[3], $content[4]) } }
                    "Food" { foreach ($item in $items) { $content = Get-Content -Path $item.FullName; if ($content.Count -ne 5) { Write-Host ("AVISO: '$($item.Name)' esta incompleto.") -ForegroundColor Yellow; continue }; Write-Host ($config.ViewFormat -f $item.BaseName, $content[0], $content[1], $content[2], $content[3], $content[4]) } }
                    "Helmets" { foreach ($item in $items) { $content = Get-Content -Path $item.FullName; if ($content.Count -ne 13) { Write-Host ("AVISO: '$($item.Name)' esta incompleto.") -ForegroundColor Yellow; continue }; Write-Host ($config.ViewFormat -f $item.BaseName, $content[0], $content[1], $content[2], $content[3], $content[4], $content[5], $content[6], $content[7], $content[8], $content[9], $content[10], $content[11], $content[12]) } }
                    "Bodyarmors" { foreach ($item in $items) { $content = Get-Content -Path $item.FullName; if ($content.Count -ne 7) { Write-Host ("AVISO: '$($item.Name)' esta incompleto.") -ForegroundColor Yellow; continue }; Write-Host ($config.ViewFormat -f $item.BaseName, $content[0], $content[2], $content[1], $content[3], $content[4], $content[5], $content[6]) } }
                    "Armoredrigs" { foreach ($item in $items) { 
                        $content = Get-Content -Path $item.FullName
                        while ($content.Count -lt 9) { $content += "/////" }
                        Write-Host ($config.ViewFormat -f $item.BaseName, $content[0], $content[2], $content[1], $content[3], $content[4], $content[5], $content[6], $content[7], $content[8]) 
                        } 
                    }
                    "Masks" { foreach ($item in $items) { $content = Get-Content -Path $item.FullName; if ($content.Count -ne 5) { Write-Host ("AVISO: '$($item.Name)' esta incompleto.") -ForegroundColor Yellow; continue }; Write-Host ($config.ViewFormat -f $item.BaseName, $content[0], $content[1], $content[2], $content[3], $content[4]) } }
                    "Gasmasks" { foreach ($item in $items) { $content = Get-Content -Path $item.FullName; if ($content.Count -ne 4) { Write-Host ("AVISO: '$($item.Name)' esta incompleto.") -ForegroundColor Yellow; continue }; Write-Host ($config.ViewFormat -f $item.BaseName, $content[0], $content[1], $content[2], $content[3]) } }
                    "Headsets" { foreach ($item in $items) { $content = Get-Content -Path $item.FullName; if ($content.Count -ne 3) { Write-Host ("AVISO: '$($item.Name)' esta incompleto.") -ForegroundColor Yellow; continue }; Write-Host ($config.ViewFormat -f $item.BaseName, $content[0], $content[1], $content[2]) } }
                    "Unarmoredrigs" { foreach ($item in $items) {
                        $content = Get-Content -Path $item.FullName
                        while ($content.Count -lt 5) { $content += "/////" }
                        Write-Host ($config.ViewFormat -f $item.BaseName, $content[0], $content[1], $content[2], $content[3], $content[4])
                        }
                    }
                    "Backpacks" { foreach ($item in $items) {
                        $content = Get-Content -Path $item.FullName
                        while ($content.Count -lt 5) { $content += "/////" }
                        Write-Host ($config.ViewFormat -f $item.BaseName, $content[0], $content[1], $content[2], $content[3], $content[4])
                        }
                    }
                }
                Write-Host; Write-Host "Pressione F1 para voltar (Selecionar categoria)" -ForegroundColor Yellow; Write-Host "Pressione F2 para voltar ao menu principal" -ForegroundColor Red
                $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
                if ($key -eq 112) { continue categoryLoop }
                if ($key -eq 113) { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return }
            }
        }
    }
}

function Add-NewAmmo {
    param([PSCustomObject]$ExistingData = $null)
    if (-not $ExistingData) {
        # MODO ADICIONAR: Este laço externo permite voltar para a seleção de calibre a qualquer momento.
        :mainAddLoop while ($true) {
            $ammoName, $penetrationLevel, $penetration, $baseDamage, $armorDamage, $velocity, $accuracy, $verticalRecoil, $horizontalRecoil, $woundChance = $null
            # 1. Seleção de Calibre
            $calibers = Get-ChildItem -Path $AmmoPath -Directory | Select-Object -ExpandProperty Name
            if ($calibers.Count -eq 0) { Write-Host "Nenhum calibre encontrado." -ForegroundColor Yellow; Start-Sleep -Seconds 3; return }
            
            # A opção "Voltar" no menu permite sair da função de adicionar munição.
            $menuOptions = @("Voltar") + ($calibers | Sort-Object)
            $selectedCaliber = Show-Menu -Title "Selecione o calibre" -Options $menuOptions
            if (-not $selectedCaliber -or $selectedCaliber -eq "Voltar") { return $global:ACTION_BACK }
            # 2. Laço Interno para Inserir os Dados da Munição
            $step = 2
            $maxSteps = 11
            $shouldGoBackToCaliber = $false
            while ($step -le $maxSteps) {
                $result = $null
                switch ($step) {
                    2  { $result = Read-InputWithPaste -Prompt "Qual e o nome da municao:" -Title "Adicionar Nova Municao ($selectedCaliber)" -EnableStandardNav -MaxLength 19 }
                    3  { $result = Get-InputWithFilter -Prompt "Nivel de penetracao (0-7):" -Title "Nivel de Penetracao" -Mode 'penetration' -EnableStandardNav }
                    4  { $result = Get-InputWithFilter -Prompt "Valor de penetracao:" -Title "Valor de Penetracao" -Mode 'numeric' -EnableStandardNav -MaxLength 2 }
                    5  { $result = Get-DanoBase -EnableStandardNav }
                    6  { $result = Get-InputWithFilter -Prompt "Dano de blindagem:" -Title "Dano de Blindagem" -Mode 'armor' -EnableStandardNav -MaxLength 4 }
                    7  { $result = Get-InputWithFilter -Prompt "Velocidade (m/s):" -Title "Velocidade" -Mode 'numeric' -EnableStandardNav -MaxLength 4 }
                    8  { $result = Get-InputWithFilter -Prompt "Precisao (Formato: +NUMEROS):" -Title "Precisao" -Mode 'precision' -EnableStandardNav -MaxLength 2 }
                    9  { $result = Get-InputWithFilter -Prompt "Recuo Vertical (Formato: +NUMEROS, -NUMEROS ou 0):" -Title "Recuo Vertical" -Mode 'recoil' -EnableStandardNav -MaxLength 3 }
                    10 { $result = Get-InputWithFilter -Prompt "Recuo Horizontal (Formato: +NUMEROS, -NUMEROS ou 0):" -Title "Recuo Horizontal" -Mode 'recoil' -EnableStandardNav -MaxLength 3 }
                    11 { $woundChanceOptions = @("Nao sei ou o jogo nao informa", "Baixo", "Medio", "Alto"); $result = Show-Menu -Title "Chance de ferir?" -Options $woundChanceOptions -EnableBackButton -EnableMainMenuButton }
                }
                
                if ($result -eq $global:ACTION_MAIN_MENU) { return }
                # Lógica de Navegação "Voltar"
                if ($result -eq $global:ACTION_BACK) {
                    if ($step -eq 2) { # Se estiver na primeira pergunta (nome), volta para a seleção de calibre.
                        $shouldGoBackToCaliber = $true
                        break # Interrompe o laço das perguntas.
                    }
                    $step-- # Volta para a pergunta anterior.
                    continue
                }
                
                if (-not $result) { continue }
                
                switch ($step) { 
                    2 { $ammoName = $result }; 3 { $penetrationLevel = $result }; 4 { $penetration = $result }; 5 { $baseDamage = $result }; 
                    6 { $armorDamage = $result }; 7 { $velocity = $result }; 8 { $accuracy = $result }; 9 { $verticalRecoil = $result }; 
                    10 { $horizontalRecoil = $result }; 11 { $woundChance = $result } 
                }
                $step++
            }
            if ($shouldGoBackToCaliber) { continue mainAddLoop } # Reinicia o laço principal para escolher o calibre novamente.
            # 3. Laço de Confirmação
            :confirmationLoop while ($true) {
                $woundChanceValue = switch ($woundChance) { "Nao sei ou o jogo nao informa" { "//////" }; "Baixo" { "Low" }; "Medio" { "Medium" }; "Alto" { "High" }; default { $woundChance } }
                $currentAmmoData = [PSCustomObject]@{
                    Nome = $ammoName; NiveldePenetracao = $penetrationLevel; Penetracao = $penetration; DanoBase = $baseDamage; Danodeblindagem = $armorDamage
                    Velocidade = $velocity; Precisao = $accuracy; RecuoVertical = $verticalRecoil; RecuoHorizontal = $horizontalRecoil; ChanceFerir = $woundChanceValue
                }
                $userAction = Show-AmmoConfirmation -AmmoData $currentAmmoData -Caliber $selectedCaliber
                
                if ($userAction -eq "CONFIRM") {
                    $caliberPath = Join-Path -Path $AmmoPath -ChildPath $selectedCaliber; $ammoFilePath = Join-Path -Path $caliberPath -ChildPath "$ammoName.txt"
                    @($penetrationLevel, $penetration, $baseDamage, $armorDamage, $velocity, $accuracy, $verticalRecoil, $horizontalRecoil, $woundChanceValue) | Out-File -FilePath $ammoFilePath -Encoding UTF8
                    Write-Host "Municao '$ammoName' salva com sucesso ao calibre '$selectedCaliber'!" -ForegroundColor Green; Start-Sleep -Seconds 2
                    return # Sai da função após salvar
                }
                
                if ($userAction -eq "CANCEL") { Write-Host "`nOperacao cancelada." -ForegroundColor Yellow; Start-Sleep -Seconds 1; continue mainAddLoop }
                
                if ($userAction -is [int]) {
                    $newValue = $null
                    switch ($userAction) {
                        0 { $newValue = Read-InputWithPaste -Prompt "Novo nome da municao:" -Title "Editar Nome" -EnableStandardNav -MaxLength 19 }
                        1 { $newValue = Get-InputWithFilter -Prompt "Novo nivel de penetracao (0-7):" -Title "Editar Nivel de Penetracao" -Mode 'penetration' -EnableStandardNav }
                        2 { $newValue = Get-InputWithFilter -Prompt "Novo valor de penetracao:" -Title "Editar Penetracao" -Mode 'numeric' -EnableStandardNav -MaxLength 2 }
                        3 { $newValue = Get-DanoBase -EnableStandardNav }
                        4 { $newValue = Get-InputWithFilter -Prompt "Novo dano de blindagem:" -Title "Editar Dano de Blindagem" -Mode 'armor' -EnableStandardNav -MaxLength 4 }
                        5 { $newValue = Get-InputWithFilter -Prompt "Nova velocidade (m/s):" -Title "Editar Velocidade" -Mode 'numeric' -EnableStandardNav -MaxLength 4 }
                        6 { $newValue = Get-InputWithFilter -Prompt "Nova precisao (Formato: +NUMEROS):" -Title "Editar Precisao" -Mode 'precision' -EnableStandardNav -MaxLength 2 }
                        7 { $newValue = Get-InputWithFilter -Prompt "Novo recuo vertical (Formato: +NUMEROS, -NUMEROS ou 0):" -Title "Editar Recuo Vertical" -Mode 'recoil' -EnableStandardNav -MaxLength 3 }
                        8 { $newValue = Get-InputWithFilter -Prompt "Novo recuo horizontal (Formato: +NUMEROS, -NUMEROS ou 0):" -Title "Editar Recuo Horizontal" -Mode 'recoil' -EnableStandardNav -MaxLength 3 }
                        9 { $woundChanceOptions = @("Nao sei ou o jogo nao informa", "Baixo", "Medio", "Alto"); $newValue = Show-Menu -Title "Chance de ferir?" -Options $woundChanceOptions -EnableBackButton -EnableMainMenuButton }
                    }
                    if ($newValue -and $newValue -ne $global:ACTION_BACK -and $newValue -ne $global:ACTION_MAIN_MENU) {
                        switch ($userAction) { 
                            0 { $ammoName = $newValue }; 1 { $penetrationLevel = $newValue }; 2 { $penetration = $newValue }; 3 { $baseDamage = $newValue }; 
                            4 { $armorDamage = $newValue }; 5 { $velocity = $newValue }; 6 { $accuracy = $newValue }; 7 { $verticalRecoil = $newValue }; 
                            8 { $horizontalRecoil = $newValue }; 9 { $woundChance = $newValue } 
                        }
                    }
                }
            }
        }
    } else {
        # MODO EDITAR (permanece igual, pois já funciona bem)
        $selectedCaliber = $ExistingData.Calibre
        $ammoName = $ExistingData.Nome; $penetrationLevel = $ExistingData.NiveldePenetracao; $penetration = $ExistingData.Penetracao
        $baseDamage = $ExistingData.DanoBase; $armorDamage = $ExistingData.Danodeblindagem; $velocity = $ExistingData.Velocidade
        $accuracy = $ExistingData.Precisao; $verticalRecoil = $ExistingData.RecuoVertical; $horizontalRecoil = $ExistingData.RecuoHorizontal
        $woundChance = $ExistingData.ChanceFerir
        
        :editConfirmationLoop while ($true) {
            $woundChanceValue = switch ($woundChance) { "Nao sei ou o jogo nao informa" { "//////" }; "Baixo" { "Low" }; "Medio" { "Medium" }; "Alto" { "High" }; default { $woundChance } }
            $currentAmmoData = [PSCustomObject]@{
                Nome = $ammoName; NiveldePenetracao = $penetrationLevel; Penetracao = $penetration; DanoBase = $baseDamage; Danodeblindagem = $armorDamage
                Velocidade = $velocity; Precisao = $accuracy; RecuoVertical = $verticalRecoil; RecuoHorizontal = $horizontalRecoil; ChanceFerir = $woundChanceValue
            }
            $userAction = Show-AmmoConfirmation -AmmoData $currentAmmoData -Caliber $selectedCaliber
            
            if ($userAction -eq "CONFIRM") {
                $caliberPath = Join-Path -Path $AmmoPath -ChildPath $selectedCaliber; $ammoFilePath = Join-Path -Path $caliberPath -ChildPath "$ammoName.txt"
                @($penetrationLevel, $penetration, $baseDamage, $armorDamage, $velocity, $accuracy, $verticalRecoil, $horizontalRecoil, $woundChanceValue) | Out-File -FilePath $ammoFilePath -Encoding UTF8
                if ($ExistingData -and $ExistingData.Nome -ne $currentAmmoData.Nome) { Remove-Item -Path (Join-Path $caliberPath "$($ExistingData.Nome).txt") -Force }
                Write-Host "Municao '$ammoName' salva com sucesso ao calibre '$selectedCaliber'!" -ForegroundColor Green; Start-Sleep -Seconds 2
                return
            }
            if ($userAction -eq "CANCEL") { Write-Host "`nOperacao cancelada." -ForegroundColor Yellow; Start-Sleep -Seconds 2; return }
            
            if ($userAction -is [int]) {
                $newValue = $null
                switch ($userAction) {
                    0 { $newValue = Read-InputWithPaste -Prompt "Novo nome da municao:" -Title "Editar Nome" -EnableStandardNav -MaxLength 19 }
                    1 { $newValue = Get-InputWithFilter -Prompt "Novo nivel de penetracao (0-7):" -Title "Editar Nivel de Penetracao" -Mode 'penetration' -EnableStandardNav }
                    2 { $newValue = Get-InputWithFilter -Prompt "Novo valor de penetracao:" -Title "Editar Penetracao" -Mode 'numeric' -EnableStandardNav -MaxLength 2 }
                    3 { $newValue = Get-DanoBase -EnableStandardNav }
                    4 { $newValue = Get-InputWithFilter -Prompt "Novo dano de blindagem:" -Title "Editar Dano de Blindagem" -Mode 'armor' -EnableStandardNav -MaxLength 4 }
                    5 { $newValue = Get-InputWithFilter -Prompt "Nova velocidade (m/s):" -Title "Editar Velocidade" -Mode 'numeric' -EnableStandardNav -MaxLength 4 }
                    6 { $newValue = Get-InputWithFilter -Prompt "Nova precisao (Formato: +NUMEROS):" -Title "Editar Precisao" -Mode 'precision' -EnableStandardNav -MaxLength 2 }
                    7 { $newValue = Get-InputWithFilter -Prompt "Novo recuo vertical (Formato: +NUMEROS, -NUMEROS ou 0):" -Title "Editar Recuo Vertical" -Mode 'recoil' -EnableStandardNav -MaxLength 3 }
                    8 { $newValue = Get-InputWithFilter -Prompt "Novo recuo horizontal (Formato: +NUMEROS, -NUMEROS ou 0):" -Title "Editar Recuo Horizontal" -Mode 'recoil' -EnableStandardNav -MaxLength 3 }
                    9 { $woundChanceOptions = @("Nao sei ou o jogo nao informa", "Baixo", "Medio", "Alto"); $newValue = Show-Menu -Title "Chance de ferir?" -Options $woundChanceOptions -EnableBackButton -EnableMainMenuButton }
                }
                if ($newValue -and $newValue -ne $global:ACTION_BACK -and $newValue -ne $global:ACTION_MAIN_MENU) {
                    switch ($userAction) { 
                        0 { $ammoName = $newValue }; 1 { $penetrationLevel = $newValue }; 2 { $penetration = $newValue }; 3 { $baseDamage = $newValue }; 
                        4 { $armorDamage = $newValue }; 5 { $velocity = $newValue }; 6 { $accuracy = $newValue }; 7 { $verticalRecoil = $newValue }; 
                        8 { $horizontalRecoil = $newValue }; 9 { $woundChance = $newValue } 
                    }
                }
            }
        }
    }
}

function Add-NewWeapon {
    param([PSCustomObject]$ExistingData = $null)
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize; (Get-Host).UI.RawUI.CursorSize = 0
    $step = 1; $maxSteps = 16; $lastEditedIndex = 0
    if (-not $ExistingData) {
        $weaponName, $selectedClass, $selectedCaliber, $verticalRecoil, $horizontalRecoil, $ergonomia, $estabilidadeArma, $precisao, $estabilidade, $alcance, $velocidade, $cadencia, $firePower, $barrelOption, $barrelValue = $null
        $fireModes = @()
        while ($step -le $maxSteps) {
            $result = $null
            switch ($step) {
                1  { $result = Read-InputWithPaste -Prompt "Qual e o nome da arma?" -Title "Adicionar Nova Arma" -EnableStandardNav -MaxLength 17 }
                2  { $result = Show-Menu -Title "Selecione a classe da arma" -Options $weaponClasses -EnableBackButton -EnableMainMenuButton }
                3  { $calibers = Get-ChildItem -Path $AmmoPath -Directory | Select-Object -ExpandProperty Name | Sort-Object; $result = Show-Menu -Title "Selecione o calibre da arma" -Options $calibers -EnableBackButton -EnableMainMenuButton }
                4  { $result = Get-InputWithFilter -Prompt "Qual e o controle de recuo vertical?" -Title "Dados Tecnicos" -Mode 'numeric' -EnableStandardNav -MaxLength 2 }
                5  { $result = Get-InputWithFilter -Prompt "Qual e o controle de recuo horizontal?" -Title "Dados Tecnicos" -Mode 'numeric' -EnableStandardNav -MaxLength 2 }
                6  { $result = Get-InputWithFilter -Prompt "Qual e a ergonomia?" -Title "Dados Tecnicos" -Mode 'numeric' -EnableStandardNav -MaxLength 2 }
                7  { $result = Get-InputWithFilter -Prompt "Qual e a estabilidade de arma?" -Title "Dados Tecnicos" -Mode 'numeric' -EnableStandardNav -MaxLength 2 }
                8  { $result = Get-InputWithFilter -Prompt "Qual e a precisao?" -Title "Dados Tecnicos" -Mode 'numeric' -EnableStandardNav -MaxLength 2 }
                9  { $result = Get-InputWithFilter -Prompt "Qual e a estabilidade sem mirar?" -Title "Dados Tecnicos" -Mode 'numeric' -EnableStandardNav -MaxLength 2 }
                10 { $result = Get-InputWithFilter -Prompt "Qual e a distancia efetiva?" -Title "Dados Tecnicos" -Mode 'numeric' -EnableStandardNav -MaxLength 3 }
                11 { $result = Get-InputWithFilter -Prompt "Qual e a velocidade do bocal?" -Title "Dados Tecnicos" -Mode 'numeric' -EnableStandardNav -MaxLength 4 }
                12 { $result = Get-InputWithFilter -Prompt "Qual e a cadencia?" -Title "Dados Tecnicos" -Mode 'numeric' -EnableStandardNav -MaxLength 4 }
                13 {
                    $tempFireModes = @()
                    $modeCountResult = Show-Menu -Title "Quantos modos de disparo?" -Options @("1", "2", "3") -EnableBackButton -EnableMainMenuButton
                    if ($modeCountResult -eq $global:ACTION_BACK -or $modeCountResult -eq $global:ACTION_MAIN_MENU -or -not $modeCountResult) { 
                        $result = $modeCountResult 
                    } else {
                        $fireModeCount = [int]$modeCountResult
                        if ($fireModeCount -eq 1) {
                            $availableModesDisplay = @("Semi", "Auto", "2-RB", "3-RB", "Acao de Bombeamento", "Acao de Ferrolho")
                            $availableModesData = @("Semi", "Full", "2-RB", "3-RB", "Pump-Action", "Bolt-Action")
                        } else {
                            $availableModesDisplay = @("Semi", "Auto", "2-RB", "3-RB")
                            $availableModesData = @("Semi", "Full", "2-RB", "3-RB")
                        }
                        $innerLoopCancelled = $false
                        for ($i = 1; $i -le $fireModeCount; $i++) {
                            $modeResultDisplay = Show-Menu -Title "Selecione o modo $i" -Options $availableModesDisplay -EnableBackButton -EnableMainMenuButton
                            if ($modeResultDisplay -eq $global:ACTION_BACK -or $modeResultDisplay -eq $global:ACTION_MAIN_MENU -or -not $modeResultDisplay) { 
                                $result = $modeResultDisplay; $innerLoopCancelled = $true; break 
                            }
                            $selectedIndex = [array]::IndexOf($availableModesDisplay, $modeResultDisplay)
                            $modeResultData = $availableModesData[$selectedIndex]
                            $tempFireModes += $modeResultData
                            $availableModesDisplay = $availableModesDisplay | Where-Object { $_ -ne $modeResultDisplay }
                            $availableModesData = $availableModesData | Where-Object { $_ -ne $modeResultData }
                        }
                        if (-not $innerLoopCancelled) { $result = $tempFireModes }
                    }
                }
                14 {
                    $displayOptions = @("Baixo", "Inferior", "Medio", "Superior", "Alto")
                    $dataValues = @("Low", "Mid-Low", "Medium", "Mid-High", "High")
                    $selectionDisplay = Show-Menu -Title "Qual e o poder de fogo?" -Options $displayOptions -EnableBackButton -EnableMainMenuButton
                    if ($selectionDisplay -and $selectionDisplay -ne $global:ACTION_BACK -and $selectionDisplay -ne $global:ACTION_MAIN_MENU) {
                        $selectedIndex = [array]::IndexOf($displayOptions, $selectionDisplay)
                        $result = $dataValues[$selectedIndex]
                    } else {
                        $result = $selectionDisplay
                    }
                }
                15 { $result = Show-Menu -Title "O cano pode ser mudado?" -Options @("Sim", "Nao") -EnableBackButton -EnableMainMenuButton }
                16 { 
                    if ($barrelOption -eq "Nao") { $result = Show-Menu -Title "O cano fixo altera dano?" -Options @("Dano reduzido", "Dano inalterado", "Dano amplificado") -EnableBackButton -EnableMainMenuButton } 
                    else { $options = @("Alcance", "Dano", "Alcance + Dano", "Customizacao apenas", "Padrao e o melhor, mudar pode reduzir performance da arma"); $result = Show-Menu -Title "O que o cano pode melhorar?" -Options $options -EnableBackButton -EnableMainMenuButton }
                }
            }
            if ($result -eq $global:ACTION_MAIN_MENU) { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $global:ACTION_MAIN_MENU }
            
            if ($result -eq $global:ACTION_BACK) {
                if ($step -gt 1) { 
                    $step-- 
                } else { 
                    (Get-Host).UI.RawUI.CursorSize = $originalCursorSize
                    return 
                }
                continue
            }
            if (-not $result) { continue }
            switch ($step) {
                1  { $weaponName = $result }; 2  { $selectedClass = $result }; 3  { $selectedCaliber = $result }; 4  { $verticalRecoil = $result }; 5  { $horizontalRecoil = $result }; 6  { $ergonomia = $result }; 7  { $estabilidadeArma = $result }; 8  { $precisao = $result }; 9  { $estabilidade = $result }; 10 { $alcance = $result }; 11 { $velocidade = $result }; 12 { $cadencia = $result }; 13 { $fireModes = $result }; 14 { $firePower = $result }; 15 { $barrelOption = $result }
                16 { if ($barrelOption -eq "Nao") { $barrelValue = switch ($result) { "Dano reduzido" { "FB D-" }; "Dano amplificado" { "FB D+" }; default { "FB" } } } else { $barrelValue = switch ($result) { "Alcance" { "R+" }; "Dano" { "D+" }; "Alcance + Dano" { "D+ R+" }; "Padrao e o melhor, mudar pode reduzir performance da arma" { "Default +" }; default { "Custom" } } } }
            }
            $step++
        }
    } else {
        $weaponName = $ExistingData.Nome; $selectedClass = $ExistingData.Classe; $selectedCaliber = $ExistingData.Calibre
        $verticalRecoil = $ExistingData.VerticalRecoil; $horizontalRecoil = $ExistingData.HorizontalRecoil
        $ergonomia = $ExistingData.Ergonomia; $precisao = $ExistingData.Precisao; $estabilidade = $ExistingData.Estabilidade
        $alcance = $ExistingData.Alcance; $velocidade = $ExistingData.Velocidade; $cadencia = $ExistingData.Cadencia
        $fireModes = $ExistingData.ModoDisparo -split ', '; $firePower = $ExistingData.PoderFogo; $barrelValue = $ExistingData.Cano
        $estabilidadeArma = $ExistingData.EstabilidadeArma
    }
    :confirmationLoop while ($true) {
        $weaponData = [PSCustomObject]@{ Nome = $weaponName; Classe = $selectedClass; Calibre = $selectedCaliber; VerticalRecoil = $verticalRecoil; HorizontalRecoil = $horizontalRecoil; Ergonomia = $ergonomia; EstabilidadeArma = $estabilidadeArma; Precisao = $precisao; Estabilidade = $estabilidade; Alcance = $alcance; Velocidade = $velocidade; ModoDisparo = ($fireModes -join ", "); Cadencia = $cadencia; PoderFogo = $firePower; Cano = $barrelValue }
        $userAction = Show-WeaponConfirmation -WeaponData $weaponData -InitialSelectedIndex $lastEditedIndex
        if ($userAction -eq "CANCEL") { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return }; if ($userAction -eq "CONFIRM") {
            $weaponFile = Join-Path -Path $weaponsPath -ChildPath "$($weaponData.Nome).txt"
            @( $weaponData.Classe, $weaponData.Calibre, $weaponData.VerticalRecoil, $weaponData.HorizontalRecoil, $weaponData.Ergonomia, $weaponData.Precisao, $weaponData.Estabilidade, $weaponData.Alcance, $weaponData.Velocidade, $weaponData.ModoDisparo, $weaponData.Cadencia, $weaponData.PoderFogo, $weaponData.Cano, $weaponData.EstabilidadeArma ) | Out-File -FilePath $weaponFile -Encoding UTF8
            
            if ($ExistingData -and $ExistingData.Nome -ne $weaponData.Nome) {
                Remove-Item -Path (Join-Path $weaponsPath "$($ExistingData.Nome).txt") -Force
            }
            Write-Host "Arma '$($weaponData.Nome)' salva com sucesso!" -ForegroundColor Green; Start-Sleep -Seconds 2; (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return
        }
        if ($userAction -is [int]) {
            $lastEditedIndex = $userAction; $newValue = $null
            switch ($userAction) {
                0 { $newValue = Read-InputWithPaste -Prompt "Novo nome da arma:" -Title "Editar Nome" -EnableStandardNav -MaxLength 17 }
                1 { $newValue = Show-Menu -Title "Selecione a nova classe" -Options $weaponClasses -EnableBackButton -EnableMainMenuButton }
                2 { $calibers = Get-ChildItem -Path $AmmoPath -Directory | Select-Object -ExpandProperty Name | Sort-Object; $newValue = Show-Menu -Title "Selecione o novo calibre" -Options $calibers -EnableBackButton -EnableMainMenuButton }
                3 { $newValue = Get-InputWithFilter -Prompt "Novo recuo vertical:" -Title "Editar Recuo Vertical" -Mode 'numeric' -EnableStandardNav -MaxLength 2 }
                4 { $newValue = Get-InputWithFilter -Prompt "Novo recuo horizontal:" -Title "Editar Recuo Horizontal" -Mode 'numeric' -EnableStandardNav -MaxLength 2 }
                5 { $newValue = Get-InputWithFilter -Prompt "Nova ergonomia:" -Title "Editar Ergonomia" -Mode 'numeric' -EnableStandardNav -MaxLength 2 }
                6 { $newValue = Get-InputWithFilter -Prompt "Nova estabilidade de arma:" -Title "Editar Estabilidade de Arma" -Mode 'numeric' -EnableStandardNav -MaxLength 2 }
                7 { $newValue = Get-InputWithFilter -Prompt "Nova precisao:" -Title "Editar Precisao" -Mode 'numeric' -EnableStandardNav -MaxLength 2 }
                8 { $newValue = Get-InputWithFilter -Prompt "Nova estabilidade sem mirar:" -Title "Editar Estabilidade" -Mode 'numeric' -EnableStandardNav -MaxLength 2 }
                9 { $newValue = Get-InputWithFilter -Prompt "Nova distancia efetiva:" -Title "Editar Alcance" -Mode 'numeric' -EnableStandardNav -MaxLength 3 }
                10 { $newValue = Get-InputWithFilter -Prompt "Nova velocidade do bocal:" -Title "Editar Velocidade" -Mode 'numeric' -EnableStandardNav -MaxLength 4 }
                11 {
                    $modeCount = Show-Menu -Title "Quantos modos de disparo?" -Options @("1", "2", "3") -EnableBackButton -EnableMainMenuButton
                    if ($modeCount -and $modeCount -ne $global:ACTION_BACK -and $modeCount -ne $global:ACTION_MAIN_MENU) {
                        $newModes = @()
                        if ($modeCount -eq "1") {
                            $availableModesDisplay = @("Semi", "Auto", "2-RB", "3-RB", "Acao de Bombeamento", "Acao de Ferrolho")
                            $availableModesData = @("Semi", "Full", "2-RB", "3-RB", "Pump-Action", "Bolt-Action")
                        } else {
                            $availableModesDisplay = @("Semi", "Auto", "2-RB", "3-RB")
                            $availableModesData = @("Semi", "Full", "2-RB", "3-RB")
                        }
                        $cancelled = $false
                        for ($i = 1; $i -le [int]$modeCount; $i++) {
                            $modeDisplay = Show-Menu -Title "Selecione o modo $i" -Options $availableModesDisplay -EnableBackButton -EnableMainMenuButton
                            if (-not $modeDisplay -or $modeDisplay -eq $global:ACTION_BACK -or $modeDisplay -eq $global:ACTION_MAIN_MENU) { $cancelled = $true; break }
                            $idx = [array]::IndexOf($availableModesDisplay, $modeDisplay)
                            $modeData = $availableModesData[$idx]
                            $newModes += $modeData
                            $availableModesDisplay = $availableModesDisplay | Where-Object { $_ -ne $modeDisplay }
                            $availableModesData = $availableModesData | Where-Object { $_ -ne $modeData }
                        }
                        if (-not $cancelled) { $newValue = $newModes }
                    }
                }
                12 { $newValue = Get-InputWithFilter -Prompt "Nova cadencia:" -Title "Editar Cadencia" -Mode 'numeric' -EnableStandardNav -MaxLength 4 }
                13 {
                    $displayOptions = @("Baixo", "Inferior", "Medio", "Superior", "Alto")
                    $dataValues = @("Low", "Mid-Low", "Medium", "Mid-High", "High")
                    $selectionDisplay = Show-Menu -Title "Selecione o poder de fogo" -Options $displayOptions -EnableBackButton -EnableMainMenuButton
                    if ($selectionDisplay -and $selectionDisplay -ne $global:ACTION_BACK -and $selectionDisplay -ne $global:ACTION_MAIN_MENU) {
                        $idx = [array]::IndexOf($displayOptions, $selectionDisplay)
                        $newValue = $dataValues[$idx]
                    }
                }
                14 {
                    $barrelOptionResult = Show-Menu -Title "O cano pode ser mudado?" -Options @("Sim", "Nao") -EnableBackButton -EnableMainMenuButton
                    if ($barrelOptionResult -and $barrelOptionResult -ne $global:ACTION_BACK -and $barrelOptionResult -ne $global:ACTION_MAIN_MENU) {
                        $barrelOption = $barrelOptionResult
                        if ($barrelOptionResult -eq "Nao") {
                            $damageOption = Show-Menu -Title "O cano fixo altera dano?" -Options @("Dano reduzido", "Dano inalterado", "Dano amplificado") -EnableBackButton -EnableMainMenuButton
                            if ($damageOption -and $damageOption -ne $global:ACTION_BACK -and $damageOption -ne $global:ACTION_MAIN_MENU) { $newValue = switch ($damageOption) { "Dano reduzido" { "FB D-" }; "Dano amplificado" { "FB D+" }; default { "FB" } } }
                        } else {
                            $options = @("Alcance", "Dano", "Alcance + Dano", "Customizacao apenas", "Padrao e o melhor, mudar pode reduzir performance da arma")
                            $improvement = Show-Menu -Title "O que o cano pode melhorar?" -Options $options -EnableBackButton -EnableMainMenuButton
                            if ($improvement -and $improvement -ne $global:ACTION_BACK -and $improvement -ne $global:ACTION_MAIN_MENU) { $newValue = switch ($improvement) { "Alcance" { "R+" }; "Dano" { "D+" }; "Alcance + Dano" { "D+ R+" }; "Padrao e o melhor, mudar pode reduzir performance da arma" { "Default +" }; default { "Custom" } } }
                        }
                    }
                }
            }
            if ($newValue -and $newValue -ne $global:ACTION_BACK -and $newValue -ne $global:ACTION_MAIN_MENU) {
                switch ($userAction) { 0 { $weaponName = $newValue }; 1 { $selectedClass = $newValue }; 2 { $selectedCaliber = $newValue }; 3 { $verticalRecoil = $newValue }; 4 { $horizontalRecoil = $newValue }; 5 { $ergonomia = $newValue }; 6 { $estabilidadeArma = $newValue }; 7 { $precisao = $newValue }; 8 { $estabilidade = $newValue }; 9 { $alcance = $newValue }; 10 { $velocidade = $newValue }; 11 { $fireModes = $newValue }; 12 { $cadencia = $newValue }; 13 { $firePower = $newValue }; 14 { $barrelValue = $newValue } }
            }
        }
    }
}

function Add-NewThrowable {
    param([PSCustomObject]$ExistingData = $null)
    if (-not $ExistingData) {
        $throwableName=$null; $delay1=$null; $delay2=$null; $range=$null; $armorDamage="/////"; $penetration="/////"; $fragments="/////"; $fragmentType="/////"; $effectTime="/////"
        $isLethal = $null; $step = 1
        :throwableInputLoop while ($true) {
            $result = $null
            switch ($step) {
                1 { $result = Show-Menu -Title "O arremessavel e letal?" -Options @("Sim", "Nao") -EnableBackButton -EnableMainMenuButton }
                2 { $result = Read-InputWithPaste -Prompt "Qual e o nome do arremessavel?" -Title "Adicionar Arremessavel" -EnableStandardNav -MaxLength 23 }
                3 { $result = Get-InputWithFilter -Prompt "Qual e o primeiro delay de explosao? (ex: 1.2)" -Title "Delay 1/2" -Mode 'decimal_fixed' -MaxLength 4 -EnableStandardNav }
                4 { $result = Get-InputWithFilter -Prompt "Qual e o segundo delay de explosao? (ex: 1.3)" -Title "Delay 2/2" -Mode 'decimal_fixed' -MaxLength 4 -EnableStandardNav }
                5 { $rawResult=Show-Menu -Title "Qual e o alcance efetivo?" -Options @("Padrao","Longo","Muito longo","Nao e informado") -EnableBackButton -EnableMainMenuButton; if($rawResult-and $rawResult-ne $global:ACTION_BACK -and $rawResult-ne $global:ACTION_MAIN_MENU){$result=switch($rawResult){"Padrao"{"Standard"};"Longo"{"Large"};"Muito longo"{"Very Large"};"Nao e informado"{"/////"};default{$rawResult}}}else{$result=$rawResult} }
                6 { if ($isLethal -ne "Sim") { $step++; continue throwableInputLoop }; $rawResult=Show-Menu -Title "Dano de blindagem?" -Options @("Padrao","Superior","Nao e informado") -EnableBackButton -EnableMainMenuButton; if($rawResult-and $rawResult-ne $global:ACTION_BACK -and $rawResult-ne $global:ACTION_MAIN_MENU){$result=switch($rawResult){"Padrao"{"Standard"};"Superior"{"Mid-High"};default{"/////"}}}else{$result=$rawResult} }
                7 { if ($isLethal -ne "Sim") { $step++; continue throwableInputLoop }; $rawResult=Show-Menu -Title "Efeito de penetracao?" -Options @("Padrao","Superior","Nao e informado") -EnableBackButton -EnableMainMenuButton; if($rawResult-and $rawResult-ne $global:ACTION_BACK -and $rawResult-ne $global:ACTION_MAIN_MENU){$result=switch($rawResult){"Padrao"{"Standard"};"Superior"{"Mid-High"};default{"/////"}}}else{$result=$rawResult} }
                8 { if ($isLethal -ne "Sim") { $step++; continue throwableInputLoop }; $rawResult=Show-Menu -Title "Quantidade de fragmentos?" -Options @("Pequeno","Grande","Nao e informado") -EnableBackButton -EnableMainMenuButton; if($rawResult-and $rawResult-ne $global:ACTION_BACK -and $rawResult-ne $global:ACTION_MAIN_MENU){$result=switch($rawResult){"Pequeno"{"Small"};"Grande"{"Large"};default{"/////"}}}else{$result=$rawResult} }
                9 { if ($isLethal -ne "Sim") { $step++; continue throwableInputLoop }; $rawResult=Show-Menu -Title "Tipo de fragmentos?" -Options @("Peca de aco","Peca de ferro","Nao e informado") -EnableBackButton -EnableMainMenuButton; if($rawResult-and $rawResult-ne $global:ACTION_BACK -and $rawResult-ne $global:ACTION_MAIN_MENU){$result=switch($rawResult){"Peca de aco"{"Steel Piece"};"Peca de ferro"{"Iron Piece"};default{"/////"}}}else{$result=$rawResult} }
                10{ $result = Get-InputWithFilter -Prompt "Qual e o tempo de efeito? (ex: 12.3)" -Title "Tempo de Efeito" -Mode 'decimal_fixed' -MaxLength 4 -EnableStandardNav }
                default { break throwableInputLoop }
            }
            if ($result -eq $global:ACTION_MAIN_MENU) { return $global:ACTION_MAIN_MENU }
            if ($result -eq $global:ACTION_BACK) { if ($step-gt 1){if($isLethal-eq"Nao"-and $step-eq 10){$step=5}elseif($isLethal-eq"Sim"-and $step-eq 10){$step=9}elseif($isLethal-eq"Nao"-and $step-eq 6){$step=5}else{$step--}}else{return $global:ACTION_BACK}; continue throwableInputLoop}
            if (-not $result) { continue throwableInputLoop }
            switch ($step) { 1 {$isLethal=$result}; 2 {$throwableName=$result}; 3 {$delay1=$result}; 4 {$delay2=$result}; 5 {$range=$result}; 6 {$armorDamage=$result}; 7 {$penetration=$result}; 8 {$fragments=$result}; 9 {$fragmentType=$result}; 10{$effectTime=$result} }
            $step++
        }
    } else {
        $throwableName = $ExistingData.Nome; $delayParts = $ExistingData.ExplosionDelay -split ' - '; $delay1 = $delayParts[0]; $delay2 = $delayParts[1]
        $range = $ExistingData.Range; $armorDamage = $ExistingData.ArmorDamage; $penetration = $ExistingData.Penetration
        $fragments = $ExistingData.Fragments; $fragmentType = $ExistingData.FragmentType; $effectTime = $ExistingData.EffectTime
    }
    $lastEditedIndex = 0
    $dataObject = [PSCustomObject]@{Nome=$throwableName; ExplosionDelay=("$delay1 - $delay2"); Range=$range; ArmorDamage=$armorDamage; Penetration=$penetration; Fragments=$fragments; FragmentType=$fragmentType; EffectTime=$effectTime}
    
    :confirmationLoop while($true) {
        $userAction = Show-ThrowableConfirmation -ItemData $dataObject -InitialSelectedIndex $lastEditedIndex
        if ($userAction -eq "CANCEL") { return }
        if ($userAction -eq "CONFIRM") {
            $path = Join-Path -Path $global:databasePath -ChildPath "Throwables"
            $filePath = Join-Path -Path $path -ChildPath "$($dataObject.Nome).txt"
            @($dataObject.ExplosionDelay, $dataObject.Range, $dataObject.ArmorDamage, $dataObject.Penetration, $dataObject.Fragments, $dataObject.FragmentType, $dataObject.EffectTime) | Out-File -FilePath $filePath -Encoding UTF8
            if ($ExistingData -and $ExistingData.Nome -ne $dataObject.Nome) {
                Remove-Item -Path (Join-Path $path "$($ExistingData.Nome).txt") -Force
            }
            Write-Host "Arremessavel '$($dataObject.Nome)' salvo com sucesso!" -ForegroundColor Green; Start-Sleep -Seconds 2
            return
        }
        if ($userAction -is [int]) {
            $lastEditedIndex = $userAction
            $newValue = $null
            $propToUpdate = $dataObject.psobject.Properties.Name[$userAction]
            switch ($propToUpdate) {
                "Nome" { $newValue = Read-InputWithPaste -Prompt "Novo nome:" -Title "Editar Nome" -EnableStandardNav -MaxLength 23 }
                "ExplosionDelay" {
                    $d1 = Get-InputWithFilter -Prompt "Primeiro delay (ex:1.2):" -Title "Delay 1/2" -Mode 'decimal_fixed' -MaxLength 4 -EnableStandardNav
                    if ($d1 -and $d1 -ne $global:ACTION_BACK -and $d1 -ne $global:ACTION_MAIN_MENU) {
                        $d2 = Get-InputWithFilter -Prompt "Segundo delay (ex:1.3):" -Title "Delay 2/2" -Mode 'decimal_fixed' -MaxLength 4 -EnableStandardNav
                        if ($d2 -and $d2 -ne $global:ACTION_BACK -and $d2 -ne $global:ACTION_MAIN_MENU) { $newValue = "$d1 - $d2" }
                        else { $newValue = $d2 }
                    } else { $newValue = $d1 }
                }
                "Range" { $raw=Show-Menu -Title "Alcance?" -Options @("Padrao","Longo","Muito longo","Nao e informado") -EnableBackButton -EnableMainMenuButton;if($raw-and $raw-ne $global:ACTION_BACK -and $raw-ne $global:ACTION_MAIN_MENU){$newValue=switch($raw){"Padrao"{"Standard"};"Longo"{"Large"};"Muito longo"{"Very Large"};"Nao e informado"{"/////"}}}else{$newValue=$raw}}
                "ArmorDamage" { $raw=Show-Menu -Title "Dano Blind.?" -Options @("Padrao","Superior","Nao e informado") -EnableBackButton -EnableMainMenuButton;if($raw-and $raw-ne $global:ACTION_BACK -and $raw-ne $global:ACTION_MAIN_MENU){$newValue=switch($raw){"Padrao"{"Standard"};"Superior"{"Mid-High"};default{"/////"}}}else{$newValue=$raw}}
                "Penetration" { $raw=Show-Menu -Title "Penetracao?" -Options @("Padrao","Superior","Nao e informado") -EnableBackButton -EnableMainMenuButton;if($raw-and $raw-ne $global:ACTION_BACK -and $raw-ne $global:ACTION_MAIN_MENU){$newValue=switch($raw){"Padrao"{"Standard"};"Superior"{"Mid-High"};default{"/////"}}}else{$newValue=$raw}}
                "Fragments" { $raw=Show-Menu -Title "Fragmentos?" -Options @("Pequeno","Grande","Nao e informado") -EnableBackButton -EnableMainMenuButton;if($raw-and $raw-ne $global:ACTION_BACK -and $raw-ne $global:ACTION_MAIN_MENU){$newValue=switch($raw){"Pequeno"{"Small"};"Grande"{"Large"};default{"/////"}}}else{$newValue=$raw}}
                "FragmentType" { $raw=Show-Menu -Title "Tipo Frags.?" -Options @("Peca de aco","Peca de ferro","Nao e informado") -EnableBackButton -EnableMainMenuButton;if($raw-and $raw-ne $global:ACTION_BACK -and $raw-ne $global:ACTION_MAIN_MENU){$newValue=switch($raw){"Peca de aco"{"Steel Piece"};"Peca de ferro"{"Iron Piece"};default{"/////"}}}else{$newValue=$raw}}
                "EffectTime" { $newValue = Get-InputWithFilter -Prompt "Novo tempo de efeito (ex: 12.3):" -Title "Efeito" -Mode 'decimal_fixed' -MaxLength 4 -EnableStandardNav }
            }
            if ($newValue -and $newValue -ne $global:ACTION_BACK -and $newValue -ne $global:ACTION_MAIN_MENU) {
                $dataObject.$propToUpdate = $newValue
            }
        }
    }
}

function Add-NewHelmet {
    param([PSCustomObject]$ExistingData = $null)
    if (-not $ExistingData) {
        $helmetName, $weight, $durability, $armorClass, $material, $soundBlocking, $movementSpeed, $ergonomics, $protectedArea, $ricochetChance, $headset, $soundPickup, $noiseReduction, $accessory = $null
        $step = 1
        while ($step -le 12) {
            $result = $null
            switch ($step) {
                1 { $result = Read-InputWithPaste -Prompt "Qual e o nome do capacete?" -Title "Adicionar Capacete" -EnableStandardNav -MaxLength 32 }
                2 { $result = Get-InputWithFilter -Prompt "Qual e o peso do capacete? (Ex: 1.20)" -Title "Peso" -Mode 'decimal_1_2' -MaxLength 4 -EnableStandardNav }
                3 { $result = Get-InputWithFilter -Prompt "Qual e a Durabilidade do capacete? (Ex: 10.0)" -Title "Durabilidade" -Mode 'decimal_2_1_fixed' -MaxLength 4 -EnableStandardNav }
                4 { $result = Get-InputWithFilter -Prompt "Qual e a Classe de Blindagem? (1-6)" -Title "Classe de Blindagem" -Mode 'numeric_1_6' -MaxLength 1 -EnableStandardNav }
                5 { $raw = Show-Menu -Title "Qual e o Material do capacete?" -Options @("Aramida","Polietileno","Aco endurecido","Composto","Aluminio","Titanio") -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$result=switch($raw){"Aramida"{"Aramid"};"Polietileno"{"Polyethylene"};"Aco endurecido"{"Hardened Steel"};"Composto"{"Composite"};"Aluminio"{"Aluminum"};"Titanio"{"Titanium"}}}else{$result=$raw}}
                6 { $raw = Show-Menu -Title "Tem Bloqueio Sonoro no capacete?" -Options @("Nao tem bloqueio sonoro","Ligeiro","Normal","Grave") -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$result=switch($raw){"Nao tem bloqueio sonoro"{"/////"};"Ligeiro"{"Low"};"Normal"{"Moderate"};"Grave"{"Severe"}}}else{$result=$raw}}
                7 { $choice = Show-Menu -Title "O capacete altera a velocidade de Movimento?" -Options @("Sim", "Nao") -EnableBackButton -EnableMainMenuButton; if($choice -eq "Sim"){$result=Get-InputWithFilter -Prompt "Digite o valor (Ex: -10):" -Title "Velocidade de Movimento" -Mode 'percentage_negative' -MaxLength 3 -EnableStandardNav}elseif($choice -eq "Nao"){$result="/////"}else{$result=$choice}}
                8 { $choice = Show-Menu -Title "O capacete afeta ergonomia?" -Options @("Sim", "Nao") -EnableBackButton -EnableMainMenuButton; if($choice -eq "Sim"){$result=Get-InputWithFilter -Prompt "Digite o valor (Ex: -10):" -Title "Ergonomia" -Mode 'numeric_negative_no_leading_zero' -MaxLength 3 -EnableStandardNav}elseif($choice -eq "Nao"){$result="/////"}else{$result=$choice}}
                9 { $raw = Show-Menu -Title "O capacete protegem quais partes da cabeca?" -Options @("Cabeca","Cabeca, Ouvidos","Cabeca, Ouvidos, Rosto") -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$result=switch($raw){"Cabeca"{"Head"};"Cabeca, Ouvidos"{"Head, Ears"};"Cabeca, Ouvidos, Rosto"{"Head, Ears, Face"}}}else{$result=$raw}}
                10{ $raw = Show-Menu -Title "Qual e a chance do capacete ricochetear?" -Options @("Baixo","Medio","Alto") -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$result=switch($raw){"Baixo"{"Low"};"Medio"{"Medium"};"Alto"{"High"}}}else{$result=$raw}}
                11{ 
                    if ($soundBlocking -ne "/////") { $headset = "Nao"; $soundPickup = "/////"; $noiseReduction = "/////"; $step = 12; continue }
                    $result = Show-Menu -Title "O capacete tem fone de ouvido embutido?" -Options @("Sim", "Nao") -EnableBackButton -EnableMainMenuButton
                }
                12{ 
                    $raw = Show-Menu -Title "Acessorio Funcional" -Options @("Nao aceita mascaras ou equipamentos taticos","Aceita Equipamento Tatico","Aceita Mascara","Aceita Mascara e Equipamento Tatico") -EnableBackButton -EnableMainMenuButton
                    if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$result=switch($raw){"Nao aceita mascaras ou equipamentos taticos"{"/////"};"Aceita Equipamento Tatico"{"TE"};"Aceita Mascara"{"Mask"};"Aceita Mascara e Equipamento Tatico"{"Mask, TE"}}}else{$result=$raw}
                }
            }
            if ($result -eq $global:ACTION_MAIN_MENU) { return $global:ACTION_MAIN_MENU }
            if ($result -eq $global:ACTION_BACK) { if ($step -gt 1) { if($step -eq 12 -and $soundBlocking -ne '/////'){$step = 11} else{$step--} } else { return $global:ACTION_BACK }; continue }
            if (-not $result) { continue }
            switch ($step) {
                1  { $helmetName = $result }; 2  { $weight = $result }; 3  { $durability = $result }; 4  { $armorClass = $result }
                5  { $material = $result }; 6  { $soundBlocking = $result }; 7  { $movementSpeed = $result }; 8  { $ergonomics = $result }
                9  { $protectedArea = $result }; 10 { $ricochetChance = $result }
                11 { 
                    $headset = $result
                    if ($headset -eq "Sim") {
                        $pickupRaw = Show-Menu -Title "Qual é a potencia de captura de som?" -Options @("Fraco", "Medio") -EnableBackButton -EnableMainMenuButton
                        if($pickupRaw -and $pickupRaw -ne $global:ACTION_BACK -and $pickupRaw -ne $global:ACTION_MAIN_MENU){$soundPickup = switch($pickupRaw){"Fraco"{"Bad"};"Medio"{"Medium"}}}else{continue}
                        
                        $reductionRaw = Show-Menu -Title "Qual é a potencia de redução de Ruído?" -Options @("Fraco", "Medio", "Forte") -EnableBackButton -EnableMainMenuButton
                        if($reductionRaw -and $reductionRaw -ne $global:ACTION_BACK -and $reductionRaw -ne $global:ACTION_MAIN_MENU){$noiseReduction = switch($reductionRaw){"Fraco"{"Bad"};"Medio"{"Medium"};"Forte"{"Strong"}}}else{continue}
                    } else { $soundPickup = "/////"; $noiseReduction = "/////" }
                }
                12 { $accessory = $result }
            }
            $step++
        }
    } else {
        $helmetName = $ExistingData.Nome; $weight = $ExistingData.Weight; $durability = $ExistingData.Durability
        $armorClass = $ExistingData.ArmorClass; $material = $ExistingData.Material; $soundBlocking = $ExistingData.SoundBlocking
        $movementSpeed = $ExistingData.MovementSpeed; $ergonomics = $ExistingData.Ergonomics; $protectedArea = $ExistingData.ProtectedArea
        $ricochetChance = $ExistingData.RicochetChance; $headset = $ExistingData.Headset; $soundPickup = $ExistingData.SoundPickup
        $noiseReduction = $ExistingData.NoiseReduction; $accessory = $ExistingData.Accessory
    }
    
    $lastEditedIndex = 0
    if ($movementSpeed -ne "/////" -and $movementSpeed -notlike "*%") { $movementSpeed = "$($movementSpeed)%" }
    $dataObject = [PSCustomObject]@{ Nome=$helmetName; Weight=$weight; Durability=$durability; ArmorClass=$armorClass; Material=$material; SoundBlocking=$soundBlocking; MovementSpeed=$movementSpeed; Ergonomics=$ergonomics; ProtectedArea=$protectedArea; RicochetChance=$ricochetChance; Headset=$headset; SoundPickup=$soundPickup; NoiseReduction=$noiseReduction; Accessory=$accessory }
    
    :confirmationLoop while($true) {
        $userAction = Show-HelmetConfirmation -ItemData $dataObject -InitialSelectedIndex $lastEditedIndex
        if ($userAction -eq "CANCEL") { return }
        if ($userAction -eq "CONFIRM") {
            $path = Join-Path -Path $global:databasePath -ChildPath "Helmets"
            if (-not (Test-Path $path)) { New-Item -Path $path -ItemType Directory | Out-Null }
            $filePath = Join-Path -Path $path -ChildPath "$($dataObject.Nome).txt"
            @($dataObject.Weight, $dataObject.Durability, $dataObject.ArmorClass, $dataObject.Material, $dataObject.SoundBlocking, $dataObject.MovementSpeed, $dataObject.Ergonomics, $dataObject.ProtectedArea, $dataObject.RicochetChance, $dataObject.Headset, $dataObject.SoundPickup, $dataObject.NoiseReduction, $dataObject.Accessory) | Out-File -FilePath $filePath -Encoding UTF8
            
            if ($ExistingData -and $ExistingData.Nome -ne $dataObject.Nome) {
                Remove-Item -Path (Join-Path $path "$($ExistingData.Nome).txt") -Force
            }
            Write-Host "Capacete '$($dataObject.Nome)' salvo com sucesso!" -ForegroundColor Green; Start-Sleep -Seconds 2
            return
        }
        
        if ($userAction -is [int]) {
            $lastEditedIndex = $userAction
            $newValue = $null
            $propToUpdate = $dataObject.psobject.Properties.Name[$userAction]
            switch ($propToUpdate) {
                "Nome" { $newValue = Read-InputWithPaste -Prompt "Novo nome:" -Title "Editar Nome" -EnableStandardNav -MaxLength 32 }
                "Weight" { $newValue = Get-InputWithFilter -Prompt "Novo peso (Ex: 1.20):" -Title "Editar Peso" -Mode 'decimal_1_2' -MaxLength 4 -EnableStandardNav }
                "Durability" { $newValue = Get-InputWithFilter -Prompt "Nova Durabilidade (Ex: 10.0):" -Title "Editar Durabilidade" -Mode 'decimal_2_1_fixed' -MaxLength 4 -EnableStandardNav }
                "ArmorClass" { $newValue = Get-InputWithFilter -Prompt "Nova Classe de Blindagem (1-6):" -Title "Editar Classe" -Mode 'numeric_1_6' -MaxLength 1 -EnableStandardNav }
                "Material" { $raw = Show-Menu -Title "Qual e o Material?" -Options @("Aramida","Polietileno","Aco endurecido","Composto","Aluminio","Titanio") -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$newValue=switch($raw){"Aramida"{"Aramid"};"Polietileno"{"Polyethylene"};"Aco endurecido"{"Hardened Steel"};"Composto"{"Composite"};"Aluminio"{"Aluminum"};"Titanio"{"Titanium"}}}else{$newValue=$raw}}
                "SoundBlocking" { $raw = Show-Menu -Title "Tem Bloqueio Sonoro?" -Options @("Nao tem bloqueio sonoro","Ligeiro","Normal","Grave") -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$newValue=switch($raw){"Nao tem bloqueio sonoro"{"/////"};"Ligeiro"{"Low"};"Normal"{"Moderate"};"Grave"{"Severe"}}}else{$newValue=$raw}}
                "MovementSpeed" { $choice = Show-Menu -Title "Altera a velocidade de Movimento?" -Options @("Sim", "Nao") -EnableBackButton -EnableMainMenuButton; if($choice -eq "Sim"){$newValue=Get-InputWithFilter -Prompt "Digite o valor (Ex: -10):" -Title "Velocidade de Movimento" -Mode 'percentage_negative' -MaxLength 3 -EnableStandardNav}elseif($choice -eq "Nao"){$newValue="/////"}else{$newValue=$choice}}
                "Ergonomics" { $choice = Show-Menu -Title "Afeta ergonomia?" -Options @("Sim", "Nao") -EnableBackButton -EnableMainMenuButton; if($choice -eq "Sim"){$newValue=Get-InputWithFilter -Prompt "Digite o valor (Ex: -10):" -Title "Ergonomia" -Mode 'numeric_negative_no_leading_zero' -MaxLength 3 -EnableStandardNav}elseif($choice -eq "Nao"){$newValue="/////"}else{$newValue=$choice}}
                "ProtectedArea" { $raw = Show-Menu -Title "Quais partes da cabeca protege?" -Options @("Cabeca","Cabeca, Ouvidos","Cabeca, Ouvidos, Rosto") -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$newValue=switch($raw){"Cabeca"{"Head"};"Cabeca, Ouvidos"{"Head, Ears"};"Cabeca, Ouvidos, Rosto"{"Head, Ears, Face"}}}else{$newValue=$raw}}
                "RicochetChance" { $raw = Show-Menu -Title "Qual e a chance de ricochetear?" -Options @("Baixo","Medio","Alto") -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$newValue=switch($raw){"Baixo"{"Low"};"Medio"{"Medium"};"Alto"{"High"}}}else{$newValue=$raw}}
                "Headset" { $newValue = Show-Menu -Title "Tem fone de ouvido embutido?" -Options @("Sim", "Nao") -EnableBackButton -EnableMainMenuButton }
                "SoundPickup" { $raw = Show-Menu -Title "Qual e a potencia de captura de som?" -Options @("Fraco", "Medio") -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$newValue=switch($raw){"Fraco"{"Bad"};"Medio"{"Medium"}}}else{$newValue=$raw}}
                "NoiseReduction" { $raw = Show-Menu -Title "Qual e a potencia de reducao de Ruido?" -Options @("Fraco", "Medio", "Forte") -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$newValue=switch($raw){"Fraco"{"Bad"};"Medio"{"Medium"};"Forte"{"Strong"}}}else{$newValue=$raw}}
                "Accessory" { $raw = Show-Menu -Title "Acessorio Funcional" -Options @("Nao aceita","Aceita Equipamento Tatico","Aceita Mascara","Aceita Ambos") -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$newValue=switch($raw){"Nao aceita"{"/////"};"Aceita Equipamento Tatico"{"TE"};"Aceita Mascara"{"Mask"};"Aceita Ambos"{"Mask, TE"}}}else{$newValue=$raw}}
            }
            if ($newValue -and $newValue -ne $global:ACTION_BACK -and $newValue -ne $global:ACTION_MAIN_MENU) {
                if($propToUpdate -eq 'MovementSpeed' -and $newValue -ne '/////') { $dataObject.$propToUpdate = "$newValue%" } 
                else { $dataObject.$propToUpdate = $newValue }
            }
        }
    }
}

function Add-NewBodyArmor {
    param([PSCustomObject]$ExistingData = $null)
    if (-not $ExistingData) {
        $itemName, $weight, $durability, $armorClass, $material, $movementSpeed, $ergonomics, $protectedArea = $null
        $step = 1
        while ($step -le 8) {
            $result = $null
            switch ($step) {
                1 { $result = Read-InputWithPaste -Prompt "Qual e o nome do colete?" -Title "Adicionar Colete Balistico" -EnableStandardNav -MaxLength 42 }
                2 { $result = Get-InputWithFilter -Prompt "Qual e o peso do colete? (Ex: 6.20 ou 11.80)" -Title "Peso" -Mode 'decimal_weight' -EnableStandardNav }
                3 { $result = Get-InputWithFilter -Prompt "Qual e a Durabilidade do colete? (Ex: 85.0 ou 123.0)" -Title "Durabilidade" -Mode 'decimal_durability_fixed' -EnableStandardNav }
                4 { $result = Get-InputWithFilter -Prompt "Qual e a Classe de Blindagem? (1-6)" -Title "Classe de Blindagem" -Mode 'numeric_1_6' -MaxLength 1 -EnableStandardNav }
                5 { 
                    $options = @("Aramida","Polietileno","Aco endurecido","Composto","Aluminio","Titanio","Ceramica")
                    $raw = Show-Menu -Title "Qual e o Material do colete?" -Options $options -EnableBackButton -EnableMainMenuButton
                    if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){
                        $result=switch($raw){
                            "Aramida"{"Aramid"}
                            "Polietileno"{"Polyethylene"}
                            "Aco endurecido"{"Hardened Steel"}
                            "Composto"{"Composite"}
                            "Aluminio"{"Aluminum"}
                            "Titanio"{"Titanium"}
                            "Ceramica"{"Ceramic"}
                        }
                    } else {
                        $result=$raw
                    }
                }
                6 { $choice = Show-Menu -Title "O colete afeta a velociade de Movimento?" -Options @("Sim", "Nao") -EnableBackButton -EnableMainMenuButton; if($choice -eq "Sim"){$result=Get-InputWithFilter -Prompt "Digite o valor (Ex: -10):" -Title "Velocidade de Movimento" -Mode 'percentage_negative' -MaxLength 3 -EnableStandardNav}elseif($choice -eq "Nao"){$result="/////"}else{$result=$choice}}
                7 { $choice = Show-Menu -Title "O colete afeta a Ergonomia?" -Options @("Sim", "Nao") -EnableBackButton -EnableMainMenuButton; if($choice -eq "Sim"){$result=Get-InputWithFilter -Prompt "Digite o valor (Ex: -10):" -Title "Ergonomia" -Mode 'numeric_negative_no_leading_zero' -MaxLength 3 -EnableStandardNav}elseif($choice -eq "Nao"){$result="/////"}else{$result=$choice}}
                8 { $options = @("Torax","Torax, Abdomen Superior","Torax, Ombro, Abdomen Superior","Torax, Abdomen Superior, Abdomen Inferior","Torax, Ombro, Abdomen Superior, Abdomen Inferior"); $raw = Show-Menu -Title "O colete protege quais partes do corpo?" -Options $options -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$result=switch($raw){"Torax"{"Chest"};"Torax, Abdomen Superior"{"Chest, Upper Abdomen"};"Torax, Ombro, Abdomen Superior"{"Chest, Shoulder, Upper Abdomen"};"Torax, Abdomen Superior, Abdomen Inferior"{"Chest, Upper Abdomen, Lower Abdomen"};"Torax, Ombro, Abdomen Superior, Abdomen Inferior"{"Chest, Shoulder, Upper Abdomen, Lower Abdomen"}}}else{$result=$raw}}
            }
            if ($result -eq $global:ACTION_MAIN_MENU) { return $global:ACTION_MAIN_MENU }
            if ($result -eq $global:ACTION_BACK) { if ($step -gt 1) { $step-- } else { return $global:ACTION_BACK }; continue }
            if (-not $result) { continue }
            switch ($step) { 1 {$itemName=$result}; 2 {$weight=$result}; 3 {$durability=$result}; 4 {$armorClass=$result}; 5 {$material=$result}; 6 {$movementSpeed=$result}; 7 {$ergonomics=$result}; 8 {$protectedArea=$result} }
            $step++
        }
    } else {
        $itemName = $ExistingData.Nome; $weight = $ExistingData.Peso; $durability = $ExistingData.Durabilidade; $armorClass = $ExistingData.ClassedeBlindagem; $material = $ExistingData.Material; $movementSpeed = $ExistingData.VelocidadedeMovimento; $ergonomics = $ExistingData.Ergonomia; $protectedArea = $ExistingData.AreaProtegida
    }
    $lastEditedIndex = 0
    if ($movementSpeed -ne "/////" -and $movementSpeed -notlike "*%") { $movementSpeed = "$($movementSpeed)%" }
    $dataObject = [PSCustomObject]@{ Nome=$itemName; Peso=$weight; Durabilidade=$durability; ClassedeBlindagem=$armorClass; Material=$material; VelocidadedeMovimento=$movementSpeed; Ergonomia=$ergonomics; AreaProtegida=$protectedArea }
    
    :confirmationLoop while($true) {
        $userAction = Show-BodyArmorConfirmation -ItemData $dataObject -InitialSelectedIndex $lastEditedIndex
        if ($userAction -eq "CANCEL") { return }
        if ($userAction -eq "CONFIRM") {
            $path = Join-Path -Path $global:databasePath -ChildPath "Bodyarmors"
            if (-not (Test-Path $path)) { New-Item -Path $path -ItemType Directory | Out-Null }
            $filePath = Join-Path -Path $path -ChildPath "$($dataObject.Nome).txt"
            @($dataObject.Peso, $dataObject.Durabilidade, $dataObject.ClassedeBlindagem, $dataObject.Material, $dataObject.VelocidadedeMovimento, $dataObject.Ergonomia, $dataObject.AreaProtegida) | Out-File -FilePath $filePath -Encoding UTF8
            if ($ExistingData -and $ExistingData.Nome -ne $dataObject.Nome) { Remove-Item -Path (Join-Path $path "$($ExistingData.Nome).txt") -Force }
            Write-Host "Colete Balistico '$($dataObject.Nome)' salvo com sucesso!" -ForegroundColor Green; Start-Sleep -Seconds 2
            return
        }
        if ($userAction -is [int]) {
            $lastEditedIndex = $userAction; $newValue = $null
            switch ($userAction) {
                0 { $newValue = Read-InputWithPaste -Prompt "Novo nome:" -Title "Editar Nome" -EnableStandardNav -MaxLength 42 }
                1 { $newValue = Get-InputWithFilter -Prompt "Novo peso (Ex: 6.20 ou 11.80):" -Title "Editar Peso" -Mode 'decimal_weight' -EnableStandardNav }
                2 { $newValue = Get-InputWithFilter -Prompt "Nova Durabilidade (Ex: 85.0 ou 123.0):" -Title "Editar Durabilidade" -Mode 'decimal_durability_fixed' -EnableStandardNav }
                3 { $newValue = Get-InputWithFilter -Prompt "Nova Classe de Blindagem (1-6):" -Title "Editar Classe" -Mode 'numeric_1_6' -MaxLength 1 -EnableStandardNav }
                4 { 
                    $options = @("Aramida","Polietileno","Aco endurecido","Composto","Aluminio","Titanio","Ceramica")
                    $raw = Show-Menu -Title "Novo Material" -Options $options -EnableBackButton -EnableMainMenuButton
                    if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){
                        $newValue=switch($raw){
                            "Aramida"{"Aramid"}
                            "Polietileno"{"Polyethylene"}
                            "Aco endurecido"{"Hardened Steel"}
                            "Composto"{"Composite"}
                            "Aluminio"{"Aluminum"}
                            "Titanio"{"Titanium"}
                            "Ceramica"{"Ceramic"}
                        }
                    } else {
                        $newValue=$raw
                    }
                }
                5 { $choice = Show-Menu -Title "O colete afeta a velociade de Movimento?" -Options @("Sim", "Nao") -EnableBackButton -EnableMainMenuButton; if($choice -eq "Sim"){$newValue=Get-InputWithFilter -Prompt "Digite o valor (Ex: -10):" -Title "Velocidade de Movimento" -Mode 'percentage_negative' -MaxLength 3 -EnableStandardNav}elseif($choice -eq "Nao"){$newValue="/////"}else{$newValue=$choice}}
                6 { $choice = Show-Menu -Title "O colete afeta a Ergonomia?" -Options @("Sim", "Nao") -EnableBackButton -EnableMainMenuButton; if($choice -eq "Sim"){$newValue=Get-InputWithFilter -Prompt "Digite o valor (Ex: -10):" -Title "Ergonomia" -Mode 'numeric_negative_no_leading_zero' -MaxLength 3 -EnableStandardNav}elseif($choice -eq "Nao"){$newValue="/////"}else{$newValue=$choice}}
                7 { $options = @("Torax","Torax, Abdomen Superior","Torax, Ombro, Abdomen Superior","Torax, Abdomen Superior, Abdomen Inferior","Torax, Ombro, Abdomen Superior, Abdomen Inferior"); $raw = Show-Menu -Title "Quais partes do corpo o colete protege?" -Options $options -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$newValue=switch($raw){"Torax"{"Chest"};"Torax, Abdomen Superior"{"Chest, Upper Abdomen"};"Torax, Ombro, Abdomen Superior"{"Chest, Shoulder, Upper Abdomen"};"Torax, Abdomen Superior, Abdomen Inferior"{"Chest, Upper Abdomen, Lower Abdomen"};"Torax, Ombro, Abdomen Superior, Abdomen Inferior"{"Chest, Shoulder, Upper Abdomen, Lower Abdomen"}}}else{$newValue=$raw}}
            }
            if ($newValue -and $newValue -ne $global:ACTION_BACK -and $newValue -ne $global:ACTION_MAIN_MENU) {
                $propName = $dataObject.psobject.Properties.Name[$userAction]
                if ($propName -eq 'VelocidadedeMovimento' -and $newValue -ne '/////') { $dataObject.$propName = "$newValue%" } 
                else { $dataObject.$propName = $newValue }
            }
        }
    }
}

function Add-NewArmoredRig {
    param([PSCustomObject]$ExistingData = $null)
    if (-not $ExistingData) {
        $itemName, $weight, $durability, $armorClass, $material, $movementSpeed, $ergonomics, $storageSpace, $protectedArea = $null
        $internalLayout = "/////"
        $addOptionalDetails = $false
        $step = 1
        
        while ($true) {
            if ($step -gt 10 -and -not $addOptionalDetails) { break }
            if ($step -gt 11) { break }
            
            $result = $null
            switch ($step) {
                1 { $result = Read-InputWithPaste -Prompt "Qual e o nome do colete blindado?" -Title "Adicionar Colete Blindado" -EnableStandardNav -MaxLength 32 }
                2 { $result = Get-InputWithFilter -Prompt "Qual e o peso do colete blindado? (Ex: 6.20 ou 11.80)" -Title "Peso" -Mode 'decimal_weight' -EnableStandardNav }
                3 { $result = Get-InputWithFilter -Prompt "Qual e a Durabilidade do colete blindado? (Ex: 85.0 ou 123.0)" -Title "Durabilidade" -Mode 'decimal_durability_fixed' -EnableStandardNav }
                4 { $result = Get-InputWithFilter -Prompt "Qual e a Classe de Blindagem? (1-6)" -Title "Classe de Blindagem" -Mode 'numeric_1_6' -MaxLength 1 -EnableStandardNav }
                5 { $options = @("Aramida","Polietileno","Aco endurecido","Composto","Aluminio","Titanio","Ceramica"); $raw = Show-Menu -Title "Qual e o Material do colete blindado?" -Options $options -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$result=switch($raw){"Aramida"{"Aramid"};"Polietileno"{"Polyethylene"};"Aco endurecido"{"Hardened Steel"};"Composto"{"Composite"};"Aluminio"{"Aluminum"};"Titanio"{"Titanium"};"Ceramica"{"Ceramic"}}}else{$result=$raw}}
                6 { $choice = Show-Menu -Title "O colete blindado afeta a velociade de Movimento?" -Options @("Sim", "Nao") -EnableBackButton -EnableMainMenuButton; if($choice -eq "Sim"){$result=Get-InputWithFilter -Prompt "Digite o valor (Ex: -10):" -Title "Velocidade de Movimento" -Mode 'percentage_negative' -MaxLength 3 -EnableStandardNav}elseif($choice -eq "Nao"){$result="/////"}else{$result=$choice}}
                7 { $choice = Show-Menu -Title "O colete blindado afeta a Ergonomia?" -Options @("Sim", "Nao") -EnableBackButton -EnableMainMenuButton; if($choice -eq "Sim"){$result=Get-InputWithFilter -Prompt "Digite o valor (Ex: -10):" -Title "Ergonomia" -Mode 'numeric_negative_no_leading_zero' -MaxLength 3 -EnableStandardNav}elseif($choice -eq "Nao"){$result="/////"}else{$result=$choice}}
                8 { $result = Get-InputWithFilter -Prompt "Qual e o espaco de armazenamento do colete blindado? (Ex: 20)" -Title "Espaco de Armazenamento" -Mode 'numeric' -MaxLength 2 -EnableStandardNav }
                9 { $options = @("Torax","Torax, Abdomen Superior","Torax, Abdomen Superior, Abdomen Inferior","Torax, Ombro, Abdomen Superior, Abdomen Inferior"); $raw = Show-Menu -Title "O colete protege quais partes do corpo?" -Options $options -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$result=switch($raw){"Torax"{"Chest"};"Torax, Abdomen Superior"{"Chest, Upper Abdomen"};"Torax, Abdomen Superior, Abdomen Inferior"{"Chest, Upper Abdomen, Lower Abdomen"};"Torax, Ombro, Abdomen Superior, Abdomen Inferior"{"Chest, Shoulder, Upper Abdomen, Lower Abdomen"}}}else{$result=$raw}}
                10{
                    $choice = Show-Menu -Title "Detalhes Opcionais" -Options @("Adicionar detalhes de blocos internos", "Concluir e ir para a confirmacao") -Footer "As proximas perguntas sobre os detalhes dos blocos internos sao opcionais." -EnableBackButton -EnableMainMenuButton
                    if ($choice -eq "Adicionar detalhes de blocos internos") { $addOptionalDetails = $true; $result = $choice }
                    else { $result = $choice }
                }
                11{ 
                    $result = Get-InternalSetLayout -ItemTypeName "colete blindado"
                }
            }
            if ($result -eq $global:ACTION_MAIN_MENU) { return $global:ACTION_MAIN_MENU }
            if ($result -eq $global:ACTION_BACK) { if ($step -gt 1) { $step-- } else { return $global:ACTION_BACK }; continue }
            if (-not $result) { continue }
            
            switch ($step) {
                1{$itemName=$result};2{$weight=$result};3{$durability=$result};4{$armorClass=$result};5{$material=$result};6{$movementSpeed=$result};7{$ergonomics=$result};8{$storageSpace=$result};9{$protectedArea=$result}
                10{ if ($result -eq "Concluir e ir para a confirmacao") { $addOptionalDetails = $false } }
                11{ if ($result) { $internalLayout = $result } }
            }
            $step++
        }
    } else {
        $itemName = $ExistingData.Nome; $weight = $ExistingData.Peso; $durability = $ExistingData.Durabilidade; $armorClass = $ExistingData.ClassedeBlindagem; $material = $ExistingData.Material; $movementSpeed = $ExistingData.VelocidadedeMovimento; $ergonomics = $ExistingData.Ergonomia; $storageSpace = $ExistingData.EspacodeArmazenamento; $protectedArea = $ExistingData.AreaProtegida; $internalLayout = $ExistingData.ConjuntosdeBlocos
    }
    $lastEditedIndex = 0
    if ($movementSpeed -ne "/////" -and $movementSpeed -notlike "*%") { $movementSpeed = "$($movementSpeed)%" }
    $dataObject = [PSCustomObject]@{ Nome=$itemName; Peso=$weight; Durabilidade=$durability; ClassedeBlindagem=$armorClass; Material=$material; VelocidadedeMovimento=$movementSpeed; Ergonomia=$ergonomics; EspacodeArmazenamento=$storageSpace; AreaProtegida=$protectedArea; ConjuntosdeBlocos=$internalLayout }
    
    :confirmationLoop while($true) {
        $userAction = Show-ArmoredRigConfirmation -ItemData $dataObject -InitialSelectedIndex $lastEditedIndex
        if ($userAction -eq "CANCEL") { return }
        if ($userAction -eq "CONFIRM") {
            $path = Join-Path -Path $global:databasePath -ChildPath "Armoredrigs"; if (-not (Test-Path $path)) { New-Item -Path $path -ItemType Directory | Out-Null }
            $filePath = Join-Path -Path $path -ChildPath "$($dataObject.Nome).txt"
            @($dataObject.Peso, $dataObject.Durabilidade, $dataObject.ClassedeBlindagem, $dataObject.Material, $dataObject.VelocidadedeMovimento, $dataObject.Ergonomia, $dataObject.EspacodeArmazenamento, $dataObject.AreaProtegida, $dataObject.ConjuntosdeBlocos) | Out-File -FilePath $filePath -Encoding UTF8
            if ($ExistingData -and $ExistingData.Nome -ne $dataObject.Nome) { Remove-Item -Path (Join-Path $path "$($ExistingData.Nome).txt") -Force }
            Write-Host "Colete Blindado '$($dataObject.Nome)' salvo com sucesso!" -ForegroundColor Green; Start-Sleep -Seconds 2
            return
        }
        if ($userAction -is [int]) {
            $lastEditedIndex = $userAction; $newValue = $null
            switch ($userAction) {
                0 { $newValue = Read-InputWithPaste -Prompt "Novo nome:" -Title "Editar Nome" -EnableStandardNav -MaxLength 32 }
                1 { $newValue = Get-InputWithFilter -Prompt "Novo peso (Ex: 6.20 ou 11.80):" -Title "Editar Peso" -Mode 'decimal_weight' -EnableStandardNav }
                2 { $newValue = Get-InputWithFilter -Prompt "Nova Durabilidade (Ex: 85.0 ou 123.0):" -Title "Editar Durabilidade" -Mode 'decimal_durability_fixed' -EnableStandardNav }
                3 { $newValue = Get-InputWithFilter -Prompt "Nova Classe de Blindagem (1-6):" -Title "Editar Classe" -Mode 'numeric_1_6' -MaxLength 1 -EnableStandardNav }
                4 { $options = @("Aramida","Polietileno","Aco endurecido","Composto","Aluminio","Titanio","Ceramica"); $raw = Show-Menu -Title "Novo Material" -Options $options -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$newValue=switch($raw){"Aramida"{"Aramid"};"Polietileno"{"Polyethylene"};"Aco endurecido"{"Hardened Steel"};"Composto"{"Composite"};"Aluminio"{"Aluminum"};"Titanio"{"Titanium"};"Ceramica"{"Ceramic"}}}else{$newValue=$raw}}
                5 { $choice = Show-Menu -Title "O colete blindado afeta a velociade de Movimento?" -Options @("Sim", "Nao") -EnableBackButton -EnableMainMenuButton; if($choice -eq "Sim"){$newValue=Get-InputWithFilter -Prompt "Digite o valor (Ex: -10):" -Title "Velocidade de Movimento" -Mode 'percentage_negative' -MaxLength 3 -EnableStandardNav}elseif($choice -eq "Nao"){$newValue="/////"}else{$newValue=$choice}}
                6 { $choice = Show-Menu -Title "O colete blindado afeta a Ergonomia?" -Options @("Sim", "Nao") -EnableBackButton -EnableMainMenuButton; if($choice -eq "Sim"){$newValue=Get-InputWithFilter -Prompt "Digite o valor (Ex: -10):" -Title "Ergonomia" -Mode 'numeric_negative_no_leading_zero' -MaxLength 3 -EnableStandardNav}elseif($choice -eq "Nao"){$newValue="/////"}else{$newValue=$choice}}
                7 { $newValue = Get-InputWithFilter -Prompt "Qual e o novo espaco de armazenamento? (Ex: 20)" -Title "Editar Espaco de Armazenamento" -Mode 'numeric' -MaxLength 2 -EnableStandardNav }
                8 { $options = @("Torax","Torax, Abdomen Superior","Torax, Abdomen Superior, Abdomen Inferior","Torax, Ombro, Abdomen Superior, Abdomen Inferior"); $raw = Show-Menu -Title "O colete protege quais partes do corpo?" -Options $options -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$newValue=switch($raw){"Torax"{"Chest"};"Torax, Abdomen Superior"{"Chest, Upper Abdomen"};"Torax, Abdomen Superior, Abdomen Inferior"{"Chest, Upper Abdomen, Lower Abdomen"};"Torax, Ombro, Abdomen Superior, Abdomen Inferior"{"Chest, Shoulder, Upper Abdomen, Lower Abdomen"}}}else{$newValue=$raw}}
                9 { $newValue = Get-InternalSetLayout -ItemTypeName "colete blindado" }
            }
            if ($newValue -and $newValue -ne $global:ACTION_BACK -and $newValue -ne $global:ACTION_MAIN_MENU) {
                $propName = $dataObject.psobject.Properties.Name[$userAction]
                if ($propName -eq 'VelocidadedeMovimento' -and $newValue -ne '/////') { $dataObject.$propName = "$newValue%" } 
                else { $dataObject.$propName = $newValue }
            }
        }
    }
}

function Add-NewMask {
    param([PSCustomObject]$ExistingData = $null)
    if (-not $ExistingData) {
        $itemName, $weight, $durability, $armorClass, $material, $ricochetChance = $null
        $step = 1
        while ($step -le 6) {
            $result = $null
            switch ($step) {
                1 { $result = Read-InputWithPaste -Prompt "Qual e o nome da mascara?" -Title "Adicionar Nova Mascara" -EnableStandardNav -MaxLength 38 }
                2 { $result = Get-InputWithFilter -Prompt "Qual e o peso da mascara? (Exemplo: 1.20)" -Title "Peso" -Mode 'decimal_mask_weight' -EnableStandardNav -MaxLength 4 }
                3 { $result = Get-InputWithFilter -Prompt "Qual e a Durabilidade da mascara? (Exemplo: 45.0)" -Title "Durabilidade" -Mode 'decimal_mask_durability' -EnableStandardNav -MaxLength 4 }
                4 { $result = Get-InputWithFilter -Prompt "Qual e a Classe da mascara? (1-6)" -Title "Classe da Mascara" -Mode 'numeric_1_6' -MaxLength 1 -EnableStandardNav }
                5 { $options = @("Vidro","Aco endurecido","Composto","Aluminio"); $raw = Show-Menu -Title "Qual e o Material da mascara?" -Options $options -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$result=switch($raw){"Vidro"{"Glass"};"Aco endurecido"{"Hardened Steel"};"Composto"{"Composite"};"Aluminio"{"Aluminum"}}}else{$result=$raw}}
                6 { $options = @("Baixo","Medio","Alto"); $raw = Show-Menu -Title "Qual é a chance da mascara ricochetear?" -Options $options -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$result=switch($raw){"Baixo"{"Low"};"Medio"{"Medium"};"Alto"{"High"}}}else{$result=$raw}}
            }
            if ($result -eq $global:ACTION_MAIN_MENU) { return $global:ACTION_MAIN_MENU }
            if ($result -eq $global:ACTION_BACK) { if ($step -gt 1) { $step-- } else { return $global:ACTION_BACK }; continue }
            if (-not $result) { continue }
            switch ($step) { 1 {$itemName=$result}; 2 {$weight=$result}; 3 {$durability=$result}; 4 {$armorClass=$result}; 5 {$material=$result}; 6 {$ricochetChance=$result} }
            $step++
        }
    } else {
        $itemName = $ExistingData.Nome; $weight = $ExistingData.Peso; $durability = $ExistingData.Durabilidade; $armorClass = $ExistingData.Classe; $material = $ExistingData.Material; $ricochetChance = $ExistingData.ChancedeRicochete
    }
    $lastEditedIndex = 0
    $dataObject = [PSCustomObject]@{ Nome=$itemName; Peso=$weight; Durabilidade=$durability; Classe=$armorClass; Material=$material; ChancedeRicochete=$ricochetChance }
    
    :confirmationLoop while($true) {
        $userAction = Show-MaskConfirmation -ItemData $dataObject -InitialSelectedIndex $lastEditedIndex
        if ($userAction -eq "CANCEL") { return }
        if ($userAction -eq "CONFIRM") {
            $path = Join-Path -Path $global:databasePath -ChildPath "Masks"
            if (-not (Test-Path $path)) { New-Item -Path $path -ItemType Directory | Out-Null }
            $filePath = Join-Path -Path $path -ChildPath "$($dataObject.Nome).txt"
            @($dataObject.Peso, $dataObject.Durabilidade, $dataObject.Classe, $dataObject.Material, $dataObject.ChancedeRicochete) | Out-File -FilePath $filePath -Encoding UTF8
            if ($ExistingData -and $ExistingData.Nome -ne $dataObject.Nome) { Remove-Item -Path (Join-Path $path "$($ExistingData.Nome).txt") -Force }
            Write-Host "Mascara '$($dataObject.Nome)' salva com sucesso!" -ForegroundColor Green; Start-Sleep -Seconds 2
            return
        }
        if ($userAction -is [int]) {
            $lastEditedIndex = $userAction; $newValue = $null
            switch ($userAction) {
                0 { $newValue = Read-InputWithPaste -Prompt "Novo nome:" -Title "Editar Nome" -EnableStandardNav -MaxLength 38 }
                1 { $newValue = Get-InputWithFilter -Prompt "Novo peso (Exemplo: 1.20):" -Title "Editar Peso" -Mode 'decimal_mask_weight' -EnableStandardNav -MaxLength 4 }
                2 { $newValue = Get-InputWithFilter -Prompt "Nova Durabilidade (Exemplo: 45.0):" -Title "Editar Durabilidade" -Mode 'decimal_mask_durability' -EnableStandardNav -MaxLength 4 }
                3 { $newValue = Get-InputWithFilter -Prompt "Nova Classe (1-6):" -Title "Editar Classe" -Mode 'numeric_1_6' -MaxLength 1 -EnableStandardNav }
                4 { $options = @("Vidro","Aco endurecido","Composto","Aluminio"); $raw = Show-Menu -Title "Novo Material" -Options $options -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$newValue=switch($raw){"Vidro"{"Glass"};"Aco endurecido"{"Hardened Steel"};"Composto"{"Composite"};"Aluminio"{"Aluminum"}}}else{$newValue=$raw}}
                5 { $options = @("Baixo","Medio","Alto"); $raw = Show-Menu -Title "Nova Chance de Ricochete" -Options $options -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$newValue=switch($raw){"Baixo"{"Low"};"Medio"{"Medium"};"Alto"{"High"}}}else{$newValue=$raw}}
            }
            if ($newValue -and $newValue -ne $global:ACTION_BACK -and $newValue -ne $global:ACTION_MAIN_MENU) {
                $propName = $dataObject.psobject.Properties.Name[$userAction]
                $dataObject.$propName = $newValue
            }
        }
    }
}

function Add-NewGasMask {
    param([PSCustomObject]$ExistingData = $null)
    if (-not $ExistingData) {
        $itemName, $weight, $durability, $antiVenom, $antiFlash = $null
        $step = 1
        while ($step -le 5) {
            $result = $null
            switch ($step) {
                1 { $result = Read-InputWithPaste -Prompt "Qual e o nome da mascara de gas?" -Title "Adicionar Mascara de Gas" -EnableStandardNav -MaxLength 36 }
                2 { $result = Get-InputWithFilter -Prompt "Qual e o peso da mascara de gas? (Exemplo: 0.50)" -Title "Peso" -Mode 'decimal_gasmask_weight' -EnableStandardNav }
                3 { $result = Get-InputWithFilter -Prompt "Qual e a Durabilidade da mascara de gas? (Exemplo: 45)" -Title "Durabilidade" -Mode 'numeric_2_digits_no_leading_zero' -EnableStandardNav }
                4 { $options = @("Fraco","Medio","Forte"); $raw = Show-Menu -Title "Qual é o poder de Anti-Veneno da mascara de gas?" -Options $options -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$result=switch($raw){"Fraco"{"Bad"};"Medio"{"Medium"};"Forte"{"Strong"}}}else{$result=$raw}}
                5 { $options = @("Nao possui defesa Anti-Flash","Fraco","Medio","Forte"); $raw = Show-Menu -Title "Qual é o poder de Anti-Flash da mascara de gas?" -Options $options -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$result=switch($raw){"Nao possui defesa Anti-Flash"{"/////"};"Fraco"{"Bad"};"Medio"{"Medium"};"Forte"{"Strong"}}}else{$result=$raw}}
            }
            if ($result -eq $global:ACTION_MAIN_MENU) { return $global:ACTION_MAIN_MENU }
            if ($result -eq $global:ACTION_BACK) { if ($step -gt 1) { $step-- } else { return $global:ACTION_BACK }; continue }
            if (-not $result) { continue }
            switch ($step) { 1 {$itemName=$result}; 2 {$weight=$result}; 3 {$durability=$result}; 4 {$antiVenom=$result}; 5 {$antiFlash=$result} }
            $step++
        }
    } else {
        $itemName = $ExistingData.Nome; $weight = $ExistingData.Peso; $durability = $ExistingData.Durabilidade; $antiVenom = $ExistingData.AntiVeneno; $antiFlash = $ExistingData.AntiFlash
    }
    $lastEditedIndex = 0
    $dataObject = [PSCustomObject]@{ Nome=$itemName; Peso=$weight; Durabilidade=$durability; AntiVeneno=$antiVenom; AntiFlash=$antiFlash }
    
    :confirmationLoop while($true) {
        $userAction = Show-GasMaskConfirmation -ItemData $dataObject -InitialSelectedIndex $lastEditedIndex
        if ($userAction -eq "CANCEL") { return }
        if ($userAction -eq "CONFIRM") {
            $path = Join-Path -Path $global:databasePath -ChildPath "Gasmasks"
            if (-not (Test-Path $path)) { New-Item -Path $path -ItemType Directory | Out-Null }
            $filePath = Join-Path -Path $path -ChildPath "$($dataObject.Nome).txt"
            @($dataObject.Peso, $dataObject.Durabilidade, $dataObject.AntiVeneno, $dataObject.AntiFlash) | Out-File -FilePath $filePath -Encoding UTF8
            if ($ExistingData -and $ExistingData.Nome -ne $dataObject.Nome) { Remove-Item -Path (Join-Path $path "$($ExistingData.Nome).txt") -Force }
            Write-Host "Mascara de Gas '$($dataObject.Nome)' salva com sucesso!" -ForegroundColor Green; Start-Sleep -Seconds 2
            return
        }
        if ($userAction -is [int]) {
            $lastEditedIndex = $userAction; $newValue = $null
            switch ($userAction) {
                0 { $newValue = Read-InputWithPaste -Prompt "Novo nome:" -Title "Editar Nome" -EnableStandardNav -MaxLength 36 }
                1 { $newValue = Get-InputWithFilter -Prompt "Novo peso (Exemplo: 0.50):" -Title "Editar Peso" -Mode 'decimal_gasmask_weight' -EnableStandardNav }
                2 { $newValue = Get-InputWithFilter -Prompt "Nova Durabilidade (Exemplo: 45):" -Title "Editar Durabilidade" -Mode 'numeric_2_digits_no_leading_zero' -EnableStandardNav }
                3 { $options = @("Fraco","Medio","Forte"); $raw = Show-Menu -Title "Novo poder de Anti-Veneno" -Options $options -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$newValue=switch($raw){"Fraco"{"Bad"};"Medio"{"Medium"};"Forte"{"Strong"}}}else{$newValue=$raw}}
                4 { $options = @("Nao possui defesa Anti-Flash","Fraco","Medio","Forte"); $raw = Show-Menu -Title "Novo poder de Anti-Flash" -Options $options -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$newValue=switch($raw){"Nao possui defesa Anti-Flash"{"/////"};"Fraco"{"Bad"};"Medio"{"Medium"};"Forte"{"Strong"}}}else{$newValue=$raw}}
            }
            if ($newValue -and $newValue -ne $global:ACTION_BACK -and $newValue -ne $global:ACTION_MAIN_MENU) {
                $propName = $dataObject.psobject.Properties.Name[$userAction]
                $dataObject.$propName = $newValue
            }
        }
    }
}

function Add-NewHeadset {
    param([PSCustomObject]$ExistingData = $null)
    if (-not $ExistingData) {
        $itemName, $weight, $soundPickup, $noiseReduction = $null
        $step = 1
        while ($step -le 4) {
            $result = $null
            switch ($step) {
                1 { $result = Read-InputWithPaste -Prompt "Qual e o nome do fone de ouvido?" -Title "Adicionar Fone de Ouvido" -EnableStandardNav -MaxLength 32 }
                2 { $result = Get-InputWithFilter -Prompt "Qual e o peso do fone de ouvido? (Exemplo: 0.55)" -Title "Peso" -Mode 'decimal_headset_weight' -EnableStandardNav }
                3 { $options = @("Fraco","Medio","Forte"); $raw = Show-Menu -Title "Qual e o poder do Captador de Som do fone de ouvido?" -Options $options -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$result=switch($raw){"Fraco"{"Bad"};"Medio"{"Medium"};"Forte"{"Strong"}}}else{$result=$raw}}
                4 { $options = @("Fraco","Medio","Forte"); $raw = Show-Menu -Title "Qual e o poder de Reducao de Ruido do fone de ouvido?" -Options $options -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$result=switch($raw){"Fraco"{"Bad"};"Medio"{"Medium"};"Forte"{"Strong"}}}else{$result=$raw}}
            }
            if ($result -eq $global:ACTION_MAIN_MENU) { return $global:ACTION_MAIN_MENU }
            if ($result -eq $global:ACTION_BACK) { if ($step -gt 1) { $step-- } else { return $global:ACTION_BACK }; continue }
            if (-not $result) { continue }
            switch ($step) { 1 {$itemName=$result}; 2 {$weight=$result}; 3 {$soundPickup=$result}; 4 {$noiseReduction=$result} }
            $step++
        }
    } else {
        $itemName = $ExistingData.Nome; $weight = $ExistingData.Peso; $soundPickup = $ExistingData.CaptadordeSom; $noiseReduction = $ExistingData.ReducaodeRuido
    }
    $lastEditedIndex = 0
    $dataObject = [PSCustomObject]@{ Nome=$itemName; Peso=$weight; CaptadordeSom=$soundPickup; ReducaodeRuido=$noiseReduction }
    
    :confirmationLoop while($true) {
        $userAction = Show-HeadsetConfirmation -ItemData $dataObject -InitialSelectedIndex $lastEditedIndex
        if ($userAction -eq "CANCEL") { return }
        if ($userAction -eq "CONFIRM") {
            $path = Join-Path -Path $global:databasePath -ChildPath "Headsets"
            if (-not (Test-Path $path)) { New-Item -Path $path -ItemType Directory | Out-Null }
            $filePath = Join-Path -Path $path -ChildPath "$($dataObject.Nome).txt"
            @($dataObject.Peso, $dataObject.CaptadordeSom, $dataObject.ReducaodeRuido) | Out-File -FilePath $filePath -Encoding UTF8
            if ($ExistingData -and $ExistingData.Nome -ne $dataObject.Nome) { Remove-Item -Path (Join-Path $path "$($ExistingData.Nome).txt") -Force }
            Write-Host "Fone de Ouvido '$($dataObject.Nome)' salvo com sucesso!" -ForegroundColor Green; Start-Sleep -Seconds 2
            return
        }
        if ($userAction -is [int]) {
            $lastEditedIndex = $userAction; $newValue = $null
            switch ($userAction) {
                0 { $newValue = Read-InputWithPaste -Prompt "Novo nome:" -Title "Editar Nome" -EnableStandardNav -MaxLength 32 }
                1 { $newValue = Get-InputWithFilter -Prompt "Novo peso (Exemplo: 0.55):" -Title "Editar Peso" -Mode 'decimal_headset_weight' -EnableStandardNav }
                2 { $options = @("Fraco","Medio","Forte"); $raw = Show-Menu -Title "Novo poder de Captador de Som" -Options $options -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$newValue=switch($raw){"Fraco"{"Bad"};"Medio"{"Medium"};"Forte"{"Strong"}}}else{$newValue=$raw}}
                3 { $options = @("Fraco","Medio","Forte"); $raw = Show-Menu -Title "Novo poder de Reducao de Ruido" -Options $options -EnableBackButton -EnableMainMenuButton; if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$newValue=switch($raw){"Fraco"{"Bad"};"Medio"{"Medium"};"Forte"{"Strong"}}}else{$newValue=$raw}}
            }
            if ($newValue -and $newValue -ne $global:ACTION_BACK -and $newValue -ne $global:ACTION_MAIN_MENU) {
                $propName = $dataObject.psobject.Properties.Name[$userAction]
                $dataObject.$propName = $newValue
            }
        }
    }
}

function Add-NewUnarmoredRig {
    param([PSCustomObject]$ExistingData = $null)
    if (-not $ExistingData) {
        $itemName, $weight, $storageSpace = $null
        $sizeUnfolded, $sizeFolded, $internalLayout = "/////", "/////", "/////"
        $addOptionalDetails = $false
        $step = 1
        $temp_h = $null 
        while ($true) {
            if ($step -gt 4 -and -not $addOptionalDetails) { break }
            if ($step -gt 9) { break }
            $result = $null
            switch ($step) {
                1 { $result = Read-InputWithPaste -Prompt "Qual e o nome do colete nao blindado?" -Title "Adicionar Colete Nao Blindado" -EnableStandardNav -MaxLength 42 }
                2 { $result = Get-InputWithFilter -Prompt "Qual e o peso do colete nao blindado? (Exemplo: 2.50)" -Title "Peso" -Mode 'decimal_unarmored_weight' -EnableStandardNav }
                3 { $result = Get-InputWithFilter -Prompt "Qual e o espaco de armazenamento? (Exemplo: 20)" -Title "Espaco de Armazenamento" -Mode 'numeric' -MaxLength 2 -EnableStandardNav }
                4 {
                    $choice = Show-Menu -Title "Detalhes Opcionais" -Options @("Adicionar detalhes de tamanho e blocos", "Concluir e ir para a confirmacao") -Footer "As proximas perguntas sao opcionais." -EnableBackButton -EnableMainMenuButton
                    if ($choice -eq "Adicionar detalhes de tamanho e blocos") { $addOptionalDetails = $true; $result = $choice }
                    else { $result = $choice }
                }
                5 { $result = Get-InputWithFilter -Prompt "Tamanho Desdobrado: Blocos horizontais? (1-9)" -Title "Tamanho Desdobrado (1/2)" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav }
                6 { $result = Get-InputWithFilter -Prompt "Tamanho Desdobrado: Blocos verticais? (1-9)" -Title "Tamanho Desdobrado (2/2)" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav }
                7 { $result = Get-InputWithFilter -Prompt "Tamanho Dobrado: Blocos horizontais? (1-9)" -Title "Tamanho Dobrado (1/2)" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav }
                8 { $result = Get-InputWithFilter -Prompt "Tamanho Dobrado: Blocos verticais? (1-9)" -Title "Tamanho Dobrado (2/2)" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav }
                9 { $result = Get-InternalSetLayout -ItemTypeName "colete nao blindado" }
            }
            if ($result -eq $global:ACTION_MAIN_MENU) { return $global:ACTION_MAIN_MENU }
            if ($result -eq $global:ACTION_BACK) { if ($step -gt 1) { $step-- } else { return $global:ACTION_BACK }; continue }
            if (-not $result) { continue }
            switch ($step) {
                1 { $itemName = $result }
                2 { $weight = $result }
                3 { $storageSpace = $result }
                4 { if ($result -eq "Concluir e ir para a confirmacao") { $addOptionalDetails = $false } }
                5 { $temp_h = $result }
                6 { $sizeUnfolded = "${temp_h}x${result}" }
                7 { $temp_h = $result }
                8 { $sizeFolded = "${temp_h}x${result}" }
                9 { if ($result) { $internalLayout = $result } }
            }
            $step++
        }
    } else {
        $itemName = $ExistingData.Nome; $weight = $ExistingData.Peso; $storageSpace = $ExistingData.Espaco; $sizeUnfolded = $ExistingData.TamanhoDesdobrado; $sizeFolded = $ExistingData.TamanhoDobrado; $internalLayout = $ExistingData.ConjuntosdeBlocos
    }
    $lastEditedIndex = 0
    $dataObject = [PSCustomObject]@{ Nome=$itemName; Peso=$weight; Espaco=$storageSpace; TamanhoDesdobrado=$sizeUnfolded; TamanhoDobrado=$sizeFolded; ConjuntosdeBlocos=$internalLayout }
    
    :confirmationLoop while($true) {
        $userAction = Show-UnarmoredRigConfirmation -ItemData $dataObject -InitialSelectedIndex $lastEditedIndex
        if ($userAction -eq "CANCEL") { return }
        if ($userAction -eq "CONFIRM") {
            $path = Join-Path -Path $global:databasePath -ChildPath "Unarmoredrigs"; if (-not (Test-Path $path)) { New-Item -Path $path -ItemType Directory | Out-Null }
            $filePath = Join-Path -Path $path -ChildPath "$($dataObject.Nome).txt"
            @($dataObject.Peso, $dataObject.Espaco, $dataObject.TamanhoDesdobrado, $dataObject.TamanhoDobrado, $dataObject.ConjuntosdeBlocos) | Out-File -FilePath $filePath -Encoding UTF8
            if ($ExistingData -and $ExistingData.Nome -ne $dataObject.Nome) { Remove-Item -Path (Join-Path $path "$($ExistingData.Nome).txt") -Force }
            Write-Host "Colete Nao Blindado '$($dataObject.Nome)' salvo com sucesso!" -ForegroundColor Green; Start-Sleep -Seconds 2
            return
        }
        if ($userAction -is [int]) {
            $lastEditedIndex = $userAction; $newValue = $null
            switch ($userAction) {
                0 { $newValue = Read-InputWithPaste -Prompt "Novo nome:" -Title "Editar Nome" -EnableStandardNav -MaxLength 42 }
                1 { $newValue = Get-InputWithFilter -Prompt "Novo peso (Exemplo: 2.50):" -Title "Editar Peso" -Mode 'decimal_unarmored_weight' -EnableStandardNav }
                2 { $newValue = Get-InputWithFilter -Prompt "Novo espaco de armazenamento (Exemplo: 20):" -Title "Editar Espaco" -Mode 'numeric' -MaxLength 2 -EnableStandardNav }
                3 { 
                    $h = Get-InputWithFilter -Prompt "Tamanho Desdobrado: Horizontais?" -Title "Editar Tamanho" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav
                    if ($h -and $h -ne $global:ACTION_BACK -and $h -ne $global:ACTION_MAIN_MENU) {
                        $v = Get-InputWithFilter -Prompt "Tamanho Desdobrado: Verticais?" -Title "Editar Tamanho" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav
                        if ($v -and $v -ne $global:ACTION_BACK -and $v -ne $global:ACTION_MAIN_MENU) { $newValue = "${h}x${v}" }
                    }
                }
                4 { 
                    $h = Get-InputWithFilter -Prompt "Tamanho Dobrado: Horizontais?" -Title "Editar Tamanho" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav
                    if ($h -and $h -ne $global:ACTION_BACK -and $h -ne $global:ACTION_MAIN_MENU) {
                        $v = Get-InputWithFilter -Prompt "Tamanho Dobrado: Verticais?" -Title "Editar Tamanho" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav
                        if ($v -and $v -ne $global:ACTION_BACK -and $v -ne $global:ACTION_MAIN_MENU) { $newValue = "${h}x${v}" }
                    }
                }
                5 { $newValue = Get-InternalSetLayout -ItemTypeName "colete nao blindado" }
            }
            if ($newValue -and $newValue -ne $global:ACTION_BACK -and $newValue -ne $global:ACTION_MAIN_MENU) {
                $propName = $dataObject.psobject.Properties.Name[$userAction]; $dataObject.$propName = $newValue
            }
        }
    }
}

function Add-NewBackpack {
    param([PSCustomObject]$ExistingData = $null)
    if (-not $ExistingData) {
        $itemName, $weight, $storageSpace = $null
        $sizeUnfolded, $sizeFolded, $internalLayout = "/////", "/////", "/////"
        $addOptionalDetails = $false
        $step = 1
        $temp_h = $null
        while ($true) {
            if ($step -gt 4 -and -not $addOptionalDetails) { break }
            if ($step -gt 9) { break }
            $result = $null
            switch ($step) {
                1 { $result = Read-InputWithPaste -Prompt "Qual e o nome da mochila?" -Title "Adicionar Nova Mochila" -EnableStandardNav -MaxLength 36 }
                2 { $result = Get-InputWithFilter -Prompt "Qual e o peso da mochila? (Exemplo: 2.50)" -Title "Peso" -Mode 'decimal_backpack_weight' -EnableStandardNav }
                3 { $result = Get-InputWithFilter -Prompt "Qual e o espaco da mochila? (Exemplo: 20)" -Title "Espaco de Armazenamento" -Mode 'numeric' -MaxLength 2 -EnableStandardNav }
                4 {
                    $choice = Show-Menu -Title "Detalhes Opcionais" -Options @("Adicionar detalhes de tamanho e blocos", "Concluir e ir para a confirmacao") -Footer "As proximas perguntas sao opcionais." -EnableBackButton -EnableMainMenuButton
                    if ($choice -eq "Adicionar detalhes de tamanho e blocos") { $addOptionalDetails = $true; $result = $choice }
                    else { $result = $choice }
                }
                5 { $result = Get-InputWithFilter -Prompt "Tamanho Desdobrado: Blocos horizontais? (1-9)" -Title "Tamanho Desdobrado (1/2)" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav }
                6 { $result = Get-InputWithFilter -Prompt "Tamanho Desdobrado: Blocos verticais? (1-9)" -Title "Tamanho Desdobrado (2/2)" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav }
                7 { $result = Get-InputWithFilter -Prompt "Tamanho Dobrado: Blocos horizontais? (1-9)" -Title "Tamanho Dobrado (1/2)" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav }
                8 { $result = Get-InputWithFilter -Prompt "Tamanho Dobrado: Blocos verticais? (1-9)" -Title "Tamanho Dobrado (2/2)" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav }
                9 { $result = Get-InternalSetLayout -ItemTypeName "mochila" }
            }
            if ($result -eq $global:ACTION_MAIN_MENU) { return $global:ACTION_MAIN_MENU }
            if ($result -eq $global:ACTION_BACK) { if ($step -gt 1) { $step-- } else { return $global:ACTION_BACK }; continue }
            if (-not $result) { continue }
            switch ($step) {
                1 { $itemName = $result }
                2 { $weight = $result }
                3 { $storageSpace = $result }
                4 { if ($result -eq "Concluir e ir para a confirmacao") { $addOptionalDetails = $false } }
                5 { $temp_h = $result }
                6 { $sizeUnfolded = "${temp_h}x${result}" }
                7 { $temp_h = $result }
                8 { $sizeFolded = "${temp_h}x${result}" }
                9 { if ($result) { $internalLayout = $result } }
            }
            $step++
        }
    } else {
        $itemName = $ExistingData.Nome; $weight = $ExistingData.Peso; $storageSpace = $ExistingData.Espaco; $sizeUnfolded = $ExistingData.TamanhoDesdobrado; $sizeFolded = $ExistingData.TamanhoDobrado; $internalLayout = $ExistingData.ConjuntosdeBlocos
    }
    $lastEditedIndex = 0
    $dataObject = [PSCustomObject]@{ Nome=$itemName; Peso=$weight; Espaco=$storageSpace; TamanhoDesdobrado=$sizeUnfolded; TamanhoDobrado=$sizeFolded; ConjuntosdeBlocos=$internalLayout }
    
    :confirmationLoop while($true) {
        $userAction = Show-BackpackConfirmation -ItemData $dataObject -InitialSelectedIndex $lastEditedIndex
        if ($userAction -eq "CANCEL") { return }
        if ($userAction -eq "CONFIRM") {
            $path = Join-Path -Path $global:databasePath -ChildPath "Backpacks"; if (-not (Test-Path $path)) { New-Item -Path $path -ItemType Directory | Out-Null }
            $filePath = Join-Path -Path $path -ChildPath "$($dataObject.Nome).txt"
            @($dataObject.Peso, $dataObject.Espaco, $dataObject.TamanhoDesdobrado, $dataObject.TamanhoDobrado, $dataObject.ConjuntosdeBlocos) | Out-File -FilePath $filePath -Encoding UTF8
            if ($ExistingData -and $ExistingData.Nome -ne $dataObject.Nome) { Remove-Item -Path (Join-Path $path "$($ExistingData.Nome).txt") -Force }
            Write-Host "Mochila '$($dataObject.Nome)' salva com sucesso!" -ForegroundColor Green; Start-Sleep -Seconds 2
            return
        }
        if ($userAction -is [int]) {
            $lastEditedIndex = $userAction; $newValue = $null
            switch ($userAction) {
                0 { $newValue = Read-InputWithPaste -Prompt "Novo nome:" -Title "Editar Nome" -EnableStandardNav -MaxLength 36 }
                1 { $newValue = Get-InputWithFilter -Prompt "Novo peso (Exemplo: 2.50):" -Title "Editar Peso" -Mode 'decimal_backpack_weight' -EnableStandardNav }
                2 { $newValue = Get-InputWithFilter -Prompt "Novo espaco de armazenamento (Exemplo: 20):" -Title "Editar Espaco" -Mode 'numeric' -MaxLength 2 -EnableStandardNav }
                3 { 
                    $h = Get-InputWithFilter -Prompt "Tamanho Desdobrado: Horizontais?" -Title "Editar Tamanho" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav
                    if ($h -and $h -ne $global:ACTION_BACK -and $h -ne $global:ACTION_MAIN_MENU) {
                        $v = Get-InputWithFilter -Prompt "Tamanho Desdobrado: Verticais?" -Title "Editar Tamanho" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav
                        if ($v -and $v -ne $global:ACTION_BACK -and $v -ne $global:ACTION_MAIN_MENU) { $newValue = "${h}x${v}" }
                    }
                }
                4 { 
                    $h = Get-InputWithFilter -Prompt "Tamanho Dobrado: Horizontais?" -Title "Editar Tamanho" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav
                    if ($h -and $h -ne $global:ACTION_BACK -and $h -ne $global:ACTION_MAIN_MENU) {
                        $v = Get-InputWithFilter -Prompt "Tamanho Dobrado: Verticais?" -Title "Editar Tamanho" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav
                        if ($v -and $v -ne $global:ACTION_BACK -and $v -ne $global:ACTION_MAIN_MENU) { $newValue = "${h}x${v}" }
                    }
                }
                5 { $newValue = Get-InternalSetLayout -ItemTypeName "mochila" }
            }
            if ($newValue -and $newValue -ne $global:ACTION_BACK -and $newValue -ne $global:ACTION_MAIN_MENU) {
                $propName = $dataObject.psobject.Properties.Name[$userAction]; $dataObject.$propName = $newValue
            }
        }
    }
}

function Add-NewMedicalSupply {
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize
    (Get-Host).UI.RawUI.CursorSize = 0
    :medicalLoop while ($true) {
        $options = @("Analgesico", "Bandagem", "Kit cirurgico", "Nebulizador", "Kit medico", "Estimulantes")
        $selectedType = Show-Menu -Title "O que voce deseja adicionar?" -Options $options -EnableBackButton -EnableMainMenuButton
        
        if ($selectedType -eq $global:ACTION_BACK) { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $global:ACTION_BACK }
        if ($selectedType -eq $global:ACTION_MAIN_MENU) { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $global:ACTION_MAIN_MENU }
        if (-not $selectedType) { continue medicalLoop }
        $result = $null
        switch ($selectedType) {
            "Analgesico"     { $result = Add-NewPainkiller }
            "Bandagem"       { $result = Add-NewBandage }
            "Kit cirurgico"  { $result = Add-NewSurgicalKit }
            "Nebulizador"    { $result = Add-NewNebulizer }
            "Kit medico"     { $result = Add-NewMedicalKit }
            "Estimulantes"   { $result = Add-NewStimulant }
        }
        if ($result -eq $global:ACTION_MAIN_MENU) { 
            (Get-Host).UI.RawUI.CursorSize = $originalCursorSize
            return $global:ACTION_MAIN_MENU 
        }
        # Se $result for ACTION_BACK, o loop continua, mostrando o menu de novo
    }
}

function Add-NewPainkiller {
    param([PSCustomObject]$ExistingData = $null)
    if (-not $ExistingData) {
        $painkillerName = $null; $uses = $null; $duration = $null; $dehydration = $null; $delay = $null
        $step = 1
        while ($step -le 5) {
            $result = $null
            switch ($step) {
                1 { $result = Read-InputWithPaste -Prompt "Qual e o nome do analgesico?" -Title "Adicionar Analgesico" -EnableStandardNav -MaxLength 25 }
                2 { $result = Get-InputWithFilter -Prompt "Quantas vezes pode ser usado? (1-9)" -Title "Usos" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav }
                3 { $result = Get-InputWithFilter -Prompt "Qual e a duracao do efeito?" -Title "Duracao" -Mode 'numeric_no_leading_zero' -MaxLength 3 -EnableStandardNav }
                4 { $dehydrationChoice = Show-Menu -Title "Ele desidrata?" -Options @("Sim", "Nao") -EnableBackButton -EnableMainMenuButton; if($dehydrationChoice -eq 'Sim'){$result=Get-InputWithFilter -Prompt "Valor (ex:-100):" -Title "Desidratacao" -Mode 'dehydration_strict' -MaxLength 4 -EnableStandardNav} elseif($dehydrationChoice -eq 'Nao'){$result='/////'} else{$result=$dehydrationChoice} }
                5 { $result = Get-InputWithFilter -Prompt "Qual e o tempo de atraso? (ex: 1.2 ou 12.3)" -Title "Tempo de Atraso" -Mode 'decimal_fixed' -MaxLength 4 -EnableStandardNav }
            }
            if ($result -eq $global:ACTION_MAIN_MENU) { return $global:ACTION_MAIN_MENU }
            if ($result -eq $global:ACTION_BACK) { if ($step -gt 1) { $step-- } else { return $global:ACTION_BACK }; continue }
            if (-not $result) { continue }
            switch ($step) { 1 {$painkillerName=$result}; 2 {$uses=$result}; 3 {$duration=$result}; 4 {$dehydration=$result}; 5 {$delay=$result} }
            $step++
        }
    } else {
        $painkillerName = $ExistingData.Nome; $uses = $ExistingData.Uses; $duration = $ExistingData.Duration; $dehydration = $ExistingData.Dehydration; $delay = $ExistingData.Delay
    }
    $lastEditedIndex = 0
    $dataObject = [PSCustomObject]@{ Nome = $painkillerName; Uses = $uses; Duration = $duration; Dehydration = $dehydration; Delay = $delay }
    :confirmationLoop while($true) {
        $userAction = Show-GenericConfirmation -ItemData $dataObject -CategoryKey "Painkillers" -InitialSelectedIndex $lastEditedIndex
        if ($userAction -eq "CANCEL") { return }
        if ($userAction -eq "CONFIRM") {
            $path = Join-Path -Path $global:databasePath -ChildPath "Painkillers"
            $filePath = Join-Path -Path $path -ChildPath "$($dataObject.Nome).txt"
            @($dataObject.Uses, $dataObject.Duration, $dataObject.Dehydration, $dataObject.Delay) | Out-File -FilePath $filePath -Encoding UTF8
            if ($ExistingData -and $ExistingData.Nome -ne $dataObject.Nome) { Remove-Item -Path (Join-Path $path "$($ExistingData.Nome).txt") -Force }
            Write-Host "Analgesico '$($dataObject.Nome)' salvo com sucesso!" -ForegroundColor Green; Start-Sleep -Seconds 2
            return
        }
        if ($userAction -is [int]) {
            $lastEditedIndex = $userAction; $newValue = $null
            switch($userAction) {
                0 {$newValue = Read-InputWithPaste -Prompt "Novo nome:" -Title "Editar Nome" -EnableStandardNav -MaxLength 25}
                1 {$newValue = Get-InputWithFilter -Prompt "Novos usos (1-9):" -Title "Editar Usos" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav}
                2 {$newValue = Get-InputWithFilter -Prompt "Nova duracao:" -Title "Editar Duracao" -Mode 'numeric_no_leading_zero' -MaxLength 3 -EnableStandardNav}
                3 {$choice=Show-Menu -Title "Ele desidrata?" -Options @("Sim","Nao") -EnableBackButton -EnableMainMenuButton; if($choice -eq "Sim"){$newValue=Get-InputWithFilter -Prompt "Valor (ex:-100):" -Title "Desidratacao" -Mode 'dehydration_strict' -MaxLength 4 -EnableStandardNav} elseif($choice -eq "Nao"){$newValue="/////"} else{$newValue=$choice}}
                4 {$newValue = Get-InputWithFilter -Prompt "Novo tempo de atraso (ex: 1.2):" -Title "Editar Atraso" -Mode 'decimal_fixed' -MaxLength 4 -EnableStandardNav}
            }
            if ($newValue -and $newValue -ne $global:ACTION_BACK -and $newValue -ne $global:ACTION_MAIN_MENU) {
                $propToUpdate = $dataObject.psobject.Properties.Name[$userAction]
                $dataObject.$propToUpdate = $newValue
            }
        }
    }
}

function Add-NewBandage {
    param([PSCustomObject]$ExistingData = $null)
    if (-not $ExistingData) {
        $bandageName = $null; $uses = $null; $delay = $null; $durabilityCost = $null
        $step = 1
        while ($step -le 4) {
            $result = $null
            switch ($step) {
                1 { $result = Read-InputWithPaste -Prompt "Qual e o nome da bandagem?" -Title "Adicionar Bandagem" -EnableStandardNav -MaxLength 25 }
                2 { $result = Get-InputWithFilter -Prompt "Quantas vezes pode ser usado? (1-9)" -Title "Usos" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav }
                3 { $result = Get-InputWithFilter -Prompt "Qual e o tempo de atraso? (ex: 1.2 ou 12.3)" -Title "Tempo de Atraso" -Mode 'decimal_fixed' -MaxLength 4 -EnableStandardNav }
                4 { $result = Get-InputWithFilter -Prompt "Qual e o custo de durabilidade? (1-9)" -Title "Custo de Durabilidade" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav }
            }
            if ($result -eq $global:ACTION_MAIN_MENU) { return $global:ACTION_MAIN_MENU }
            if ($result -eq $global:ACTION_BACK) { if ($step -gt 1) { $step-- } else { return $global:ACTION_BACK }; continue }
            if (-not $result) { continue }
            switch ($step) { 1 {$bandageName=$result}; 2 {$uses=$result}; 3 {$delay=$result}; 4 {$durabilityCost=$result} }
            $step++
        }
    } else {
        $bandageName = $ExistingData.Nome; $uses = $ExistingData.Uses; $delay = $ExistingData.Delay; $durabilityCost = $ExistingData.DurabilityCost
    }
    $lastEditedIndex = 0
    $dataObject = [PSCustomObject]@{ Nome = $bandageName; Uses = $uses; Delay = $delay; DurabilityCost = $durabilityCost }
    :confirmationLoop while($true) {
        $userAction = Show-GenericConfirmation -ItemData $dataObject -CategoryKey "Bandages" -InitialSelectedIndex $lastEditedIndex
        if ($userAction -eq "CANCEL") { return }
        if ($userAction -eq "CONFIRM") {
            $path = Join-Path -Path $global:databasePath -ChildPath "Bandages"
            $filePath = Join-Path -Path $path -ChildPath "$($dataObject.Nome).txt"
            @($dataObject.Uses, $dataObject.Delay, $dataObject.DurabilityCost) | Out-File -FilePath $filePath -Encoding UTF8
            if ($ExistingData -and $ExistingData.Nome -ne $dataObject.Nome) { Remove-Item -Path (Join-Path $path "$($ExistingData.Nome).txt") -Force }
            Write-Host "Bandagem '$($dataObject.Nome)' salva com sucesso!" -ForegroundColor Green; Start-Sleep -Seconds 2
            return
        }
        if ($userAction -is [int]) {
            $lastEditedIndex = $userAction; $newValue = $null
            switch($userAction) {
                0 {$newValue = Read-InputWithPaste -Prompt "Novo nome:" -Title "Editar Nome" -EnableStandardNav -MaxLength 25}
                1 {$newValue = Get-InputWithFilter -Prompt "Novos usos (1-9):" -Title "Editar Usos" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav}
                2 {$newValue = Get-InputWithFilter -Prompt "Novo tempo de atraso (ex: 1.2):" -Title "Editar Atraso" -Mode 'decimal_fixed' -MaxLength 4 -EnableStandardNav}
                3 {$newValue = Get-InputWithFilter -Prompt "Novo custo (1-9):" -Title "Editar Custo" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav}
            }
            if ($newValue -and $newValue -ne $global:ACTION_BACK -and $newValue -ne $global:ACTION_MAIN_MENU) {
                $propToUpdate = $dataObject.psobject.Properties.Name[$userAction]
                $dataObject.$propToUpdate = $newValue
            }
        }
    }
}

function Add-NewSurgicalKit {
    param([PSCustomObject]$ExistingData = $null)
    if (-not $ExistingData) {
        $kitName = $null; $uses = $null; $delay = $null; $dehydration = $null; $hpRecovery = $null; $durabilityCost = $null; $space = $null
        $step = 1
        while ($step -le 7) {
            $result = $null
            switch ($step) {
                1 { $result = Read-InputWithPaste -Prompt "Qual e o nome do kit cirurgico?" -Title "Adicionar Kit Cirurgico" -EnableStandardNav -MaxLength 32 }
                2 { $result = Get-InputWithFilter -Prompt "Quantas vezes pode ser usado?" -Title "Usos" -Mode 'numeric_no_leading_zero' -MaxLength 2 -EnableStandardNav }
                3 { $result = Get-InputWithFilter -Prompt "Qual e o tempo de atraso? (ex: 12.3)" -Title "Tempo de Atraso" -Mode 'decimal_fixed' -MaxLength 4 -EnableStandardNav }
                4 { $dehydrationChoice = Show-Menu -Title "Ele desidrata?" -Options @("Sim", "Nao") -EnableBackButton -EnableMainMenuButton; if($dehydrationChoice -eq 'Sim'){$result=Get-InputWithFilter -Prompt "Valor (ex:-100):" -Title "Desidratacao" -Mode 'dehydration_strict' -MaxLength 4 -EnableStandardNav} elseif($dehydrationChoice -eq 'Nao'){$result='/////'} else{$result=$dehydrationChoice} }
                5 { $result = Get-InputWithFilter -Prompt "Qual e a recuperacao de HP?" -Title "Recuperacao de HP" -Mode 'numeric_no_leading_zero' -MaxLength 2 -EnableStandardNav }
                6 { $result = Get-InputWithFilter -Prompt "Qual e o custo de durabilidade? (1-9)" -Title "Custo de Durabilidade" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav }
                7 { $result = Get-SpaceUsage }
            }
            if ($result -eq $global:ACTION_MAIN_MENU) { return $global:ACTION_MAIN_MENU }
            if ($result -eq $global:ACTION_BACK) { if ($step -gt 1) { $step-- } else { return $global:ACTION_BACK }; continue }
            if (-not $result) { continue }
            switch ($step) { 1 {$kitName=$result}; 2 {$uses=$result}; 3 {$delay=$result}; 4 {$dehydration=$result}; 5 {$hpRecovery=$result}; 6 {$durabilityCost=$result}; 7 {$space=$result} }
            $step++
        }
    } else {
        $kitName = $ExistingData.Nome; $uses = $ExistingData.Uses; $delay = $ExistingData.Delay; $dehydration = $ExistingData.Dehydration; $hpRecovery = $ExistingData.HPRecovery; $durabilityCost = $ExistingData.DurabilityCost; $space = $ExistingData.Space
    }
    
    $lastEditedIndex = 0
    $dataObject = [PSCustomObject]@{ Nome=$kitName; Uses=$uses; Delay=$delay; Dehydration=$dehydration; HPRecovery=$hpRecovery; DurabilityCost=$durabilityCost; Space=$space }
    :confirmationLoop while($true) {
        $userAction = Show-GenericConfirmation -ItemData $dataObject -CategoryKey "Surgicalkit" -InitialSelectedIndex $lastEditedIndex
        if ($userAction -eq "CANCEL") { return }
        if ($userAction -eq "CONFIRM") {
            $path = Join-Path -Path $global:databasePath -ChildPath "Surgicalkit"
            $filePath = Join-Path -Path $path -ChildPath "$($dataObject.Nome).txt"
            @($dataObject.Uses, $dataObject.Delay, $dataObject.Dehydration, $dataObject.HPRecovery, $dataObject.DurabilityCost, $dataObject.Space) | Out-File -FilePath $filePath -Encoding UTF8
            if ($ExistingData -and $ExistingData.Nome -ne $dataObject.Nome) { Remove-Item -Path (Join-Path $path "$($ExistingData.Nome).txt") -Force }
            Write-Host "Kit Cirurgico '$($dataObject.Nome)' salvo com sucesso!" -ForegroundColor Green; Start-Sleep -Seconds 2
            return
        }
        if ($userAction -is [int]) {
            $lastEditedIndex = $userAction; $newValue = $null
            switch($userAction) {
                0 {$newValue = Read-InputWithPaste -Prompt "Novo nome:" -Title "Editar Nome" -EnableStandardNav -MaxLength 32}
                1 {$newValue = Get-InputWithFilter -Prompt "Novos usos:" -Title "Editar Usos" -Mode 'numeric_no_leading_zero' -MaxLength 2 -EnableStandardNav}
                2 {$newValue = Get-InputWithFilter -Prompt "Novo tempo de atraso (ex: 12.3):" -Title "Editar Atraso" -Mode 'decimal_fixed' -MaxLength 4 -EnableStandardNav}
                3 {$choice=Show-Menu -Title "Ele desidrata?" -Options @("Sim","Nao") -EnableBackButton -EnableMainMenuButton; if($choice -eq "Sim"){$newValue=Get-InputWithFilter -Prompt "Valor (ex:-100):" -Title "Desidratacao" -Mode 'dehydration_strict' -MaxLength 4 -EnableStandardNav} elseif($choice -eq "Nao"){$newValue="/////"} else{$newValue=$choice}}
                4 {$newValue = Get-InputWithFilter -Prompt "Nova recuperacao HP:" -Title "Editar HP" -Mode 'numeric_no_leading_zero' -MaxLength 2 -EnableStandardNav}
                5 {$newValue = Get-InputWithFilter -Prompt "Novo custo (1-9):" -Title "Editar Custo" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav}
                6 {$newValue = Get-SpaceUsage}
            }
            if ($newValue -and $newValue -ne $global:ACTION_BACK -and $newValue -ne $global:ACTION_MAIN_MENU) {
                $propToUpdate = $dataObject.psobject.Properties.Name[$userAction]
                $dataObject.$propToUpdate = $newValue
            }
        }
    }
}

function Add-NewNebulizer {
    param([PSCustomObject]$ExistingData = $null)
    if (-not $ExistingData) {
        $nebulizerName = $null; $uses = $null; $delay = $null; $durabilityCost = $null
        $step = 1
        while ($step -le 4) {
            $result = $null
            switch ($step) {
                1 { $result = Read-InputWithPaste -Prompt "Qual e o nome do nebulizador?" -Title "Adicionar Nebulizador" -EnableStandardNav -MaxLength 25 }
                2 { $result = Get-InputWithFilter -Prompt "Quantas vezes pode ser usado? (1-9)" -Title "Usos" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav }
                3 { $result = Get-InputWithFilter -Prompt "Qual e o tempo de atraso? (ex: 1.2 ou 12.3)" -Title "Tempo de Atraso" -Mode 'decimal_fixed' -MaxLength 4 -EnableStandardNav }
                4 { $result = Get-InputWithFilter -Prompt "Qual e o custo de durabilidade? (1-9)" -Title "Custo de Durabilidade" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav }
            }
            if ($result -eq $global:ACTION_MAIN_MENU) { return $global:ACTION_MAIN_MENU }
            if ($result -eq $global:ACTION_BACK) { if ($step -gt 1) { $step-- } else { return $global:ACTION_BACK }; continue }
            if (-not $result) { continue }
            switch ($step) { 1 {$nebulizerName=$result}; 2 {$uses=$result}; 3 {$delay=$result}; 4 {$durabilityCost=$result} }
            $step++
        }
    } else {
        $nebulizerName = $ExistingData.Nome; $uses = $ExistingData.Uses; $delay = $ExistingData.Delay; $durabilityCost = $ExistingData.DurabilityCost
    }
    $lastEditedIndex = 0
    $dataObject = [PSCustomObject]@{ Nome = $nebulizerName; Uses = $uses; Delay = $delay; DurabilityCost = $durabilityCost }
    :confirmationLoop while($true) {
        $userAction = Show-GenericConfirmation -ItemData $dataObject -CategoryKey "Nebulizers" -InitialSelectedIndex $lastEditedIndex
        if ($userAction -eq "CANCEL") { return }
        if ($userAction -eq "CONFIRM") {
            $path = Join-Path -Path $global:databasePath -ChildPath "Nebulizers"
            $filePath = Join-Path -Path $path -ChildPath "$($dataObject.Nome).txt"
            @($dataObject.Uses, $dataObject.Delay, $dataObject.DurabilityCost) | Out-File -FilePath $filePath -Encoding UTF8
            if ($ExistingData -and $ExistingData.Nome -ne $dataObject.Nome) { Remove-Item -Path (Join-Path $path "$($ExistingData.Nome).txt") -Force }
            Write-Host "Nebulizador '$($dataObject.Nome)' salvo com sucesso!" -ForegroundColor Green; Start-Sleep -Seconds 2
            return
        }
        if ($userAction -is [int]) {
            $lastEditedIndex = $userAction; $newValue = $null
            switch($userAction) {
                0 {$newValue = Read-InputWithPaste -Prompt "Novo nome:" -Title "Editar Nome" -EnableStandardNav -MaxLength 25}
                1 {$newValue = Get-InputWithFilter -Prompt "Novos usos (1-9):" -Title "Editar Usos" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav}
                2 {$newValue = Get-InputWithFilter -Prompt "Novo tempo de atraso (ex: 1.2):" -Title "Editar Atraso" -Mode 'decimal_fixed' -MaxLength 4 -EnableStandardNav}
                3 {$newValue = Get-InputWithFilter -Prompt "Novo custo (1-9):" -Title "Editar Custo" -Mode 'numeric_1_9' -MaxLength 1 -EnableStandardNav}
            }
            if ($newValue -and $newValue -ne $global:ACTION_BACK -and $newValue -ne $global:ACTION_MAIN_MENU) {
                $propToUpdate = $dataObject.psobject.Properties.Name[$userAction]
                $dataObject.$propToUpdate = $newValue
            }
        }
    }
}

function Add-NewMedicalKit {
    param([PSCustomObject]$ExistingData = $null)
    if (-not $ExistingData) {
        $kitName = $null; $durability = $null; $dehydration = $null; $cureSpeed = $null; $delay = $null; $durabilityCost = $null; $space = $null
        $step = 1
        while ($step -le 7) {
            $result = $null
            switch ($step) {
                1 { $result = Read-InputWithPaste -Prompt "Qual e o nome do kit medico?" -Title "Adicionar Kit Medico" -EnableStandardNav -MaxLength 25 }
                2 { $result = Get-InputWithFilter -Prompt "Qual e a durabilidade do kit?" -Title "Durabilidade" -Mode 'numeric_no_leading_zero' -MaxLength 4 -EnableStandardNav }
                3 { $dehydrationChoice = Show-Menu -Title "Ele desidrata?" -Options @("Sim", "Nao") -EnableBackButton -EnableMainMenuButton; if($dehydrationChoice -eq 'Sim'){$result=Get-InputWithFilter -Prompt "Valor (ex:-100):" -Title "Desidratacao" -Mode 'dehydration_strict' -MaxLength 4 -EnableStandardNav} elseif($dehydrationChoice -eq 'Nao'){$result='/////'} else{$result=$dehydrationChoice} }
                4 { $result = Get-InputWithFilter -Prompt "Qual e a velocidade de cura?" -Title "Velocidade de Cura" -Mode 'numeric_no_leading_zero' -MaxLength 2 -EnableStandardNav }
                5 { $result = Get-InputWithFilter -Prompt "Qual e o tempo de atraso? (ex: 1.2 ou 12.3)" -Title "Tempo de Atraso" -Mode 'decimal_fixed' -MaxLength 4 -EnableStandardNav }
                6 { $result = Get-InputWithFilter -Prompt "Qual e o custo de durabilidade?" -Title "Custo de Durabilidade" -Mode 'numeric_allow_zero_single' -MaxLength 2 -EnableStandardNav }
                7 { $result = Get-SpaceUsage }
            }
            if ($result -eq $global:ACTION_MAIN_MENU) { return $global:ACTION_MAIN_MENU }
            if ($result -eq $global:ACTION_BACK) { if ($step -gt 1) { $step-- } else { return $global:ACTION_BACK }; continue }
            if (-not $result) { continue }
            switch ($step) { 1 {$kitName=$result}; 2 {$durability=$result}; 3 {$dehydration=$result}; 4 {$cureSpeed=$result}; 5 {$delay=$result}; 6 {$durabilityCost=$result}; 7 {$space=$result} }
            $step++
        }
    } else {
        $kitName = $ExistingData.Nome; $durability = $ExistingData.Durability; $dehydration = $ExistingData.Dehydration; $cureSpeed = $ExistingData.CureSpeed; $delay = $ExistingData.Delay; $durabilityCost = $ExistingData.DurabilityCost; $space = $ExistingData.Space
    }
    
    $lastEditedIndex = 0
    $dataObject = [PSCustomObject]@{ Nome=$kitName; Durability=$durability; Dehydration=$dehydration; CureSpeed=$cureSpeed; Delay=$delay; DurabilityCost=$durabilityCost; Space=$space }
    :confirmationLoop while($true) {
        $userAction = Show-GenericConfirmation -ItemData $dataObject -CategoryKey "Medicalkit" -InitialSelectedIndex $lastEditedIndex
        if ($userAction -eq "CANCEL") { return }
        if ($userAction -eq "CONFIRM") {
            $path = Join-Path -Path $global:databasePath -ChildPath "Medicalkit"
            $filePath = Join-Path -Path $path -ChildPath "$($dataObject.Nome).txt"
            @($dataObject.Durability, $dataObject.Dehydration, $dataObject.CureSpeed, $dataObject.Delay, $dataObject.DurabilityCost, $dataObject.Space) | Out-File -FilePath $filePath -Encoding UTF8
            if ($ExistingData -and $ExistingData.Nome -ne $dataObject.Nome) { Remove-Item -Path (Join-Path $path "$($ExistingData.Nome).txt") -Force }
            Write-Host "Kit Medico '$($dataObject.Nome)' salvo com sucesso!" -ForegroundColor Green; Start-Sleep -Seconds 2
            return
        }
        if ($userAction -is [int]) {
            $lastEditedIndex = $userAction; $newValue = $null
            switch($userAction) {
                0 {$newValue = Read-InputWithPaste -Prompt "Novo nome:" -Title "Editar Nome" -EnableStandardNav -MaxLength 25}
                1 {$newValue = Get-InputWithFilter -Prompt "Nova durabilidade:" -Title "Editar Durabilidade" -Mode 'numeric_no_leading_zero' -MaxLength 4 -EnableStandardNav}
                2 {$choice=Show-Menu -Title "Ele desidrata?" -Options @("Sim","Nao") -EnableBackButton -EnableMainMenuButton; if($choice -eq "Sim"){$newValue=Get-InputWithFilter -Prompt "Valor (ex:-100):" -Title "Desidratacao" -Mode 'dehydration_strict' -MaxLength 4 -EnableStandardNav} elseif($choice -eq "Nao"){$newValue="/////"} else{$newValue=$choice}}
                3 {$newValue = Get-InputWithFilter -Prompt "Nova velocidade de cura:" -Title "Editar Vel. Cura" -Mode 'numeric_no_leading_zero' -MaxLength 2 -EnableStandardNav}
                4 {$newValue = Get-InputWithFilter -Prompt "Novo delay (ex: 1.2):" -Title "Editar Delay" -Mode 'decimal_fixed' -MaxLength 4 -EnableStandardNav}
                5 {$newValue = Get-InputWithFilter -Prompt "Novo custo:" -Title "Editar Custo" -Mode 'numeric_allow_zero_single' -MaxLength 2 -EnableStandardNav}
                6 {$newValue = Get-SpaceUsage}
            }
            if ($newValue -and $newValue -ne $global:ACTION_BACK -and $newValue -ne $global:ACTION_MAIN_MENU) {
                $propToUpdate = $dataObject.psobject.Properties.Name[$userAction]
                $dataObject.$propToUpdate = $newValue
            }
        }
    }
}

function Add-NewStimulant {
    param([PSCustomObject]$ExistingData = $null)
    if (-not $ExistingData) {
        $stimulantName=$null; $mainEffect=$null; $duration=$null; $dehydration=$null; $energyReduction=$null; $delay=$null
        $step = 1
        while ($step -le 6) {
            $result = $null
            switch ($step) {
                1 { $result = Read-InputWithPaste -Prompt "Qual e o nome do estimulante?" -Title "Adicionar Estimulante" -EnableStandardNav -MaxLength 25 }
                2 { $rawResult = Show-Menu -Title "Qual e o efeito principal?" -Options @("Stamina melhorada", "Forca melhorada", "Regeneracao continua") -EnableBackButton -EnableMainMenuButton; if($rawResult -and $rawResult-ne $global:ACTION_BACK -and $rawResult-ne $global:ACTION_MAIN_MENU){$result=switch($rawResult){"Stamina melhorada"{"Stamina"};"Forca melhorada"{"Strength"};"Regeneracao continua"{"Regeneration"}}}else{$result=$rawResult} }
                3 { $result = Get-InputWithFilter -Prompt "Qual e a duracao do efeito?" -Title "Duracao" -Mode 'numeric_no_leading_zero' -MaxLength 3 -EnableStandardNav }
                4 { $dehydrationChoice = Show-Menu -Title "Ele desidrata?" -Options @("Sim", "Nao") -EnableBackButton -EnableMainMenuButton; if($dehydrationChoice -eq 'Sim'){$result=Get-InputWithFilter -Prompt "Valor (ex:-100):" -Title "Desidratacao" -Mode 'dehydration_strict' -MaxLength 4 -EnableStandardNav} elseif($dehydrationChoice -eq 'Nao'){$result='/////'} else{$result=$dehydrationChoice} }
                5 { $result = Get-InputWithFilter -Prompt "Qual e a reducao de energia? (ex: -10)" -Title "Reducao de Energia" -Mode 'energy_negative_only' -MaxLength 3 -EnableStandardNav }
                6 { $result = Get-InputWithFilter -Prompt "Qual e o tempo de atraso? (ex: 1.2 ou 12.3)" -Title "Tempo de Atraso" -Mode 'decimal_fixed' -MaxLength 4 -EnableStandardNav }
            }
            if ($result -eq $global:ACTION_MAIN_MENU) { return $global:ACTION_MAIN_MENU }
            if ($result -eq $global:ACTION_BACK) { if ($step -gt 1) { $step-- } else { return $global:ACTION_BACK }; continue }
            if (-not $result) { continue }
            switch ($step) { 1 {$stimulantName=$result}; 2 {$mainEffect=$result}; 3 {$duration=$result}; 4 {$dehydration=$result}; 5 {$energyReduction=$result}; 6 {$delay=$result} }
            $step++
        }
    } else {
        $stimulantName = $ExistingData.Nome; $mainEffect = $ExistingData.MainEffect; $duration = $ExistingData.Duration; $dehydration = $ExistingData.Dehydration; $energyReduction = $ExistingData.EnergyReduction; $delay = $ExistingData.Delay
    }
    $lastEditedIndex = 0
    $dataObject = [PSCustomObject]@{ Nome=$stimulantName; MainEffect=$mainEffect; Duration=$duration; Dehydration=$dehydration; EnergyReduction=$energyReduction; Delay=$delay }
    :confirmationLoop while($true) {
        $userAction = Show-GenericConfirmation -ItemData $dataObject -CategoryKey "Stimulants" -InitialSelectedIndex $lastEditedIndex
        if ($userAction -eq "CANCEL") { return }
        if ($userAction -eq "CONFIRM") {
            $path = Join-Path -Path $global:databasePath -ChildPath "Stimulants"
            $filePath = Join-Path -Path $path -ChildPath "$($dataObject.Nome).txt"
            @($dataObject.MainEffect, $dataObject.Duration, $dataObject.Dehydration, $dataObject.EnergyReduction, $dataObject.Delay) | Out-File -FilePath $filePath -Encoding UTF8
            if ($ExistingData -and $ExistingData.Nome -ne $dataObject.Nome) { Remove-Item -Path (Join-Path $path "$($ExistingData.Nome).txt") -Force }
            Write-Host "Estimulante '$($dataObject.Nome)' salvo com sucesso!" -ForegroundColor Green; Start-Sleep -Seconds 2
            return
        }
        if ($userAction -is [int]) {
            $lastEditedIndex = $userAction; $newValue = $null
            switch ($userAction) {
                0 {$newValue = Read-InputWithPaste -Prompt "Novo nome:" -Title "Editar Nome" -EnableStandardNav -MaxLength 25}
                1 {$raw=Show-Menu -Title "Efeito principal?" -Options @("Stamina melhorada","Forca melhorada","Regeneracao continua") -EnableBackButton -EnableMainMenuButton;if($raw -and $raw -ne $global:ACTION_BACK -and $raw -ne $global:ACTION_MAIN_MENU){$newValue=switch($raw){"Stamina melhorada"{"Stamina"};"Forca melhorada"{"Strength"};"Regeneracao continua"{"Regeneration"}}}else{$newValue=$raw}}
                2 {$newValue = Get-InputWithFilter -Prompt "Nova duracao:" -Title "Editar Duracao" -Mode 'numeric_no_leading_zero' -MaxLength 3 -EnableStandardNav}
                3 {$choice=Show-Menu -Title "Ele desidrata?" -Options @("Sim","Nao") -EnableBackButton -EnableMainMenuButton; if($choice -eq "Sim"){$newValue=Get-InputWithFilter -Prompt "Valor (ex:-100):" -Title "Desidratacao" -Mode 'dehydration_strict' -MaxLength 4 -EnableStandardNav} elseif($choice -eq "Nao"){$newValue="/////"} else{$newValue=$choice}}
                4 {$newValue = Get-InputWithFilter -Prompt "Nova reducao de energia (ex: -10):" -Title "Editar Energia" -Mode 'energy_negative_only' -MaxLength 3 -EnableStandardNav}
                5 {$newValue = Get-InputWithFilter -Prompt "Novo delay (ex: 1.2):" -Title "Editar Delay" -Mode 'decimal_fixed' -MaxLength 4 -EnableStandardNav}
            }
            if ($newValue -and $newValue -ne $global:ACTION_BACK -and $newValue -ne $global:ACTION_MAIN_MENU) {
                $propToUpdate = $dataObject.psobject.Properties.Name[$userAction]
                $dataObject.$propToUpdate = $newValue
            }
        }
    }
}

function Add-NewFoodOrDrink {
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize
    (Get-Host).UI.RawUI.CursorSize = 0
    :typeLoop while ($true) {
        $type = Show-Menu -Title "O que voce deseja adicionar?" -Options @("Bebida", "Comida") -EnableBackButton -EnableMainMenuButton
        
        if ($type -eq $global:ACTION_BACK) { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $global:ACTION_BACK }
        if ($type -eq $global:ACTION_MAIN_MENU) { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return $global:ACTION_MAIN_MENU }
        if (-not $type) { continue typeLoop }
        $result = $null
        switch ($type) {
            "Bebida"  { $result = Add-NewBeverage }
            "Comida"  { $result = Add-NewFood }
        }
        
        if ($result -eq $global:ACTION_MAIN_MENU) { 
            (Get-Host).UI.RawUI.CursorSize = $originalCursorSize
            return $global:ACTION_MAIN_MENU 
        }
    }
}

function Add-NewBeverage {
    param([PSCustomObject]$ExistingData = $null)
    if (-not $ExistingData) {
        $beverageName=$null; $hydration=$null; $energy=$null; $delay=$null; $staminaRecovery=$null; $space=$null
        $step = 1
        while ($step -le 6) {
            $result = $null
            switch ($step) {
                1 { $result = Read-InputWithPaste -Prompt "Qual e o nome da bebida?" -Title "Adicionar Bebida" -EnableStandardNav -MaxLength 35 }
                2 { $result = Get-InputWithFilter -Prompt "Qual e a hidratacao? (Ex: 0, +50, -100)" -Title "Hidratacao" -Mode 'hydration_strict' -MaxLength 4 -EnableStandardNav }
                3 { $result = Get-InputWithFilter -Prompt "Qual e a energia? (Ex: 0, +50, -100)" -Title "Energia" -Mode 'hydration_strict' -MaxLength 4 -EnableStandardNav }
                4 { $result = Get-InputWithFilter -Prompt "Qual e o tempo de atraso? (ex: 1.2 ou 12.3)" -Title "Tempo de Atraso" -Mode 'decimal_fixed' -MaxLength 4 -EnableStandardNav }
                5 { $rawResult=Show-Menu -Title "Recuperacao de stamina?" -Options @("Baixo","Medio","Alto","Nenhum") -EnableBackButton -EnableMainMenuButton; if($rawResult-and $rawResult-ne $global:ACTION_BACK -and $rawResult-ne $global:ACTION_MAIN_MENU){$result=switch($rawResult){"Baixo"{"Low"};"Medio"{"Medium"};"Alto"{"High"};"Nenhum"{"None"}}}else{$result=$rawResult}}
                6 { $result = Get-SpaceUsage }
            }
            if ($result -eq $global:ACTION_MAIN_MENU) { return $global:ACTION_MAIN_MENU }
            if ($result -eq $global:ACTION_BACK) { if ($step -gt 1) { $step-- } else { return $global:ACTION_BACK }; continue }
            if (-not $result) { continue }
            switch ($step) { 1 {$beverageName=$result}; 2 {$hydration=$result}; 3 {$energy=$result}; 4 {$delay=$result}; 5 {$staminaRecovery=$result}; 6 {$space=$result} }
            $step++
        }
    } else {
        $beverageName = $ExistingData.Nome; $hydration = $ExistingData.Hydration; $energy = $ExistingData.Energy; $delay = $ExistingData.Delay; $staminaRecovery = $ExistingData.StaminaRecovery; $space = $ExistingData.Space
    }
    
    $lastEditedIndex = 0
    $dataObject = [PSCustomObject]@{ Nome=$beverageName; Hydration=$hydration; Energy=$energy; Delay=$delay; StaminaRecovery=$staminaRecovery; Space=$space }
    :confirmationLoop while($true) {
        $userAction = Show-GenericConfirmation -ItemData $dataObject -CategoryKey "Beverages" -InitialSelectedIndex $lastEditedIndex
        if ($userAction -eq "CANCEL") { return }
        if ($userAction -eq "CONFIRM") {
            $path = Join-Path -Path $global:databasePath -ChildPath "Beverages"
            $filePath = Join-Path -Path $path -ChildPath "$($dataObject.Nome).txt"
            @($dataObject.Hydration, $dataObject.Energy, $dataObject.Delay, $dataObject.StaminaRecovery, $dataObject.Space) | Out-File -FilePath $filePath -Encoding UTF8
            if ($ExistingData -and $ExistingData.Nome -ne $dataObject.Nome) { Remove-Item -Path (Join-Path $path "$($ExistingData.Nome).txt") -Force }
            Write-Host "Bebida '$($dataObject.Nome)' salva com sucesso!" -ForegroundColor Green; Start-Sleep -Seconds 2
            return
        }
        if ($userAction -is [int]) {
            $lastEditedIndex = $userAction; $newValue = $null
            switch ($userAction) {
                0 {$newValue = Read-InputWithPaste -Prompt "Novo nome:" -Title "Editar Nome" -EnableStandardNav -MaxLength 35 }
                1 {$newValue = Get-InputWithFilter -Prompt "Nova hidratacao:" -Title "Hidratacao" -Mode 'hydration_strict' -MaxLength 4 -EnableStandardNav}
                2 {$newValue = Get-InputWithFilter -Prompt "Nova energia:" -Title "Energia" -Mode 'hydration_strict' -MaxLength 4 -EnableStandardNav}
                3 {$newValue = Get-InputWithFilter -Prompt "Novo delay (ex: 1.2):" -Title "Delay" -Mode 'decimal_fixed' -MaxLength 4 -EnableStandardNav}
                4 {$raw=Show-Menu -Title "Rec. Stamina?" -Options @("Baixo","Medio","Alto","Nenhum") -EnableBackButton -EnableMainMenuButton;if($raw-and $raw-ne $global:ACTION_BACK -and $raw-ne $global:ACTION_MAIN_MENU){$newValue=switch($raw){"Baixo"{"Low"};"Medio"{"Medium"};"Alto"{"High"};"Nenhum"{"None"}}}else{$newValue=$raw}}
                5 {$newValue = Get-SpaceUsage}
            }
            if ($newValue -and $newValue -ne $global:ACTION_BACK -and $newValue -ne $global:ACTION_MAIN_MENU) {
                $propToUpdate = $dataObject.psobject.Properties.Name[$userAction]
                $dataObject.$propToUpdate = $newValue
            }
        }
    }
}

function Add-NewFood {
    param([PSCustomObject]$ExistingData = $null)
    if (-not $ExistingData) {
        $foodName=$null; $hydration=$null; $energy=$null; $delay=$null; $staminaRecovery=$null; $space=$null
        $step = 1
        while ($step -le 6) {
            $result = $null
            switch ($step) {
                1 { $result = Read-InputWithPaste -Prompt "Qual e o nome da comida?" -Title "Adicionar Comida" -EnableStandardNav -MaxLength 35 }
                2 { $result = Get-InputWithFilter -Prompt "Qual e a hidratacao? (Ex: 0, +50, -100)" -Title "Hidratacao" -Mode 'hydration_strict' -MaxLength 4 -EnableStandardNav }
                3 { $result = Get-InputWithFilter -Prompt "Qual e a energia? (Ex: 0, +50, -100)" -Title "Energia" -Mode 'hydration_strict' -MaxLength 4 -EnableStandardNav }
                4 { $result = Get-InputWithFilter -Prompt "Qual e o tempo de atraso? (ex: 1.2 ou 12.3)" -Title "Tempo de Atraso" -Mode 'decimal_fixed' -MaxLength 4 -EnableStandardNav }
                5 { $rawResult=Show-Menu -Title "Recuperacao de stamina?" -Options @("Baixo","Medio","Alto","Nenhum") -EnableBackButton -EnableMainMenuButton; if($rawResult-and $rawResult-ne $global:ACTION_BACK -and $rawResult-ne $global:ACTION_MAIN_MENU){$result=switch($rawResult){"Baixo"{"Low"};"Medio"{"Medium"};"Alto"{"High"};"Nenhum"{"None"}}}else{$result=$rawResult}}
                6 { $result = Get-SpaceUsage }
            }
            if ($result -eq $global:ACTION_MAIN_MENU) { return $global:ACTION_MAIN_MENU }
            if ($result -eq $global:ACTION_BACK) { if ($step -gt 1) { $step-- } else { return $global:ACTION_BACK }; continue }
            if (-not $result) { continue }
            switch ($step) { 1 {$foodName=$result}; 2 {$hydration=$result}; 3 {$energy=$result}; 4 {$delay=$result}; 5 {$staminaRecovery=$result}; 6 {$space=$result} }
            $step++
        }
    } else {
        $foodName = $ExistingData.Nome; $hydration = $ExistingData.Hydration; $energy = $ExistingData.Energy; $delay = $ExistingData.Delay; $staminaRecovery = $ExistingData.StaminaRecovery; $space = $ExistingData.Space
    }
    $lastEditedIndex = 0
    $dataObject = [PSCustomObject]@{ Nome=$foodName; Hydration=$hydration; Energy=$energy; Delay=$delay; StaminaRecovery=$staminaRecovery; Space=$space }
    :confirmationLoop while($true) {
        $userAction = Show-GenericConfirmation -ItemData $dataObject -CategoryKey "Food" -InitialSelectedIndex $lastEditedIndex
        if ($userAction -eq "CANCEL") { return }
        if ($userAction -eq "CONFIRM") {
            $path = Join-Path -Path $global:databasePath -ChildPath "Food"
            $filePath = Join-Path -Path $path -ChildPath "$($dataObject.Nome).txt"
            @($dataObject.Hydration, $dataObject.Energy, $dataObject.Delay, $dataObject.StaminaRecovery, $dataObject.Space) | Out-File -FilePath $filePath -Encoding UTF8
            if ($ExistingData -and $ExistingData.Nome -ne $dataObject.Nome) { Remove-Item -Path (Join-Path $path "$($ExistingData.Nome).txt") -Force }
            Write-Host "Comida '$($dataObject.Nome)' salva com sucesso!" -ForegroundColor Green; Start-Sleep -Seconds 2
            return
        }
        if ($userAction -is [int]) {
            $lastEditedIndex = $userAction; $newValue = $null
            switch ($userAction) {
                0 {$newValue = Read-InputWithPaste -Prompt "Novo nome:" -Title "Editar Nome" -EnableStandardNav -MaxLength 35}
                1 {$newValue = Get-InputWithFilter -Prompt "Nova hidratacao:" -Title "Hidratacao" -Mode 'hydration_strict' -MaxLength 4 -EnableStandardNav}
                2 {$newValue = Get-InputWithFilter -Prompt "Nova energia:" -Title "Energia" -Mode 'hydration_strict' -MaxLength 4 -EnableStandardNav}
                3 {$newValue = Get-InputWithFilter -Prompt "Novo delay (ex: 1.2):" -Title "Delay" -Mode 'decimal_fixed' -MaxLength 4 -EnableStandardNav}
                4 {$raw=Show-Menu -Title "Rec. Stamina?" -Options @("Baixo","Medio","Alto","Nenhum") -EnableBackButton -EnableMainMenuButton;if($raw-and $raw-ne $global:ACTION_BACK -and $raw-ne $global:ACTION_MAIN_MENU){$newValue=switch($raw){"Baixo"{"Low"};"Medio"{"Medium"};"Alto"{"High"};"Nenhum"{"None"}}}else{$newValue=$raw}}
                5 {$newValue = Get-SpaceUsage}
            }
            if ($newValue -and $newValue -ne $global:ACTION_BACK -and $newValue -ne $global:ACTION_MAIN_MENU) {
                $propToUpdate = $dataObject.psobject.Properties.Name[$userAction]
                $dataObject.$propToUpdate = $newValue
            }
        }
    }
}

function Edit-Items {
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize
    (Get-Host).UI.RawUI.CursorSize = 0
    $lastCategoryIndex = 0; $lastCaliberIndex = 0; $lastAmmoIndex = 0; $lastWeaponClassIndex = 0; $lastWeaponIndex = 0; $lastItemIndex = 0
    :mainLoop while ($true) {
        # toda vez que o menu principal de categorias é exibido. Isso resolve o bug da "posição esquisita".
        $lastCategoryIndex = 0
        $lastCaliberIndex = 0
        $lastAmmoIndex = 0
        $lastWeaponClassIndex = 0
        $lastWeaponIndex = 0
        $lastItemIndex = 0
        $editViewOrder = @(
            "Ammo", "Painkillers", "Weapons", "Throwables", "Bandages", "Beverages", 
            "Helmets", "Bodyarmors", "Armoredrigs", "Masks", "Gasmasks", "Headsets", "Unarmoredrigs", "Backpacks", "Food", "Stimulants", "Surgicalkit", "Medicalkit", "Nebulizers"
        )
        $menuOptions = ($editViewOrder | ForEach-Object { $global:ItemCategoryConfig[$_].EditViewMenuName } | Sort-Object)
        
        $selectedDisplayName = Show-Menu -Title "Editar Itens - Selecione a Categoria" -Options $menuOptions -FlickerFree -EnableF1BackButton -InitialSelectedIndex $lastCategoryIndex
        
        if ($selectedDisplayName -eq $global:ACTION_BACK -or -not $selectedDisplayName) {
            (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return
        }
        $lastCategoryIndex = [array]::IndexOf($menuOptions, $selectedDisplayName)
        $selectedCategoryKey = ($global:ItemCategoryConfig.GetEnumerator() | Where-Object { $_.Value.EditViewMenuName -eq $selectedDisplayName }).Name
        $config = $global:ItemCategoryConfig[$selectedCategoryKey]
        $continueMainLoop = $false
        :itemSelectionLoop while($true) {
            if ($continueMainLoop) { break }
            $selectedItemName = $null; $itemFilePath = $null; $dataObject = $null
            if ($selectedCategoryKey -eq "Ammo") {
                :ammoCategoryLoop while ($true) {
                    $calibers = Get-ChildItem -Path $AmmoPath -Directory | Select-Object -ExpandProperty Name | Sort-Object
                    $selectedCaliber = Show-Menu -Title "Selecione o calibre para editar" -Options $calibers -EnableF1BackButton
                    if ($selectedCaliber -eq $global:ACTION_BACK -or -not $selectedCaliber) { $continueMainLoop = $true; break }
                    $lastCaliberIndex = [array]::IndexOf($calibers, $selectedCaliber)
                    
                    $lastAmmoIndex = 0
                    
                    :ammoEditLoop while($true) {
                        $ammoFiles = Get-ChildItem -Path (Join-Path $AmmoPath $selectedCaliber) -Filter "*.txt" -File
                        if (-not $ammoFiles) { Write-Host "Nenhuma municao encontrada." -ForegroundColor Yellow; Start-Sleep -Seconds 2; continue ammoCategoryLoop }
                        $ammoOptions = ($ammoFiles | Select-Object -ExpandProperty BaseName | Sort-Object)
                        $selectedItemName = Show-Menu -Title "Selecione a municao para editar ($selectedCaliber)" -Options $ammoOptions -EnableF1BackButton -InitialSelectedIndex $lastAmmoIndex -F1HelpOnTop
                        if ($selectedItemName -eq $global:ACTION_BACK -or -not $selectedItemName) { continue ammoCategoryLoop }
                        $lastAmmoIndex = [array]::IndexOf($ammoOptions, $selectedItemName)
                        $itemFilePath = Join-Path -Path (Join-Path $AmmoPath $selectedCaliber) -ChildPath "$selectedItemName.txt"
                        
                        $actionMenu = Show-Menu -Title "O que deseja fazer com '$selectedItemName'?" -Options @("Editar", "Apagar") -FlickerFree -EnableF1BackButton
                        if ($actionMenu -eq $global:ACTION_BACK -or -not $actionMenu) { 
                            continue ammoEditLoop 
                        }
                        
                        if ($actionMenu -eq 'Editar') {
                            $currentData = Get-Content -Path $itemFilePath
                            $propNames = "NiveldePenetracao", "Penetracao", "DanoBase", "Danodeblindagem", "Velocidade", "Precisao", "RecuoVertical", "RecuoHorizontal", "ChanceFerir"
                            $dataObject = [PSCustomObject]@{ Nome = $selectedItemName; Calibre = $selectedCaliber }
                            for ($i=0; $i -lt $propNames.Length; $i++) { if ($i -lt $currentData.Length) { $dataObject | Add-Member -Name $propNames[$i] -Value $currentData[$i] -MemberType NoteProperty } }
                            & $config.EditFunction -ExistingData $dataObject
                            continue ammoEditLoop
                        }
                        break ammoEditLoop
                    }
                    if ($actionMenu -eq 'Apagar') { break ammoCategoryLoop }
                }
            } elseif ($selectedCategoryKey -eq "Weapons") {
                :classSelectionLoop while ($true) {
                    $itemPath = Join-Path -Path $global:databasePath -ChildPath $config.PathName
                    
                    $translatedClasses = $weaponClasses | ForEach-Object { $global:WeaponClassToPortugueseMap[$_] } | Sort-Object
                    $selectedClassDisplay = Show-Menu -Title "Selecione a classe da arma para editar" -Options $translatedClasses -FlickerFree -EnableF1BackButton
                    if ($selectedClassDisplay -eq $global:ACTION_BACK -or -not $selectedClassDisplay) { $continueMainLoop = $true; break }
                    
                    $selectedClass = $global:PortugueseToWeaponClassMap[$selectedClassDisplay]
                    $lastWeaponClassIndex = [array]::IndexOf($translatedClasses, $selectedClassDisplay)
                    $lastWeaponIndex = 0
                    :weaponSelectionLoop while ($true) {
                        $weaponFilesInClass = Get-ChildItem -Path $itemPath -Filter "*.txt" -File | Where-Object { (Get-Content $_.FullName -TotalCount 1) -eq $selectedClass }
                        if (-not $weaponFilesInClass) { Write-Host "Nenhuma arma encontrada nesta classe." -ForegroundColor Yellow; Start-Sleep -Seconds 2; continue classSelectionLoop }
                        $weaponOptions = ($weaponFilesInClass | Select-Object -ExpandProperty BaseName | Sort-Object)
                        $selectedItemName = Show-Menu -Title "Selecione o item para editar ($selectedClassDisplay)" -Options $weaponOptions -EnableF1BackButton -InitialSelectedIndex $lastWeaponIndex -F1HelpOnTop
                        if ($selectedItemName -eq $global:ACTION_BACK -or -not $selectedItemName) { continue classSelectionLoop }
                        $lastWeaponIndex = [array]::IndexOf($weaponOptions, $selectedItemName)
                        $itemFilePath = Join-Path -Path $itemPath -ChildPath "$selectedItemName.txt"
                        
                        $actionMenu = Show-Menu -Title "O que deseja fazer com '$selectedItemName'?" -Options @("Editar", "Apagar") -FlickerFree -EnableF1BackButton
                        if ($actionMenu -eq $global:ACTION_BACK -or -not $actionMenu) { 
                            continue weaponSelectionLoop 
                        }
                        
                        if ($actionMenu -eq 'Editar') {
                            $currentData = Get-Content -Path $itemFilePath
                            $propNames = "Classe", "Calibre", "VerticalRecoil", "HorizontalRecoil", "Ergonomia", "Precisao", "Estabilidade", "Alcance", "Velocidade", "ModoDisparo", "Cadencia", "PoderFogo", "Cano", "EstabilidadeArma"
                            $dataObject = [PSCustomObject]@{ Nome = $selectedItemName }
                            for ($i=0; $i -lt $propNames.Length; $i++) { if ($i -lt $currentData.Length) { $dataObject | Add-Member -Name $propNames[$i] -Value $currentData[$i] -MemberType NoteProperty } }
                            & $config.EditFunction -ExistingData $dataObject
                            continue weaponSelectionLoop
                        }
                        break classSelectionLoop 
                    }
                    if ($actionMenu -eq 'Apagar') { break classSelectionLoop }
                }
            } else { # Para categorias genéricas como Capacetes, Coletes, etc.
                $itemPath = Join-Path -Path $global:databasePath -ChildPath $config.PathName
                $itemFiles = Get-ChildItem -Path $itemPath -Filter "*.txt" -File
                if (-not $itemFiles) { Write-Host "Nenhum item encontrado para editar." -ForegroundColor Yellow; Start-Sleep -Seconds 2; $continueMainLoop = $true; break }
                $itemOptions = ($itemFiles | Select-Object -ExpandProperty BaseName | Sort-Object)
                $selectedItemName = Show-Menu -Title "Selecione o item para editar ($($config.EditViewMenuName))" -Options $itemOptions -EnableF1BackButton -InitialSelectedIndex $lastItemIndex -F1HelpOnTop
                if ($selectedItemName -eq $global:ACTION_BACK -or -not $selectedItemName) { $continueMainLoop = $true; break }
                $lastItemIndex = [array]::IndexOf($itemOptions, $selectedItemName)
                $itemFilePath = Join-Path -Path $itemPath -ChildPath "$selectedItemName.txt"
                
                $actionMenu = Show-Menu -Title "O que deseja fazer com '$selectedItemName'?" -Options @("Editar", "Apagar") -FlickerFree -EnableF1BackButton
                if ($actionMenu -eq $global:ACTION_BACK -or -not $actionMenu) { continue itemSelectionLoop }
            }
            if ($continueMainLoop) { break }
            if ($actionMenu -eq "Apagar") {
                $confirm = Show-Menu -Title "CONFIRMAR EXCLUSAO" -Options @("Nao, cancelar", "Sim, apagar '$selectedItemName'") -FlickerFree
                if ($confirm -eq "Sim, apagar '$selectedItemName'") {
                    Remove-Item -Path $itemFilePath -Force
                    Write-Host "Item removido com sucesso!" -ForegroundColor Green; Start-Sleep -Seconds 1
                    $lastItemIndex = 0; $lastAmmoIndex = 0; $lastWeaponIndex = 0
                }
                continue itemSelectionLoop
            }
            # Este bloco só é alcançado pela categoria 'else' genérica
            $currentData = Get-Content -Path $itemFilePath
            $propNames = @()
            switch ($selectedCategoryKey) {
                "Helmets"    { $propNames = "Weight", "Durability", "ArmorClass", "Material", "SoundBlocking", "MovementSpeed", "Ergonomics", "ProtectedArea", "RicochetChance", "Headset", "SoundPickup", "NoiseReduction", "Accessory"; $dataObject = [PSCustomObject]@{ Nome = $selectedItemName } }
                "Throwables" { $propNames = "ExplosionDelay", "Range", "ArmorDamage", "Penetration", "Fragments", "FragmentType", "EffectTime"; $dataObject = [PSCustomObject]@{ Nome = $selectedItemName } }
                "Bodyarmors" { $propNames = "Peso", "Durabilidade", "ClassedeBlindagem", "Material", "VelocidadedeMovimento", "Ergonomia", "AreaProtegida"; $dataObject = [PSCustomObject]@{ Nome = $selectedItemName } }
                "Armoredrigs" { $propNames = "Peso", "Durabilidade", "ClassedeBlindagem", "Material", "VelocidadedeMovimento", "Ergonomia", "EspacodeArmazenamento", "AreaProtegida", "ConjuntosdeBlocos"; $dataObject = [PSCustomObject]@{ Nome = $selectedItemName } } 
                "Masks" { $propNames = "Peso", "Durabilidade", "Classe", "Material", "ChancedeRicochete"; $dataObject = [PSCustomObject]@{ Nome = $selectedItemName } }
                "Gasmasks" { $propNames = "Peso", "Durabilidade", "AntiVeneno", "AntiFlash"; $dataObject = [PSCustomObject]@{ Nome = $selectedItemName } }
                "Headsets" { $propNames = "Peso", "CaptadordeSom", "ReducaodeRuido"; $dataObject = [PSCustomObject]@{ Nome = $selectedItemName } }
                "Unarmoredrigs" { $propNames = "Peso", "Espaco", "TamanhoDesdobrado", "TamanhoDobrado", "ConjuntosdeBlocos"; $dataObject = [PSCustomObject]@{ Nome = $selectedItemName } } 
                "Backpacks" { $propNames = "Peso", "Espaco", "TamanhoDesdobrado", "TamanhoDobrado", "ConjuntosdeBlocos"; $dataObject = [PSCustomObject]@{ Nome = $selectedItemName } } 
                default      { $propNames = $config.Properties.PropName; $dataObject = [PSCustomObject]@{ Nome = $selectedItemName } }
            }
            for ($i=0; $i -lt $propNames.Length; $i++) { if ($i -lt $currentData.Length) { $dataObject | Add-Member -Name $propNames[$i] -Value $currentData[$i] -MemberType NoteProperty } }
            
            & $config.EditFunction -ExistingData $dataObject
            continue itemSelectionLoop
        }
    }
}

function Manage-Calibers {
    :mainCaliberLoop while ($true) {
        $calibers = Get-ChildItem -Path $AmmoPath -Directory | Select-Object -ExpandProperty Name | Sort-Object
        if ($calibers.Count -eq 0) {
            Write-Host "Nenhum calibre encontrado para gerenciar." -ForegroundColor Yellow; Start-Sleep -Seconds 3; return
        }
        $menuOptions = $calibers
        $selectedCaliber = Show-Menu -Title "Selecione o calibre para gerenciar" -Options $menuOptions -FlickerFree -EnableF1BackButton
        
        if ($selectedCaliber -eq $global:ACTION_BACK) { return }
        if (-not $selectedCaliber) { continue }
        $caliberPath = Join-Path -Path $AmmoPath -ChildPath $selectedCaliber
        $ammoFiles = Get-ChildItem -Path $caliberPath -Filter "*.txt" -File
        
        $actionOptions = @("Editar Nome")
        if ($ammoFiles.Count -eq 0) {
            $actionOptions += "Apagar Calibre"
        } else {
            $actionOptions += "(Apagar Indisponivel - Calibre em uso)"
        }
        
        $action = Show-Menu -Title "Gerenciar: $selectedCaliber" -Options $actionOptions -FlickerFree -EnableF1BackButton
        
        if ($action -eq $global:ACTION_BACK) { continue mainCaliberLoop }
        
        switch ($action) {
            "Editar Nome" { Edit-CaliberName -Caliber $selectedCaliber }
            "Apagar Calibre" { Delete-Caliber -Caliber $selectedCaliber; continue mainCaliberLoop }
            default { continue }
        }
    }
}

function Add-NewCaliber {
    Clear-Host
    Write-Host "=== Adicionar Novo Calibre ==="
    Write-Host
    $caliberName = Read-InputWithPaste -Prompt "Qual e o nome do calibre" -Title "Adicionar Novo Calibre"
    
    if (-not [string]::IsNullOrWhiteSpace($caliberName)) {
        $newCaliberPath = Join-Path -Path $AmmoPath -ChildPath $caliberName
        if (-not (Test-Path -Path $newCaliberPath)) {
            New-Item -Path $newCaliberPath -ItemType Directory | Out-Null
            Write-Host "Calibre '$caliberName' adicionado com sucesso!" -ForegroundColor Green
        } else {
            Write-Host "Este calibre ja existe." -ForegroundColor Yellow
        }
        Start-Sleep -Seconds 2
    }
}

function Edit-CaliberName {
    param([string]$Caliber)
    
    $newName = Read-InputWithPaste -Prompt "Digite o novo nome para o calibre '$Caliber':" -Title "Editar Nome do Calibre"
    if (-not $newName -or [string]::IsNullOrWhiteSpace($newName)) {
        Write-Host "Operação cancelada." -ForegroundColor Yellow; Start-Sleep -Seconds 2; return
    }
    $newPath = Join-Path -Path $AmmoPath -ChildPath $newName
    if (Test-Path $newPath) {
        Write-Host "ERRO: O calibre '$newName' já existe." -ForegroundColor Red; Start-Sleep -Seconds 3; return
    }
    $oldPath = Join-Path -Path $AmmoPath -ChildPath $Caliber
    Rename-Item -Path $oldPath -NewName $newName
    Write-Host "Calibre '$Caliber' renomeado para '$newName' com sucesso!" -ForegroundColor Green; Start-Sleep -Seconds 2
}

function Delete-Caliber {
    param([string]$Caliber)
    $confirmation = Show-Menu -Title "APAGAR CALIBRE" -Options @("Nao, cancelar", "Sim, apagar permanentemente o calibre '$Caliber'")
    if ($confirmation -ne "Sim, apagar permanentemente o calibre '$Caliber'") {
        Write-Host "Operação cancelada." -ForegroundColor Yellow; Start-Sleep -Seconds 2; return
    }
    $pathToDelete = Join-Path -Path $AmmoPath -ChildPath $Caliber
    Remove-Item -Path $pathToDelete -Recurse -Force
    Write-Host "Calibre '$Caliber' apagado com sucesso!" -ForegroundColor Green; Start-Sleep -Seconds 2
}

function Manage-MaskCompatibility {
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize; (Get-Host).UI.RawUI.CursorSize = 0
    # --- ESTA É A LINHA QUE FALTAVA ---
    $compatibilityPath = Join-Path -Path $global:databasePath -ChildPath "Maskcompatibility"
    
    :maskSelectionLoop while ($true) {
        $maskFiles = Get-ChildItem -Path (Join-Path $global:databasePath "Masks") -Filter "*.txt" -File
        if (-not $maskFiles) {
            Write-Host "Nenhuma mascara encontrada na base de dados para criar uma lista." -ForegroundColor Yellow; Start-Sleep -Seconds 3; return
        }
        $maskOptions = ($maskFiles | Select-Object -ExpandProperty BaseName | Sort-Object)
        $selectedMask = Show-Menu -Title "Selecione a mascara para adicionar compatibilidade" -Options $maskOptions -EnableF1BackButton
        
        if ($selectedMask -eq $global:ACTION_BACK) { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return }
        if (-not $selectedMask) { continue }
        :helmetSelectionLoop while ($true) {
            $compatibilityFile = Join-Path -Path $compatibilityPath -ChildPath "$selectedMask (MCP).txt"
            $compatibleHelmets = @()
            if (Test-Path $compatibilityFile) {
                $compatibleHelmets = Get-Content -Path $compatibilityFile | Select-Object -Skip 1
            }
            $allHelmets = Get-ChildItem -Path (Join-Path $global:databasePath "Helmets") -Filter "*.txt" -File | Select-Object -ExpandProperty BaseName
            $availableHelmets = $allHelmets | Where-Object { $_ -notin $compatibleHelmets } | Sort-Object
            
            if ($availableHelmets.Count -eq 0) {
                Write-Host "Todos os capacetes ja sao compativeis com esta mascara." -ForegroundColor Green; Start-Sleep -Seconds 3; continue maskSelectionLoop
            }
            $helmetOptions = $availableHelmets
            $selectedHelmet = Show-Menu -Title "Selecione um capacete para tornar compativel" -Options $helmetOptions -EnableF1BackButton
            
            if ($selectedHelmet -eq $global:ACTION_BACK) { continue maskSelectionLoop }
            if (-not $selectedHelmet) { continue }
            if (-not (Test-Path $compatibilityFile)) {
                $selectedMask | Out-File -FilePath $compatibilityFile -Encoding UTF8
            }
            Add-Content -Path $compatibilityFile -Value $selectedHelmet
            Write-Host "Compatibilidade entre '$selectedMask' e '$selectedHelmet' adicionada com sucesso!" -ForegroundColor Green; Start-Sleep -Seconds 2
        }
    }
}

function Edit-MaskCompatibility {
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize; (Get-Host).UI.RawUI.CursorSize = 0
    $compatibilityPath = Join-Path -Path $global:databasePath -ChildPath "Maskcompatibility"
    :mainEditLoop while ($true) {
        $action = Show-Menu -Title "O que voce deseja apagar?" -Options @("Apagar registro de mascara", "Apagar capacete de registro") -EnableF1BackButton
        if ($action -eq $global:ACTION_BACK) { (Get-Host).UI.RawUI.CursorSize = $originalCursorSize; return }
        if (-not $action) { continue }
        $compFiles = Get-ChildItem -Path $compatibilityPath -Filter "*.txt" -File
        if (-not $compFiles) {
            Write-Host "Nenhum registro de compatibilidade encontrado." -ForegroundColor Yellow; Start-Sleep -Seconds 2; continue
        }
        $maskNames = $compFiles | ForEach-Object { (Get-Content -Path $_.FullName -TotalCount 1) } | Sort-Object
        $maskOptions = $maskNames
        $selectedMask = Show-Menu -Title "Selecione o registro da mascara" -Options $maskOptions -EnableF1BackButton
        if ($selectedMask -eq $global:ACTION_BACK) { continue mainEditLoop }
        if (-not $selectedMask) { continue }
        $compatibilityFile = Join-Path -Path $compatibilityPath -ChildPath "$selectedMask (MCP).txt"
        if ($action -eq "Apagar registro de mascara") {
            $confirm = Show-Menu -Title "Tem certeza que deseja apagar TODO o registro de '$selectedMask'?" -Options @("Nao", "Sim")
            if ($confirm -eq "Sim") {
                Remove-Item -Path $compatibilityFile -Force
                Write-Host "Registro de '$selectedMask' apagado com sucesso." -ForegroundColor Green; Start-Sleep -Seconds 2
            }
        }
        elseif ($action -eq "Apagar capacete de registro") {
            :helmetDeleteLoop while($true) {
                $helmetsInFile = Get-Content -Path $compatibilityFile | Select-Object -Skip 1
                if ($helmetsInFile.Count -eq 0) {
                    Write-Host "Nao ha capacetes neste registro para apagar." -ForegroundColor Yellow; Start-Sleep -Seconds 2; break
                }
                $helmetOptions = ($helmetsInFile | Sort-Object)
                $helmetToDelete = Show-Menu -Title "Selecione o capacete para remover de '$selectedMask'" -Options $helmetOptions -EnableF1BackButton
                
                if ($helmetToDelete -eq $global:ACTION_BACK) { break }
                if (-not $helmetToDelete) { continue }
                $newContent = @($selectedMask) + ($helmetsInFile | Where-Object { $_ -ne $helmetToDelete })
                $newContent | Out-File -FilePath $compatibilityFile -Encoding UTF8
                Write-Host "Capacete '$helmetToDelete' removido do registro de '$selectedMask'." -ForegroundColor Green; Start-Sleep -Seconds 2
            }
        }
    }
}

function Show-ConsultasMenu {
    do {
        $consultasOptions = @(
            "Busca de Armas",
            "Busca de Municao",
            "Comparar armas",
            "Busca de Granadas",
            "Busca de Capacetes",
            "Busca de Mascaras",
            "Consultar compatibilidade de mascaras e capacetes",
            "Busca de Mascaras de Gas",
            "Busca de Fones de Ouvido (Headsets)",
            "Busca de Coletes Balisticos",
            "Busca de Coletes Blindados (Armored Rigs)",
            "Busca de Coletes Nao Blindados (Rigs)",
            "Busca de Mochilas",
            "Busca Farmaceutica (Itens Medicos)",
            "Busca Gastronomica (Comidas e Bebidas)"
        )
        
        $selection = Show-Menu -Title "Consultar Itens (Busca com Filtro)" -Options $consultasOptions -FlickerFree -EnableF1BackButton
        
        if ($selection -eq $global:ACTION_BACK) { return }
        switch ($selection) {
            "Busca de Armas"                           { Search-WeaponsWithFilters }
            "Busca de Municao"                         { Search-WithFilters }
            "Comparar armas"                           { Compare-Weapons }
            "Busca de Granadas"                        { Search-ThrowablesWithFilters }
            "Busca de Capacetes"                       { Search-HelmetsWithFilters }
            "Busca de Mascaras"                        { Search-MasksWithFilters }
            "Consultar compatibilidade de mascaras e capacetes" { List-MaskCompatibility }
            "Busca de Mascaras de Gas"                 { Search-GasMasksWithFilters }
            "Busca de Fones de Ouvido (Headsets)"      { Search-HeadsetsWithFilters }
            "Busca de Coletes Balisticos"              { Search-BodyArmorsWithFilters }
            "Busca de Coletes Blindados (Armored Rigs)" { Search-ArmoredRigsWithFilters }
            "Busca de Coletes Nao Blindados (Rigs)"    { Search-UnarmoredRigsWithFilters }
            "Busca de Mochilas"                        { Search-BackpacksWithFilters }
            "Busca Farmaceutica (Itens Medicos)"       { Search-PharmaceuticalWithFilters }
            "Busca Gastronomica (Comidas e Bebidas)"   { Search-GastronomyWithFilters }
        }
    } while ($true)
}

function Show-GerenciamentoMenu {
    $lastAddItemIndex = 0
    do {
        $gerenciamentoOptions = @(
            "Adicionar Novo Item",
            "Editar ou Apagar Item",
            "Gerenciar Compatibilidade de Mascaras",
            "Gerenciar Calibres",
            "Visualizar Banco de Dados (Dados Brutos)"
        )
        $selection = Show-Menu -Title "Gerenciar Banco de Dados" -Options $gerenciamentoOptions -FlickerFree -EnableF1BackButton
        if ($selection -eq $global:ACTION_BACK) { return }
        switch ($selection) {
            "Adicionar Novo Item" {
                :addItemLoop while ($true) {
                    $addItemOrder = @(
                        "Weapons",
                        "Ammo",
                        "Throwables",
                        "Helmets",
                        "Masks",
                        "Gasmasks",
                        "Headsets",
                        "Bodyarmors",
                        "Armoredrigs",
                        "Unarmoredrigs",
                        "Backpacks",
                        "Painkillers",
                        "Bandages",
                        "Surgicalkit",
                        "Nebulizers",
                        "Medicalkit",
                        "Stimulants",
                        "Beverages",
                        "Food"
                    )
                    
                    $addMenuOptions = ($addItemOrder | ForEach-Object { $global:ItemCategoryConfig[$_].AddItemMenuName }) + "Um novo Calibre"
                    
                    $itemTypeSelection = Show-Menu -Title "Tipo de item para Adicionar" -Options $addMenuOptions -FlickerFree -InitialSelectedIndex $lastAddItemIndex -EnableF1BackButton
                    
                    if ($itemTypeSelection -and ($itemTypeSelection -ne $global:ACTION_BACK)) {
                        $lastAddItemIndex = [array]::IndexOf($addMenuOptions, $itemTypeSelection)
                    }
                    if (-not $itemTypeSelection -or $itemTypeSelection -eq $global:ACTION_BACK) { break addItemLoop }
                    if ($itemTypeSelection -eq "Um novo Calibre") {
                        Add-NewCaliber
                        continue addItemLoop
                    }
                    $categoryKeyToAdd = ($global:ItemCategoryConfig.GetEnumerator() | Where-Object { $_.Value.AddItemMenuName -eq $itemTypeSelection }).Name
                    $addFunctionName = $global:ItemCategoryConfig[$categoryKeyToAdd].AddFunction
                    & $addFunctionName
                }
            }
            "Editar ou Apagar Item" { Edit-Items }
            "Gerenciar Compatibilidade de Mascaras" {
                $compSelection = Show-Menu -Title "Gerenciar Compatibilidade" -Options @("Adicionar Compatibilidade", "Editar/Remover Compatibilidade") -EnableF1BackButton
                if ($compSelection -eq $global:ACTION_BACK) { continue }
                switch ($compSelection) {
                    "Adicionar Compatibilidade"       { Manage-MaskCompatibility }
                    "Editar/Remover Compatibilidade"  { Edit-MaskCompatibility }
                }
            }
            "Gerenciar Calibres" { Manage-Calibers }
            "Visualizar Banco de Dados (Dados Brutos)" { View-Database }
        }
    } while ($true)
}

function Show-CriteriaSelectionMenu {
    :helpSelectionLoop while ($true) {
        $options = @(
            "Busca de Municao",
            "Busca de Armas",
            "Busca Gastronomica (Comidas e Bebidas)",
            "Busca Farmaceutica (Itens Medicos)",
            "Busca de Granadas",
            "Busca de Capacetes",
            "Busca de Coletes Balisticos",
            "Busca de Coletes Blindados (Armored Rigs)",
            "Busca de Mascaras",
            "Busca de Mascaras de Gas",
            "Busca de Fones de Ouvido (Headsets)",
            "Busca de Coletes Nao Blindados (Rigs)",
            "Busca de Mochilas"
        )
        $selection = Show-Menu -Title "Como funcionam os criterios (Busca com Filtro)" -Options $options -FlickerFree -EnableF1BackButton
        if (-not $selection -or $selection -eq $global:ACTION_BACK) { return }
        switch ($selection) {
            "Busca de Municao"                         { Show-AmmoHelpCriteria }
            "Busca de Armas"                           { Show-WeaponHelpCriteria }
            "Busca Gastronomica (Comidas e Bebidas)"   { Show-GastronomyHelpCriteria }
            "Busca Farmaceutica (Itens Medicos)"       { Show-PharmaceuticalHelpCriteria }
            "Busca de Granadas"                        { Show-ThrowableHelpCriteria }
            "Busca de Capacetes"                       { Show-HelmetHelpCriteria }
            "Busca de Coletes Balisticos"              { Show-BodyArmorHelpCriteria }
            "Busca de Coletes Blindados (Armored Rigs)" { Show-ArmoredRigHelpCriteria }
            "Busca de Mascaras"                        { Show-MaskHelpCriteria }
            "Busca de Mascaras de Gas"                 { Show-GasMaskHelpCriteria }
            "Busca de Fones de Ouvido (Headsets)"      { Show-HeadsetHelpCriteria }
            "Busca de Coletes Nao Blindados (Rigs)"    { Show-UnarmoredRigHelpCriteria }
            "Busca de Mochilas"                        { Show-BackpackHelpCriteria }
        }
    }
}

function Invoke-UpdateCheck {
    (Get-Host).UI.RawUI.CursorSize = 0
    Clear-Host
    Write-Host "=== Verificar Atualizacoes ==="; Write-Host
    Write-Host "Verificando a versao mais recente no GitHub..."
    Write-Host "(Isso pode demorar alguns segundos)"

    try {
        $latestRelease = Invoke-RestMethod -Uri $global:GitHubApiUrl -TimeoutSec 5 -ErrorAction Stop
    } catch {
        $latestRelease = $null
    }

    if (-not $latestRelease) {
        Clear-Host
        Write-Host "=== Verificar Atualizacoes ==="; Write-Host
        Write-Host "ERRO: Nao foi possivel conectar ao GitHub." -ForegroundColor Red
        Write-Host "Verifique sua conexao com a internet ou o link da API no script."
        Write-Host; Write-Host "Voltando ao menu em 5 segundos..."
        Start-Sleep -Seconds 5
        return
    }

    $latestVersion = $latestRelease.tag_name.TrimStart('v')

    do {
        Clear-Host
        Write-Host "=== Verificar Atualizacoes ==="; Write-Host

        if ($latestVersion -eq $global:ScriptVersion) {
            Write-Host "Verificacao concluida."
            Write-Host; Write-Host "Voce ja esta com a versao mais recente do SCRIPT! (Versao $global:ScriptVersion)" -ForegroundColor Green
            Write-Host; Write-Host "** IMPORTANTE: Esta verificacao e apenas para o SCRIPT (ABIDB.ps1). **"
            Write-Host "** O seu banco de dados (pasta ""Database ABI"") NAO e verificado. **"
            Write-Host; Write-Host "Voce pode pressionar F2 para visitar a pagina de releases"
            Write-Host "e checar o TITULO da versao para ver se ha uma nova"
            Write-Host "atualizacao do BANCO DE DADOS (ex: ""Database Update - 14/11/2025"")."
            Write-Host; Write-Host "Link da Pagina:"; Write-Host $global:GitHubReleasePageUrl

        } else {
            Write-Host "ATUALIZACAO DE SCRIPT ENCONTRADA!" -ForegroundColor Yellow
            Write-Host; Write-Host "Uma nova versao ($latestVersion) esta disponivel." -ForegroundColor Yellow
            Write-Host "Sua versao atual e a $global:ScriptVersion."
            Write-Host; Write-Host "** IMPORTANTE: Esta atualizacao e para o SCRIPT (ABIDB.ps1). **"
            Write-Host "** O seu banco de dados (pasta ""Database ABI"") NAO sera alterado. **"
            Write-Host; Write-Host "** DICA: Ao abrir a pagina, LEIA O TITULO da nova release. **"
            Write-Host "** Ele indicara se uma nova versao do BANCO DE DADOS tambem esta inclusa. **"
            Write-Host; Write-Host "Passos para atualizar o SCRIPT:"
            Write-Host; Write-Host "1. Pressione F2 para abrir a pagina de download no seu navegador."
            Write-Host "2. Baixe o novo arquivo ""ABIDB.ps1"" da pagina."
            Write-Host "3. Substitua o seu arquivo ""ABIDB.ps1"" antigo pelo novo."
            Write-Host "4. Feche e abra o script novamente."
            Write-Host; Write-Host "Link da Pagina:"; Write-Host $global:GitHubReleasePageUrl
        }
        
        Write-Host; Write-Host "Pressione " -NoNewline; Write-Host "F1" -ForegroundColor Red -NoNewline; Write-Host " para voltar ao menu..."
        Write-Host "Pressione " -NoNewline; Write-Host "F2" -ForegroundColor Blue -NoNewline; Write-Host " para abrir o link no seu navegador padrao"
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
        
        if ($key -eq 113) {
            try {
                Start-Process $global:GitHubReleasePageUrl
            } catch {
                Write-Host "ERRO ao tentar abrir o navegador." -ForegroundColor Red
                Start-Sleep -Seconds 3
            }
        }
    } while ($key -ne 112)
    return
}

function Show-MainMenu {
    Initialize-Database
    $originalCursorSize = (Get-Host).UI.RawUI.CursorSize
    (Get-Host).UI.RawUI.CursorSize = 0
    do {
        $mainMenuOptions = @(
            "Consultar Itens (Busca com Filtro)",
            "Gerenciar Banco de Dados",
            "Tira Duvidas",
            "Verificar Atualizacoes",
            "Sair"
        )
        
        $selectedOption = Show-Menu -Title "Arena Breakout Infinite Offline Database 0.9.1 (Creator: Fabiopsyduck)" -Options $mainMenuOptions -FlickerFree
        
        switch ($selectedOption) {
            "Consultar Itens (Busca com Filtro)" { Show-ConsultasMenu }
            "Gerenciar Banco de Dados"           { Show-GerenciamentoMenu }
            "Tira Duvidas" {
                $helpOption = Show-Menu -Title "Tira Duvidas" -Options @("Como funciona os criterios (Busca com Filtro)") -FlickerFree -EnableF1BackButton
                if ($helpOption -eq $global:ACTION_BACK) { continue }
                if ($helpOption -eq "Como funciona os criterios (Busca com Filtro)") { Show-CriteriaSelectionMenu }
            }
            "Verificar Atualizacoes" { Invoke-UpdateCheck }
            "Sair" { 
                (Get-Host).UI.RawUI.CursorSize = $originalCursorSize
                Clear-Host
                exit 
            }
        }
    } while ($true)
}

Show-MainMenu


