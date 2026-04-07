# ===================================================================================
# NOME: Arena Breakout Infinite - Database Offline (ABIDB)
# VERSAO: 1.0.0
# CRIADOR: Fabiopsyduck
# DESCRICAO: Banco de dados offline com interface grafica para consultar, filtrar, comparar e gerenciar estatisticas detalhadas de armas, municoes e equipamentos do jogo.
# ===================================================================================

# --- VERSAO DO APLICATIVO ---
$AppVersion = "1.0.0"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# [NOVO] Configuração de DPI e Estilos Visuais (Trazido do Script 2)
# Isso deve rodar antes de qualquer elemento visual ser criado
if ([System.Environment]::OSVersion.Version.Major -ge 6) {
    [System.Runtime.InteropServices.Marshal]::PrelinkAll([System.Windows.Forms.Application])
    try { [System.Windows.Forms.Application]::SetHighDpiMode([System.Windows.Forms.HighDpiMode]::SystemAware) } catch {}
}
[System.Windows.Forms.Application]::EnableVisualStyles()

$defaultCalibers = @(
    "5.45x39mm", "5.56x45mm", "5.7x28mm", "5.8x42mm",
    "7.62x25mm", "7.62x39mm", "7.62x51mm", "7.62x54mm",
    "9x19mm", "9x39mm", "12x70mm", ".44", ".45", ".338"
)

# --- MAPAS E TRADUÇÕES GLOBAIS ---
$global:WeaponClassToPortugueseMap = @{
    "ASSAULT RIFLE"     = "Rifle de assalto"; "SUBMACHINE GUN"    = "Submetralhadora"
    "CARBINE"           = "Carabina";         "MARKSMAN RIFLE"    = "Fuzil DMR"
    "BOLT-ACTION RIFLE" = "Rifle de ferrolho";"SHOTGUN"           = "Escopeta"
    "LIGHT MACHINE GUN" = "Metralhadora leve";"PISTOL"            = "Pistola"
}

$global:PoderFogoMap = @{ "Low"=1; "Mid-Low"=2; "Medium"=3; "Mid-High"=4; "High"=5; "Ultra High"=6 }
$global:CanoMap      = @{ "FB D-"=1; "Custom"=2; "FB"=2; "FB D+"=4; "Default +"=5; "R+"=6; "D+"=6; "D+ R+"=7 }

$global:FireModeTrans = @{
    "Bolt-Action" = "A.Ferrolho"
    "Pump-Action" = "A.Bombeamento"
    "Semi" = "Semi"; "Full" = "Auto"
}

$global:FirePowerTrans = @{
    "Ultra High" = "Ultra-alto"
    "High"       = "Alto"
    "Mid-High"   = "Médio-Alto"
    "Medium"     = "Médio"
    "Mid-Low"    = "Médio-Baixo"
    "Low"        = "Baixo"
}

$global:BarrelTrans = @{
    "FB D-"     = "CF D-"
    "FB"        = "CF"
    "FB D+"     = "CF D+"
    "Default +" = "Padrão +"
    "R+"        = "A+"
    "D+"        = "D+" 
    "D+ R+"     = "D+ A+"
}


function Initialize-Database {
    # --- CORREÇÃO PS2EXE: Descobre o caminho real antes de criar a pasta ---
    $baseDir = $PSScriptRoot
    if ([string]::IsNullOrEmpty($baseDir)) {
        $baseDir = [System.IO.Path]::GetDirectoryName([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
    }

    $global:databasePath = Join-Path -Path $baseDir -ChildPath "Database ABI"
    
    if (-not (Test-Path $global:databasePath)) {
        New-Item -ItemType Directory -Path $global:databasePath -Force | Out-Null
    }
    
    $filesConfig = @{
        "Ammo.csv"              = '"NomeItem";"Calibre";"DanoBase";"DanoBlindagem";"Penetracao";"Velocidade";"Precisao";"RecuoVertical";"RecuoHorizontal";"NivelPenetracao";"ChanceFerir"'
        "Weapons.csv"           = '"NomeItem";"Classe";"Calibre";"RecuoVertical";"RecuoHorizontal";"Ergonomia";"Precisao";"EstabilidadeHipFire";"Alcance";"VelocidadeBocal";"ModoDisparo";"Cadencia";"PoderFogo";"TipoCano";"EstabilidadeArma"'
        "Throwables.csv"        = '"NomeItem";"DelayExplosao";"Alcance";"DanoBlindagem";"Penetracao";"Fragmentos";"TipoFragmento";"TempoEfeito"'
        "Helmets.csv"           = '"NomeItem";"Peso";"Durabilidade";"ClasseBlindagem";"Material";"BloqueioSom";"PenalidadeMovimento";"Ergonomia";"AreaProtegida";"Ricochete";"TemHeadset";"CaptacaoSom";"ReducaoRuido";"Acessorio"'
        "Bodyarmors.csv"        = '"NomeItem";"Peso";"Durabilidade";"ClasseBlindagem";"Material";"PenalidadeMovimento";"Ergonomia";"AreaProtegida"'
        "Armoredrigs.csv"       = '"NomeItem";"Peso";"Durabilidade";"ClasseBlindagem";"Material";"PenalidadeMovimento";"Ergonomia";"EspacoArmazenamento";"AreaProtegida";"LayoutInterno"'
        "Masks.csv"             = '"NomeItem";"Peso";"Durabilidade";"ClasseBlindagem";"Material";"Ricochete"'
        "Gasmasks.csv"          = '"NomeItem";"Peso";"Durabilidade";"AntiVeneno";"AntiFlash"'
        "Headsets.csv"          = '"NomeItem";"Peso";"CaptacaoSom";"ReducaoRuido"'
        "Unarmoredrigs.csv"     = '"NomeItem";"Peso";"EspacoTotal";"TamanhoDesdobrada";"TamanhoDobrada";"LayoutInterno"'
        "Backpacks.csv"         = '"NomeItem";"Peso";"EspacoTotal";"TamanhoDesdobrada";"TamanhoDobrada";"LayoutInterno"'
        "Painkillers.csv"       = '"NomeItem";"Usos";"Duracao";"Desidratacao";"Delay"'
        "Bandages.csv"          = '"NomeItem";"Usos";"Delay";"CustoDurabilidade"'
        "Surgicalkit.csv"       = '"NomeItem";"Usos";"Delay";"Desidratacao";"RecuperacaoHP";"CustoDurabilidade";"EspacoOcupado"'
        "Nebulizers.csv"        = '"NomeItem";"Usos";"Delay";"CustoDurabilidade"'
        "Medicalkit.csv"        = '"NomeItem";"DurabilidadeTotal";"Desidratacao";"VelocidadeCura";"Delay";"CustoPorUso";"EspacoOcupado"'
        "Stimulants.csv"        = '"NomeItem";"EfeitoPrincipal";"Duracao";"Desidratacao";"ReducaoEnergia";"Delay"'
        "Beverages.csv"         = '"NomeItem";"Hidratacao";"Energia";"Delay";"RecuperacaoStamina";"EspacoOcupado"'
        "Food.csv"              = '"NomeItem";"Hidratacao";"Energia";"Delay";"RecuperacaoStamina";"EspacoOcupado"'
        "MaskCompatibility.csv" = '"MaskName";"CompatibleHelmets"'
        "Caliber.csv"           = '"CalibreName"'
    }

    foreach ($file in $filesConfig.Keys) {
        $filePath = Join-Path -Path $global:databasePath -ChildPath $file
        if (-not (Test-Path $filePath)) {
            $filesConfig[$file] | Set-Content -Path $filePath -Encoding UTF8
            if ($file -eq "Caliber.csv") {
                foreach ($calibre in $global:defaultCalibers) { Add-Content -Path $filePath -Value "`"$calibre`"" -Encoding UTF8 }
            }
        }
    }
}

$script:manualFilters = @{
    "ClasseDisplay"      = @() 
    "Calibre"            = @() 
    "ModoDisparoDisplay" = @() 
    "PoderFogoDisplay"   = @() 
    "CanoDisplay"        = @() 
}

Initialize-Database

# ===================================================================================
# 2. ESQUEMA DE CORES (THEME)
# ===================================================================================
$theme = @{
    Background   = [System.Drawing.ColorTranslator]::FromHtml("#1e1e1e")
    PanelBack    = [System.Drawing.ColorTranslator]::FromHtml("#2d2d30")
    TextMain     = [System.Drawing.ColorTranslator]::FromHtml("#e0e0e0")
    TextDim      = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    ButtonBack   = [System.Drawing.ColorTranslator]::FromHtml("#333333")
    OrangeAccent = [System.Drawing.ColorTranslator]::FromHtml("#FFA500")
    Success      = [System.Drawing.ColorTranslator]::FromHtml("#4CAF50") 
    Fail         = [System.Drawing.ColorTranslator]::FromHtml("#F44336") 
    Warning      = [System.Drawing.ColorTranslator]::FromHtml("#FFC107") 
    Dev          = [System.Drawing.ColorTranslator]::FromHtml("#00BCD4") 
    
    # [NOVO] Adicionado para compatibilidade com o Script 2 (Gerenciador)
    ButtonHover  = [System.Drawing.ColorTranslator]::FromHtml("#505050") 
    ButtonActive = [System.Drawing.ColorTranslator]::FromHtml("#646464")
    RedAlert     = [System.Drawing.Color]::IndianRed
    GreenSuccess = [System.Drawing.Color]::LightGreen
}

# ===================================================================================
# 2.5. FUNCOES AUXILIARES E LOGICA DE NEGOCIO
# ===================================================================================

function Get-DatabasePath {
    $path = $global:databasePath
    
    # Se a variável global estiver vazia, vamos descobrir o caminho base real
    if ([string]::IsNullOrEmpty($path)) { 
        $baseDir = $PSScriptRoot
        
        # [CORREÇÃO PS2EXE]: Se o $PSScriptRoot falhar ou estiver vazio no .exe, 
        # forçamos o Windows a dizer-nos onde este .exe está aberto fisicamente.
        if ([string]::IsNullOrEmpty($baseDir)) {
            $baseDir = [System.IO.Path]::GetDirectoryName([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
        }

        $path = Join-Path -Path $baseDir -ChildPath "Database ABI" 
    }
    
    # Se a pasta padrao nao existir, usa a raiz (fallback de seguranca)
    if (-not (Test-Path $path)) { 
        # Re-calcula o baseDir caso ele tenha caído direto aqui
        $baseDir = $PSScriptRoot
        if ([string]::IsNullOrEmpty($baseDir)) {
            $baseDir = [System.IO.Path]::GetDirectoryName([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
        }
        $path = $baseDir 
    }
    
    return $path
}

function Get-MaskCompatibilityData {
    # [ALTERACAO] Usa a funcao para obter o caminho correto
    $dbPath = Get-DatabasePath

    $csvCompPath    = Join-Path -Path $dbPath -ChildPath "MaskCompatibility.csv"
    $csvMasksPath   = Join-Path -Path $dbPath -ChildPath "Masks.csv"
    $csvHelmetsPath = Join-Path -Path $dbPath -ChildPath "Helmets.csv"

    if (-not (Test-Path $csvCompPath)) { return @() }

    $maskClasses = @{}
    if (Test-Path $csvMasksPath) {
        $maskData = Import-Csv -Path $csvMasksPath -Delimiter ";" -Encoding UTF8
        foreach ($m in $maskData) { $maskClasses[$m.NomeItem] = $m.ClasseBlindagem }
    }

    $helmetClasses = @{}
    if (Test-Path $csvHelmetsPath) {
        $helmetData = Import-Csv -Path $csvHelmetsPath -Delimiter ";" -Encoding UTF8
        foreach ($h in $helmetData) { $helmetClasses[$h.NomeItem] = $h.ClasseBlindagem }
    }

    $compContent = Import-Csv -Path $csvCompPath -Delimiter ";" -Encoding UTF8
    $results = @()

    foreach ($row in $compContent) {
        $maskName = $row.MaskName
        
        $armorClass = "N/A"
        $armorClassNum = 0
        if ($maskClasses.ContainsKey($maskName)) {
            $armorClass = $maskClasses[$maskName]
            if ($armorClass -match '\d') { $armorClassNum = [int]$armorClass }
        }

        $displayMaskName = "$maskName (Cl. $armorClass)"

        $helmetObjs = @()
        $maxHelmetClass = 0 

        if (-not [string]::IsNullOrWhiteSpace($row.CompatibleHelmets)) {
            $rawHelmets = $row.CompatibleHelmets -split ','
            foreach ($hName in $rawHelmets) {
                $hNameTrimmed = $hName.Trim()
                $hClass = "?"
                $hClassNum = 0
                
                if ($helmetClasses.ContainsKey($hNameTrimmed)) {
                    $hClass = $helmetClasses[$hNameTrimmed]
                    if ($hClass -match '\d') { $hClassNum = [int]$hClass }
                }
                
                if ($hClassNum -gt $maxHelmetClass) { $maxHelmetClass = $hClassNum }

                $helmetObjs += [PSCustomObject]@{
                    Texto = "$hNameTrimmed (Cl. $hClass)"
                    Nivel = $hClassNum
                }
            }
        }
        
        # Ordenacao Interna dos Capacetes (Maior Nivel Primeiro)
        $sortedHelmets = $helmetObjs | Sort-Object Nivel -Descending | Select-Object -ExpandProperty Texto
        $listaCapacetes = $sortedHelmets -join [Environment]::NewLine

        $results += [PSCustomObject]@{
            DisplayMascara = $displayMaskName
            ClasseNum = $armorClassNum
            MaxHelmetClass = $maxHelmetClass
            CapacetesCompativeis = $listaCapacetes
        }
    }

    # Ordenacao Principal: 1. Nivel Mascara, 2. Maior Nivel Capacete
    return $results | Sort-Object -Property @{ Expression = "ClasseNum"; Descending = $true }, @{ Expression = "MaxHelmetClass"; Descending = $true }
}

function Get-FireModeWeight ($txt) {
        if ($txt -match "Auto") { return 3 } 
        if ($txt -eq "Semi" -or $txt -eq "Semi, 3-RB") { return 2 }
        return 1 
    }
	
function Get-Color ($val, $statKey) {
        if ($statsW.ContainsKey($statKey)) {
            $s = $statsW[$statKey]
            if ($s.Minimum -ne $s.Maximum) {
                if ($val -eq $s.Maximum) { return [System.Drawing.Color]::LightGreen }
                if ($val -eq $s.Minimum) { return [System.Drawing.Color]::IndianRed }
            }
        }
        return $theme.TextMain
    }

function Get-ColorAmmo ($val, $statKey) {
        if ($statsA.ContainsKey($statKey)) {
            $s = $statsA[$statKey]
            if ($s.Minimum -ne $s.Maximum) {
                if ($val -eq $s.Maximum) { return [System.Drawing.Color]::LightGreen }
                if ($val -eq $s.Minimum) { return [System.Drawing.Color]::IndianRed }
            }
        }
        return $theme.TextMain
    }
	
function Set-ColorGlobal($cell, $val, $statKey) {
        if ($globalStats.ContainsKey($statKey)) {
            $s = $globalStats[$statKey]
            if ($s.Minimum -ne $s.Maximum) {
                if ($val -eq $s.Maximum) { $cell.Style.ForeColor = [System.Drawing.Color]::LightGreen }
                elseif ($val -eq $s.Minimum) { $cell.Style.ForeColor = [System.Drawing.Color]::IndianRed }
            }
        }
    }

$script:manualFilters = @{
    "ClasseDisplay"      = @() 
    "Calibre"            = @() 
    "ModoDisparoDisplay" = @() 
    "PoderFogoDisplay"   = @() 
    "CanoDisplay"        = @() 
}

# ===================================================================================
# 2.6. ENGINE DE DADOS, ORDENACAO E FILTROS (CORE)
# ===================================================================================

function Get-ViewConfig {
    param([string]$Mode, [string]$Category = $null)

    switch ($Mode) {
        "Weapon" {
            return @{
                Criteria = @("Alfabético", "Controle de Recuo Vertical", "Controle de Recuo Horizontal", "Ergonomia", "Estabilidade da Arma", "Precisão", "Estabilidade sem Mirar", "Distância Efetiva", "Velocidade de Saída", "Modo de Disparo", "Cadência", "Poder de Fogo", "Melhoria de Cano")
                BtnFilterText = "Filtros (Ocultar Armas)"
                ColumnLayout = @{ "Melh.Cano"=@{W=10; M=75}; "Cad"=@{W=5; M=50}; "ModoDisparo"=@{W=14; M=110}; "Esta.DA"=@{W=6; M=50}; "Esta.SM"=@{W=6; M=50}; "Classe"=@{W=14; M=110}; "Poder.DFG"=@{W=11; M=90}; "Vel.bo"=@{W=5; M=45}; "CRV"=@{W=4; M=40}; "CRH"=@{W=4; M=40}; "Ergo"=@{W=4; M=35}; "Prec"=@{W=4; M=35}; "Dis(m)"=@{W=6; M=50}; "Calibre"=@{W=9; M=75}; "Nome"=@{W=16; M=120} }
                Tooltips = @{ "CRV"="Controle de recuo vertical"; "CRH"="Controle de recuo horizontal"; "Ergo"="Ergonomia"; "Prec"="Precisão"; "Esta.DA"="Estabilidade de Arma."; "Esta.SM"="Hip-fire."; "Dis(m)"="Distância Efetiva."; "Vel.bo"="Velocidade de Saída."; "Poder.DFG"="Poder de fogo"; "Cad"="Cadência"; "ModoDisparo"="Modos de disparo"; "Melh.Cano"="Customização de cano" }
            }
        }
        "Helmet" {
            return @{
                Criteria = @("Alfabético", "Peso", "Durabilidade", "Classe de Blindagem", "Bloqueio", "Penalidade de Movimento", "Ergonomia", "Área Protegida", "Chance de Ricochete", "Captura de Som", "Redução de Ruído", "Acessório", "Classe Máxima da Máscara Compatível")
                BtnFilterText = "Filtros (Ocultar Cap.)"
                ColumnLayout = @{ "Nome"=@{W=22;M=180}; "Peso"=@{W=4;M=40}; "Dur."=@{W=4;M=40}; "Cl"=@{W=2;M=30}; "Material"=@{W=11;M=95}; "Bloqueio"=@{W=8;M=70}; "Vel.M"=@{W=4;M=40}; "Ergo"=@{W=4;M=40}; "Área Protegida"=@{W=16;M=130}; "Ricoch"=@{W=6;M=50}; "Captad"=@{W=6;M=50}; "Red.Ru"=@{W=6;M=50}; "Acessório"=@{W=9;M=80}; "Cl Max Masc"=@{W=8;M=70} }
                Tooltips = @{ "Nome"="O nome do item."; "Peso"="O peso do capacete em quilogramas (kg)."; "Dur."="Pontos totais de durabilidade do capacete."; "Cl"="A Classe de Blindagem do capacete (de 1 a 6)."; "Material"="O material principal de fabricação do capacete."; "Bloqueio"="O nível de bloqueio sonoro que o capacete causa."; "Vel.M"="A porcentagem de penalidade na velocidade de movimento."; "Ergo"="A penalidade nos pontos de ergonomia."; "Área Protegida"="As partes da cabeça que o capacete protege."; "Ricoch"="A chance de um projétil ricochetear no capacete."; "Captad"="A potência do fone de ouvido para captar sons do ambiente."; "Red.Ru"="A potência do fone de ouvido para reduzir ruídos altos."; "Acessório"="Indica a compatibilidade com acessórios táticos (TE) e máscaras."; "Cl Max Masc"="Mostra a Classe (Cl) máxima da máscara compatível." }
            }
        }
        "Armor" {
            return @{
                Criteria = @("Alfabético", "Peso", "Durabilidade", "Classe de Blindagem", "Material", "Penalidade de Movimento", "Ergonomia", "Área Protegida")
                BtnFilterText = "Filtros (Ocultar Coletes)"
                ColumnLayout = @{ "Nome"=@{W=25;M=150}; "Peso"=@{W=5;M=40}; "Cl"=@{W=4;M=30}; "Dur."=@{W=5;M=40}; "Material"=@{W=15;M=100}; "Vel.M"=@{W=6;M=50}; "Ergo"=@{W=6;M=40}; "Área Protegida"=@{W=34;M=200} }
                Tooltips = @{ "Nome"="O nome do item."; "Peso"="O peso do colete em quilogramas (kg)."; "Cl"="A Classe de Blindagem do colete (de 1 a 6)."; "Dur."="Pontos totais de durabilidade do colete."; "Material"="O material principal de fabricação do colete."; "Vel.M"="A porcentagem de penalidade na velocidade de movimento."; "Ergo"="A penalidade nos pontos de ergonomia."; "Área Protegida"="As partes do corpo que o colete protege." }
            }
        }
        "ArmoredRig" {
            return @{
                Criteria = @("Alfabético", "Peso", "Classe de Blindagem", "Durabilidade", "Penalidade de Movimento", "Ergonomia", "Armazenamento", "Área Protegida", "Conjunto de Blocos (HxV)")
                BtnFilterText = "Filtros (Ocultar C. Blind.)"
                ColumnLayout = @{ "Nome"=@{W=25;M=180}; "Peso"=@{W=5;M=40}; "Cl"=@{W=3;M=30}; "Dur."=@{W=5;M=40}; "Material"=@{W=12;M=90}; "Vel.M"=@{W=5;M=45}; "Ergo"=@{W=5;M=40}; "Esp"=@{W=4;M=30}; "Área Protegida"=@{W=20;M=150}; "Conj d. blocos (HxV)"=@{W=16;M=120} }
                Tooltips = @{ "Nome"="O nome do item."; "Peso"="O peso do colete em quilogramas (kg)."; "Cl"="A Classe de Blindagem do colete (de 1 a 6)."; "Dur."="Pontos totais de durabilidade do colete."; "Material"="O material principal de fabricação do colete."; "Vel.M"="A porcentagem de penalidade na velocidade de movimento."; "Ergo"="A penalidade nos pontos de ergonomia."; "Esp"="A quantidade de slots de armazenamento que o colete oferece."; "Área Protegida"="As partes do corpo que o colete protege."; "Conj d. blocos (HxV)"="O layout e o tamanho dos slots internos (Formato: Horizontal x Vertical)" }
            }
        }
        "UnarmoredRig" {
            return @{
                Criteria = @("Alfabético", "Peso", "Armazenamento", "Conjunto de Blocos (HxV)", "+Espaço p/ Armaz. -Espaço Consumido")
                BtnFilterText = "Filtros (Indisponível)" 
                ColumnLayout = @{ "Nome"=@{W=25;M=180}; "Peso"=@{W=5;M=40}; "Espaço"=@{W=5;M=40}; "Desdobrada"=@{W=10;M=70}; "Dobrada"=@{W=8;M=60}; "Conj d. blocos (HxV)"=@{W=20;M=150}; "+Armaz -Espaço"=@{W=10;M=80} }
                Tooltips = @{ "Nome"="O nome do item."; "Peso"="O peso do colete em quilogramas (kg)."; "Espaço"="A quantidade de slots de armazenamento que o colete oferece."; "Desdobrada"="O espaço que o item ocupa no inventário no formato 'Horizontal x Vertical'."; "Dobrada"="O espaço que o item ocupa quando dobrado, também no formato 'HxV'."; "Conj d. blocos (HxV)"="O layout e o tamanho dos bolsos/compartimentos internos."; "+Armaz -Espaço"="Cálculo de eficiência: (Total de Slots de Armazenamento - Espaço Ocupado Desdobrado)." }
            }
        }
        "Backpack" {
            return @{
                Criteria = @("Alfabético", "Peso", "Armazenamento", "Conjunto de Blocos (HxV)", "+Espaço p/ Armaz. -Espaço Consumido")
                BtnFilterText = "Filtros (Indisponível)" 
                ColumnLayout = @{ "Nome"=@{W=25;M=180}; "Peso"=@{W=5;M=40}; "Espaço"=@{W=5;M=40}; "Desdobrada"=@{W=10;M=70}; "Dobrada"=@{W=8;M=60}; "Conj d. blocos (HxV)"=@{W=20;M=150}; "+Armaz -Espaço"=@{W=10;M=80} }
                Tooltips = @{ "Nome"="O nome do item."; "Peso"="O peso da mochila em quilogramas (kg)."; "Espaço"="A quantidade de slots de armazenamento que a mochila oferece."; "Desdobrada"="O espaço que o item ocupa no inventário no formato 'Horizontal x Vertical'."; "Dobrada"="O espaço que o item ocupa quando dobrado, também no formato 'HxV'."; "Conj d. blocos (HxV)"="O layout e o tamanho dos bolsos/compartimentos internos."; "+Armaz -Espaço"="Cálculo de eficiência: (Total de Slots de Armazenamento - Espaço Ocupado Desdobrado)." }
            }
        }
        "Headset" {
            return @{
                Criteria = @("Alfabético", "Peso", "Captador de Som", "Redução de Ruído")
                BtnFilterText = "Filtros (Indisponível)" 
                ColumnLayout = @{ "Nome"=@{W=30;M=200}; "Peso"=@{W=10;M=60}; "Captador de Som"=@{W=25;M=120}; "Redução de Ruído"=@{W=25;M=120} }
                Tooltips = @{ "Nome"="O nome do item."; "Peso"="O peso do fone de ouvido em quilogramas (kg)."; "Captador de Som"="O nível de amplificação de sons do ambiente (Forte > Médio > Fraco)."; "Redução de Ruído"="O nível de redução de ruídos altos, como tiros (Forte > Médio > Fraco)." }
            }
        }
        "GasMask" {
            return @{
                Criteria = @("Alfabético", "Peso", "Durabilidade", "Anti-Veneno", "Anti-Flash")
                BtnFilterText = "Filtros (Indisponível)" 
                ColumnLayout = @{ "Nome"=@{W=30;M=200}; "Peso"=@{W=10;M=60}; "Dur."=@{W=10;M=60}; "Anti-Veneno"=@{W=20;M=120}; "Anti-Flash"=@{W=20;M=120} }
                Tooltips = @{ "Nome"="O nome do item."; "Peso"="O peso da máscara (não em kg)."; "Dur."="Pontos totais de durabilidade da máscara."; "Anti-Veneno"="O nível de proteção contra gás venenoso (Forte > Médio > Fraco)."; "Anti-Flash"="O nível de proteção contra granadas de luz (Forte > Médio > Fraco > Não possui)." }
            }
        }
        "Mask" {
            return @{
                Criteria = @("Alfabético", "Peso", "Durabilidade", "Classe de Blindagem", "Chance de Ricochete")
                BtnFilterText = "Filtros (Indisponível)" 
                ColumnLayout = @{ "Nome"=@{W=30;M=200}; "Peso"=@{W=10;M=60}; "Dur."=@{W=10;M=60}; "Cl"=@{W=10;M=50}; "Material"=@{W=20;M=100}; "Chance de Ricochete"=@{W=20;M=120} }
                Tooltips = @{ "Nome"="O nome do item."; "Peso"="O peso da máscara em quilogramas (kg)."; "Dur."="Pontos totais de durabilidade da máscara."; "Cl"="A Classe de Blindagem da máscara (de 1 a 6)."; "Material"="O material principal de fabricação da máscara."; "Chance de Ricochete"="A chance de um projétil ricochetear na máscara (Alto > Médio > Baixo)." }
            }
        }
        "Throwable" {
            return @{
                Criteria = @("Alfabético", "Delay de Explosão", "Alcance", "Dano em Blindagem", "Penetração", "Fragmentos", "Tipo de Frags.", "Tempo de Efeito")
                BtnFilterText = "Filtros (Indisponível)" 
                ColumnLayout = @{ "Nome"=@{W=25;M=180}; "Delay Explosão"=@{W=10;M=80}; "Alcance"=@{W=10;M=80}; "Dano Blind"=@{W=10;M=80}; "Penetração"=@{W=10;M=80}; "Fragmentos"=@{W=10;M=80}; "Tipo Frags."=@{W=15;M=100}; "Tempo Efeito"=@{W=10;M=80} }
                Tooltips = @{ "Delay de Explosão"="O tempo mínimo e máximo em segundos para a detonação."; "Alcance"="O raio efetivo da granada (Muito Longo > Longo > Padrão)."; "Dano Blind"="O potencial de dano contra blindagem (Superior > Padrão)."; "Penetração"="A capacidade de penetrar blindagens (Superior > Padrão)."; "Fragmentos"="A quantidade de fragmentos gerados (Grande > Pequeno)."; "Tipo Frags."="O tipo de material dos fragmentos (Peça de aço > Peça de ferro)."; "Tempo Efeito"="A duração em segundos de efeitos contínuos (fumaça, gás, fogo)." }
            }
        }
        "Gastronomy" {
            return @{
                Criteria = @("Alfabético", "Hidratação", "Energia", "Hidratação por Slot", "Energia por Slot")
                BtnFilterText = "Filtros (Indisponível)" 
                ColumnLayout = @{ "Nome"=@{W=30;M=180}; "Hidratação"=@{W=10;M=70}; "Energia"=@{W=10;M=70}; "Rec.Stamina"=@{W=10;M=80}; "Espaço (HxV)"=@{W=10;M=80}; "Hidrat.Slot"=@{W=10;M=80}; "Energ.Slot"=@{W=10;M=80}; "Delay"=@{W=5;M=50} }
                Tooltips = @{ "Nome"="O nome do item."; "Hidratação"="Pontos de hidratação que o item recupera (pode ser negativo)."; "Energia"="Pontos de energia que o item recupera (pode ser negativo)."; "Rec.Stamina"="Nível de recuperação de estamina (fôlego)."; "Espaço (HxV)"="Formato 'Horizontal x Vertical' que indica o número de slots ocupados pelo item no inventário."; "Hidrat.Slot"="Custo-benefício de HIDRATAÇÃO POR SLOT."; "Energ.Slot"="Custo-benefício de ENERGIA POR SLOT."; "Delay"="Tempo em segundos para consumir completamente o item." }
            }
        }
        "Pharmaceutical" {
            $defaultCrit = @("Alfabético")
            $layout = @{}
            $tooltips = @{}

            switch ($Category) {
                "Analgesico" {
                    $defaultCrit = @("Usos", "Duração", "Desidratação", "Duração Máxima")
                    $layout = [ordered]@{ "Nome"=@{W=25;M=150}; "Usos"=@{W=5;M=40}; "Duração"=@{W=18;M=100}; "Desidratação"=@{W=13;M=80}; "Tempo de Atraso"=@{W=17;M=90}; "Dur. Max"=@{W=18;M=100}; "Des. Max"=@{W=10;M=80} }
                    $tooltips = @{ "Usos"="Quantidade de vezes que o item pode ser usado."; "Duração"="Tempo do efeito em segundos para um único uso."; "Desidratação"="Pontos de hidratação perdidos por uso."; "Tempo de Atraso"="Tempo em segundos para consumir o item."; "Dur. Max"="Duração máxima total do efeito (Usos * Duração)."; "Des. Max"="Desidratação máxima total." }
                }
                "Bandagem" {
                    $defaultCrit = @("Padrão")
                    $layout = [ordered]@{ "Nome"=@{W=25;M=150}; "Usos"=@{W=5;M=40}; "Tempo de Atraso"=@{W=16;M=100}; "Custo Durabilidade"=@{W=20;M=120} }
                    $tooltips = @{ "Usos"="Quantidade de vezes que o item pode ser usado."; "Tempo de Atraso"="Tempo em segundos para aplicar o item."; "Custo Durabilidade"="Pontos de durabilidade gastos por uso em um kit médico." }
                }
                "Kit cirurgico" {
                    $defaultCrit = @("Usos", "Tempo de Atraso", "Desidratação", "Recuperação por Uso", "Espaço (HxV)")
                    $layout = [ordered]@{ "Nome"=@{W=30;M=180}; "Usos"=@{W=5;M=40}; "Tempo de Atraso"=@{W=15;M=100}; "Desidratação"=@{W=13;M=80}; "Rec. HP"=@{W=9;M=60}; "Custo Dur."=@{W=11;M=80}; "Espaco (HxV)"=@{W=12;M=80} }
                    $tooltips = @{ "Usos"="Quantidade de vezes que o item pode ser usado."; "Tempo de Atraso"="Tempo em segundos para aplicar o item."; "Desidratação"="Pontos de hidratação perdidos ao usar o item."; "Rec. HP"="Pontos de vida (HP) recuperados por uso."; "Custo Dur."="Pontos de durabilidade gastos por uso em um kit médico."; "Espaco (HxV)"="Formato 'Horizontal x Vertical' dos slots ocupados." }
                }
                "Nebulizador" {
                    $defaultCrit = @("Padrão")
                    $layout = [ordered]@{ "Nome"=@{W=25;M=150}; "Usos"=@{W=5;M=40}; "Tempo de Atraso"=@{W=16;M=100}; "Custo Durabilidade"=@{W=20;M=120} }
                    $tooltips = @{ "Usos"="Quantidade de vezes que o item pode ser usado."; "Tempo de Atraso"="Tempo em segundos para aplicar o item."; "Custo Durabilidade"="Pontos de durabilidade gastos por uso em um kit médico." }
                }
                "Kit medico" {
                    $defaultCrit = @("Durabilidade", "Desidratação", "Velocidade de Cura", "Delay", "Espaço (HxV)", "Durabilidade por Slot")
                    $layout = [ordered]@{ "Nome"=@{W=26;M=160}; "Durabilidade"=@{W=10;M=80}; "Desidratação"=@{W=10;M=80}; "Vel. Cura"=@{W=10;M=80}; "Delay"=@{W=6;M=50}; "Custo Dur."=@{W=10;M=80}; "Espaco (HxV)"=@{W=10;M=80}; "Durab. p/ Slot"=@{W=14;M=100} }
                    $tooltips = @{ "Durabilidade"="Pontos totais de durabilidade do kit."; "Desidratação"="Pontos de hidratação perdidos ao usar o kit."; "Vel. Cura"="Velocidade com que o kit cura ferimentos."; "Delay"="Tempo em segundos para aplicar o item."; "Custo Dur."="Quantidade de durabilidade gasta por uso."; "Espaco (HxV)"="Formato 'Horizontal x Vertical' dos slots ocupados."; "Durab. p/ Slot"="Custo-benefício de DURABILIDADE POR SLOT." }
                }
                "Estimulantes" {
                    $defaultCrit = @("Padrão")
                    $layout = [ordered]@{ "Nome"=@{W=25;M=150}; "Efeito Principal"=@{W=17;M=120}; "Duração"=@{W=15;M=90}; "Desidratação"=@{W=10;M=70}; "Red. Energia"=@{W=10;M=70}; "Delay"=@{W=6;M=50} }
                    $tooltips = @{ "Efeito Principal"="O principal bônus fornecido pelo estimulante."; "Duração"="Tempo do efeito em segundos."; "Desidratação"="Pontos de hidratação perdidos ao usar o item."; "Red. Energia"="Pontos de energia perdidos ao usar o item."; "Delay"="Tempo em segundos para aplicar o item." }
                }
            }

            return @{
                Criteria = $defaultCrit
                BtnFilterText = "Filtros (Indisponível)" 
                ColumnLayout = $layout
                Tooltips = $tooltips
            }
        }
    }
}


function Get-AmmoData {
    if ($script:cachedAmmoData) { $script:cachedAmmoData = $null }

    $folderPath = Get-DatabasePath
    $csvPath = Join-Path -Path $folderPath -ChildPath "Ammo.csv"
    
    if (-not (Test-Path $csvPath)) { return @() }
    
    $data = Import-Csv -Path $csvPath -Delimiter ";" -Encoding UTF8
    $results = @()
    foreach ($row in $data) {
        $chanceRaw = $row.ChanceFerir
        $chanceDisplay = switch ($chanceRaw) { 'Low' {'Baixo'}; 'Medium' {'Médio'}; 'High' {'Alto'}; default {'//////'} }
        $chanceNum = switch ($chanceRaw) { 'Low' {1}; 'Medium' {2}; 'High' {3}; default {0} }
        
        $danoBaseNum = 0
        if ($row.DanoBase -match '\((\d+)\)') { $danoBaseNum = [int]$Matches[1] } 
        else { 
            $clean = $row.DanoBase -replace '[^\d]', ''
            if ($clean) { $danoBaseNum = [int]$clean }
        }

        $results += [PSCustomObject]@{ 
            Nome = $row.NomeItem
            Lv = [int]$row.NivelPenetracao
            Penetracao = $row.Penetracao; PenetracaoNum = [int]$row.Penetracao
            DanoBase = $row.DanoBase; DanoBaseNum = $danoBaseNum
            DanoArmadura = $row.DanoBlindagem; DanoArmaduraNum = [int]$row.DanoBlindagem
            Velocidade = [int]$row.Velocidade
            Precisao = $row.Precisao; PrecisaoNum = [int]$row.Precisao
            RecuoVert = $row.RecuoVertical; RecuoVertNum = [int]$row.RecuoVertical
            RecuoHoriz = $row.RecuoHorizontal; RecuoHorizNum = [int]$row.RecuoHorizontal
            ChanceFerir = $chanceRaw; ChanceFerirDisplay = $chanceDisplay; ChanceFerirNum = $chanceNum
            Calibre = $row.Calibre
        }
    }
    return $results
}


function Sort-MaskDataComplex {
    param ($Data, $Criterion, $Order)

    $expPeso       = { [double]$_.Weight }
    $expDurab      = { [double]$_.Durability }
    $expArmor      = { [int]$_.ArmorClass }
    $expRicochete  = { [int]$_.RicocheteNum }

    # Controle de Direção Dinâmica
    $userWantsDescending = ($Order -eq "Decrescente") 
    $descNormal  = $userWantsDescending      # Maior = Melhor (Durabilidade, Blindagem, Ricochete)
    $descInverso = -not $userWantsDescending # Menor = Melhor (Peso)
    
    $primaryExpr = $null
    $primaryDesc = $descNormal

    switch ($Criterion) {
        "Alfabético"          { $primaryExpr = { $_.Nome }; $primaryDesc = $false; if ($userWantsDescending) { $primaryDesc = $true } }
        "Peso"                { $primaryExpr = $expPeso; $primaryDesc = $descInverso }
        "Durabilidade"        { $primaryExpr = $expDurab }
        "Classe de Blindagem" { $primaryExpr = $expArmor }
        "Chance de Ricochete" { $primaryExpr = $expRicochete }
        Default               { $primaryExpr = { $_.Nome } }
    }

    $ordenacaoParams = @()
    $ordenacaoParams += @{ Expression = $primaryExpr; Descending = $primaryDesc }

    # Tie-Breakers (ATUALIZADO)
    switch ($Criterion) {
        "Peso" {
            $ordenacaoParams += @{ Expression = $expArmor; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expDurab; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expRicochete; Descending = $descNormal }
        }
        "Durabilidade" {
            # 1. Maior Classe de Blindagem
            $ordenacaoParams += @{ Expression = $expArmor; Descending = $descNormal }
            # 2. Maior Chance de Ricochete (NOVO: Subiu para 2º lugar)
            $ordenacaoParams += @{ Expression = $expRicochete; Descending = $descNormal }
            # 3. Menor Peso (Caiu para 3º lugar)
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
        }
        "Classe de Blindagem" {
            # 1. Maior Durabilidade
            $ordenacaoParams += @{ Expression = $expDurab; Descending = $descNormal }
            # 2. Maior Chance de Ricochete (NOVO: Subiu para 2º lugar)
            $ordenacaoParams += @{ Expression = $expRicochete; Descending = $descNormal }
            # 3. Menor Peso (Caiu para 3º lugar)
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
        }
        "Chance de Ricochete" {
            $ordenacaoParams += @{ Expression = $expArmor; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expDurab; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
        }
    }
    return $Data | Sort-Object -Property $ordenacaoParams
}


function Get-ArmorData {
    $folderPath = Get-DatabasePath
    $csvPath = Join-Path -Path $folderPath -ChildPath "Bodyarmors.csv"
    
    if (-not (Test-Path $csvPath)) { 
        Write-Warning "Arquivo Bodyarmors.csv não encontrado em: $csvPath"
        return @() 
    }
    
    $data = Import-Csv -Path $csvPath -Delimiter ";" -Encoding UTF8
    $results = @()

    $materialMap = @{ "Aramid"="Aramida"; "Polyethylene"="Polietileno"; "Hardened Steel"="Aço endurecido"; "Composite"="Composto"; "Aluminum"="Alumínio"; "Titanium"="Titânio"; "Ceramic"="Cerâmica" }
    $areaMapDisplay = @{ "Chest"="Tórax"; "Chest, Upper Abdomen"="Tórax, Abdômen Superior"; "Chest, Shoulder, Upper Abdomen"="Tórax, Ombro, Abdômen Superior"; "Chest, Upper Abdomen, Lower Abdomen"="Tórax, Abdômen Superior, Abdômen Inferior"; "Chest, Shoulder, Upper Abdomen, Lower Abdomen"="Tórax, Ombro, Abdômen Superior, Abdômen Inferior" }
    $areaMapRank = @{ "Chest"=1; "Chest, Upper Abdomen"=2; "Chest, Shoulder, Upper Abdomen"=3; "Chest, Upper Abdomen, Lower Abdomen"=4; "Chest, Shoulder, Upper Abdomen, Lower Abdomen"=5 }

    foreach ($row in $data) {
        $matDisp = if ($materialMap.ContainsKey($row.Material)) { $materialMap[$row.Material] } else { $row.Material }
        $areaDisp = if ($areaMapDisplay.ContainsKey($row.AreaProtegida)) { $areaMapDisplay[$row.AreaProtegida] } else { $row.AreaProtegida }
        
        $velNum = if ($row.PenalidadeMovimento -eq '/////' -or -not $row.PenalidadeMovimento) { 0 } else { [int]($row.PenalidadeMovimento -replace '%', '') }
        $ergoNum = if ($row.Ergonomia -eq '/////' -or -not $row.Ergonomia) { 0 } else { [int]$row.Ergonomia }
        $areaRank = if ($areaMapRank.ContainsKey($row.AreaProtegida)) { $areaMapRank[$row.AreaProtegida] } else { 0 }

        $obj = [PSCustomObject]@{
            Nome                 = $row.NomeItem
            Weight               = if ($row.Peso) { [double]$row.Peso } else { 0 }
            Durability           = if ($row.Durabilidade) { [double]$row.Durabilidade } else { 0 }
            WeightDisplay        = $row.Peso
            DurabilityDisplay    = $row.Durabilidade
            ArmorClass           = if ($row.ClasseBlindagem) { [int]$row.ClasseBlindagem } else { 0 }
            MaterialDisplay      = $matDisp
            MovementSpeed        = $row.PenalidadeMovimento
            MovementSpeedNum     = $velNum
            Ergonomics           = $row.Ergonomia
            ErgonomicsNum        = $ergoNum
            AreaDisplay          = $areaDisp
            AreaNum              = $areaRank
        }
        $results += $obj
    }
    return $results
}


function Sort-BackpackDataComplex {
    param ($Data, $Criterion, $Order)

    $expPeso       = { [double]$_.Weight }
    $expStorage    = { [int]$_.Storage }
    $expEfficiency = { [int]$_.Efficiency }
    $expBlock      = { [double]$_.BlockSortingScore }
    $expSetCount   = { [int]$_.SetCount } 
    $expUnfolded   = { [int]$_.UnfoldedArea }

    # Controle de Direção Dinâmica
    $userWantsDescending = ($Order -eq "Decrescente") 
    $descNormal  = $userWantsDescending      # Maior = Melhor (Espaço, Eficiência, Blocos)
    $descInverso = -not $userWantsDescending # Menor = Melhor (Peso, Tamanho Desdobrado)
    
    # Menor quantidade de bolsos geralmente é melhor (bolsos maiores e unificados)
    $descSetCount = -not $userWantsDescending 

    $primaryExpr = $null
    $primaryDesc = $descNormal

    switch ($Criterion) {
        "Alfabético"                          { $primaryExpr = { $_.Nome }; $primaryDesc = $false; if ($userWantsDescending) { $primaryDesc = $true } }
        "Peso"                                { $primaryExpr = $expPeso; $primaryDesc = $descInverso }
        "Armazenamento"                       { $primaryExpr = $expStorage }
        "Conjunto de Blocos (HxV)"            { $primaryExpr = $expBlock }
        "+Espaço p/ Armaz. -Espaço Consumido" { $primaryExpr = $expEfficiency }
        Default                               { $primaryExpr = { $_.Nome } }
    }

    $ordenacaoParams = @()
    $ordenacaoParams += @{ Expression = $primaryExpr; Descending = $primaryDesc }

    # Tie-Breakers (Baseado no Script Antigo + Melhoria de Desempate)
    switch ($Criterion) {
        "Peso" {
            $ordenacaoParams += @{ Expression = $expStorage; Descending = $descNormal }
        }
        "Armazenamento" {
            $ordenacaoParams += @{ Expression = $expBlock; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expUnfolded; Descending = $descInverso } # Menor tamanho desdobrado ajuda
            $ordenacaoParams += @{ Expression = $expEfficiency; Descending = $descNormal }
        }
        "Conjunto de Blocos (HxV)" {
            $ordenacaoParams += @{ Expression = $expStorage; Descending = $descNormal }
        }
        "+Espaço p/ Armaz. -Espaço Consumido" {
            # 1º Desempate: Menor Tamanho Desdobrado (Reaproveitado da alteração anterior)
            $ordenacaoParams += @{ Expression = $expUnfolded; Descending = $descInverso }
            
            $ordenacaoParams += @{ Expression = $expStorage; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expSetCount; Descending = $descSetCount }
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
        }
    }
    return $Data | Sort-Object -Property $ordenacaoParams
}


function Show-HelmetFilterDialog {
    param(
        [Parameter(Mandatory=$true)] $Data,
        [Parameter(Mandatory=$true)] $ThemeColors
    )

    $dlg = New-Object System.Windows.Forms.Form; $dlg.Text = "Filtro de Capacetes"; $dlg.Size = New-Object System.Drawing.Size(1200, 600); $dlg.StartPosition = "CenterParent"; $dlg.FormBorderStyle = "FixedDialog"; $dlg.MaximizeBox = $false
    $dlg.BackColor = $ThemeColors.Background; $dlg.ForeColor = $ThemeColors.TextMain

    # 1. Copia filtros globais existentes
    $tempManualFilters = @{}; foreach ($k in $script:manualFilters.Keys) { $tempManualFilters[$k] = [System.Collections.ArrayList]@($script:manualFilters[$k]) }
    
    # 2. Define as Ordens Personalizadas (Com redundância de acentos para segurança total)
    $customOrderClass     = @("1", "2", "3", "4", "5", "6")
    $customOrderBlock     = @("/////", "Baixo", "Moderado", "Grave")
    $customOrderArea      = @("Cabeça", "Cabeça, Ouvidos", "Cabeça, Ouvidos, Rosto", "Cabeca", "Cabeca, Ouvidos", "Cabeca, Ouvidos, Rosto")
    $customOrderRicochet  = @("Baixo", "Médio", "Alto", "Medio")
    $customOrderAccessory = @("/////", "TE", "Máscara", "Máscara, TE", "Mascara", "Mascara, TE")
    $customOrderMasc      = @("/////", "1", "2", "3", "4", "5", "6") # Sequência lógica para máscaras

    # 3. Define as 6 Colunas na ordem correta
    $filterDefs = @(
        @{Title="Classe (Cl)";             Prop="ArmorClass";       ColIndex=0; CustomOrder=$customOrderClass},
        @{Title="Bloqueio Sonoro";         Prop="BloqueioDisplay";  ColIndex=1; CustomOrder=$customOrderBlock},
        @{Title="Área Protegida";          Prop="AreaDisplay";      ColIndex=2; CustomOrder=$customOrderArea},
        @{Title="Ricochete";               Prop="RicochDisplay";    ColIndex=3; CustomOrder=$customOrderRicochet},
        @{Title="Acessório";               Prop="AcessorioDisplay"; ColIndex=4; CustomOrder=$customOrderAccessory},
        @{Title="Máscara (Classe Máxima)"; Prop="ClMaxMascValue";   ColIndex=5; CustomOrder=$customOrderMasc}
    )

    # Inicializa chaves que faltam para evitar erro de nulo
    foreach ($def in $filterDefs) {
        if (-not $tempManualFilters.ContainsKey($def.Prop)) {
            $tempManualFilters[$def.Prop] = New-Object System.Collections.ArrayList
        }
    }
    
    $visualState = @{} 
    # Layout de 6 colunas (aprox 16.6% cada)
    $mainLayout = New-Object System.Windows.Forms.TableLayoutPanel; $mainLayout.Dock = "Top"; $mainLayout.Height = 480; $mainLayout.ColumnCount = 6
    for($i=0; $i -lt 6; $i++){ $mainLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 16.66))) | Out-Null }
    $allCheckBoxes = @()

    $script:UpdateFilterUI = {
        $survivors = New-Object System.Collections.Generic.List[Object]; foreach ($item in $Data) { $isSurvivor = $true; foreach ($k in $tempManualFilters.Keys) { $filterList = $tempManualFilters[$k]; if ($filterList.Count -eq 0) { continue }; if ($filterList -contains $item.($k)) { $isSurvivor = $false; break } }; if ($isSurvivor) { $survivors.Add($item) } }
        $availableValues = @{}; foreach ($k in $script:manualFilters.Keys) { $availableValues[$k] = New-Object System.Collections.Generic.HashSet[string] }
        foreach ($def in $filterDefs) { if (-not $availableValues.ContainsKey($def.Prop)) { $availableValues[$def.Prop] = New-Object System.Collections.Generic.HashSet[string] } }

        foreach ($item in $survivors) { foreach ($k in $availableValues.Keys) { $val = $item.($k); if (-not [string]::IsNullOrEmpty($val)) { $availableValues[$k].Add($val) | Out-Null } } }
        
        foreach ($cb in $allCheckBoxes) {
            $prop = $cb.Tag.Prop; $val = $cb.Tag.Value; $uKey = $cb.Tag.UniqueKey
            if ($tempManualFilters[$prop].Contains($val)) { $visualState[$uKey] = 'M'; $cb.Checked = $true; $cb.BackColor = [System.Drawing.Color]::Empty; $cb.ForeColor = $ThemeColors.OrangeAccent; $cb.Enabled = $true }
            elseif (-not $availableValues[$prop].Contains($val)) { $visualState[$uKey] = 'A'; $cb.Checked = $true; $cb.BackColor = $ThemeColors.ButtonBack; $cb.ForeColor = $ThemeColors.TextDim }
            else { $visualState[$uKey] = 'F'; $cb.Checked = $false; $cb.BackColor = [System.Drawing.Color]::Empty; $cb.ForeColor = $ThemeColors.TextMain }
        }
    }

    foreach ($def in $filterDefs) {
        $gb = New-Object System.Windows.Forms.GroupBox; $gb.Text = $def.Title; $gb.Dock = "Fill"; $gb.ForeColor = $ThemeColors.TextMain
        $flow = New-Object System.Windows.Forms.FlowLayoutPanel; $flow.Dock = "Fill"; $flow.FlowDirection = "TopDown"; $flow.AutoScroll = $true; $flow.WrapContents = $false
        $rawValues = $Data | Select-Object -ExpandProperty $def.Prop -Unique
        
        $orderedValues = @()
        if ($def.CustomOrder) { 
            # Adiciona na ordem do CustomOrder se existir no RawValues
            foreach ($orderedItem in $def.CustomOrder) { 
                # Truque para lidar com tipos diferentes (int vs string) na comparação
                $exists = $false
                foreach($r in $rawValues) { if("$r" -eq "$orderedItem") { $exists = $true; break } }
                if ($exists) { $orderedValues += $orderedItem } 
            }
            # Adiciona o restante que não estava na lista customizada
            foreach ($rawItem in $rawValues) { 
                $isInList = $false
                foreach($o in $orderedValues) { if("$o" -eq "$rawItem") { $isInList = $true; break } }
                if (-not $isInList) { $orderedValues += $rawItem } 
            } 
        } else { 
            $orderedValues = $rawValues | Sort-Object 
        }

        foreach ($val in $orderedValues) {
            if ([string]::IsNullOrWhiteSpace($val) -and $val -ne "/////") { continue } # Ignora vazio, mas aceita /////
            $cb = New-Object System.Windows.Forms.CheckBox; $cb.Text = "$val"; $cb.AutoSize = $true; $cb.AutoCheck = $false; $cb.Tag = @{ Prop = $def.Prop; Value = $val; UniqueKey = "$($def.Prop)_$val" }
            $cb.ForeColor = $ThemeColors.TextMain
            $cb.Add_Click({ param($sender, $e) $prop = $sender.Tag.Prop; $v = $sender.Tag.Value; $k = $sender.Tag.UniqueKey; $state = $visualState[$k]; if ($state -eq 'A') { return }; if ($tempManualFilters[$prop].Contains($v)) { $tempManualFilters[$prop].Remove($v) } else { $tempManualFilters[$prop].Add($v) | Out-Null }; & $script:UpdateFilterUI })
            $flow.Controls.Add($cb); $allCheckBoxes += $cb
        }
        $gb.Controls.Add($flow); $mainLayout.Controls.Add($gb, $def.ColIndex, 0)
    }

    & $script:UpdateFilterUI

    $btnPanel = New-Object System.Windows.Forms.Panel; $btnPanel.Dock = "Bottom"; $btnPanel.Height = 60; $btnPanel.BackColor = $ThemeColors.Background
    $btnReset = New-Object System.Windows.Forms.Button; $btnReset.Text = "Resetar Filtros"; $btnReset.Size = New-Object System.Drawing.Size(150, 40); $btnReset.Location = New-Object System.Drawing.Point(300, 10); $btnReset.FlatStyle = "Flat"
    $btnReset.BackColor = $ThemeColors.ButtonBack; $btnReset.ForeColor = $ThemeColors.TextMain; $btnReset.FlatAppearance.BorderColor = $ThemeColors.OrangeAccent
    $btnReset.Add_Click({ foreach ($k in $tempManualFilters.Keys) { $tempManualFilters[$k].Clear() }; & $script:UpdateFilterUI })

    $btnOk = New-Object System.Windows.Forms.Button; $btnOk.Text = "Confirmar Filtros"; $btnOk.Size = New-Object System.Drawing.Size(200, 40); $btnOk.Location = New-Object System.Drawing.Point(460, 10); $btnOk.DialogResult = "OK"; $btnOk.FlatStyle = "Flat"
    $btnOk.BackColor = $ThemeColors.OrangeAccent; $btnOk.ForeColor = $ThemeColors.Background; $btnOk.FlatAppearance.BorderSize = 0
    
    $btnPanel.Controls.Add($btnReset); $btnPanel.Controls.Add($btnOk); $dlg.Controls.AddRange(@($mainLayout, $btnPanel)); $res = $dlg.ShowDialog()
    
    if ($res -eq "OK") { 
        # Atualiza a variável global garantindo que as chaves existam
        foreach($k in $tempManualFilters.Keys) { 
            if (-not $script:manualFilters.ContainsKey($k)) {
                $script:manualFilters[$k] = [System.Collections.ArrayList]@()
            }
            $script:manualFilters[$k] = $tempManualFilters[$k] 
        } 
    }

    # --- CORREÇÃO MEMORY LEAK: Liberta os recursos da janela da RAM ---
    $dlg.Dispose()
}


function Show-AmmoFilterDialog {
    param($ThemeColors)
    
    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = "Filtros de Munição - Marque o que deseja OCULTAR"
    $dlg.Size = New-Object System.Drawing.Size(900, 500) 
    $dlg.StartPosition = "CenterParent"
    $dlg.FormBorderStyle = "FixedDialog"
    $dlg.MaximizeBox = $false
    $dlg.BackColor = $ThemeColors.Background
    $dlg.ForeColor = $ThemeColors.TextMain

    # 1. Clona filtros globais
    $keysToCheck = @("Lv", "Calibre", "ChanceFerirDisplay")
    foreach ($k in $keysToCheck) { if (-not $script:manualFilters.ContainsKey($k)) { $script:manualFilters[$k] = [System.Collections.ArrayList]@() } }

    $tempManualFilters = @{}
    foreach ($k in $script:manualFilters.Keys) { $tempManualFilters[$k] = [System.Collections.ArrayList]@($script:manualFilters[$k]) }

    # 2. Definições
    $customOrderWound = @("//////", "Baixo", "Médio", "Medio", "Alto")
    $filterDefs = @(
        @{Title="Níveis (Lv)";       Prop="Lv";                 ColIndex=0},
        @{Title="Calibres";          Prop="Calibre";            ColIndex=1},
        @{Title="Chance de Ferir";   Prop="ChanceFerirDisplay"; ColIndex=2; CustomOrder=$customOrderWound}
    )

    foreach ($def in $filterDefs) { if (-not $tempManualFilters.ContainsKey($def.Prop)) { $tempManualFilters[$def.Prop] = New-Object System.Collections.ArrayList } }

    # 3. Layout (3 Colunas)
    $mainLayout = New-Object System.Windows.Forms.TableLayoutPanel
    $mainLayout.Dock = "Top"; $mainLayout.Height = 380
    $mainLayout.ColumnCount = 3
    $mainLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null
    $mainLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 50))) | Out-Null
    $mainLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 30))) | Out-Null

    $visualState = @{}
    $allCheckBoxes = @()

    # 4. Lógica de Atualização (COM CORREÇÃO COSMÉTICA DE FUNDO)
    $script:UpdateAmmoUI = {
        # Calcula Sobreviventes
        $survivors = New-Object System.Collections.Generic.List[Object]
        foreach ($item in $script:cachedAmmoData) { 
            $isSurvivor = $true
            foreach ($k in $tempManualFilters.Keys) { 
                $filterList = $tempManualFilters[$k]
                if ($filterList.Count -eq 0) { continue }
                if ($filterList -contains $item.($k)) { 
                    $isSurvivor = $false; break 
                } 
            }
            if ($isSurvivor) { $survivors.Add($item) } 
        }

        # Calcula Disponíveis
        $availableValues = @{}
        foreach ($k in $script:manualFilters.Keys) { $availableValues[$k] = New-Object System.Collections.Generic.HashSet[string] }
        foreach ($def in $filterDefs) { if (-not $availableValues.ContainsKey($def.Prop)) { $availableValues[$def.Prop] = New-Object System.Collections.Generic.HashSet[string] } }

        foreach ($item in $survivors) { 
            foreach ($k in $availableValues.Keys) { 
                $val = $item.($k)
                if (-not [string]::IsNullOrEmpty("$val")) { $availableValues[$k].Add("$val") | Out-Null } 
            } 
        }
        
        # Atualiza Visual (Checkboxes)
        foreach ($cb in $allCheckBoxes) {
            $prop = $cb.Tag.Prop; $val = $cb.Tag.Value; $uKey = $cb.Tag.UniqueKey
            
            # M (Marcado Manualmente) -> Laranja, Fundo Vazio
            if ($tempManualFilters[$prop].Contains($val)) { 
                $visualState[$uKey] = 'M'
                $cb.Checked = $true
                $cb.Enabled = $true
                $cb.ForeColor = $ThemeColors.OrangeAccent 
                $cb.BackColor = [System.Drawing.Color]::Empty # Fundo normal
            }
            # A (Automático/Indisponível) -> Cinza, FUNDO DESTACADO (ButtonBack)
            elseif (-not $availableValues[$prop].Contains("$val")) { 
                $visualState[$uKey] = 'A'
                $cb.Checked = $true 
                $cb.ForeColor = $ThemeColors.TextDim 
                $cb.BackColor = $ThemeColors.ButtonBack # <--- EFEITO MARCA-TEXTO ACINZENTADO
            }
            # F (Livre) -> Branco, Fundo Vazio
            else { 
                $visualState[$uKey] = 'F'
                $cb.Checked = $false
                $cb.ForeColor = $ThemeColors.TextMain 
                $cb.BackColor = [System.Drawing.Color]::Empty # Fundo normal
            }
        }
    }

    # 5. Construção UI
    foreach ($def in $filterDefs) {
        $gb = New-Object System.Windows.Forms.GroupBox; $gb.Text = $def.Title; $gb.Dock = "Fill"; $gb.ForeColor = $ThemeColors.TextMain
        $flow = New-Object System.Windows.Forms.FlowLayoutPanel; $flow.Dock = "Fill"; $flow.FlowDirection = "TopDown"; $flow.AutoScroll = $true; $flow.WrapContents = $false
        
        $rawValues = $script:cachedAmmoData | Select-Object -ExpandProperty $def.Prop -Unique
        
        $orderedValues = @()
        if ($def.CustomOrder) { 
            foreach ($orderedItem in $def.CustomOrder) { 
                foreach ($r in $rawValues) { if ("$r" -eq "$orderedItem") { $orderedValues += $r; break } }
            }
            foreach ($r in $rawValues) { if ($orderedValues -notcontains $r) { $orderedValues += $r } } 
        } else { $orderedValues = $rawValues | Sort-Object }

        foreach ($val in $orderedValues) {
            if ([string]::IsNullOrWhiteSpace("$val")) { continue }
            
            $cb = New-Object System.Windows.Forms.CheckBox; $cb.Text = "$val"; $cb.AutoSize = $true; $cb.AutoCheck = $false
            $cb.Tag = @{ Prop = $def.Prop; Value = "$val"; UniqueKey = "$($def.Prop)_$val" }
            $cb.ForeColor = $ThemeColors.TextMain
            
            $cb.Add_Click({ 
                param($sender, $e) 
                $prop = $sender.Tag.Prop; $v = $sender.Tag.Value; $k = $sender.Tag.UniqueKey
                $state = $visualState[$k]
                
                # Bloqueia clique se for Automático (A)
                if ($state -eq 'A') { return }
                
                if ($tempManualFilters[$prop].Contains($v)) { 
                    $tempManualFilters[$prop].Remove($v) 
                } else { 
                    $tempManualFilters[$prop].Add($v) | Out-Null 
                }
                & $script:UpdateAmmoUI 
            })
            $flow.Controls.Add($cb); $allCheckBoxes += $cb
        }
        $gb.Controls.Add($flow); $mainLayout.Controls.Add($gb, $def.ColIndex, 0)
    }

    & $script:UpdateAmmoUI

    # 6. Botões
    $btnPanel = New-Object System.Windows.Forms.Panel; $btnPanel.Dock = "Bottom"; $btnPanel.Height = 60; $btnPanel.BackColor = $ThemeColors.Background
    
    $btnReset = New-Object System.Windows.Forms.Button; $btnReset.Text = "Resetar"; $btnReset.Size = New-Object System.Drawing.Size(150, 35); $btnReset.Location = New-Object System.Drawing.Point(280, 12)
    $btnReset.FlatStyle = "Flat"; $btnReset.BackColor = $ThemeColors.ButtonBack; $btnReset.ForeColor = $ThemeColors.TextMain
    $btnReset.Add_Click({ 
        foreach ($k in $tempManualFilters.Keys) { $tempManualFilters[$k].Clear() }
        & $script:UpdateAmmoUI 
    })

    $btnOk = New-Object System.Windows.Forms.Button; $btnOk.Text = "Confirmar"; $btnOk.DialogResult = "OK"
    $btnOk.Size = New-Object System.Drawing.Size(150, 35); $btnOk.Location = New-Object System.Drawing.Point(450, 12)
    $btnOk.FlatStyle = "Flat"; $btnOk.BackColor = $ThemeColors.OrangeAccent; $btnOk.ForeColor = $ThemeColors.Background
    
    $btnPanel.Controls.AddRange(@($btnReset, $btnOk)); $dlg.Controls.AddRange(@($mainLayout, $btnPanel))

    if ($dlg.ShowDialog() -eq "OK") { 
        foreach($k in $tempManualFilters.Keys) { $script:manualFilters[$k] = $tempManualFilters[$k] } 
    }

    # --- CORREÇÃO MEMORY LEAK: Liberta os recursos da janela da RAM ---
    $dlg.Dispose()
}


function Sort-HelmetDataComplex {
    param ($Data, $Criterion, $Order)

    # --- 1. Mapas de Peso para Conversão Lógica ---
    $bloqueioWeights  = @{ "/////"=0; "Baixo"=1; "Moderado"=2; "Grave"=3 }
    $ricocheteWeights = @{ "/////"=0; "Baixo"=1; "Médio"=2; "Medio"=2; "Alto"=3 }
    $acessorioWeights = @{ "/////"=0; "TE"=1; "Máscara"=2; "Mascara"=2; "Máscara, TE"=3; "Mascara, TE"=3 }
    $reducaoWeights   = @{ "/////"=0; "Fraco"=1; "Médio"=2; "Medio"=2; "Forte"=3 }

    # --- 2. Definição das Expressões ---
    $expBloqueio  = { $val = $_.BloqueioDisplay; if ($bloqueioWeights.ContainsKey($val)) { $bloqueioWeights[$val] } else { 0 } }
    $expRicochete = { $val = $_.RicochDisplay; if ($ricocheteWeights.ContainsKey($val)) { $ricocheteWeights[$val] } else { 0 } }
    $expAcessorio = { $val = $_.AcessorioDisplay; if ($acessorioWeights.ContainsKey($val)) { $acessorioWeights[$val] } else { 0 } }
    $expReducao   = { $val = $_.ReduRuDisplay; if ($reducaoWeights.ContainsKey($val)) { $reducaoWeights[$val] } else { 0 } }
    $expPeso      = { [double]$_.Weight }
    $expDurab     = { [double]$_.Durability }
    $expArmor     = { [int]$_.ArmorClass }
    $expClMasc    = { if ($_.ClMaxMascValue -eq '/////') { 0 } else { [int]$_.ClMaxMascValue } }

    # --- 3. Controle de Direção Dinâmica (CORREÇÃO AQUI) ---
    # Define o que o usuário quer no geral
    $userWantsDescending = ($Order -eq "Decrescente") 
    
    # Define a direção para atributos Normais (Onde Maior = Melhor: Blindagem, Durabilidade, Ricochete)
    # Se user quer Decrescente (Melhor Primeiro) -> True. Se Crescente -> False.
    $descNormal = $userWantsDescending
    
    # Define a direção para atributos Inversos (Onde Menor = Melhor: Peso, Bloqueio, Ergo)
    # Se user quer Decrescente (Melhor Primeiro) -> False (0->10). Se Crescente -> True (10->0).
    $descInverso = -not $userWantsDescending

    # --- 4. Definição do Critério Principal ---
    $primaryExpr = $null
    $primaryIsInverso = $false

    switch ($Criterion) {
        "Bloqueio"                              { $primaryExpr = $expBloqueio; $primaryIsInverso = $true }
        "Chance de Ricochete"                   { $primaryExpr = $expRicochete }
        "Acessório"                             { $primaryExpr = $expAcessorio }
        "Redução de Ruído"                      { $primaryExpr = $expReducao }
        "Peso"                                  { $primaryExpr = $expPeso; $primaryIsInverso = $true }
        "Durabilidade"                          { $primaryExpr = $expDurab }
        "Classe de Blindagem"                   { $primaryExpr = $expArmor }
        "Penalidade de Movimento"               { $primaryExpr = { [int]$_.MovementSpeedNum }; $primaryIsInverso = $true }
        "Ergonomia"                             { $primaryExpr = { [int]$_.ErgonomicsNum }; $primaryIsInverso = $true }
        "Classe Máxima da Máscara Compatível"   { $primaryExpr = $expClMasc }
        "Alfabético"                            { $primaryExpr = { $_.Nome } } # Alfabético segue padrão normal (A-Z Crescente)
        "Área Protegida"                        { $primaryExpr = { $_.AreaDisplay } }
        "Captura de Som"                        { $primaryExpr = { $_.CaptadDisplay } }
        Default                                 { $primaryExpr = { $_.Nome } }
    }

    # Calcula a direção do Critério Principal
    $primaryDesc = if ($primaryIsInverso) { $descInverso } else { $descNormal }
    
    # Exceção para Alfabético: Crescente é A-Z (False), Decrescente Z-A (True) independente da lógica de Melhor/Pior
    if ($Criterion -eq "Alfabético" -or $Criterion -eq "Área Protegida") { $primaryDesc = $userWantsDescending }

    # --- 5. Construção da Lista de Ordenação ---
    $ordenacaoParams = @()
    $ordenacaoParams += @{ Expression = $primaryExpr; Descending = $primaryDesc }

    # Adiciona os Desempates (Usando as variáveis dinâmicas $descNormal / $descInverso)
    switch ($Criterion) {
        "Peso" {
            $ordenacaoParams += @{ Expression = $expArmor; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expDurab; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expBloqueio; Descending = $descInverso }
            $ordenacaoParams += @{ Expression = $expRicochete; Descending = $descNormal }
        }
        "Durabilidade" {
            $ordenacaoParams += @{ Expression = $expArmor; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expBloqueio; Descending = $descInverso }
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
            $ordenacaoParams += @{ Expression = $expRicochete; Descending = $descNormal }
        }
        { $_ -in "Classe de Blindagem", "Classe Máxima da Máscara Compatível" } {
            $ordenacaoParams += @{ Expression = $expDurab; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expBloqueio; Descending = $descInverso }
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
        }
        { $_ -in "Bloqueio", "Penalidade de Movimento", "Ergonomia" } {
            $ordenacaoParams += @{ Expression = $expArmor; Descending = $descNormal }
            if ($Criterion -ne "Bloqueio") { $ordenacaoParams += @{ Expression = $expBloqueio; Descending = $descInverso } }
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
            $ordenacaoParams += @{ Expression = $expRicochete; Descending = $descNormal }
        }
        "Área Protegida" {
            $ordenacaoParams += @{ Expression = $expArmor; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expBloqueio; Descending = $descInverso }
            $ordenacaoParams += @{ Expression = $expDurab; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expRicochete; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
        }
        Default {
            $ordenacaoParams += @{ Expression = $expArmor; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expDurab; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expBloqueio; Descending = $descInverso }
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
            if ($Criterion -ne "Chance de Ricochete") { $ordenacaoParams += @{ Expression = $expRicochete; Descending = $descNormal } }
        }
    }

    return $Data | Sort-Object -Property $ordenacaoParams
}


function Get-PharmaceuticalData {
    param([string]$Category = "Analgesico")

    $folderPath = Get-DatabasePath
    
    $csvMap = @{
        "Analgesico"    = "Painkillers.csv"
        "Bandagem"      = "Bandages.csv"
        "Kit cirurgico" = "Surgicalkit.csv"
        "Nebulizador"   = "Nebulizers.csv"
        "Kit medico"    = "Medicalkit.csv"
        "Estimulantes"  = "Stimulants.csv"
    }

    $fileName = $csvMap[$Category]
    $csvPath = Join-Path -Path $folderPath -ChildPath $fileName
    
    if (-not (Test-Path $csvPath)) { return @() }
    
    $data = Import-Csv -Path $csvPath -Delimiter ";" -Encoding UTF8
    $results = @()

    foreach ($row in $data) {
        $obj = [PSCustomObject]@{ Nome = $row.NomeItem }

        switch ($Category) {
            "Analgesico" {
                $usosNum = [int]$row.Usos
                $durNum = if($row.Duracao -ne '/////') { [int]$row.Duracao } else { 0 }
                $desidratacaoNum = if($row.Desidratacao -ne '/////') { [int]$row.Desidratacao } else { 0 }
                
                $durMaxNum = $usosNum * $durNum
                $desMaxNum = $usosNum * $desidratacaoNum
                
                $duracaoDisplay = $row.Duracao
                if($durNum -gt 0){
                    $min=[math]::Floor($durNum/60); $sec=$durNum%60
                    if($min -gt 0 -and $sec -gt 0){$duracaoDisplay="$durNum ($($min)min/$($sec)seg)"}
                    elseif($min -gt 0){$duracaoDisplay="$durNum ($($min)min)"}
                    elseif($durNum -gt 0){$duracaoDisplay="$durNum ($($sec)seg)"}
                }
                
                $durMaxDisplay = $durMaxNum
                if($durMaxNum -gt 0){
                    $min=[math]::Floor($durMaxNum/60); $sec=$durMaxNum%60
                    if($min -gt 0 -and $sec -gt 0){$durMaxDisplay="$durMaxNum ($($min)min/$($sec)seg)"}
                    elseif($min -gt 0){$durMaxDisplay="$durMaxNum ($($min)min)"}
                    elseif($durMaxNum -gt 0){$durMaxDisplay="$durMaxNum ($($sec)seg)"}
                }

                $obj | Add-Member -MemberType NoteProperty -Name Usos -Value $row.Usos
                $obj | Add-Member -MemberType NoteProperty -Name UsosNum -Value $usosNum
                $obj | Add-Member -MemberType NoteProperty -Name Duracao -Value $duracaoDisplay
                $obj | Add-Member -MemberType NoteProperty -Name DuracaoNum -Value $durNum
                $obj | Add-Member -MemberType NoteProperty -Name Desidratacao -Value $row.Desidratacao
                $obj | Add-Member -MemberType NoteProperty -Name DesidratacaoNum -Value $desidratacaoNum
                $obj | Add-Member -MemberType NoteProperty -Name TempoAtraso -Value $row.Delay
                $obj | Add-Member -MemberType NoteProperty -Name DurMax -Value $durMaxDisplay
                $obj | Add-Member -MemberType NoteProperty -Name DesMax -Value $desMaxNum
                $obj | Add-Member -MemberType NoteProperty -Name DurMaxNum -Value $durMaxNum
                $obj | Add-Member -MemberType NoteProperty -Name DesMaxNum -Value $desMaxNum
            }
            "Bandagem" {
                $obj | Add-Member -MemberType NoteProperty -Name Usos -Value $row.Usos
                $obj | Add-Member -MemberType NoteProperty -Name UsosNum -Value ([int]$row.Usos)
                $obj | Add-Member -MemberType NoteProperty -Name TempoAtraso -Value $row.Delay
                $obj | Add-Member -MemberType NoteProperty -Name CustoDurabilidade -Value $row.CustoDurabilidade
            }
            "Kit cirurgico" {
                $slots = 1
                if ($row.EspacoOcupado -match '(\d+)x(\d+)') {
                    $h = [int]$Matches[1]; $v = [int]$Matches[2]
                    if (($h * $v) -gt 0) { $slots = $h * $v }
                }
                $desidratacaoNum = if($row.Desidratacao -ne '/////') { [int]$row.Desidratacao } else { 0 }
                
                $obj | Add-Member -MemberType NoteProperty -Name Usos -Value $row.Usos
                $obj | Add-Member -MemberType NoteProperty -Name UsosNum -Value ([int]$row.Usos)
                $obj | Add-Member -MemberType NoteProperty -Name TempoAtraso -Value $row.Delay
                $obj | Add-Member -MemberType NoteProperty -Name TempoAtrasoNum -Value ([double]$row.Delay)
                $obj | Add-Member -MemberType NoteProperty -Name Desidratacao -Value $row.Desidratacao
                $obj | Add-Member -MemberType NoteProperty -Name DesidratacaoNum -Value $desidratacaoNum
                $obj | Add-Member -MemberType NoteProperty -Name RecHP -Value $row.RecuperacaoHP
                $obj | Add-Member -MemberType NoteProperty -Name RecHPNum -Value ([int]$row.RecuperacaoHP)
                $obj | Add-Member -MemberType NoteProperty -Name CustoDur -Value $row.CustoDurabilidade
                $obj | Add-Member -MemberType NoteProperty -Name EspacoHV -Value $row.EspacoOcupado
                $obj | Add-Member -MemberType NoteProperty -Name TotalSlots -Value $slots
            }
            "Nebulizador" {
                $obj | Add-Member -MemberType NoteProperty -Name Usos -Value $row.Usos
                $obj | Add-Member -MemberType NoteProperty -Name UsosNum -Value ([int]$row.Usos)
                $obj | Add-Member -MemberType NoteProperty -Name TempoAtraso -Value $row.Delay
                $obj | Add-Member -MemberType NoteProperty -Name CustoDurabilidade -Value $row.CustoDurabilidade
            }
            "Kit medico" {
                $slots = 1
                if ($row.EspacoOcupado -match '(\d+)x(\d+)') {
                    $h = [int]$Matches[1]; $v = [int]$Matches[2]
                    if (($h * $v) -gt 0) { $slots = $h * $v }
                }
                $durabNum = if($row.DurabilidadeTotal -ne '/////') { [int]$row.DurabilidadeTotal } else { 0 }
                $desidratacaoNum = if($row.Desidratacao -ne '/////') { [int]$row.Desidratacao } else { 0 }
                
                $obj | Add-Member -MemberType NoteProperty -Name Durabilidade -Value $row.DurabilidadeTotal
                $obj | Add-Member -MemberType NoteProperty -Name DurabilidadeNum -Value $durabNum
                $obj | Add-Member -MemberType NoteProperty -Name Desidratacao -Value $row.Desidratacao
                $obj | Add-Member -MemberType NoteProperty -Name DesidratacaoNum -Value $desidratacaoNum
                $obj | Add-Member -MemberType NoteProperty -Name VelCura -Value $row.VelocidadeCura
                $obj | Add-Member -MemberType NoteProperty -Name VelCuraNum -Value ([int]$row.VelocidadeCura)
                $obj | Add-Member -MemberType NoteProperty -Name Delay -Value $row.Delay
                $obj | Add-Member -MemberType NoteProperty -Name DelayNum -Value ([double]$row.Delay)
                $obj | Add-Member -MemberType NoteProperty -Name CustoDur -Value $row.CustoPorUso
                $obj | Add-Member -MemberType NoteProperty -Name EspacoHV -Value $row.EspacoOcupado
                $obj | Add-Member -MemberType NoteProperty -Name TotalSlots -Value $slots
                $obj | Add-Member -MemberType NoteProperty -Name DurabSlot -Value ([math]::Round(($durabNum / $slots), 1))
            }
            "Estimulantes" {
                $durNum = if($row.Duracao -ne '/////') { [int]$row.Duracao } else { 0 }
                $duracaoDisplay = $row.Duracao
                if($durNum -gt 0){
                    $min=[math]::Floor($durNum/60); $sec=$durNum%60
                    if($min -gt 0 -and $sec -gt 0){$duracaoDisplay="$durNum ($($min)min/$($sec)seg)"}
                    elseif($min -gt 0){$duracaoDisplay="$durNum ($($min)min)"}
                    elseif($durNum -gt 0){$duracaoDisplay="$durNum ($($sec)seg)"}
                }
                
                $obj | Add-Member -MemberType NoteProperty -Name EfeitoPrincipal -Value $row.EfeitoPrincipal
                $obj | Add-Member -MemberType NoteProperty -Name Duracao -Value $duracaoDisplay
                $obj | Add-Member -MemberType NoteProperty -Name DuracaoNum -Value $durNum
                $obj | Add-Member -MemberType NoteProperty -Name Desidratacao -Value $row.Desidratacao
                $obj | Add-Member -MemberType NoteProperty -Name RedEnergia -Value $row.ReducaoEnergia
                $obj | Add-Member -MemberType NoteProperty -Name Delay -Value $row.Delay
            }
        }
        $results += $obj
    }
    return $results
}

function Get-ArmoredRigData {
    $folderPath = Get-DatabasePath
    $csvPath = Join-Path -Path $folderPath -ChildPath "Armoredrigs.csv"
    
    if (-not (Test-Path $csvPath)) { return @() }
    
    $data = Import-Csv -Path $csvPath -Delimiter ";" -Encoding UTF8
    $results = @()

    $materialMap = @{ "Aramid"="Aramida"; "Polyethylene"="Polietileno"; "Hardened Steel"="Aço endurecido"; "Composite"="Composto"; "Aluminum"="Alumínio"; "Titanium"="Titânio"; "Ceramic"="Cerâmica" }
    $areaMapDisplay = @{ "Chest"="Tórax"; "Chest, Upper Abdomen"="Tórax, Abdômen Sup."; "Chest, Upper Abdomen, Lower Abdomen"="Tórax, Abdômen Sup. e Inf."; "Chest, Shoulder, Upper Abdomen, Lower Abdomen"="Tórax, Ombro, Abdômen Sup. e Inf." }
    $areaMapRank = @{ "Chest"=1; "Chest, Upper Abdomen"=2; "Chest, Upper Abdomen, Lower Abdomen"=3; "Chest, Shoulder, Upper Abdomen, Lower Abdomen"=4 }

    foreach ($row in $data) {
        $maxBlockArea = 0
        $countOfMaxBlock = 0
        $layoutStr = $row.LayoutInterno
        $displayLayout = "/////"
        $storageVal = if ($row.EspacoArmazenamento) { [int]$row.EspacoArmazenamento } else { 0 }

        if ($layoutStr -ne '/////' -and -not [string]::IsNullOrWhiteSpace($layoutStr)) {
            $parts = $layoutStr -split ',\s*'
            $parsedLayout = @()

            foreach ($part in $parts) {
                $count = 1
                $dims = $part
                if ($part -match '^\((\d+)\)(.+)') {
                    $count = [int]$Matches[1]
                    $dims = $Matches[2]
                }
                
                $area = 0
                if ($dims -match '(\d+)x(\d+)') {
                    $area = [int]$Matches[1] * [int]$Matches[2]
                    
                    if ($area -gt $maxBlockArea) {
                        $maxBlockArea = $area
                        $countOfMaxBlock = $count
                    } elseif ($area -eq $maxBlockArea) {
                        $countOfMaxBlock += $count
                    }
                }
                $parsedLayout += [PSCustomObject]@{ Original = $part; Area = $area; Count = $count }
            }
            $sortedLayout = $parsedLayout | Sort-Object -Property @{e="Area"; Descending=$true}, @{e="Count"; Descending=$true}
            $displayLayout = ($sortedLayout.Original) -join ', '
        }
        
        $sortingScore = ($maxBlockArea * 100) + ($storageVal * 10) + $countOfMaxBlock

        $matDisp = if ($materialMap.ContainsKey($row.Material)) { $materialMap[$row.Material] } else { $row.Material }
        $areaDisp = if ($areaMapDisplay.ContainsKey($row.AreaProtegida)) { $areaMapDisplay[$row.AreaProtegida] } else { $row.AreaProtegida }
        
        $velNum = if ($row.PenalidadeMovimento -eq '/////' -or -not $row.PenalidadeMovimento) { 0 } else { [int]($row.PenalidadeMovimento -replace '%', '') }
        $ergoNum = if ($row.Ergonomia -eq '/////' -or -not $row.Ergonomia) { 0 } else { [int]$row.Ergonomia }
        $areaRank = if ($areaMapRank.ContainsKey($row.AreaProtegida)) { $areaMapRank[$row.AreaProtegida] } else { 0 }

        $obj = [PSCustomObject]@{
            Nome                 = $row.NomeItem
            Weight               = if ($row.Peso) { [double]$row.Peso } else { 0 }
            Durability           = if ($row.Durabilidade) { [double]$row.Durabilidade } else { 0 }
            ArmorClass           = if ($row.ClasseBlindagem) { [int]$row.ClasseBlindagem } else { 0 }
            Storage              = $storageVal
            
            WeightDisplay        = $row.Peso
            DurabilityDisplay    = $row.Durabilidade
            LayoutDisplay        = $displayLayout
            
            MaterialDisplay      = $matDisp
            MovementSpeed        = $row.PenalidadeMovimento
            MovementSpeedNum     = $velNum
            Ergonomics           = $row.Ergonomia
            ErgonomicsNum        = $ergoNum
            AreaDisplay          = $areaDisp
            AreaNum              = $areaRank
            BlockSortingScore    = $sortingScore
        }
        $results += $obj
    }
    return $results
}

function Get-UnarmoredRigData {
    $folderPath = Get-DatabasePath
    $csvPath = Join-Path -Path $folderPath -ChildPath "Unarmoredrigs.csv"
    
    if (-not (Test-Path $csvPath)) { return @() }
    
    $data = Import-Csv -Path $csvPath -Delimiter ";" -Encoding UTF8
    $results = @()

    foreach ($row in $data) {
        $storage = [int]$row.EspacoTotal
        $sizeUnfolded = $row.TamanhoDesdobrada
        $efficiency = -9999 
        $occupiedArea = 9999 

        if ($sizeUnfolded -ne '/////' -and $sizeUnfolded -match '(\d+)x(\d+)') {
            $occupiedArea = [int]$Matches[1] * [int]$Matches[2]
            $efficiency = $storage - $occupiedArea
        }

        $internalLayout = $row.LayoutInterno
        $setCount = 0
        $maxBlockArea = 0
        $countOfMaxBlock = 0
        $displayLayout = "/////"

        if ($internalLayout -ne '/////' -and -not [string]::IsNullOrWhiteSpace($internalLayout)) {
            $sets = $internalLayout -split ',\s*'
            $parsedLayout = @()

            foreach ($set in $sets) {
                $cnt = 1
                $dims = $set
                
                if ($set -match '^\((\d+)\)(.+)') {
                    $cnt = [int]$Matches[1]
                    $dims = $Matches[2]
                } elseif ($set -match '^\((\d+)\)') {
                    $cnt = [int]$Matches[1]
                }
                
                $setCount += $cnt 
                
                $area = 0
                if ($dims -match '(\d+)x(\d+)') {
                    $area = [int]$Matches[1] * [int]$Matches[2]
                    
                    if ($area -gt $maxBlockArea) {
                        $maxBlockArea = $area
                        $countOfMaxBlock = $cnt
                    } elseif ($area -eq $maxBlockArea) {
                        $countOfMaxBlock += $cnt
                    }
                }
                $parsedLayout += [PSCustomObject]@{ Original = $set; Area = $area; Count = $cnt }
            }
            $sortedLayout = $parsedLayout | Sort-Object -Property @{e="Area"; Descending=$true}, @{e="Count"; Descending=$true}
            $displayLayout = ($sortedLayout.Original) -join ', '
        } else {
            $setCount = 999 
        }

        $sortingScore = ($maxBlockArea * 1000) + $countOfMaxBlock

        $obj = [PSCustomObject]@{
            Nome                 = $row.NomeItem
            
            Weight               = if ($row.Peso) { [double]$row.Peso } else { 0 }
            Storage              = $storage
            Efficiency           = $efficiency
            UnfoldedArea         = $occupiedArea 
            BlockSortingScore    = $sortingScore
            SetCount             = $setCount

            WeightDisplay        = $row.Peso
            SizeUnfolded         = $row.TamanhoDesdobrada
            SizeFolded           = $row.TamanhoDobrada
            LayoutDisplay        = $displayLayout
            EfficiencyDisplay    = if($efficiency -eq -9999) { "/////" } else { "{0:+#;-#;0}" -f $efficiency }
        }
        $results += $obj
    }
    return $results
}


function Show-Top5AmmoDialog {
    # Puxamos a interface principal que ja esta carregada na memoria do script
    $ui = $script:SearchUI 

    $f = New-Object System.Windows.Forms.Form
    $f.Text = "Top 5 Calibres (Melhores Munições)"
    $f.Size = New-Object System.Drawing.Size(600, 700); $f.StartPosition = "CenterParent"
    $f.BackColor = $theme.Background; $f.ForeColor = $theme.TextMain

    $txt = New-Object System.Windows.Forms.TextBox; $txt.Multiline = $true; $txt.Dock = "Top"; $txt.Height = 600; $txt.ScrollBars = "Vertical"
    $txt.BackColor = $theme.PanelBack; $txt.ForeColor = $theme.TextMain; $txt.Font = New-Object System.Drawing.Font("Consolas", 10)
    $txt.ReadOnly = $true

    # Recalcula a lista filtrada atual da Grid usando o objeto $ui
    $items = @()
    if ($ui.Dgv.Rows.Count -gt 0) {
        foreach ($row in $ui.Dgv.Rows) { 
            $items += [PSCustomObject]@{ Nome=$row.Cells["Nome"].Value; Calibre=$row.Cells["Calibre"].Value } 
        }
    }
    
    # Logica de selecao do "Melhor" (Topo ou Fundo dependendo da ordem)
    $isDesc = ($ui.CbOrdem.SelectedItem -eq "Decrescente")
    
    # Trava de seguranca para indexacao vazia
    $processedList = @()
    if ($items.Count -gt 0) {
        $processedList = if ($isDesc) { $items } else { $items[-1..-$items.Count] }
    }
    
    $topCalibres = @(); $seen = @{}
    foreach ($i in $processedList) {
        if (-not $seen.Contains($i.Calibre)) {
            $seen[$i.Calibre] = $true
            $topCalibres += $i
            if ($topCalibres.Count -ge 5) { break }
        }
    }

    $sb = new-object System.Text.StringBuilder
    $sb.AppendLine("== Top 5 Calibres (Melhores Munições) ==")
    $sb.AppendLine("")
    
    $pos = 1
    foreach ($calInfo in $topCalibres) {
        # [CORREÇÃO AQUI]: Isolamos a variável $pos para o PowerShell a ler corretamente
        $sb.AppendLine("$($pos)ª posição: $($calInfo.Calibre)")
        $sb.AppendLine("Nome da munição: $($calInfo.Nome)")
        
        $armas = $script:cachedWeaponData | Where-Object { $_.Calibre -eq $calInfo.Calibre } | Select-Object -ExpandProperty Nome | Sort-Object
        $sb.AppendLine("Armas compatíveis: $($armas -join ', ')")
        $sb.AppendLine("")
        $pos++
    }
    $txt.Text = $sb.ToString()

    $btnClose = New-Object System.Windows.Forms.Button; $btnClose.Text = "Fechar"; $btnClose.Location = "450, 620"; $btnClose.DialogResult = "Cancel"; $btnClose.BackColor = $theme.ButtonBack; $btnClose.ForeColor = $theme.TextMain; $btnClose.FlatStyle = "Flat"
    $btnSaveReport = New-Object System.Windows.Forms.Button; $btnSaveReport.Text = "Salvar Resultados"; $btnSaveReport.Location = "20, 620"; $btnSaveReport.Width = 150; $btnSaveReport.BackColor = $theme.OrangeAccent; $btnSaveReport.ForeColor = $theme.Background; $btnSaveReport.FlatStyle = "Flat"
    
    $btnSaveReport.Add_Click({
        $sfd = New-Object System.Windows.Forms.SaveFileDialog; $sfd.Filter = "Text File|*.txt"; $sfd.FileName = "Top5_Municao.txt"
        if ($sfd.ShowDialog() -eq "OK") { 
            # Garantindo a codificacao rigorosa UTF-8 com BOM
            $utf8Bom = New-Object System.Text.UTF8Encoding($true)
            [System.IO.File]::WriteAllText($sfd.FileName, $txt.Text, $utf8Bom)
        }
        
        # --- CORREÇÃO MEMORY LEAK: Liberta a janela de Salvar Ficheiro ---
        $sfd.Dispose()
    })

    $f.Controls.AddRange(@($txt, $btnClose, $btnSaveReport))
    $f.ShowDialog() | Out-Null
    
    # --- CORREÇÃO MEMORY LEAK: Liberta o formulário principal do Top 5 ---
    $f.Dispose()
}


function Sort-GasMaskDataComplex {
    param ($Data, $Criterion, $Order)

    $expPeso       = { [double]$_.Weight }
    $expDurab      = { [double]$_.Durability }
    $expVeneno     = { [int]$_.AntiVenenoNum }
    $expFlash      = { [int]$_.AntiFlashNum }

    # Controle de Direção Dinâmica
    $userWantsDescending = ($Order -eq "Decrescente") 
    $descNormal  = $userWantsDescending      # Maior = Melhor (Durabilidade, Efeitos)
    $descInverso = -not $userWantsDescending # Menor = Melhor (Peso)
    
    $primaryExpr = $null
    $primaryDesc = $descNormal

    switch ($Criterion) {
        "Alfabético"   { $primaryExpr = { $_.Nome }; $primaryDesc = $false; if ($userWantsDescending) { $primaryDesc = $true } }
        "Peso"         { $primaryExpr = $expPeso; $primaryDesc = $descInverso }
        "Durabilidade" { $primaryExpr = $expDurab }
        "Anti-Veneno"  { $primaryExpr = $expVeneno }
        "Anti-Flash"   { $primaryExpr = $expFlash }
        Default        { $primaryExpr = { $_.Nome } }
    }

    $ordenacaoParams = @()
    $ordenacaoParams += @{ Expression = $primaryExpr; Descending = $primaryDesc }

    # Tie-Breakers (Baseado no Script Antigo)
    switch ($Criterion) {
        "Peso" {
            $ordenacaoParams += @{ Expression = $expVeneno; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expDurab; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expFlash; Descending = $descNormal }
        }
        "Durabilidade" {
            $ordenacaoParams += @{ Expression = $expVeneno; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expFlash; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
        }
        "Anti-Veneno" {
            $ordenacaoParams += @{ Expression = $expDurab; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expFlash; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
        }
        "Anti-Flash" {
            $ordenacaoParams += @{ Expression = $expVeneno; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expDurab; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
        }
    }
    return $Data | Sort-Object -Property $ordenacaoParams
}


function Sort-HeadsetDataComplex {
    param ($Data, $Criterion, $Order)

    $expPeso       = { [double]$_.Weight }
    $expSound      = { [int]$_.SoundPickupNum }
    $expNoise      = { [int]$_.NoiseReductionNum }

    # Controle de Direção Dinâmica
    $userWantsDescending = ($Order -eq "Decrescente") 
    $descNormal  = $userWantsDescending      # Maior = Melhor (Captador, Redução)
    $descInverso = -not $userWantsDescending # Menor = Melhor (Peso)
    
    $primaryExpr = $null
    $primaryDesc = $descNormal

    switch ($Criterion) {
        "Alfabético"       { $primaryExpr = { $_.Nome }; $primaryDesc = $false; if ($userWantsDescending) { $primaryDesc = $true } }
        "Peso"             { $primaryExpr = $expPeso; $primaryDesc = $descInverso }
        "Captador de Som"  { $primaryExpr = $expSound }
        "Redução de Ruído" { $primaryExpr = $expNoise }
        Default            { $primaryExpr = { $_.Nome } }
    }

    $ordenacaoParams = @()
    $ordenacaoParams += @{ Expression = $primaryExpr; Descending = $primaryDesc }

    # Tie-Breakers (Baseado no Script Antigo)
    switch ($Criterion) {
        "Captador de Som" {
            $ordenacaoParams += @{ Expression = $expNoise; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
        }
        "Redução de Ruído" {
            $ordenacaoParams += @{ Expression = $expSound; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
        }
        "Peso" {
            # Adicionado desempate lógico para Peso (Melhor som primeiro)
            $ordenacaoParams += @{ Expression = $expSound; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expNoise; Descending = $descNormal }
        }
    }
    return $Data | Sort-Object -Property $ordenacaoParams
}


function Show-ArmorFilterDialog {
    param([Parameter(Mandatory=$true)] $Data, [Parameter(Mandatory=$true)] $ThemeColors)

    $dlg = New-Object System.Windows.Forms.Form; $dlg.Text = "Filtro de Coletes"; $dlg.Size = New-Object System.Drawing.Size(800, 500); $dlg.StartPosition = "CenterParent"; $dlg.FormBorderStyle = "FixedDialog"; $dlg.MaximizeBox = $false
    $dlg.BackColor = $ThemeColors.Background; $dlg.ForeColor = $ThemeColors.TextMain

    $tempManualFilters = @{}; foreach ($k in $script:manualFilters.Keys) { $tempManualFilters[$k] = [System.Collections.ArrayList]@($script:manualFilters[$k]) }
    
    $customOrderClass = @("1", "2", "3", "4", "5", "6")
    
    # ATUALIZADO: Nova ordem solicitada para Área Protegida, com redundância de segurança
    $customOrderArea = @(
        "Tórax", "Torax", 
        "Tórax, Abdômen Superior", "Torax, Abdomen Superior", 
        "Tórax, Abdômen Superior, Abdômen Inferior", "Torax, Abdomen Superior, Abdomen Inferior", 
        "Tórax, Ombro, Abdômen Superior", "Torax, Ombro, Abdomen Superior", 
        "Tórax, Ombro, Abdômen Superior, Abdômen Inferior", "Torax, Ombro, Abdomen Superior, Abdomen Inferior"
    )

    # ATUALIZADO: Removida a coluna Material. Layout agora tem apenas 2 colunas.
    $filterDefs = @(
        @{Title="Classe de Blindagem"; Prop="ArmorClass";  ColIndex=0; CustomOrder=$customOrderClass},
        @{Title="Área Protegida";      Prop="AreaDisplay"; ColIndex=1; CustomOrder=$customOrderArea}
    )

    foreach ($def in $filterDefs) { if (-not $tempManualFilters.ContainsKey($def.Prop)) { $tempManualFilters[$def.Prop] = New-Object System.Collections.ArrayList } }
    
    $visualState = @{} 
    # ATUALIZADO: Ajustado para 2 Colunas (50% cada)
    $mainLayout = New-Object System.Windows.Forms.TableLayoutPanel; $mainLayout.Dock = "Top"; $mainLayout.Height = 380; $mainLayout.ColumnCount = 2
    for($i=0; $i -lt 2; $i++){ $mainLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 50))) | Out-Null }
    $allCheckBoxes = @()

    $script:UpdateFilterUI = {
        $survivors = New-Object System.Collections.Generic.List[Object]; foreach ($item in $Data) { $isSurvivor = $true; foreach ($k in $tempManualFilters.Keys) { $filterList = $tempManualFilters[$k]; if ($filterList.Count -eq 0) { continue }; if ($filterList -contains $item.($k)) { $isSurvivor = $false; break } }; if ($isSurvivor) { $survivors.Add($item) } }
        $availableValues = @{}; foreach ($k in $script:manualFilters.Keys) { $availableValues[$k] = New-Object System.Collections.Generic.HashSet[string] }
        foreach ($def in $filterDefs) { if (-not $availableValues.ContainsKey($def.Prop)) { $availableValues[$def.Prop] = New-Object System.Collections.Generic.HashSet[string] } }

        foreach ($item in $survivors) { foreach ($k in $availableValues.Keys) { $val = $item.($k); if (-not [string]::IsNullOrEmpty($val)) { $availableValues[$k].Add($val) | Out-Null } } }
        
        foreach ($cb in $allCheckBoxes) {
            $prop = $cb.Tag.Prop; $val = $cb.Tag.Value; $uKey = $cb.Tag.UniqueKey
            if ($tempManualFilters[$prop].Contains($val)) { 
                $visualState[$uKey] = 'M'
                $cb.Checked = $true
                $cb.Enabled = $true
                $cb.ForeColor = $ThemeColors.OrangeAccent 
                $cb.BackColor = [System.Drawing.Color]::Empty # Fundo normal
            }
            elseif (-not $availableValues[$prop].Contains($val)) { 
                $visualState[$uKey] = 'A'
                $cb.Checked = $true
                $cb.ForeColor = $ThemeColors.TextDim 
                $cb.BackColor = $ThemeColors.ButtonBack # Destaca opções auto-filtradas
            }
            else { 
                $visualState[$uKey] = 'F'
                $cb.Checked = $false
                $cb.ForeColor = $ThemeColors.TextMain 
                $cb.BackColor = [System.Drawing.Color]::Empty # Fundo normal
            }
        }
    }

    foreach ($def in $filterDefs) {
        $gb = New-Object System.Windows.Forms.GroupBox; $gb.Text = $def.Title; $gb.Dock = "Fill"; $gb.ForeColor = $ThemeColors.TextMain
        $flow = New-Object System.Windows.Forms.FlowLayoutPanel; $flow.Dock = "Fill"; $flow.FlowDirection = "TopDown"; $flow.AutoScroll = $true; $flow.WrapContents = $false
        $rawValues = $Data | Select-Object -ExpandProperty $def.Prop -Unique
        
        $orderedValues = @()
        if ($def.CustomOrder) { 
            foreach ($orderedItem in $def.CustomOrder) { 
                $exists = $false; foreach($r in $rawValues) { if("$r" -eq "$orderedItem") { $exists = $true; break } }
                if ($exists) { $orderedValues += $orderedItem } 
            }
            foreach ($rawItem in $rawValues) { $isInList = $false; foreach($o in $orderedValues) { if("$o" -eq "$rawItem") { $isInList = $true; break } }; if (-not $isInList) { $orderedValues += $rawItem } } 
        } else { $orderedValues = $rawValues | Sort-Object }

        foreach ($val in $orderedValues) {
            if ([string]::IsNullOrWhiteSpace($val)) { continue }
            $cb = New-Object System.Windows.Forms.CheckBox; $cb.Text = "$val"; $cb.AutoSize = $true; $cb.AutoCheck = $false; $cb.Tag = @{ Prop = $def.Prop; Value = $val; UniqueKey = "$($def.Prop)_$val" }
            $cb.ForeColor = $ThemeColors.TextMain
            $cb.Add_Click({ param($sender, $e) $prop = $sender.Tag.Prop; $v = $sender.Tag.Value; $k = $sender.Tag.UniqueKey; $state = $visualState[$k]; if ($state -eq 'A') { return }; if ($tempManualFilters[$prop].Contains($v)) { $tempManualFilters[$prop].Remove($v) } else { $tempManualFilters[$prop].Add($v) | Out-Null }; & $script:UpdateFilterUI })
            $flow.Controls.Add($cb); $allCheckBoxes += $cb
        }
        $gb.Controls.Add($flow); $mainLayout.Controls.Add($gb, $def.ColIndex, 0)
    }

    & $script:UpdateFilterUI
    $btnPanel = New-Object System.Windows.Forms.Panel; $btnPanel.Dock = "Bottom"; $btnPanel.Height = 60; $btnPanel.BackColor = $ThemeColors.Background
    $btnReset = New-Object System.Windows.Forms.Button; $btnReset.Text = "Resetar"; $btnReset.Size = "100, 30"; $btnReset.Location = "350, 15"; $btnReset.FlatStyle = "Flat"; $btnReset.BackColor = $ThemeColors.ButtonBack; $btnReset.ForeColor = $ThemeColors.TextMain; $btnReset.Add_Click({ foreach ($k in $tempManualFilters.Keys) { $tempManualFilters[$k].Clear() }; & $script:UpdateFilterUI })
    $btnOk = New-Object System.Windows.Forms.Button; $btnOk.Text = "OK"; $btnOk.Size = "100, 30"; $btnOk.Location = "460, 15"; $btnOk.DialogResult = "OK"; $btnOk.FlatStyle = "Flat"; $btnOk.BackColor = $ThemeColors.OrangeAccent; $btnOk.ForeColor = $ThemeColors.Background
    $btnPanel.Controls.AddRange(@($btnReset, $btnOk)); $dlg.Controls.AddRange(@($mainLayout, $btnPanel)); $res = $dlg.ShowDialog()
    if ($res -eq "OK") { foreach($k in $tempManualFilters.Keys) { $script:manualFilters[$k] = $tempManualFilters[$k] } }

    # --- CORREÇÃO MEMORY LEAK: Liberta os recursos da janela da RAM ---
    $dlg.Dispose()
}


function Get-MaskData {
    $folderPath = Get-DatabasePath
    $csvPath = Join-Path -Path $folderPath -ChildPath "Masks.csv"
    
    if (-not (Test-Path $csvPath)) { return @() }
    
    $data = Import-Csv -Path $csvPath -Delimiter ";" -Encoding UTF8
    $results = @()

    $materialMap = @{ "Glass"="Vidro"; "Hardened Steel"="Aço endurecido"; "Composite"="Composto"; "Aluminum"="Alumínio" }
    $ricocheteMapDisplay = @{ "Low"="Baixo"; "Medium"="Médio"; "High"="Alto" }
    $ricocheteMapNum     = @{ "/////"=0; "Low"=1; "Medium"=2; "High"=3 }

    foreach ($row in $data) {
        $matDisp = if ($materialMap.ContainsKey($row.Material)) { $materialMap[$row.Material] } else { $row.Material }
        $ricocheteDisp = if ($ricocheteMapDisplay.ContainsKey($row.Ricochete)) { $ricocheteMapDisplay[$row.Ricochete] } else { $row.Ricochete }
        $ricocheteNum  = if ($ricocheteMapNum.ContainsKey($row.Ricochete)) { $ricocheteMapNum[$row.Ricochete] } else { 0 }

        $obj = [PSCustomObject]@{
            Nome              = $row.NomeItem
            
            Weight            = if ($row.Peso) { [double]$row.Peso } else { 0 }
            Durability        = if ($row.Durabilidade) { [double]$row.Durabilidade } else { 0 }
            ArmorClass        = if ($row.ClasseBlindagem) { [int]$row.ClasseBlindagem } else { 0 }
            RicocheteNum      = $ricocheteNum

            WeightDisplay     = $row.Peso
            DurabilityDisplay = $row.Durabilidade
            MaterialDisplay   = $matDisp
            RicocheteDisplay  = $ricocheteDisp
        }
        $results += $obj
    }
    return $results
}


function Get-ThrowableData {
    $folderPath = Get-DatabasePath
    $csvPath = Join-Path -Path $folderPath -ChildPath "Throwables.csv"
    
    if (-not (Test-Path $csvPath)) { return @() }
    
    $data = Import-Csv -Path $csvPath -Delimiter ";" -Encoding UTF8
    $results = @()

    $alcanceMap    = @{ "Standard" = "Padrão"; "Large" = "Longo"; "Very Large" = "Muito longo"; "/////" = "/////" }
    $danoBlindMap  = @{ "Standard" = "Padrão"; "Mid-High" = "Superior"; "/////" = "/////" }
    $penetracaoMap = @{ "Standard" = "Padrão"; "Mid-High" = "Superior"; "/////" = "/////" }
    $fragmentosMap = @{ "Small" = "Pequeno"; "Large" = "Grande"; "/////" = "/////" }
    $tipoFragsMap  = @{ "Steel Piece" = "Peça de aço"; "Iron Piece" = "Peça de ferro"; "/////" = "/////" }

    $alcanceNum    = @{ "/////" = 0; "Standard" = 1; "Large" = 2; "Very Large" = 3 }
    $danoBlindNum  = @{ "/////" = 0; "Standard" = 1; "Mid-High" = 2 }
    $penetracaoNum = @{ "/////" = 0; "Standard" = 1; "Mid-High" = 2 }
    $fragmentosNum = @{ "/////" = 0; "Small" = 1; "Large" = 2 }
    $tipoFragsNum  = @{ "/////" = 0; "Iron Piece" = 1; "Steel Piece" = 2 }

    foreach ($row in $data) {
        $delayParts = $row.DelayExplosao -split ' - '
        $d1 = 0
        $d2 = 0
        if ($delayParts.Count -ge 1) { $d1 = [double]$delayParts[0] }
        if ($delayParts.Count -ge 2) { $d2 = [double]$delayParts[1] }

        $alcanceDisplay = if ($alcanceMap.ContainsKey($row.Alcance)) { $alcanceMap[$row.Alcance] } else { $row.Alcance }
        $danoBlindDisplay = if ($danoBlindMap.ContainsKey($row.DanoBlindagem)) { $danoBlindMap[$row.DanoBlindagem] } else { $row.DanoBlindagem }
        $penetracaoDisplay = if ($penetracaoMap.ContainsKey($row.Penetracao)) { $penetracaoMap[$row.Penetracao] } else { $row.Penetracao }
        $fragmentosDisplay = if ($fragmentosMap.ContainsKey($row.Fragmentos)) { $fragmentosMap[$row.Fragmentos] } else { $row.Fragmentos }
        $tipoFragsDisplay = if ($tipoFragsMap.ContainsKey($row.TipoFragmento)) { $tipoFragsMap[$row.TipoFragmento] } else { $row.TipoFragmento }
        
        $tempoEfeitoVal = if ($row.TempoEfeito -eq '/////') { 0 } else { [double]$row.TempoEfeito }
        $tempoEfeitoDisp = if ($row.TempoEfeito -eq '/////') { "/////" } else { $row.TempoEfeito }

        $obj = [PSCustomObject]@{
            Nome              = $row.NomeItem
            
            DelayExplosao     = $row.DelayExplosao
            DelayNum1         = $d1
            DelayNum2         = $d2
            AlcanceNum        = $alcanceNum[$row.Alcance]
            DanoBlindNum      = $danoBlindNum[$row.DanoBlindagem]
            PenetracaoNum     = $penetracaoNum[$row.Penetracao]
            FragmentosNum     = $fragmentosNum[$row.Fragmentos]
            TipoFragsNum      = $tipoFragsNum[$row.TipoFragmento]
            TempoEfeitoNum    = $tempoEfeitoVal

            Alcance           = $alcanceDisplay
            DanoBlind         = $danoBlindDisplay
            Penetracao        = $penetracaoDisplay
            Fragmentos        = $fragmentosDisplay
            TipoFrags         = $tipoFragsDisplay
            TempoEfeito       = $tempoEfeitoDisp
        }
        $results += $obj
    }
    return $results
}


function Sort-GastronomyDataComplex {
    param ($Data, $Criterion, $Order)

    $expHidrat     = { [int]$_.HidratacaoNum }
    $expEnerg      = { [int]$_.EnergiaNum }
    $expHidSlot    = { [double]$_.HidratSlot }
    $expEngSlot    = { [double]$_.EnergSlot }
    $expSlots      = { [int]$_.TotalSlots }

    # Controle de Direção Dinâmica
    $userWantsDescending = ($Order -eq "Decrescente") 
    $descNormal  = $userWantsDescending      # Maior = Melhor (Hidratação, Energia)
    $descInverso = -not $userWantsDescending # Menor = Melhor (Slots ocupados)
    
    $primaryExpr = $null
    $primaryDesc = $descNormal

    switch ($Criterion) {
        "Alfabético"          { $primaryExpr = { $_.Nome }; $primaryDesc = $false; if ($userWantsDescending) { $primaryDesc = $true } }
        "Hidratação"          { $primaryExpr = $expHidrat }
        "Energia"             { $primaryExpr = $expEnerg }
        "Hidratação por Slot" { $primaryExpr = $expHidSlot }
        "Energia por Slot"    { $primaryExpr = $expEngSlot }
        Default               { $primaryExpr = { $_.Nome } }
    }

    $ordenacaoParams = @()
    $ordenacaoParams += @{ Expression = $primaryExpr; Descending = $primaryDesc }

    # Tie-Breakers (Baseado no Script Antigo)
    switch ($Criterion) {
        "Hidratação" {
            $ordenacaoParams += @{ Expression = $expHidSlot; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expSlots; Descending = $descInverso } # Menos slots = melhor
            $ordenacaoParams += @{ Expression = $expEnerg; Descending = $descNormal }
        }
        "Energia" {
            $ordenacaoParams += @{ Expression = $expEngSlot; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expSlots; Descending = $descInverso }
            $ordenacaoParams += @{ Expression = $expHidrat; Descending = $descNormal }
        }
        "Hidratação por Slot" {
            $ordenacaoParams += @{ Expression = $expSlots; Descending = $descInverso }      
            $ordenacaoParams += @{ Expression = $expHidrat; Descending = $descNormal } 
            $ordenacaoParams += @{ Expression = $expEngSlot; Descending = $descNormal }      
        }
        "Energia por Slot"  {
            $ordenacaoParams += @{ Expression = $expSlots; Descending = $descInverso }      
            $ordenacaoParams += @{ Expression = $expEnerg; Descending = $descNormal }      
            $ordenacaoParams += @{ Expression = $expHidSlot; Descending = $descNormal }      
        }
    }
    return $Data | Sort-Object -Property $ordenacaoParams
}


function Sort-ArmorDataComplex {
    param ($Data, $Criterion, $Order)

    # Expressões de leitura
    $expPeso      = { [double]$_.Weight }
    $expDurab     = { [double]$_.Durability }
    $expArmor     = { [int]$_.ArmorClass }
    $expMov       = { [int]$_.MovementSpeedNum } # Maior (mais próximo de 0) é melhor
    $expErgo      = { [int]$_.ErgonomicsNum }    # Maior (mais próximo de 0) é melhor
    $expArea      = { [int]$_.AreaNum }

    # Controle de Direção Dinâmica
    $userWantsDescending = ($Order -eq "Decrescente") 
    $descNormal  = $userWantsDescending      # Maior = Melhor (Blindagem, Durabilidade, Movimento, Ergo)
    $descInverso = -not $userWantsDescending # Menor = Melhor (Peso)

    # Define Critério Principal
    $primaryExpr = $null
    $primaryDesc = $descNormal

    switch ($Criterion) {
        "Alfabético"              { $primaryExpr = { $_.Nome }; $primaryDesc = $false; if ($userWantsDescending) { $primaryDesc = $true } }
        "Peso"                    { $primaryExpr = $expPeso; $primaryDesc = $descInverso }
        "Durabilidade"            { $primaryExpr = $expDurab }
        "Classe de Blindagem"     { $primaryExpr = $expArmor }
        "Material"                { $primaryExpr = { $_.MaterialDisplay } }
        "Penalidade de Movimento" { $primaryExpr = $expMov }
        "Ergonomia"               { $primaryExpr = $expErgo }
        "Área Protegida"          { $primaryExpr = $expArea }
        Default                   { $primaryExpr = { $_.Nome } }
    }

    $ordenacaoParams = @()
    $ordenacaoParams += @{ Expression = $primaryExpr; Descending = $primaryDesc }

    # Aplica os Desempates (Tie-Breakers) conforme script antigo
    # Nota: Usamos $descNormal para garantir consistência na inversão de ordem
    switch ($Criterion) {
        "Peso" {
            $ordenacaoParams += @{ Expression = $expArmor; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expDurab; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expMov; Descending = $descNormal }
        }
        "Durabilidade" {
            $ordenacaoParams += @{ Expression = $expArmor; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
            $ordenacaoParams += @{ Expression = $expMov; Descending = $descNormal }
        }
        "Classe de Blindagem" {
            $ordenacaoParams += @{ Expression = $expDurab; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
            $ordenacaoParams += @{ Expression = $expMov; Descending = $descNormal }
        }
        "Material" {
            $ordenacaoParams += @{ Expression = $expArmor; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expDurab; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
            $ordenacaoParams += @{ Expression = $expMov; Descending = $descNormal }
        }
        "Penalidade de Movimento" {
            $ordenacaoParams += @{ Expression = $expArmor; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expDurab; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
        }
        "Ergonomia" {
            $ordenacaoParams += @{ Expression = $expArmor; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expDurab; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
            $ordenacaoParams += @{ Expression = $expMov; Descending = $descNormal }
        }
        "Área Protegida" {
            $ordenacaoParams += @{ Expression = $expArmor; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expDurab; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
            $ordenacaoParams += @{ Expression = $expMov; Descending = $descNormal }
        }
    }
    return $Data | Sort-Object -Property $ordenacaoParams
}


function Sort-PharmaceuticalDataComplex {
    param ($Data, $Criterion, $Order, $Category)

    # Converte para string para garantir comparação correta
    $catStr = "$Category"

    # Define a direção baseada na escolha do usuário na UI
    $userWantsDescending = ($Order -eq "Decrescente") 
    
    # Lógica de Direção
    # descNormal: True se Decrescente (Maior -> Menor), False se Crescente (Menor -> Maior)
    $descNormal  = $userWantsDescending      
    # descInverso: True se Crescente (Menor -> Maior), False se Decrescente (Maior -> Menor)
    # Usado para atributos onde "Menor é Melhor" (Delay, Espaço)
    $descInverso = -not $userWantsDescending 

    # --- CATEGORIAS COM CRITÉRIO FIXO (Bandagem, Nebulizador, Estimulantes) ---
    if ($catStr -eq "Bandagem") {
        return $Data | Sort-Object -Property @{ Expression="UsosNum"; Descending=$userWantsDescending }
    }
    if ($catStr -eq "Nebulizador") {
        return $Data | Sort-Object -Property @{ Expression="UsosNum"; Descending=$userWantsDescending }
    }
    if ($catStr -eq "Estimulantes") {
        return $Data | Sort-Object -Property @{ Expression="EfeitoPrincipal"; Descending=$userWantsDescending }, @{ Expression="DuracaoNum"; Descending=$userWantsDescending }
    }

    # --- CATEGORIAS DINÂMICAS ---
    
    $ordenacaoParams = @()
    
    # Bloco principal de configuração de critérios e desempates
    switch ($catStr) {
        "Analgesico" {
            switch($Criterion) {
                "Usos" { 
                    $ordenacaoParams += @{ Expression = "UsosNum"; Descending = $descNormal }
                    $ordenacaoParams += @{ Expression = "DesidratacaoNum"; Descending = $descNormal }
                    $ordenacaoParams += @{ Expression = "DuracaoNum"; Descending = $descNormal }
                }
                "Duração" { 
                    $ordenacaoParams += @{ Expression = "DuracaoNum"; Descending = $descNormal }
                    $ordenacaoParams += @{ Expression = "DesidratacaoNum"; Descending = $descNormal }
                    $ordenacaoParams += @{ Expression = "UsosNum"; Descending = $descNormal }
                }
                "Desidratação" { 
                    $ordenacaoParams += @{ Expression = "DesidratacaoNum"; Descending = $descNormal }
                    $ordenacaoParams += @{ Expression = "DuracaoNum"; Descending = $descNormal }
                    $ordenacaoParams += @{ Expression = "UsosNum"; Descending = $descNormal }
                }
                "Duração Máxima" { 
                    $ordenacaoParams += @{ Expression = "DurMaxNum"; Descending = $descNormal }
                    $ordenacaoParams += @{ Expression = "DesidratacaoNum"; Descending = $descNormal }
                }
                Default { 
                    $ordenacaoParams += @{ Expression = "Nome"; Descending = $descNormal } 
                }
            }
        }
        "Kit cirurgico" {
            switch($Criterion) {
                "Usos" {
                    $ordenacaoParams += @{ Expression = "UsosNum"; Descending = $descNormal }
                    $ordenacaoParams += @{ Expression = "RecHPNum"; Descending = $descNormal }
                    $ordenacaoParams += @{ Expression = "DesidratacaoNum"; Descending = $descNormal }
                }
                "Tempo de Atraso" {
                    $ordenacaoParams += @{ Expression = "TempoAtrasoNum"; Descending = $descInverso }
                    $ordenacaoParams += @{ Expression = "RecHPNum"; Descending = $descNormal }
                    $ordenacaoParams += @{ Expression = "DesidratacaoNum"; Descending = $descNormal }
                }
                "Desidratação" {
                    $ordenacaoParams += @{ Expression = "DesidratacaoNum"; Descending = $descNormal }
                    $ordenacaoParams += @{ Expression = "RecHPNum"; Descending = $descNormal }
                    $ordenacaoParams += @{ Expression = "UsosNum"; Descending = $descNormal }
                }
                "Recuperação por Uso" {
                    $ordenacaoParams += @{ Expression = "RecHPNum"; Descending = $descNormal }
                    $ordenacaoParams += @{ Expression = "UsosNum"; Descending = $descNormal }
                    $ordenacaoParams += @{ Expression = "DesidratacaoNum"; Descending = $descNormal }
                }
                "Espaço (HxV)" {
                    $ordenacaoParams += @{ Expression = "TotalSlots"; Descending = $descInverso }
                    $ordenacaoParams += @{ Expression = "RecHPNum"; Descending = $descNormal }
                    $ordenacaoParams += @{ Expression = "UsosNum"; Descending = $descNormal }
                }
                Default { $ordenacaoParams += @{ Expression = "Nome"; Descending = $descNormal } }
            }
        }
        "Kit medico" {
            switch($Criterion) {
                "Durabilidade" {
                    $ordenacaoParams += @{ Expression = "DurabilidadeNum"; Descending = $descNormal }
                    $ordenacaoParams += @{ Expression = "VelCuraNum"; Descending = $descNormal }
                    $ordenacaoParams += @{ Expression = "DesidratacaoNum"; Descending = $descNormal }
                }
                "Desidratação" {
                    $ordenacaoParams += @{ Expression = "DesidratacaoNum"; Descending = $descNormal }
                    $ordenacaoParams += @{ Expression = "VelCuraNum"; Descending = $descNormal }
                    $ordenacaoParams += @{ Expression = "DurabilidadeNum"; Descending = $descNormal }
                }
                "Velocidade de Cura" {
                    $ordenacaoParams += @{ Expression = "VelCuraNum"; Descending = $descNormal }
                    $ordenacaoParams += @{ Expression = "DesidratacaoNum"; Descending = $descNormal }
                    $ordenacaoParams += @{ Expression = "DurabilidadeNum"; Descending = $descNormal }
                }
                "Delay" {
                    $ordenacaoParams += @{ Expression = "DelayNum"; Descending = $descInverso }
                    $ordenacaoParams += @{ Expression = "VelCuraNum"; Descending = $descNormal }
                    $ordenacaoParams += @{ Expression = "DesidratacaoNum"; Descending = $descNormal }
                }
                "Espaço (HxV)" {
                    $ordenacaoParams += @{ Expression = "TotalSlots"; Descending = $descInverso }
                    $ordenacaoParams += @{ Expression = "VelCuraNum"; Descending = $descNormal }
                    $ordenacaoParams += @{ Expression = "DesidratacaoNum"; Descending = $descNormal }
                }
                "Durabilidade por Slot" {
                    $ordenacaoParams += @{ Expression = "DurabSlot"; Descending = $descNormal }
                    $ordenacaoParams += @{ Expression = "VelCuraNum"; Descending = $descNormal } 
                    $ordenacaoParams += @{ Expression = "DesidratacaoNum"; Descending = $descNormal }
                }
                Default { $ordenacaoParams += @{ Expression = "Nome"; Descending = $descNormal } }
            }
        }
    }
    
    # Se o usuário escolheu Alfabético explicitamente (fallback)
    if ($Criterion -eq "Alfabético") { 
        $ordenacaoParams = @() # Limpa anteriores
        $alfabeticoDesc = if ($userWantsDescending) { $true } else { $false }
        $ordenacaoParams += @{ Expression = "Nome"; Descending = $alfabeticoDesc } 
    }

    return $Data | Sort-Object -Property $ordenacaoParams
}


function Save-ToCSV {
    param(
        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.DataGridView]$Grid
    )
    try {
        $dt = $Grid.DataSource
        if ($dt -eq $null -or $dt.Rows.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Nenhum dado para salvar.", "Aviso")
            return
        }
        $timestamp = (Get-Date).ToString("ddMMyyyy_HHmmss")
        $fileName = "Resultados_$timestamp.csv"
        
        # --- CORREÇÃO PS2EXE: Garante que salva na pasta do executável ---
        $baseDir = $PSScriptRoot
        if ([string]::IsNullOrEmpty($baseDir)) {
            $baseDir = [System.IO.Path]::GetDirectoryName([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
        }
        $savePath = Join-Path -Path $baseDir -ChildPath $fileName
        
        $exportData = @()
        foreach ($row in $dt.Rows) {
            $obj = [Ordered]@{}
            foreach ($col in $dt.Columns) { $obj[$col.ColumnName] = $row[$col.ColumnName] }
            $exportData += [PSCustomObject]$obj
        }
        
        # Gera o ficheiro formatado
        $exportData | Export-Csv -Path $savePath -NoTypeInformation -Encoding UTF8 -Delimiter ";" -Force
        [System.Windows.Forms.MessageBox]::Show("Resultados salvos com sucesso em:`n$savePath", "Sucesso")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erro ao salvar arquivo: $_", "Erro")
    }
}


function Sort-UnarmoredRigDataComplex {
    param ($Data, $Criterion, $Order)

    $expPeso       = { [double]$_.Weight }
    $expStorage    = { [int]$_.Storage }
    $expEfficiency = { [int]$_.Efficiency }
    $expBlock      = { [double]$_.BlockSortingScore }
    $expSetCount   = { [int]$_.SetCount } 
    $expUnfolded   = { [int]$_.UnfoldedArea } # Expressão do Novo Critério

    # Controle de Direção Dinâmica
    $userWantsDescending = ($Order -eq "Decrescente") 
    $descNormal  = $userWantsDescending      # Maior = Melhor (Espaço, Eficiência, Blocos)
    $descInverso = -not $userWantsDescending # Menor = Melhor (Peso, Tamanho Desdobrado)
    
    # Menor quantidade de bolsos (SetCount) é preferível
    $descSetCount = -not $userWantsDescending 

    $primaryExpr = $null
    $primaryDesc = $descNormal

    switch ($Criterion) {
        "Alfabético"                          { $primaryExpr = { $_.Nome }; $primaryDesc = $false; if ($userWantsDescending) { $primaryDesc = $true } }
        "Peso"                                { $primaryExpr = $expPeso; $primaryDesc = $descInverso }
        "Armazenamento"                       { $primaryExpr = $expStorage }
        "Conjunto de Blocos (HxV)"            { $primaryExpr = $expBlock }
        "+Espaço p/ Armaz. -Espaço Consumido" { $primaryExpr = $expEfficiency }
        Default                               { $primaryExpr = { $_.Nome } }
    }

    $ordenacaoParams = @()
    $ordenacaoParams += @{ Expression = $primaryExpr; Descending = $primaryDesc }

    # Tie-Breakers
    switch ($Criterion) {
        "Peso" {
            $ordenacaoParams += @{ Expression = $expStorage; Descending = $descNormal }
        }
        "Armazenamento" {
            $ordenacaoParams += @{ Expression = $expBlock; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expEfficiency; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
        }
        "Conjunto de Blocos (HxV)" {
            $ordenacaoParams += @{ Expression = $expStorage; Descending = $descNormal }
        }
        "+Espaço p/ Armaz. -Espaço Consumido" {
            # 1º Desempate: Menor Tamanho Desdobrado
            $ordenacaoParams += @{ Expression = $expUnfolded; Descending = $descInverso }
            
            # Desempates Originais Mantidos
            $ordenacaoParams += @{ Expression = $expStorage; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expSetCount; Descending = $descSetCount }
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
        }
    }
    return $Data | Sort-Object -Property $ordenacaoParams
}


function Sort-AmmoDataComplex {
    param ($Data, $Criterion, $Order)
    
    $primaryProp = switch ($Criterion) {
        "Alfabético"                   { "Nome" }
        "Nível de Penetração"          { "Lv" }
        "Penetração"                   { "PenetracaoNum" }
        "Dano Base"                    { "DanoBaseNum" }
        "Dano de Blindagem"            { "DanoArmaduraNum" }
        "Velocidade Inicial"           { "Velocidade" }
        "Precisão"                     { "PrecisaoNum" }
        "Controle de Recuo Vertical"   { "RecuoVertNum" }
        "Controle de Recuo Horizontal" { "RecuoHorizNum" }
        "Chance de Ferir"              { "ChanceFerirNum" }
    }

    $isDescending = ($Order -eq "Decrescente")
    $params = @()
    # Adiciona o critério principal
    $params += @{ Expression=$primaryProp; Descending=$isDescending }
    
    # Critérios de Desempate (Estrutura "Funcional" + Dano Base)
    switch ($Criterion) {
        "Alfabético" { 
            $params += @{ Expression="Lv"; Descending=$true }
            $params += @{ Expression="DanoBaseNum"; Descending=$true } 
        }
        "Dano Base" { 
            $params += @{ Expression="Lv"; Descending=$isDescending }
            $params += @{ Expression="PenetracaoNum"; Descending=$isDescending } 
        }
        "Nível de Penetração" { 
            $params += @{ Expression="DanoBaseNum"; Descending=$isDescending }
            $params += @{ Expression="PenetracaoNum"; Descending=$isDescending } 
        }
        "Chance de Ferir" { 
            $params += @{ Expression="DanoBaseNum"; Descending=$isDescending }
            $params += @{ Expression="Lv"; Descending=$isDescending } 
        }
        "Precisão" { 
            $params += @{ Expression="Lv"; Descending=$isDescending }
            $params += @{ Expression="DanoBaseNum"; Descending=$isDescending } 
        }
        "Penetração" { 
            $params += @{ Expression="Lv"; Descending=$isDescending }
            $params += @{ Expression="DanoBaseNum"; Descending=$isDescending } 
        }
        "Velocidade Inicial" { 
            $params += @{ Expression="Lv"; Descending=$isDescending }
            $params += @{ Expression="DanoBaseNum"; Descending=$isDescending } 
        }
        "Dano de Blindagem" { 
            $params += @{ Expression="Lv"; Descending=$isDescending }            # 1. Nível
            $params += @{ Expression="PenetracaoNum"; Descending=$isDescending } # 2. Penetração
            $params += @{ Expression="DanoBaseNum"; Descending=$isDescending }   # 3. Dano Base
        }
        "Controle de Recuo Vertical" { 
            $params += @{ Expression="Lv"; Descending=$isDescending }
            $params += @{ Expression="DanoBaseNum"; Descending=$isDescending } 
        }
        "Controle de Recuo Horizontal" { 
            $params += @{ Expression="Lv"; Descending=$isDescending }
            $params += @{ Expression="DanoBaseNum"; Descending=$isDescending } 
        }
    }
    
    return $Data | Sort-Object -Property $params
}


function Get-AbiDataTable {
    param (
        [string]$Mode,
        [array]$SortedData,
        [string]$CategorySelection # Usado para Gastronomia/Farmácia
    )

    $table = New-Object System.Data.DataTable

    # --- 1. ARMAS ---
    if ($Mode -eq "Weapon") {
        $table.Columns.Add("Nome"); $table.Columns.Add("Classe"); $table.Columns.Add("Calibre"); $table.Columns.Add("CRV"); $table.Columns.Add("CRH"); $table.Columns.Add("Ergo"); $table.Columns.Add("Esta.DA"); $table.Columns.Add("Prec"); $table.Columns.Add("Esta.SM"); $table.Columns.Add("Dis(m)"); $table.Columns.Add("Vel.bo"); $table.Columns.Add("ModoDisparo"); $table.Columns.Add("Cad"); $table.Columns.Add("Poder.DFG"); $table.Columns.Add("Melh.Cano")
        foreach ($item in $SortedData) { $row = $table.NewRow(); $row["Nome"] = $item.Nome; $row["Classe"] = $item.ClasseDisplay; $row["Calibre"] = $item.Calibre; $row["CRV"] = $item.VerticalRecoil; $row["CRH"] = $item.HorizontalRecoil; $row["Ergo"] = $item.Ergonomia; $row["Esta.DA"] = $item.EstabilidadeArma; $row["Prec"] = $item.Precisao; $row["Esta.SM"] = $item.Estabilidade; $row["Dis(m)"] = $item.Alcance; $row["Vel.bo"] = $item.Velocidade; $row["ModoDisparo"] = $item.ModoDisparoDisplay; $row["Cad"] = $item.Cadencia; $row["Poder.DFG"] = $item.PoderFogoDisplay; $row["Melh.Cano"] = $item.CanoDisplay; $table.Rows.Add($row) }
    } 
    # --- 2. CAPACETES ---
    elseif ($Mode -eq "Helmet") {
        $table.Columns.Add("Nome"); $table.Columns.Add("Peso"); $table.Columns.Add("Dur."); $table.Columns.Add("Cl"); $table.Columns.Add("Material"); $table.Columns.Add("Bloqueio"); $table.Columns.Add("Vel.M"); $table.Columns.Add("Ergo"); $table.Columns.Add("Área Protegida"); $table.Columns.Add("Ricoch"); $table.Columns.Add("Captad"); $table.Columns.Add("Red.Ru"); $table.Columns.Add("Acessório"); $table.Columns.Add("Cl Max Masc")
        foreach ($item in $SortedData) { $row = $table.NewRow(); $row["Nome"] = $item.Nome; $row["Peso"] = $item.Weight; $row["Dur."] = $item.Durability; $row["Cl"] = $item.ArmorClass; $row["Material"] = $item.MaterialDisplay; $row["Bloqueio"] = $item.BloqueioDisplay; $row["Vel.M"] = $item.MovementSpeed; $row["Ergo"] = $item.Ergonomics; $row["Área Protegida"] = $item.AreaDisplay; $row["Ricoch"] = $item.RicochDisplay; $row["Captad"] = $item.CaptadDisplay; $row["Red.Ru"] = $item.ReduRuDisplay; $row["Acessório"] = $item.AcessorioDisplay; $row["Cl Max Masc"] = $item.ClMaxMasc; $table.Rows.Add($row) }
    } 
    # --- 3. COLETES BALÍSTICOS ---
    elseif ($Mode -eq "Armor") {
        $table.Columns.Add("Nome"); $table.Columns.Add("Peso"); $table.Columns.Add("Cl"); $table.Columns.Add("Dur."); $table.Columns.Add("Material"); $table.Columns.Add("Vel.M"); $table.Columns.Add("Ergo"); $table.Columns.Add("Área Protegida")
        foreach ($item in $SortedData) { $row = $table.NewRow(); $row["Nome"] = $item.Nome; $row["Peso"] = $item.WeightDisplay; $row["Cl"] = $item.ArmorClass; $row["Dur."] = $item.DurabilityDisplay; $row["Material"] = $item.MaterialDisplay; $row["Vel.M"] = $item.MovementSpeed; $row["Ergo"] = $item.Ergonomics; $row["Área Protegida"] = $item.AreaDisplay; $table.Rows.Add($row) }
    } 
    # --- 4. COLETES BLINDADOS (RIGS) ---
    elseif ($Mode -eq "ArmoredRig") {
        $table.Columns.Add("Nome"); $table.Columns.Add("Peso"); $table.Columns.Add("Cl"); $table.Columns.Add("Dur."); $table.Columns.Add("Material"); $table.Columns.Add("Vel.M"); $table.Columns.Add("Ergo"); $table.Columns.Add("Esp"); $table.Columns.Add("Área Protegida"); $table.Columns.Add("Conj d. blocos (HxV)")
        foreach ($item in $SortedData) { $row = $table.NewRow(); $row["Nome"] = $item.Nome; $row["Peso"] = $item.WeightDisplay; $row["Cl"] = $item.ArmorClass; $row["Dur."] = $item.DurabilityDisplay; $row["Material"] = $item.MaterialDisplay; $row["Vel.M"] = $item.MovementSpeed; $row["Ergo"] = $item.Ergonomics; $row["Esp"] = $item.Storage; $row["Área Protegida"] = $item.AreaDisplay; $row["Conj d. blocos (HxV)"] = $item.LayoutDisplay; $table.Rows.Add($row) }
    } 
    # --- 5. COLETES NÃO BLINDADOS ---
    elseif ($Mode -eq "UnarmoredRig") { 
        $table.Columns.Add("Nome"); $table.Columns.Add("Peso"); $table.Columns.Add("Espaço"); $table.Columns.Add("Desdobrada"); $table.Columns.Add("Dobrada"); $table.Columns.Add("Conj d. blocos (HxV)"); $table.Columns.Add("+Armaz -Espaço")
        foreach ($item in $SortedData) { $row = $table.NewRow(); $row["Nome"] = $item.Nome; $row["Peso"] = $item.WeightDisplay; $row["Espaço"] = $item.Storage; $row["Desdobrada"] = $item.SizeUnfolded; $row["Dobrada"] = $item.SizeFolded; $row["Conj d. blocos (HxV)"] = $item.LayoutDisplay; $row["+Armaz -Espaço"] = $item.EfficiencyDisplay; $table.Rows.Add($row) } 
    } 
    # --- 6. MOCHILAS ---
    elseif ($Mode -eq "Backpack") { 
        $table.Columns.Add("Nome"); $table.Columns.Add("Peso"); $table.Columns.Add("Espaço"); $table.Columns.Add("Desdobrada"); $table.Columns.Add("Dobrada"); $table.Columns.Add("Conj d. blocos (HxV)"); $table.Columns.Add("+Armaz -Espaço")
        foreach ($item in $SortedData) { $row = $table.NewRow(); $row["Nome"] = $item.Nome; $row["Peso"] = $item.WeightDisplay; $row["Espaço"] = $item.Storage; $row["Desdobrada"] = $item.SizeUnfolded; $row["Dobrada"] = $item.SizeFolded; $row["Conj d. blocos (HxV)"] = $item.LayoutDisplay; $row["+Armaz -Espaço"] = $item.EfficiencyDisplay; $table.Rows.Add($row) } 
    } 
    # --- 7. HEADSETS ---
    elseif ($Mode -eq "Headset") { 
        $table.Columns.Add("Nome"); $table.Columns.Add("Peso"); $table.Columns.Add("Captador de Som"); $table.Columns.Add("Redução de Ruído")
        foreach ($item in $SortedData) { $row = $table.NewRow(); $row["Nome"] = $item.Nome; $row["Peso"] = $item.WeightDisplay; $row["Captador de Som"] = $item.SoundPickup; $row["Redução de Ruído"] = $item.NoiseReduction; $table.Rows.Add($row) } 
    } 
    # --- 8. MÁSCARAS DE GÁS ---
    elseif ($Mode -eq "GasMask") { 
        $table.Columns.Add("Nome"); $table.Columns.Add("Peso"); $table.Columns.Add("Dur."); $table.Columns.Add("Anti-Veneno"); $table.Columns.Add("Anti-Flash")
        foreach ($item in $SortedData) { $row = $table.NewRow(); $row["Nome"] = $item.Nome; $row["Peso"] = $item.WeightDisplay; $row["Dur."] = $item.DurabilityDisplay; $row["Anti-Veneno"] = $item.AntiVeneno; $row["Anti-Flash"] = $item.AntiFlash; $table.Rows.Add($row) } 
    } 
    # --- 9. MÁSCARAS ---
    elseif ($Mode -eq "Mask") { 
        $table.Columns.Add("Nome"); $table.Columns.Add("Peso"); $table.Columns.Add("Dur."); $table.Columns.Add("Cl"); $table.Columns.Add("Material"); $table.Columns.Add("Chance de Ricochete")
        foreach ($item in $SortedData) { $row = $table.NewRow(); $row["Nome"] = $item.Nome; $row["Peso"] = $item.WeightDisplay; $row["Dur."] = $item.DurabilityDisplay; $row["Cl"] = $item.ArmorClass; $row["Material"] = $item.MaterialDisplay; $row["Chance de Ricochete"] = $item.RicocheteDisplay; $table.Rows.Add($row) } 
    } 
    # --- 10. ARREMESSÁVEIS ---
    elseif ($Mode -eq "Throwable") { 
        $table.Columns.Add("Nome"); $table.Columns.Add("Delay Explosão"); $table.Columns.Add("Alcance"); $table.Columns.Add("Dano Blind"); $table.Columns.Add("Penetração"); $table.Columns.Add("Fragmentos"); $table.Columns.Add("Tipo Frags."); $table.Columns.Add("Tempo Efeito")
        foreach ($item in $SortedData) { $row = $table.NewRow(); $row["Nome"] = $item.Nome; $row["Delay Explosão"] = $item.DelayExplosao; $row["Alcance"] = $item.Alcance; $row["Dano Blind"] = $item.DanoBlind; $row["Penetração"] = $item.Penetracao; $row["Fragmentos"] = $item.Fragmentos; $row["Tipo Frags."] = $item.TipoFrags; $row["Tempo Efeito"] = $item.TempoEfeito; $table.Rows.Add($row) } 
    } 
    # --- 11. GASTRONOMIA ---
    elseif ($Mode -eq "Gastronomy") { 
        $table.Columns.Add("Nome"); $table.Columns.Add("Hidratação"); $table.Columns.Add("Energia"); $table.Columns.Add("Rec.Stamina"); $table.Columns.Add("Espaço (HxV)"); $table.Columns.Add("Hidrat.Slot"); $table.Columns.Add("Energ.Slot"); $table.Columns.Add("Delay")
        foreach ($item in $SortedData) { $row = $table.NewRow(); $row["Nome"] = $item.Nome; $row["Hidratação"] = $item.Hidratacao; $row["Energia"] = $item.Energia; $row["Rec.Stamina"] = $item.RecStamina; $row["Espaço (HxV)"] = $item.EspacoHV; $row["Hidrat.Slot"] = $item.HidratSlot; $row["Energ.Slot"] = $item.EnergSlot; $row["Delay"] = $item.Delay; $table.Rows.Add($row) }
    } 
    # --- 12. FARMÁCIA (Estrutura Dinâmica via Config) ---
    elseif ($Mode -eq "Pharmaceutical") {
        $config = Get-ViewConfig -Mode $Mode -Category $CategorySelection
        foreach ($colName in $config.ColumnLayout.Keys) { if (-not $table.Columns.Contains($colName)) { $table.Columns.Add($colName) } }
        foreach ($item in $SortedData) { 
            $row = $table.NewRow(); $row["Nome"] = $item.Nome
            if ($table.Columns.Contains("Usos")) { $row["Usos"] = $item.Usos }
            if ($table.Columns.Contains("Duração")) { $row["Duração"] = $item.Duracao }
            if ($table.Columns.Contains("Desidratação")) { $row["Desidratação"] = $item.Desidratacao }
            if ($table.Columns.Contains("Tempo de Atraso")) { $row["Tempo de Atraso"] = $item.TempoAtraso }
            if ($table.Columns.Contains("Dur. Max")) { $row["Dur. Max"] = $item.DurMax }
            if ($table.Columns.Contains("Des. Max")) { $row["Des. Max"] = $item.DesMax }
            if ($table.Columns.Contains("Custo Durabilidade")) { $row["Custo Durabilidade"] = $item.CustoDurabilidade }
            if ($table.Columns.Contains("Rec. HP")) { $row["Rec. HP"] = $item.RecHP }
            if ($table.Columns.Contains("Custo Dur.")) { $row["Custo Dur."] = $item.CustoDur }
            if ($table.Columns.Contains("Espaco (HxV)")) { $row["Espaco (HxV)"] = $item.EspacoHV }
            if ($table.Columns.Contains("Durabilidade")) { $row["Durabilidade"] = $item.Durabilidade }
            if ($table.Columns.Contains("Vel. Cura")) { $row["Vel. Cura"] = $item.VelCura }
            if ($table.Columns.Contains("Delay")) { $row["Delay"] = $item.Delay }
            if ($table.Columns.Contains("Durab. p/ Slot")) { $row["Durab. p/ Slot"] = $item.DurabSlot }
            if ($table.Columns.Contains("Efeito Principal")) { $row["Efeito Principal"] = $item.EfeitoPrincipal }
            if ($table.Columns.Contains("Red. Energia")) { $row["Red. Energia"] = $item.RedEnergia }
            $table.Rows.Add($row)
        }
    }

    return $table
}


function Sort-ThrowableDataComplex {
    param ($Data, $Criterion, $Order)

    # Controle de Direção Dinâmica
    $userWantsDescending = ($Order -eq "Decrescente") 
    $descNormal  = $userWantsDescending      # Maior = Melhor (Dano, Alcance, etc)
    $descInverso = -not $userWantsDescending # Menor = Melhor (Delay - quanto mais rápido melhor)
    
    $primaryExpr = $null
    $primaryDesc = $descNormal

    switch ($Criterion) {
        "Alfabético"        { $primaryExpr = { $_.Nome }; $primaryDesc = $false; if ($userWantsDescending) { $primaryDesc = $true } }
        "Delay de Explosão" { $primaryExpr = { $_.DelayNum1 }; $primaryDesc = $descInverso }
        "Alcance"           { $primaryExpr = { $_.AlcanceNum } }
        "Dano em Blindagem" { $primaryExpr = { $_.DanoBlindNum } }
        "Penetração"        { $primaryExpr = { $_.PenetracaoNum } }
        "Fragmentos"        { $primaryExpr = { $_.FragmentosNum } }
        "Tipo de Frags."    { $primaryExpr = { $_.TipoFragsNum } }
        "Tempo de Efeito"   { $primaryExpr = { $_.TempoEfeitoNum } }
        Default             { $primaryExpr = { $_.Nome } }
    }

    $ordenacaoParams = @()
    $ordenacaoParams += @{ Expression = $primaryExpr; Descending = $primaryDesc }

    # Tie-Breakers (Baseado no Script Antigo)
    # Todos usam $descNormal (Melhor) exceto Delay (Menor é Melhor)
    $ordenacaoParams += @{ Expression = { $_.AlcanceNum }; Descending = $descNormal }
    $ordenacaoParams += @{ Expression = { $_.DelayNum1 }; Descending = $descInverso }
    $ordenacaoParams += @{ Expression = { $_.DelayNum2 }; Descending = $descInverso }
    
    # Adicionais baseados na especificidade do critério
    if ($Criterion -eq "Dano em Blindagem" -or $Criterion -eq "Penetração" -or $Criterion -eq "Fragmentos" -or $Criterion -eq "Tipo de Frags.") {
        $ordenacaoParams += @{ Expression = { $_.PenetracaoNum }; Descending = $descNormal }
        $ordenacaoParams += @{ Expression = { $_.DanoBlindNum }; Descending = $descNormal }
    }

    return $Data | Sort-Object -Property $ordenacaoParams
}


function Get-HeadsetData {
    $folderPath = Get-DatabasePath
    $csvPath = Join-Path -Path $folderPath -ChildPath "Headsets.csv"
    
    if (-not (Test-Path $csvPath)) { return @() }
    
    $data = Import-Csv -Path $csvPath -Delimiter ";" -Encoding UTF8
    $results = @()

    $effectMapDisplay = @{ "Bad"="Fraco"; "Medium"="Médio"; "Strong"="Forte" }
    $effectMapNum     = @{ "Bad"=1; "Medium"=2; "Strong"=3 }

    foreach ($row in $data) {
        $soundDisp = if ($effectMapDisplay.ContainsKey($row.CaptacaoSom)) { $effectMapDisplay[$row.CaptacaoSom] } else { $row.CaptacaoSom }
        $noiseDisp = if ($effectMapDisplay.ContainsKey($row.ReducaoRuido)) { $effectMapDisplay[$row.ReducaoRuido] } else { $row.ReducaoRuido }
        
        $soundNum = if ($effectMapNum.ContainsKey($row.CaptacaoSom)) { $effectMapNum[$row.CaptacaoSom] } else { 0 }
        $noiseNum = if ($effectMapNum.ContainsKey($row.ReducaoRuido)) { $effectMapNum[$row.ReducaoRuido] } else { 0 }

        $obj = [PSCustomObject]@{
            Nome              = $row.NomeItem
            
            Weight            = if ($row.Peso) { [double]$row.Peso } else { 0 }
            SoundPickupNum    = $soundNum
            NoiseReductionNum = $noiseNum

            WeightDisplay     = $row.Peso
            SoundPickup       = $soundDisp
            NoiseReduction    = $noiseDisp
        }
        $results += $obj
    }
    return $results
}


function Get-GastronomyData {
    param([string]$Category = "Todas as comidas e bebidas")

    $folderPath = Get-DatabasePath
    if (-not (Test-Path $folderPath)) {
        # --- CORREÇÃO PS2EXE ---
        $baseDir = $PSScriptRoot
        if ([string]::IsNullOrEmpty($baseDir)) {
            $baseDir = [System.IO.Path]::GetDirectoryName([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
        }
        
        if (Test-Path (Join-Path $baseDir "Food.csv")) { $folderPath = $baseDir }
    }

    $filesToRead = @()
    if ($Category -eq "Todas as comidas e bebidas") {
        $filesToRead = "Beverages.csv", "Food.csv"
    } elseif ($Category -eq "Bebida") {
        $filesToRead = "Beverages.csv"
    } else {
        $filesToRead = "Food.csv"
    }
    
    $results = @()

    foreach ($fileName in $filesToRead) {
        $csvPath = Join-Path -Path $folderPath -ChildPath $fileName
        if (Test-Path $csvPath) {
            $csvContent = Import-Csv -Path $csvPath -Delimiter ";" -Encoding UTF8
            
            foreach ($row in $csvContent) {
                $slots = 1
                if ($row.EspacoOcupado -match '(\d+)x(\d+)') {
                    $hSlots = [int]$Matches[1]; $vSlots = [int]$Matches[2]
                    if (($hSlots * $vSlots) -gt 0) { $slots = $hSlots * $vSlots }
                }
                
                $hidratacaoNum = 0
                if ($row.Hidratacao -ne '/////') {
                    $cleanHid = $row.Hidratacao.Replace('+', '')
                    if ($cleanHid -match '^-?\d+$') { $hidratacaoNum = [int]$cleanHid }
                }
                
                $energiaNum = 0
                if ($row.Energia -ne '/////') {
                    $cleanEng = $row.Energia.Replace('+', '')
                    if ($cleanEng -match '^-?\d+$') { $energiaNum = [int]$cleanEng }
                }

                $hidratSlot = [math]::Round(($hidratacaoNum / $slots), 1)
                $energSlot  = [math]::Round(($energiaNum / $slots), 1)
                
                $recStaminaDisplay = if ($row.RecuperacaoStamina -eq 'None') { '/////' } else { $row.RecuperacaoStamina }

                $obj = [PSCustomObject]@{
                    Nome                 = $row.NomeItem
                    
                    HidratacaoNum        = $hidratacaoNum
                    EnergiaNum           = $energiaNum
                    HidratSlot           = $hidratSlot
                    EnergSlot            = $energSlot
                    TotalSlots           = $slots

                    Hidratacao           = $row.Hidratacao
                    Energia              = $row.Energia
                    Delay                = $row.Delay
                    RecStamina           = $recStaminaDisplay
                    EspacoHV             = $row.EspacoOcupado
                }
                $results += $obj
            }
        }
    }
    return $results
}


function Get-GasMaskData {
    $folderPath = Get-DatabasePath
    $csvPath = Join-Path -Path $folderPath -ChildPath "Gasmasks.csv"
    
    if (-not (Test-Path $csvPath)) { return @() }
    
    $data = Import-Csv -Path $csvPath -Delimiter ";" -Encoding UTF8
    $results = @()

    $effectMapDisplay = @{ "/////"="/////"; "Bad"="Fraco"; "Medium"="Médio"; "Strong"="Forte" }
    $effectMapNum     = @{ "/////"=0; "Bad"=1; "Medium"=2; "Strong"=3 }

    foreach ($row in $data) {
        $antiVenenoDisp = if ($effectMapDisplay.ContainsKey($row.AntiVeneno)) { $effectMapDisplay[$row.AntiVeneno] } else { $row.AntiVeneno }
        $antiFlashDisp  = if ($effectMapDisplay.ContainsKey($row.AntiFlash)) { $effectMapDisplay[$row.AntiFlash] } else { $row.AntiFlash }
        
        $antiVenenoNum = if ($effectMapNum.ContainsKey($row.AntiVeneno)) { $effectMapNum[$row.AntiVeneno] } else { 0 }
        $antiFlashNum  = if ($effectMapNum.ContainsKey($row.AntiFlash)) { $effectMapNum[$row.AntiFlash] } else { 0 }

        $obj = [PSCustomObject]@{
            Nome              = $row.NomeItem
            
            Weight            = if ($row.Peso) { [double]$row.Peso } else { 0 }
            Durability        = if ($row.Durabilidade) { [double]$row.Durabilidade } else { 0 }
            AntiVenenoNum     = $antiVenenoNum
            AntiFlashNum      = $antiFlashNum

            WeightDisplay     = $row.Peso
            DurabilityDisplay = $row.Durabilidade
            AntiVeneno        = $antiVenenoDisp
            AntiFlash         = $antiFlashDisp
        }
        $results += $obj
    }
    return $results
}


function Sort-WeaponDataComplex {
    param ($Data, $Criterion, $Order)

    $propriedadePrimaria = switch ($Criterion) {
        "Alfabético"                   { "Nome" }
        "Controle de Recuo Vertical"   { "VerticalRecoil" }
        "Controle de Recuo Horizontal" { "HorizontalRecoil" }
        "Ergonomia"                    { "Ergonomia" }
        "Estabilidade da Arma"         { "EstabilidadeArma" }
        "Precisão"                     { "Precisao" }
        "Estabilidade sem Mirar"       { "Estabilidade" }
        "Distância Efetiva"            { "Alcance" }
        "Velocidade de Saída"          { "Velocidade" }
        "Modo de Disparo"              { "ModoDisparoNum" }
        "Cadência"                     { "Cadencia" }
        "Poder de Fogo"                { "PoderFogoNum" }
        "Melhoria de Cano"             { "CanoNum" }
        Default                        { "Nome" }
    }
    
    $isDescending = ($Order -eq "Decrescente")
    
    # Adiciona o critério principal
    $ordenacaoParams = @( @{ Expression = { $_."$propriedadePrimaria" }; Descending = $isDescending } )
    
    # Adiciona os critérios de desempate (Tie-Breakers)
    switch ($Criterion) {
        "Controle de Recuo Vertical" { 
            $ordenacaoParams += @{ Expression = 'Precisao'; Descending = $isDescending }         # 1º Desempate
            $ordenacaoParams += @{ Expression = 'HorizontalRecoil'; Descending = $isDescending } # 2º Desempate
            $ordenacaoParams += @{ Expression = 'Cadencia'; Descending = $isDescending }         # 3º Desempate
        }
        "Controle de Recuo Horizontal" { 
            $ordenacaoParams += @{ Expression = 'Precisao'; Descending = $isDescending }         # 1º Desempate
            $ordenacaoParams += @{ Expression = 'VerticalRecoil'; Descending = $isDescending }   # 2º Desempate
            $ordenacaoParams += @{ Expression = 'Cadencia'; Descending = $isDescending }         # 3º Desempate
        }
        "Ergonomia" { 
            $ordenacaoParams += @{ Expression = 'Precisao'; Descending = $isDescending }         # 1º Desempate
            $ordenacaoParams += @{ Expression = 'Cadencia'; Descending = $isDescending }         # 2º Desempate
        }
        "Estabilidade da Arma" {
            $ordenacaoParams += @{ Expression = 'Precisao'; Descending = $isDescending }         # 1º Desempate
            $ordenacaoParams += @{ Expression = 'HorizontalRecoil'; Descending = $isDescending } # 2º Desempate
            $ordenacaoParams += @{ Expression = 'Cadencia'; Descending = $isDescending }         # 3º Desempate
        }
        "Precisão" {
            $ordenacaoParams += @{ Expression = 'Cadencia'; Descending = $isDescending }         # 1º Desempate
            $ordenacaoParams += @{ Expression = 'HorizontalRecoil'; Descending = $isDescending } # 2º Desempate
        }
        "Estabilidade sem Mirar" {
            $ordenacaoParams += @{ Expression = 'Precisao'; Descending = $isDescending }         # 1º Desempate
            $ordenacaoParams += @{ Expression = 'Cadencia'; Descending = $isDescending }         # 2º Desempate
        }
        "Distância Efetiva" {
            $ordenacaoParams += @{ Expression = 'Velocidade'; Descending = $isDescending }       # 1º Desempate
            $ordenacaoParams += @{ Expression = 'Cadencia'; Descending = $isDescending }         # 2º Desempate
            $ordenacaoParams += @{ Expression = 'HorizontalRecoil'; Descending = $isDescending }  # 3º Desempate
        }
        "Velocidade de Saída" { 
            $ordenacaoParams += @{ Expression = 'Alcance'; Descending = $isDescending }            # 1º Desempate
        }
        "Modo de Disparo"  { 
            $ordenacaoParams += @{ Expression = 'PoderFogoNum'; Descending = $isDescending }      # 1º Desempate
            $ordenacaoParams += @{ Expression = 'Cadencia'; Descending = $isDescending }          # 2º Desempate
            $ordenacaoParams += @{ Expression = 'Alcance'; Descending = $isDescending }           # 3º Desempate
            $ordenacaoParams += @{ Expression = 'HorizontalRecoil'; Descending = $isDescending }  # 4º Desempate
        }
        "Cadência"          { 
            $ordenacaoParams += @{ Expression = 'PoderFogoNum'; Descending = $isDescending }      # 1º Desempate
        }
        "Poder de Fogo"     { 
            $ordenacaoParams += @{ Expression = 'Velocidade'; Descending = $isDescending }        # 1º Desempate
            $ordenacaoParams += @{ Expression = 'Cadencia'; Descending = $isDescending }          # 2º Desempate
        }
        "Melhoria de Cano"    { 
            $ordenacaoParams += @{ Expression = 'PoderFogoNum'; Descending = $isDescending }      # 1º Desempate
            $ordenacaoParams += @{ Expression = 'Alcance'; Descending = $isDescending }           # 2º Desempate
            $ordenacaoParams += @{ Expression = 'Cadencia'; Descending = $isDescending }          # 3º Desempate
            $ordenacaoParams += @{ Expression = 'HorizontalRecoil'; Descending = $isDescending }  # 4º Desempate
        }
    }

    return $Data | Sort-Object -Property $ordenacaoParams
}


function Sort-ArmoredRigDataComplex {
    param ($Data, $Criterion, $Order)

    $expPeso      = { [double]$_.Weight }
    $expDurab     = { [double]$_.Durability }
    $expArmor     = { [int]$_.ArmorClass }
    $expMov       = { [int]$_.MovementSpeedNum }
    $expErgo      = { [int]$_.ErgonomicsNum }
    $expStorage   = { [int]$_.Storage }
    $expBlock     = { [double]$_.BlockSortingScore }
    $expArea      = { [int]$_.AreaNum }

    # Controle de Direção Dinâmica
    $userWantsDescending = ($Order -eq "Decrescente") 
    $descNormal  = $userWantsDescending      # Maior = Melhor
    $descInverso = -not $userWantsDescending # Menor = Melhor (Peso)

    $primaryExpr = $null
    $primaryDesc = $descNormal

    switch ($Criterion) {
        "Alfabético"              { $primaryExpr = { $_.Nome }; $primaryDesc = $false; if ($userWantsDescending) { $primaryDesc = $true } }
        "Peso"                    { $primaryExpr = $expPeso; $primaryDesc = $descInverso }
        "Durabilidade"            { $primaryExpr = $expDurab }
        "Classe de Blindagem"     { $primaryExpr = $expArmor }
        "Penalidade de Movimento" { $primaryExpr = $expMov }
        "Ergonomia"               { $primaryExpr = $expErgo }
        "Armazenamento"           { $primaryExpr = $expStorage }
        "Área Protegida"          { $primaryExpr = $expArea }
        "Conjunto de Blocos (HxV)"{ $primaryExpr = $expBlock }
        Default                   { $primaryExpr = { $_.Nome } }
    }

    $ordenacaoParams = @()
    $ordenacaoParams += @{ Expression = $primaryExpr; Descending = $primaryDesc }

    # Tie-Breakers (Regras do Script Antigo)
    switch ($Criterion) {
        "Armazenamento" {
            $ordenacaoParams += @{ Expression = $expArmor; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expDurab; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
        }
        "Conjunto de Blocos (HxV)" {
            $ordenacaoParams += @{ Expression = $expArmor; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expDurab; Descending = $descNormal }
        }
        "Peso" {
            $ordenacaoParams += @{ Expression = $expArmor; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expDurab; Descending = $descNormal }
        }
        "Durabilidade" {
            $ordenacaoParams += @{ Expression = $expArmor; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
        }
        "Classe de Blindagem" {
            $ordenacaoParams += @{ Expression = $expDurab; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
        }
        "Ergonomia" {
            $ordenacaoParams += @{ Expression = $expArmor; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expDurab; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
        }
        "Área Protegida" {
            $ordenacaoParams += @{ Expression = $expArmor; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expDurab; Descending = $descNormal }
            $ordenacaoParams += @{ Expression = $expPeso; Descending = $descInverso }
        }
    }
    return $Data | Sort-Object -Property $ordenacaoParams
}


function Get-WeaponData {
    $folderPath = Get-DatabasePath
    $csvPath = Join-Path -Path $folderPath -ChildPath "Weapons.csv"

    $poderFogoMapDisplay = @{ "Low"="Baixo";"Mid-Low"="Médio-Baixo";"Medium"="Médio";"Mid-High"="Médio-Alto";"High"="Alto"; "Ultra High"="Ultra-alto" }
    $canoMapDisplay      = @{ "Default +"="Padrão +";"FB"="CF";"R+"="A+";"FB D+"="CF D+";"FB D-"="CF D-";"D+ R+"="D+ A+";"Custom"="Custom" }
    
    $poderFogoMapNum = @{ "Low"=1; "Mid-Low"=2; "Medium"=3; "Mid-High"=4; "High"=5; "Ultra High"=6 }
    $canoMapNum      = @{ "FB D-"=1; "Custom"=2; "FB"=2; "FB D+"=4; "Default +"=5; "R+"=6; "D+"=6; "D+ R+"=7 }
    $modoMapNum      = @{
        "Pump-Action" = 1; "Bolt-Action" = 1
        "3-RB" = 2
        "Semi" = 3; "Semi, 3-RB" = 3
        "Full" = 4; "Semi, Full" = 4; "2-RB, Semi, Full" = 4; "3-RB, Semi, Full" = 4
    }

    $data = @()

    if (Test-Path $csvPath) {
        $rawContent = Import-Csv -Path $csvPath -Delimiter ";" -Encoding UTF8
        
        foreach ($row in $rawContent) {
            $estabilidadeArmaValue = if ($row.EstabilidadeArma) { [int]$row.EstabilidadeArma } else { 0 }
            $classePT = if ($global:WeaponClassToPortugueseMap[$row.Classe]) { $global:WeaponClassToPortugueseMap[$row.Classe] } else { $row.Classe }
            
            $modoDisparoDisplay = $row.ModoDisparo.Replace('Bolt-Action', 'A.Ferrolho').Replace('Pump-Action', 'A.Bombeamento').Replace('Full', 'Auto')
            $poderDisplay = if ($poderFogoMapDisplay.ContainsKey($row.PoderFogo)) { $poderFogoMapDisplay[$row.PoderFogo] } else { $row.PoderFogo }
            $canoDisplay  = if ($canoMapDisplay.ContainsKey($row.TipoCano)) { $canoMapDisplay[$row.TipoCano] } else { $row.TipoCano }
 
            $poderNum = if ($poderFogoMapNum[$row.PoderFogo]) { $poderFogoMapNum[$row.PoderFogo] } else { 0 }
            $canoNum  = if ($canoMapNum[$row.TipoCano]) { $canoMapNum[$row.TipoCano] } else { 0 }
            $modoNum  = if ($modoMapNum[$row.ModoDisparo]) { $modoMapNum[$row.ModoDisparo] } else { 0 }
 
            $data += [PSCustomObject]@{
                Nome               = $row.NomeItem
                ClasseDisplay      = $classePT
                Calibre            = $row.Calibre
                VerticalRecoil     = [int]$row.RecuoVertical
                HorizontalRecoil   = [int]$row.RecuoHorizontal
                Ergonomia          = [int]$row.Ergonomia
                EstabilidadeArma   = $estabilidadeArmaValue
                Precisao           = [int]$row.Precisao
                Estabilidade       = [int]$row.EstabilidadeHipFire
                Alcance            = [int]$row.Alcance
                Velocidade         = [int]$row.VelocidadeBocal
                ModoDisparoDisplay = $modoDisparoDisplay
                ModoDisparoNum     = $modoNum
                Cadencia           = [int]$row.Cadencia
                PoderFogoDisplay   = $poderDisplay
                PoderFogoNum       = $poderNum
                CanoDisplay        = $canoDisplay
                CanoNum            = $canoNum
            }
        }
    } else {
        Write-Warning "Arquivo Weapons.csv não encontrado em: $csvPath"
    }
    return $data
}


function Show-ArmoredRigFilterDialog {
    param([Parameter(Mandatory=$true)] $Data, [Parameter(Mandatory=$true)] $ThemeColors)

    $dlg = New-Object System.Windows.Forms.Form; $dlg.Text = "Filtro de Coletes Blindados"; $dlg.Size = New-Object System.Drawing.Size(800, 500); $dlg.StartPosition = "CenterParent"; $dlg.FormBorderStyle = "FixedDialog"; $dlg.MaximizeBox = $false
    $dlg.BackColor = $ThemeColors.Background; $dlg.ForeColor = $ThemeColors.TextMain

    $tempManualFilters = @{}; foreach ($k in $script:manualFilters.Keys) { $tempManualFilters[$k] = [System.Collections.ArrayList]@($script:manualFilters[$k]) }
    
    $customOrderClass = @("1", "2", "3", "4", "5", "6")
    
    # ATENÇÃO: Esta lista deve combinar com os dados REAIS da tabela (abreviados) para a ordenação funcionar
    $customOrderAreaData = @(
        "Torax", 
        "Torax, Abdomen Sup.", 
        "Torax, Abd. Sup. e Inf.", 
        "Torax, Ombro, Abd. Sup. e Inf."
    )

    # NOVO: Mapa para traduzir o "Dado Real" (Abreviado) para o "Texto do Filtro" (Completo e Acentuado)
    $areaDisplayMap = @{
        "Torax"                          = "Tórax"
        "Torax, Abdomen Sup."            = "Tórax, Abdômen Superior"
        "Torax, Abd. Sup. e Inf."        = "Tórax, Abdômen Superior e Inferior"
        "Torax, Ombro, Abd. Sup. e Inf." = "Tórax, Ombro, Abdômen Superior e Inferior"
    }

    $filterDefs = @(
        @{Title="Classe de Blindagem"; Prop="ArmorClass";  ColIndex=0; CustomOrder=$customOrderClass},
        @{Title="Área Protegida";      Prop="AreaDisplay"; ColIndex=1; CustomOrder=$customOrderAreaData}
    )

    foreach ($def in $filterDefs) { if (-not $tempManualFilters.ContainsKey($def.Prop)) { $tempManualFilters[$def.Prop] = New-Object System.Collections.ArrayList } }
    
    $visualState = @{} 
    $mainLayout = New-Object System.Windows.Forms.TableLayoutPanel; $mainLayout.Dock = "Top"; $mainLayout.Height = 380; $mainLayout.ColumnCount = 2
    for($i=0; $i -lt 2; $i++){ $mainLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 50))) | Out-Null }
    $allCheckBoxes = @()

    $script:UpdateFilterUI = {
        $survivors = New-Object System.Collections.Generic.List[Object]; foreach ($item in $Data) { $isSurvivor = $true; foreach ($k in $tempManualFilters.Keys) { $filterList = $tempManualFilters[$k]; if ($filterList.Count -eq 0) { continue }; if ($filterList -contains $item.($k)) { $isSurvivor = $false; break } }; if ($isSurvivor) { $survivors.Add($item) } }
        $availableValues = @{}; foreach ($k in $script:manualFilters.Keys) { $availableValues[$k] = New-Object System.Collections.Generic.HashSet[string] }
        foreach ($def in $filterDefs) { if (-not $availableValues.ContainsKey($def.Prop)) { $availableValues[$def.Prop] = New-Object System.Collections.Generic.HashSet[string] } }

        foreach ($item in $survivors) { foreach ($k in $availableValues.Keys) { $val = $item.($k); if (-not [string]::IsNullOrEmpty($val)) { $availableValues[$k].Add($val) | Out-Null } } }
        
        foreach ($cb in $allCheckBoxes) {
            $prop = $cb.Tag.Prop; $val = $cb.Tag.Value; $uKey = $cb.Tag.UniqueKey
            if ($tempManualFilters[$prop].Contains($val)) { 
                $visualState[$uKey] = 'M'
                $cb.Checked = $true
                $cb.Enabled = $true
                $cb.ForeColor = $ThemeColors.OrangeAccent 
                $cb.BackColor = [System.Drawing.Color]::Empty
            }
            elseif (-not $availableValues[$prop].Contains($val)) { 
                $visualState[$uKey] = 'A'
                $cb.Checked = $true
                $cb.ForeColor = $ThemeColors.TextDim 
                $cb.BackColor = $ThemeColors.ButtonBack # Destaca opções auto-filtradas
            }
            else { 
                $visualState[$uKey] = 'F'
                $cb.Checked = $false
                $cb.ForeColor = $ThemeColors.TextMain 
                $cb.BackColor = [System.Drawing.Color]::Empty
            }
        }
    }

    foreach ($def in $filterDefs) {
        $gb = New-Object System.Windows.Forms.GroupBox; $gb.Text = $def.Title; $gb.Dock = "Fill"; $gb.ForeColor = $ThemeColors.TextMain
        $flow = New-Object System.Windows.Forms.FlowLayoutPanel; $flow.Dock = "Fill"; $flow.FlowDirection = "TopDown"; $flow.AutoScroll = $true; $flow.WrapContents = $false
        $rawValues = $Data | Select-Object -ExpandProperty $def.Prop -Unique
        
        $orderedValues = @()
        if ($def.CustomOrder) { 
            foreach ($orderedItem in $def.CustomOrder) { 
                $exists = $false; foreach($r in $rawValues) { if("$r" -eq "$orderedItem") { $exists = $true; break } }
                if ($exists) { $orderedValues += $orderedItem } 
            }
            foreach ($rawItem in $rawValues) { $isInList = $false; foreach($o in $orderedValues) { if("$o" -eq "$rawItem") { $isInList = $true; break } }; if (-not $isInList) { $orderedValues += $rawItem } } 
        } else { $orderedValues = $rawValues | Sort-Object }

        foreach ($val in $orderedValues) {
            if ([string]::IsNullOrWhiteSpace($val)) { continue }
            
            # --- LÓGICA DE TRADUÇÃO VISUAL ---
            # Se for Área Protegida, tenta usar o nome longo. Se não, usa o valor original.
            $displayText = $val
            if ($def.Prop -eq "AreaDisplay" -and $areaDisplayMap.ContainsKey($val)) {
                $displayText = $areaDisplayMap[$val]
            }
            # ---------------------------------

            $cb = New-Object System.Windows.Forms.CheckBox; $cb.Text = "$displayText"; $cb.AutoSize = $true; $cb.AutoCheck = $false; $cb.Tag = @{ Prop = $def.Prop; Value = $val; UniqueKey = "$($def.Prop)_$val" }
            $cb.ForeColor = $ThemeColors.TextMain
            $cb.Add_Click({ param($sender, $e) $prop = $sender.Tag.Prop; $v = $sender.Tag.Value; $k = $sender.Tag.UniqueKey; $state = $visualState[$k]; if ($state -eq 'A') { return }; if ($tempManualFilters[$prop].Contains($v)) { $tempManualFilters[$prop].Remove($v) } else { $tempManualFilters[$prop].Add($v) | Out-Null }; & $script:UpdateFilterUI })
            $flow.Controls.Add($cb); $allCheckBoxes += $cb
        }
        $gb.Controls.Add($flow); $mainLayout.Controls.Add($gb, $def.ColIndex, 0)
    }

    & $script:UpdateFilterUI
    $btnPanel = New-Object System.Windows.Forms.Panel; $btnPanel.Dock = "Bottom"; $btnPanel.Height = 60; $btnPanel.BackColor = $ThemeColors.Background
    $btnReset = New-Object System.Windows.Forms.Button; $btnReset.Text = "Resetar"; $btnReset.Size = "100, 30"; $btnReset.Location = "350, 15"; $btnReset.FlatStyle = "Flat"; $btnReset.BackColor = $ThemeColors.ButtonBack; $btnReset.ForeColor = $ThemeColors.TextMain; $btnReset.Add_Click({ foreach ($k in $tempManualFilters.Keys) { $tempManualFilters[$k].Clear() }; & $script:UpdateFilterUI })
    $btnOk = New-Object System.Windows.Forms.Button; $btnOk.Text = "OK"; $btnOk.Size = "100, 30"; $btnOk.Location = "460, 15"; $btnOk.DialogResult = "OK"; $btnOk.FlatStyle = "Flat"; $btnOk.BackColor = $ThemeColors.OrangeAccent; $btnOk.ForeColor = $ThemeColors.Background
    $btnPanel.Controls.AddRange(@($btnReset, $btnOk)); $dlg.Controls.AddRange(@($mainLayout, $btnPanel)); $res = $dlg.ShowDialog()
    if ($res -eq "OK") { foreach($k in $tempManualFilters.Keys) { $script:manualFilters[$k] = $tempManualFilters[$k] } }

    # --- CORREÇÃO MEMORY LEAK: Liberta os recursos da janela da RAM ---
    $dlg.Dispose()
}


function Show-WeaponFilterDialog {
    param(
        [Parameter(Mandatory=$true)] $Data,
        [Parameter(Mandatory=$true)] $ThemeColors
    )

    $dlg = New-Object System.Windows.Forms.Form; $dlg.Text = "Ocultar Armas - Marque o que deseja OCULTAR"; $dlg.Size = New-Object System.Drawing.Size(1100, 600); $dlg.StartPosition = "CenterParent"; $dlg.FormBorderStyle = "FixedDialog"; $dlg.MaximizeBox = $false
    $dlg.BackColor = $ThemeColors.Background; $dlg.ForeColor = $ThemeColors.TextMain

    # 1. Copia filtros globais existentes (mesmo que esteja vazio por causa do .Clear no menu principal)
    $tempManualFilters = @{}; foreach ($k in $script:manualFilters.Keys) { $tempManualFilters[$k] = [System.Collections.ArrayList]@($script:manualFilters[$k]) }
    
    # 2. Definição das Colunas e Ordens
    $customOrderCategory = @("Carabina", "Escopeta", "Fuzil DMR", "Metralhadora leve", "Pistola", "Rifle de assalto", "Rifle de ferrolho", "Submetralhadora")
    $customOrderCaliber  = @(".338", ".44", ".45", "12x70mm", "5.45x39mm", "5.56x45mm", "5.7x28mm", "5.8x42mm", "7.62x25mm", "7.62x39mm", "7.62x51mm", "7.62x54mm", "9x19mm", "9x39mm")
    $customOrderMode     = @("A.Bombeamento", "A.Ferrolho", "3-RB", "Semi", "Semi, 3-RB", "Auto", "Semi, Auto", "2-RB, Semi, Auto", "3-RB, Semi, Auto")
    $customOrderPower    = @("Baixo", "Médio-Baixo", "Medio-Baixo", "Médio", "Medio", "Médio-Alto", "Medio-Alto", "Alto", "Ultra-alto")
    $customOrderBarrel   = @("CF D-", "Custom", "CF", "CF D+", "Padrão +", "Padrao +", "A+", "D+ A+")
    
    $filterDefs = @( 
        @{Title="Categoria"; Prop="ClasseDisplay"; ColIndex=0; CustomOrder=$customOrderCategory}, 
        @{Title="Calibre"; Prop="Calibre"; ColIndex=1; CustomOrder=$customOrderCaliber}, 
        @{Title="Modo de Disparo"; Prop="ModoDisparoDisplay"; ColIndex=2; CustomOrder=$customOrderMode}, 
        @{Title="Poder de Fogo"; Prop="PoderFogoDisplay"; ColIndex=3; CustomOrder=$customOrderPower}, 
        @{Title="Melhoria de Cano"; Prop="CanoDisplay"; ColIndex=4; CustomOrder=$customOrderBarrel} 
    )
    
    # --- CORREÇÃO DO ERRO (Bloco de Segurança) ---
    # Se o menu principal usou .Clear(), as chaves sumiram. Isso as recria para evitar erro de Nulo.
    foreach ($def in $filterDefs) {
        if (-not $tempManualFilters.ContainsKey($def.Prop)) {
            $tempManualFilters[$def.Prop] = New-Object System.Collections.ArrayList
        }
    }
    # ---------------------------------------------

    $visualState = @{} 
    $mainLayout = New-Object System.Windows.Forms.TableLayoutPanel; $mainLayout.Dock = "Top"; $mainLayout.Height = 480; $mainLayout.ColumnCount = 5; for($i=0; $i -lt 5; $i++){ $mainLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 20))) | Out-Null }
    $allCheckBoxes = @()

    # Função interna para atualizar visual
    $script:UpdateFilterUI = {
        $survivors = New-Object System.Collections.Generic.List[Object]; foreach ($item in $Data) { $isSurvivor = $true; foreach ($k in $tempManualFilters.Keys) { $filterList = $tempManualFilters[$k]; if ($filterList.Count -eq 0) { continue }; if ($filterList -contains $item.($k)) { $isSurvivor = $false; break } }; if ($isSurvivor) { $survivors.Add($item) } }
        $availableValues = @{}; foreach ($k in $script:manualFilters.Keys) { $availableValues[$k] = New-Object System.Collections.Generic.HashSet[string] }
        
        # Garante que as chaves existam em availableValues também
        foreach ($def in $filterDefs) { if (-not $availableValues.ContainsKey($def.Prop)) { $availableValues[$def.Prop] = New-Object System.Collections.Generic.HashSet[string] } }

        foreach ($item in $survivors) { foreach ($k in $availableValues.Keys) { $val = $item.($k); if (-not [string]::IsNullOrEmpty($val)) { $availableValues[$k].Add($val) | Out-Null } } }
        foreach ($cb in $allCheckBoxes) {
            $prop = $cb.Tag.Prop; $val = $cb.Tag.Value; $uKey = $cb.Tag.UniqueKey
            if ($tempManualFilters[$prop].Contains($val)) { $visualState[$uKey] = 'M'; $cb.Checked = $true; $cb.BackColor = [System.Drawing.Color]::Empty; $cb.ForeColor = $ThemeColors.OrangeAccent; $cb.Enabled = $true }
            elseif (-not $availableValues[$prop].Contains($val)) { $visualState[$uKey] = 'A'; $cb.Checked = $true; $cb.BackColor = $ThemeColors.ButtonBack; $cb.ForeColor = $ThemeColors.TextDim }
            else { $visualState[$uKey] = 'F'; $cb.Checked = $false; $cb.BackColor = [System.Drawing.Color]::Empty; $cb.ForeColor = $ThemeColors.TextMain }
        }
    }

    foreach ($def in $filterDefs) {
        $gb = New-Object System.Windows.Forms.GroupBox; $gb.Text = $def.Title; $gb.Dock = "Fill"; $gb.ForeColor = $ThemeColors.TextMain
        $flow = New-Object System.Windows.Forms.FlowLayoutPanel; $flow.Dock = "Fill"; $flow.FlowDirection = "TopDown"; $flow.AutoScroll = $true; $flow.WrapContents = $false
        $rawValues = $Data | Select-Object -ExpandProperty $def.Prop -Unique
        $orderedValues = @(); if ($def.CustomOrder) { foreach ($orderedItem in $def.CustomOrder) { if ($rawValues -contains $orderedItem) { $orderedValues += $orderedItem } }; foreach ($rawItem in $rawValues) { if ($orderedValues -notcontains $rawItem) { $orderedValues += $rawItem } } } else { $orderedValues = $rawValues | Sort-Object }
        foreach ($val in $orderedValues) {
            if ([string]::IsNullOrWhiteSpace($val)) { continue }
            $cb = New-Object System.Windows.Forms.CheckBox; $cb.Text = $val; $cb.AutoSize = $true; $cb.AutoCheck = $false; $cb.Tag = @{ Prop = $def.Prop; Value = $val; UniqueKey = "$($def.Prop)_$val" }
            $cb.ForeColor = $ThemeColors.TextMain
            $cb.Add_Click({ param($sender, $e) $prop = $sender.Tag.Prop; $v = $sender.Tag.Value; $k = $sender.Tag.UniqueKey; $state = $visualState[$k]; if ($state -eq 'A') { return }; if ($tempManualFilters[$prop].Contains($v)) { $tempManualFilters[$prop].Remove($v) } else { $tempManualFilters[$prop].Add($v) | Out-Null }; & $script:UpdateFilterUI })
            $flow.Controls.Add($cb); $allCheckBoxes += $cb
        }
        $gb.Controls.Add($flow); $mainLayout.Controls.Add($gb, $def.ColIndex, 0)
    }

    & $script:UpdateFilterUI # Chamada inicial

    $btnPanel = New-Object System.Windows.Forms.Panel; $btnPanel.Dock = "Bottom"; $btnPanel.Height = 60; $btnPanel.BackColor = $ThemeColors.Background
    $btnReset = New-Object System.Windows.Forms.Button; $btnReset.Text = "Resetar Filtros"; $btnReset.Size = New-Object System.Drawing.Size(150, 40); $btnReset.Location = New-Object System.Drawing.Point(300, 10); $btnReset.FlatStyle = "Flat"
    $btnReset.BackColor = $ThemeColors.ButtonBack; $btnReset.ForeColor = $ThemeColors.TextMain; $btnReset.FlatAppearance.BorderColor = $ThemeColors.OrangeAccent
    $btnReset.Add_Click({ foreach ($k in $tempManualFilters.Keys) { $tempManualFilters[$k].Clear() }; & $script:UpdateFilterUI })

    $btnOk = New-Object System.Windows.Forms.Button; $btnOk.Text = "Confirmar Filtros"; $btnOk.Size = New-Object System.Drawing.Size(200, 40); $btnOk.Location = New-Object System.Drawing.Point(460, 10); $btnOk.DialogResult = "OK"; $btnOk.FlatStyle = "Flat"
    $btnOk.BackColor = $ThemeColors.OrangeAccent; $btnOk.ForeColor = $ThemeColors.Background; $btnOk.FlatAppearance.BorderSize = 0
    
    $btnPanel.Controls.Add($btnReset); $btnPanel.Controls.Add($btnOk); $dlg.Controls.AddRange(@($mainLayout, $btnPanel)); $res = $dlg.ShowDialog()
    
    if ($res -eq "OK") { 
        # Atualiza a variável global garantindo que as chaves existam
        foreach($k in $tempManualFilters.Keys) { 
            if (-not $script:manualFilters.ContainsKey($k)) {
                $script:manualFilters[$k] = [System.Collections.ArrayList]@()
            }
            $script:manualFilters[$k] = $tempManualFilters[$k] 
        } 
    }

    # --- CORREÇÃO MEMORY LEAK: Liberta os recursos da janela da RAM ---
    $dlg.Dispose()
}


function Get-BackpackData {
    $folderPath = Get-DatabasePath
    $csvPath = Join-Path -Path $folderPath -ChildPath "Backpacks.csv"
    
    if (-not (Test-Path $csvPath)) { return @() }
    
    $data = Import-Csv -Path $csvPath -Delimiter ";" -Encoding UTF8
    $results = @()

    foreach ($row in $data) {
        $storage = [int]$row.EspacoTotal
        $sizeUnfolded = $row.TamanhoDesdobrada
        $efficiency = -9999 
        $occupiedArea = 9999 

        if ($sizeUnfolded -ne '/////' -and $sizeUnfolded -match '(\d+)x(\d+)') {
            $occupiedArea = [int]$Matches[1] * [int]$Matches[2]
            $efficiency = $storage - $occupiedArea
        }

        $internalLayout = $row.LayoutInterno
        $setCount = 0
        $maxBlockArea = 0
        $countOfMaxBlock = 0
        $displayLayout = "/////"

        if ($internalLayout -ne '/////' -and -not [string]::IsNullOrWhiteSpace($internalLayout)) {
            $sets = $internalLayout -split ',\s*'
            $parsedLayout = @()

            foreach ($set in $sets) {
                $cnt = 1
                $dims = $set
                
                if ($set -match '^\((\d+)\)$') {
                    $cnt = [int]$Matches[1]
                    $setCount += $cnt
                } elseif ($set -match '^\((\d+)\)(.+)') {
                    $cnt = [int]$Matches[1]
                    $dims = $Matches[2]
                    $setCount += $cnt
                } else {
                    $setCount += 1
                }
                
                $area = 0
                if ($dims -match '(\d+)x(\d+)') {
                    $area = [int]$Matches[1] * [int]$Matches[2]
                    
                    if ($area -gt $maxBlockArea) {
                        $maxBlockArea = $area
                        $countOfMaxBlock = $cnt
                    } elseif ($area -eq $maxBlockArea) {
                        $countOfMaxBlock += $cnt
                    }
                }
                $parsedLayout += [PSCustomObject]@{ Original = $set; Area = $area; Count = $cnt }
            }
            $sortedLayout = $parsedLayout | Sort-Object -Property @{e="Area"; Descending=$true}, @{e="Count"; Descending=$true}
            $displayLayout = ($sortedLayout.Original) -join ', '
        } else {
            $setCount = 999 
        }

        $sortingScore = ($maxBlockArea * 1000) + $countOfMaxBlock

        $obj = [PSCustomObject]@{
            Nome                 = $row.NomeItem
            
            Weight               = if ($row.Peso) { [double]$row.Peso } else { 0 }
            Storage              = $storage
            Efficiency           = $efficiency
            UnfoldedArea         = $occupiedArea
            BlockSortingScore    = $sortingScore
            SetCount             = $setCount

            WeightDisplay        = $row.Peso
            SizeUnfolded         = $row.TamanhoDesdobrada
            SizeFolded           = $row.TamanhoDobrada
            LayoutDisplay        = $displayLayout
            EfficiencyDisplay    = if($efficiency -eq -9999) { "/////" } else { "{0:+#;-#;0}" -f $efficiency }
        }
        $results += $obj
    }
    return $results
}


function Get-HelmetData {
    $folderPath = Get-DatabasePath
    $csvHelmetsPath = Join-Path -Path $folderPath -ChildPath "Helmets.csv"
    $csvMasksPath   = Join-Path -Path $folderPath -ChildPath "Masks.csv"
    $csvCompPath    = Join-Path -Path $folderPath -ChildPath "MaskCompatibility.csv"

    $helmetToMasks = @{} 
    $maskClasses = @{}

    if (Test-Path $csvCompPath) {
        $compContent = Import-Csv -Path $csvCompPath -Delimiter ";" -Encoding UTF8
        foreach ($row in $compContent) {
            $maskName = $row.MaskName
            if (-not [string]::IsNullOrWhiteSpace($row.CompatibleHelmets)) {
                $helmetsList = $row.CompatibleHelmets -split ','
                foreach ($h in $helmetsList) {
                    $hTrim = $h.Trim()
                    if (-not $helmetToMasks.ContainsKey($hTrim)) {
                        $helmetToMasks[$hTrim] = [System.Collections.ArrayList]@()
                    }
                    $helmetToMasks[$hTrim].Add($maskName) | Out-Null
                }
            }
        }
    }

    if (Test-Path $csvMasksPath) {
        $maskContent = Import-Csv -Path $csvMasksPath -Delimiter ";" -Encoding UTF8
        foreach ($m in $maskContent) {
            if ($m.ClasseBlindagem -match '\d') {
                $maskClasses[$m.NomeItem] = [int]$m.ClasseBlindagem
            }
        }
    }

    $materialMap = @{ "Aramid"="Aramida";"Polyethylene"="Polietileno";"Hardened Steel"="Aço endurecido";"Composite"="Composto";"Aluminum"="Alumínio";"Titanium"="Titânio" }
    $bloqueioMap = @{ "Low"="Baixo"; "Moderate"="Moderado"; "Severe"="Grave" }
    $areaMap = @{ "Head"="Cabeça";"Head, Ears"="Cabeça, Ouvidos";"Head, Ears, Face"="Cabeça, Ouvidos, Rosto" }
    $ricocheteMap = @{ "Low"="Baixo";"Medium"="Médio";"High"="Alto" }
    $captadorMap = @{ "Bad"="Fraco";"Medium"="Médio" }
    $reducaoMap = @{ "Bad"="Fraco";"Medium"="Médio";"Strong"="Forte" }
    $acessorioMap = @{ "TE"="TE"; "Mask"="Máscara"; "Mask, TE"="Máscara, TE" }

    $data = @()
    if (Test-Path $csvHelmetsPath) {
        $rawContent = Import-Csv -Path $csvHelmetsPath -Delimiter ";" -Encoding UTF8
        foreach ($row in $rawContent) {
            $helmetName = $row.NomeItem
            $clMaxMascValue = "/////"
            
            if ($helmetToMasks.ContainsKey($helmetName)) {
                $compatibleMaskNames = $helmetToMasks[$helmetName]
                $maxMaskClass = 0
                foreach ($maskName in $compatibleMaskNames) {
                    if ($maskClasses.ContainsKey($maskName)) {
                        $maskClass = $maskClasses[$maskName]
                        if ($maskClass -gt $maxMaskClass) { $maxMaskClass = $maskClass }
                    }
                }
                if ($maxMaskClass -gt 0) { $clMaxMascValue = $maxMaskClass.ToString() }
            }

            if ($clMaxMascValue -eq "/////" -and $row.AreaProtegida -eq "Head, Ears, Face") {
                $clMaxMascValue = "$($row.ClasseBlindagem)*"
            }

            $clMaxMascFilterValue = $clMaxMascValue.Replace("*", "")
            $movSpeedNum = if ($row.PenalidadeMovimento -eq '/////') { 0 } else { [int]($row.PenalidadeMovimento -replace '%', '') }
            $ergoNum = if ($row.Ergonomia -eq '/////') { 0 } else { [int]$row.Ergonomia }

            $data += [PSCustomObject]@{
                Nome = $helmetName
                Weight = ([double]$row.Peso).ToString("F2", [System.Globalization.CultureInfo]::InvariantCulture)
                Durability = ([double]$row.Durabilidade).ToString("F1", [System.Globalization.CultureInfo]::InvariantCulture)
                ArmorClass = [int]$row.ClasseBlindagem
                Material = $row.Material
                SoundBlocking = $row.BloqueioSom
                MovementSpeed = $row.PenalidadeMovimento
                MovementSpeedNum = $movSpeedNum
                Ergonomics = $row.Ergonomia
                ErgonomicsNum = $ergoNum
                ProtectedArea = $row.AreaProtegida
                RicochetChance = $row.Ricochete
                SoundPickup = $row.CaptacaoSom
                NoiseReduction = $row.ReducaoRuido
                Accessory = $row.Acessorio
                
                MaterialDisplay = if ($materialMap.ContainsKey($row.Material)) { $materialMap[$row.Material] } else { $row.Material }
                BloqueioDisplay = if ($bloqueioMap.ContainsKey($row.BloqueioSom)) { $bloqueioMap[$row.BloqueioSom] } else { $row.BloqueioSom }
                AreaDisplay = if ($areaMap.ContainsKey($row.AreaProtegida)) { $areaMap[$row.AreaProtegida] } else { $row.AreaProtegida }
                RicochDisplay = if ($ricocheteMap.ContainsKey($row.Ricochete)) { $ricocheteMap[$row.Ricochete] } else { $row.Ricochete }
                CaptadDisplay = if ($captadorMap.ContainsKey($row.CaptacaoSom)) { $captadorMap[$row.CaptacaoSom] } else { $row.CaptacaoSom }
                ReduRuDisplay = if ($reducaoMap.ContainsKey($row.ReducaoRuido)) { $reducaoMap[$row.ReducaoRuido] } else { $row.ReducaoRuido }
                AcessorioDisplay = if ($acessorioMap.ContainsKey($row.Acessorio)) { $acessorioMap[$row.Acessorio] } else { $row.Acessorio }
                ClMaxMasc = $clMaxMascValue
                ClMaxMascValue = $clMaxMascFilterValue
            }
        }
    } else {
         Write-Warning "Arquivo Helmets.csv não encontrado em: $csvHelmetsPath"
    }
    return $data
}

# ===================================================================================
# 3. MODULOS INTEGRADOS
# ===================================================================================

# --- JANELA DE CHANGELOG (SEPARADA) ---
function Show-ChangelogWindow {
    param($OwnerForm)
    
    $cForm = New-Object System.Windows.Forms.Form
    $cForm.SuspendLayout()
    
    $cForm.Text = "Changelog - Versao.txt"
    $cForm.Size = New-Object System.Drawing.Size(800, 600)
    $cForm.StartPosition = "CenterParent"
    $cForm.BackColor = $theme.Background
    $cForm.ForeColor = $theme.TextMain
    $cForm.FormBorderStyle = "FixedToolWindow"

    # --- CORREÇÃO MEMORY LEAK GDI: Reutiliza fontes ---
    if (-not $script:fontChangeTitle) { $script:fontChangeTitle = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold) }
    if (-not $script:fontChangeBody) { $script:fontChangeBody = New-Object System.Drawing.Font("Consolas", 10) }

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "Historico de Versoes"
    $lblTitle.Font = $script:fontChangeTitle
    $lblTitle.ForeColor = $theme.OrangeAccent
    $lblTitle.AutoSize = $true
    $lblTitle.Location = New-Object System.Drawing.Point(20, 20)
    $cForm.Controls.Add($lblTitle)

    $txtLog = New-Object System.Windows.Forms.RichTextBox
    $txtLog.Location = New-Object System.Drawing.Point(20, 70)
    $txtLog.Size = New-Object System.Drawing.Size(740, 420)
    $txtLog.BackColor = $theme.PanelBack
    $txtLog.ForeColor = $theme.TextMain
    $txtLog.BorderStyle = "None"
    $txtLog.ReadOnly = $true
    $txtLog.Font = $script:fontChangeBody
    $cForm.Controls.Add($txtLog)

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "Fechar"
    $btnClose.Size = New-Object System.Drawing.Size(120, 35)
    $btnClose.Location = New-Object System.Drawing.Point(340, 510)
    $btnClose.FlatStyle = "Flat"
    $btnClose.BackColor = $theme.ButtonBack
    $btnClose.ForeColor = $theme.TextMain
    $btnClose.Add_Click({ $cForm.Close() })
    $cForm.Controls.Add($btnClose)

    # Carrega Conteudo
    if (Test-Path $global:databasePath) {
        $vFile = Join-Path -Path $global:databasePath -ChildPath "Versao.txt"
        if (Test-Path $vFile) { $txtLog.Text = Get-Content -Path $vFile -Raw }
        else { $txtLog.Text = "Arquivo 'Versao.txt' nao encontrado na pasta 'Database ABI'." }
    } else { $txtLog.Text = "Pasta de Database nao encontrada." }

    $cForm.ResumeLayout()
    $cForm.ShowDialog($OwnerForm) | Out-Null
    
    # --- CORREÇÃO MEMORY LEAK: Liberta a janela de Changelog ---
    $cForm.Dispose()
}

# --- MODULO DE ATUALIZACAO ---

function Close-UpdateScreen {
    # Verifica se existe o estado global da tela de atualizacao
    if ($script:UpdateUI) {
        $form = $script:UpdateUI.Form
        $panel = $script:UpdateUI.RootPanel
        $keyEvent = $script:UpdateUI.KeyDownEvent

        # 1. Remove o evento de teclado da janela principal (para parar de escutar o ESC)
        if ($form -and $keyEvent) {
            $form.remove_KeyDown($keyEvent)
        }

        # 2. Destroi o painel visual (Isto está Perfeito! Destrói os controlos filhos)
        if ($panel) {
            $panel.Dispose()
        }

        # 3. Limpa a variavel global para liberar memoria
        $script:UpdateUI = $null
    }
}

function Start-UpdateModule {
    param(
        $CurrentVersion,
        $MainForm 
    )

    # --- CORREÇÃO MEMORY LEAK GDI: Cria fontes uma única vez e reutiliza ---
    if (-not $script:fontUpdTitle) { $script:fontUpdTitle = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold) }
    if (-not $script:fontUpdNorm)  { $script:fontUpdNorm = New-Object System.Drawing.Font("Segoe UI", 11) }
    if (-not $script:fontUpdBold)  { $script:fontUpdBold = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold) }
    if (-not $script:fontUpdWarn)  { $script:fontUpdWarn = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold) }
    if (-not $script:fontUpdBody)  { $script:fontUpdBody = New-Object System.Drawing.Font("Segoe UI", 12) }

    # --- 1. PREPARAÇÃO DO ESTADO GLOBAL ---
    $script:UpdateUI = @{}
    $script:UpdateUI.Form = $MainForm
    
    # [IMPORTANTE] Garante que o Form capture o teclado antes dos botões
    $MainForm.KeyPreview = $true 

    # --- 2. PAINEL MESTRE ---
    $rootPanel = New-Object System.Windows.Forms.Panel
    $rootPanel.Dock = "Fill"
    $rootPanel.BackColor = $theme.Background
    $MainForm.Controls.Add($rootPanel)
    $rootPanel.BringToFront()
    
    # Define o foco no painel para garantir que o ESC seja capturado imediatamente
    $rootPanel.Focus()

    # Salva o painel na global para a função de fechar usar depois
    $script:UpdateUI.RootPanel = $rootPanel

    # --- Lógica de Versão (CORREÇÃO DE ESCOPO PARA OS BOTÕES) ---
    $script:GitHubApiScript = "https://api.github.com/repos/fabiopsyduck/Arena-Breakout-Infinite-Offline-Database/releases/latest"
    $script:GitHubLinkScript = "https://github.com/fabiopsyduck/Arena-Breakout-Infinite-Offline-Database/releases"
    $script:GitHubApiDB = "https://api.github.com/repos/fabiopsyduck/-ABIDB-Database/releases/latest"
    $script:GitHubLinkDB = "https://github.com/fabiopsyduck/-ABIDB-Database/releases"

    function Get-GithubVersion {
        param($Url)
        try {
            $req = Invoke-RestMethod -Uri $Url -TimeoutSec 5 -ErrorAction Stop
            return $req.tag_name.TrimStart('v')
        } catch { return "Erro" }
    }

    function Get-LocalDbVersion {
        if (Test-Path $global:databasePath) {
            $vFile = Join-Path -Path $global:databasePath -ChildPath "Versao.txt"
            if (Test-Path $vFile) {
                $content = Get-Content -Path $vFile -TotalCount 1
                if ($content) { return $content.Trim() }
            }
        }
        return "N/A"
    }

    function Compare-Versions {
        param($Local, $Remote, $LabelStatus)
        try {
            $vL = [System.Version]$Local
            $vR = [System.Version]$Remote
        } catch {
            if ($Local -eq $Remote) { 
                $LabelStatus.Text = "Status: OK (Atualizado)"
                $LabelStatus.ForeColor = $theme.Success
            } else {
                $LabelStatus.Text = "Status: VERSÃO DIFERENTE"
                $LabelStatus.ForeColor = $theme.Warning
            }
            return
        }

        if ($vL -gt $vR) {
            $LabelStatus.Text = "Status: VERSÃO DEV / PRÉ-RELEASE"
            $LabelStatus.ForeColor = $theme.Dev
        } elseif ($vL -eq $vR) {
            $LabelStatus.Text = "Status: OK (Atualizado)"
            $LabelStatus.ForeColor = $theme.Success
        } else {
            $LabelStatus.Text = "Status: DESATUALIZADO"
            $LabelStatus.ForeColor = $theme.Fail
        }
    }

    # --- ELEMENTOS VISUAIS ---
    $lblTitle = New-Object System.Windows.Forms.Label; $lblTitle.Text = "Verificação de Atualizações"; $lblTitle.Font = $script:fontUpdTitle; $lblTitle.ForeColor = $theme.OrangeAccent; $lblTitle.AutoSize = $true; $lblTitle.Location = "50, 50"; $rootPanel.Controls.Add($lblTitle)
    
    $btnVoltar = New-Object System.Windows.Forms.Button; $btnVoltar.Text = "Voltar"; $btnVoltar.Size = "100, 30"; $btnVoltar.Location = "950, 30"; $btnVoltar.FlatStyle = "Flat"; $btnVoltar.BackColor = $theme.ButtonBack; $btnVoltar.ForeColor = $theme.TextMain; $btnVoltar.Enabled = $true
    $btnVoltar.Add_Click({ Close-UpdateScreen }) 
    $rootPanel.Controls.Add($btnVoltar)

    # --- EVENTO DE TECLADO (ESC) ---
    $keyDownAction = {
        param($sender, $e)
        if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
            Close-UpdateScreen
        }
    }
    
    $script:UpdateUI.KeyDownEvent = $keyDownAction
    $MainForm.remove_KeyDown($keyDownAction) 
    $MainForm.Add_KeyDown($keyDownAction)

    # --- RESTANTE DA UI ---
    $grpScript = New-Object System.Windows.Forms.GroupBox; $grpScript.Text = "SCRIPT: Arena Breakout Offline Database"; $grpScript.Location = "50, 120"; $grpScript.Size = "520, 200"; $grpScript.ForeColor = [System.Drawing.Color]::Cyan; $grpScript.Font = $script:fontUpdNorm
    $lblScriptLocal = New-Object System.Windows.Forms.Label; $lblScriptLocal.Text = "Versão Local: $CurrentVersion"; $lblScriptLocal.Location = "20, 40"; $lblScriptLocal.AutoSize = $true; $lblScriptLocal.ForeColor = $theme.TextMain; $grpScript.Controls.Add($lblScriptLocal)
    $lblScriptRemote = New-Object System.Windows.Forms.Label; $lblScriptRemote.Text = "Versão GitHub: Verificando..."; $lblScriptRemote.Location = "20, 70"; $lblScriptRemote.AutoSize = $true; $lblScriptRemote.ForeColor = $theme.TextMain; $grpScript.Controls.Add($lblScriptRemote)
    $lblScriptStatus = New-Object System.Windows.Forms.Label; $lblScriptStatus.Text = "Status: Aguardando..."; $lblScriptStatus.Location = "20, 110"; $lblScriptStatus.AutoSize = $true; $lblScriptStatus.Font = $script:fontUpdBold; $grpScript.Controls.Add($lblScriptStatus)
    $btnDlScript = New-Object System.Windows.Forms.Button; $btnDlScript.Text = "Baixar ABIDB (GitHub)"; $btnDlScript.Size = "200, 35"; $btnDlScript.Location = "20, 150"; $btnDlScript.FlatStyle = "Flat"; $btnDlScript.BackColor = $theme.ButtonBack; $btnDlScript.ForeColor = [System.Drawing.Color]::Cyan; $btnDlScript.Cursor = "Hand"; $btnDlScript.Add_Click({ Start-Process $script:GitHubLinkScript }); $grpScript.Controls.Add($btnDlScript)
    $rootPanel.Controls.Add($grpScript)

    $grpDb = New-Object System.Windows.Forms.GroupBox; $grpDb.Text = "DATABASE: Pasta 'Database ABI'"; $grpDb.Location = "600, 120"; $grpDb.Size = "520, 200"; $grpDb.ForeColor = [System.Drawing.Color]::Magenta; $grpDb.Font = $script:fontUpdNorm
    $lblDbLocal = New-Object System.Windows.Forms.Label; $lblDbLocal.Text = "Versão Local: Verificando..."; $lblDbLocal.Location = "20, 40"; $lblDbLocal.AutoSize = $true; $lblDbLocal.ForeColor = $theme.TextMain; $grpDb.Controls.Add($lblDbLocal)
    $lblDbRemote = New-Object System.Windows.Forms.Label; $lblDbRemote.Text = "Versão GitHub: Verificando..."; $lblDbRemote.Location = "20, 70"; $lblDbRemote.AutoSize = $true; $lblDbRemote.ForeColor = $theme.TextMain; $grpDb.Controls.Add($lblDbRemote)
    $lblDbStatus = New-Object System.Windows.Forms.Label; $lblDbStatus.Text = "Status: Aguardando..."; $lblDbStatus.Location = "20, 110"; $lblDbStatus.AutoSize = $true; $lblDbStatus.Font = $script:fontUpdBold; $grpDb.Controls.Add($lblDbStatus)
    $btnDlDb = New-Object System.Windows.Forms.Button; $btnDlDb.Text = "Baixar Database (GitHub)"; $btnDlDb.Size = "200, 35"; $btnDlDb.Location = "20, 150"; $btnDlDb.FlatStyle = "Flat"; $btnDlDb.BackColor = $theme.ButtonBack; $btnDlDb.ForeColor = [System.Drawing.Color]::Magenta; $btnDlDb.Cursor = "Hand"; $btnDlDb.Add_Click({ Start-Process $script:GitHubLinkDB }); $grpDb.Controls.Add($btnDlDb)
    $rootPanel.Controls.Add($grpDb)

    $lblWarnTitle = New-Object System.Windows.Forms.Label; $lblWarnTitle.Text = "IMPORTANTE"; $lblWarnTitle.Font = $script:fontUpdWarn; $lblWarnTitle.ForeColor = $theme.Warning; $lblWarnTitle.AutoSize = $false; $lblWarnTitle.Size = "1100, 40"; $lblWarnTitle.Location = "50, 360"; $lblWarnTitle.TextAlign = "MiddleCenter"; $rootPanel.Controls.Add($lblWarnTitle)
    $lblWarnBody = New-Object System.Windows.Forms.Label; $lblWarnBody.Text = "A ATUALIZAÇÃO NÃO É AUTOMÁTICA!`n`nPara atualizar, você deve:`n1. Baixar os arquivos pelos links acima.`n2. SUBSTITUIR manualmente o arquivo principal ('ABIDB.exe' ou 'ABIDB.ps1').`n3. (OPCIONAL) Substituir a pasta 'Database ABI' apenas se desejar atualizar os itens."; $lblWarnBody.Font = $script:fontUpdBody; $lblWarnBody.ForeColor = $theme.TextMain; $lblWarnBody.AutoSize = $false; $lblWarnBody.Size = "1100, 125"; $lblWarnBody.Location = "50, 400"; $lblWarnBody.TextAlign = "TopCenter"; $rootPanel.Controls.Add($lblWarnBody)

    $btnOpenLog = New-Object System.Windows.Forms.Button
    $btnOpenLog.Text = "Ler Changelog Completo (Versao.txt)"
    $btnOpenLog.Size = New-Object System.Drawing.Size(300, 40)
    $btnOpenLog.Location = New-Object System.Drawing.Point(450, 550)
    $btnOpenLog.FlatStyle = "Flat"
    $btnOpenLog.BackColor = $theme.PanelBack
    $btnOpenLog.ForeColor = $theme.OrangeAccent
    $btnOpenLog.Font = $script:fontUpdNorm
    $btnOpenLog.Cursor = "Hand"
    $btnOpenLog.Add_Click({ Show-ChangelogWindow -OwnerForm $MainForm })
    $rootPanel.Controls.Add($btnOpenLog)

    # --- EXECUÇÃO ---
    [System.Windows.Forms.Application]::DoEvents()
    $MainForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    
    $remoteScript = Get-GithubVersion -Url $script:GitHubApiScript
    $lblScriptRemote.Text = "Versão GitHub: " + $remoteScript
    if ($remoteScript -eq "Erro") { $lblScriptStatus.Text = "Status: ERRO CONEXÃO"; $lblScriptStatus.ForeColor = $theme.Fail }
    else { Compare-Versions -Local $CurrentVersion -Remote $remoteScript -LabelStatus $lblScriptStatus }

    $localDb = Get-LocalDbVersion
    $lblDbLocal.Text = "Versão Local: " + $localDb
    $remoteDb = Get-GithubVersion -Url $script:GitHubApiDB
    $lblDbRemote.Text = "Versão GitHub: " + $remoteDb
    if ($remoteDb -eq "Erro") { $lblDbStatus.Text = "Status: ERRO CONEXÃO"; $lblDbStatus.ForeColor = $theme.Fail }
    elseif ($localDb -eq "N/A") { $lblDbStatus.Text = "Status: NÃO ENCONTRADA"; $lblDbStatus.ForeColor = $theme.OrangeAccent }
    else { Compare-Versions -Local $localDb -Remote $remoteDb -LabelStatus $lblDbStatus }
    
    $MainForm.Cursor = [System.Windows.Forms.Cursors]::Default
}


function Initialize-CompVisuals {
    param ($MainForm)

    # Cria a variavel global para garantir acesso em qualquer lugar
    $script:CompUI = @{}
    $ui = $script:CompUI # Atalho local
    
    $ui.IsLoading = $false
    $ui.Form = $MainForm
    $ui.Form.KeyPreview = $true 

    # --- CORREÇÃO MEMORY LEAK GDI: Cria e faz cache das Fontes apenas UMA vez ---
    if (-not $script:fontCompTitle) { $script:fontCompTitle = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold) }
    if (-not $script:fontCompSub)   { $script:fontCompSub   = New-Object System.Drawing.Font("Segoe UI", 16) }
    if (-not $script:fontCompGridH) { $script:fontCompGridH = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold) }
    if (-not $script:fontCompGridC) { $script:fontCompGridC = New-Object System.Drawing.Font("Segoe UI", 10) }

    # --- 1. PAINEL MESTRE ---
    $rootPanel = New-Object System.Windows.Forms.Panel
    $rootPanel.Dock = "Fill"
    $rootPanel.BackColor = $theme.Background
    $MainForm.Controls.Add($rootPanel)
    $rootPanel.BringToFront()
    
    $ui.RootPanel = $rootPanel

    # --- 2. Paineis de Navegacao ---
    $pnlMenu = New-Object System.Windows.Forms.Panel; $pnlMenu.Dock = "Fill"; $pnlMenu.BackColor = $theme.Background; $pnlMenu.Visible = $true
    $pnlWeaponsMenu = New-Object System.Windows.Forms.Panel; $pnlWeaponsMenu.Dock = "Fill"; $pnlWeaponsMenu.BackColor = $theme.Background; $pnlWeaponsMenu.Visible = $false
    
    $pnlContent = New-Object System.Windows.Forms.TableLayoutPanel; $pnlContent.Dock = "Fill"; $pnlContent.BackColor = $theme.Background; $pnlContent.Visible = $false
    $pnlContent.ColumnCount = 1; $pnlContent.RowCount = 2
    $pnlContent.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 60)))
    $pnlContent.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100)))

    # [IMPORTANTE] Salvando na variavel global
    $ui.PnlMenu = $pnlMenu
    $ui.PnlWeaponsMenu = $pnlWeaponsMenu
    $ui.PnlContent = $pnlContent
    
    $rootPanel.Controls.AddRange(@($pnlMenu, $pnlWeaponsMenu, $pnlContent))

    # --- 3. MENU PRINCIPAL DO MODULO ---
    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "Comparação e Compatibilidade"
    $lblTitle.Font = $script:fontCompTitle # <--- REUTILIZA A FONTE
    $lblTitle.ForeColor = $theme.OrangeAccent
    $lblTitle.AutoSize = $true
    $lblTitle.Location = "50, 50"
    $pnlMenu.Controls.Add($lblTitle)

    $btnCompArmas = New-Object System.Windows.Forms.Button; $btnCompArmas.Text = "Comparar armas"; $btnCompArmas.Size = "320, 42"; $btnCompArmas.Location = "390, 250"
    $btnCompArmas.FlatStyle = "Flat"; $btnCompArmas.BackColor = $theme.ButtonBack; $btnCompArmas.ForeColor = $theme.TextMain; $btnCompArmas.FlatAppearance.BorderColor = $theme.OrangeAccent; $btnCompArmas.FlatAppearance.MouseOverBackColor = "#555555"; $btnCompArmas.FlatAppearance.MouseDownBackColor = "#777777"
    $pnlMenu.Controls.Add($btnCompArmas)
    $ui.BtnCompArmas = $btnCompArmas # [SALVANDO]

    $btnMasks = New-Object System.Windows.Forms.Button; $btnMasks.Text = "Consultar compatibilidade de máscaras e capacetes"; $btnMasks.Size = "320, 42"; $btnMasks.Location = "390, 310"
    $btnMasks.FlatStyle = "Flat"; $btnMasks.BackColor = $theme.ButtonBack; $btnMasks.ForeColor = $theme.TextMain; $btnMasks.FlatAppearance.BorderColor = $theme.OrangeAccent; $btnMasks.FlatAppearance.MouseOverBackColor = "#555555"; $btnMasks.FlatAppearance.MouseDownBackColor = "#777777"
    $pnlMenu.Controls.Add($btnMasks)
    $ui.BtnMasks = $btnMasks # [SALVANDO]

    $btnBackMain = New-Object System.Windows.Forms.Button
    $btnBackMain.Text = "Voltar"; $btnBackMain.Location = "950, 30"; $btnBackMain.Size = "100, 30"
    $btnBackMain.FlatStyle = "Flat"; $btnBackMain.BackColor = $theme.ButtonBack; $btnBackMain.ForeColor = $theme.TextMain; $btnBackMain.FlatAppearance.BorderColor = $theme.TextDim; $btnBackMain.FlatAppearance.MouseOverBackColor = "#555555"; $btnBackMain.FlatAppearance.MouseDownBackColor = "#777777"
    $pnlMenu.Controls.Add($btnBackMain)
    $ui.BtnBackMain = $btnBackMain # [SALVANDO]

    # --- 4. MENU DE ARMAS ---
    $lblSub = New-Object System.Windows.Forms.Label; $lblSub.Text = "Opções de Comparação de Armas"; $lblSub.Font = $script:fontCompSub; $lblSub.ForeColor = $theme.OrangeAccent; $lblSub.AutoSize = $true; $lblSub.Location = "390, 150"
    $pnlWeaponsMenu.Controls.Add($lblSub)

    $btnBasic = New-Object System.Windows.Forms.Button; $btnBasic.Text = "Comparação Básica"; $btnBasic.Size = "320, 42"; $btnBasic.Location = "390, 250"
    $btnBasic.FlatStyle = "Flat"; $btnBasic.BackColor = $theme.ButtonBack; $btnBasic.ForeColor = $theme.TextMain; $btnBasic.FlatAppearance.BorderColor = $theme.OrangeAccent; $btnBasic.FlatAppearance.MouseOverBackColor = "#555555"; $btnBasic.FlatAppearance.MouseDownBackColor = "#777777"
    $pnlWeaponsMenu.Controls.Add($btnBasic)
    $ui.BtnBasic = $btnBasic # [SALVANDO]

    $btnAdv = New-Object System.Windows.Forms.Button; $btnAdv.Text = "Comparação Avançada"; $btnAdv.Size = "320, 42"; $btnAdv.Location = "390, 310"
    $btnAdv.FlatStyle = "Flat"; $btnAdv.BackColor = $theme.ButtonBack; $btnAdv.ForeColor = $theme.TextMain; $btnAdv.FlatAppearance.BorderColor = $theme.OrangeAccent; $btnAdv.Enabled = $false; $btnAdv.FlatAppearance.MouseOverBackColor = "#555555"; $btnAdv.FlatAppearance.MouseDownBackColor = "#777777"
    $pnlWeaponsMenu.Controls.Add($btnAdv)
    $ui.BtnAdv = $btnAdv # [SALVANDO]

    $btnBackSub = New-Object System.Windows.Forms.Button; $btnBackSub.Text = "Voltar"; $btnBackSub.Location = "950, 30"; $btnBackSub.Size = "100, 30"
    $btnBackSub.FlatStyle = "Flat"; $btnBackSub.BackColor = $theme.ButtonBack; $btnBackSub.ForeColor = $theme.TextMain; $btnBackSub.FlatAppearance.BorderColor = $theme.TextDim; $btnBackSub.FlatAppearance.MouseOverBackColor = "#555555"; $btnBackSub.FlatAppearance.MouseDownBackColor = "#777777"
    $pnlWeaponsMenu.Controls.Add($btnBackSub)
    $ui.BtnBackSub = $btnBackSub # [SALVANDO]

    # --- 5. CONTEUDO (GRID) ---
    $pnlHeader = New-Object System.Windows.Forms.Panel; $pnlHeader.Dock = "Fill"; $pnlHeader.BackColor = $theme.PanelBack
    $lblGridTitle = New-Object System.Windows.Forms.Label; $lblGridTitle.Text = "Resultados"; $lblGridTitle.Font = $script:fontCompGridH; $lblGridTitle.ForeColor = $theme.OrangeAccent; $lblGridTitle.AutoSize = $true; $lblGridTitle.Location = "20, 15"
    $ui.LblGridTitle = $lblGridTitle # [SALVANDO]
    
    $btnNewComp = New-Object System.Windows.Forms.Button; $btnNewComp.Text = "Nova Comparação"; $btnNewComp.Location = "830, 10"; $btnNewComp.Size = "120, 35"; $btnNewComp.FlatStyle = "Flat"; $btnNewComp.BackColor = "Orange"; $btnNewComp.ForeColor = "Black"; $btnNewComp.FlatAppearance.MouseOverBackColor = "#FFB84D"; $btnNewComp.FlatAppearance.MouseDownBackColor = "#FFCC80"
    $ui.BtnNewComp = $btnNewComp # [SALVANDO]
    
    $btnBackContent = New-Object System.Windows.Forms.Button; $btnBackContent.Text = "Voltar"; $btnBackContent.Location = "960, 10"; $btnBackContent.Size = "100, 35"
    $btnBackContent.FlatStyle = "Flat"; $btnBackContent.BackColor = "#333"; $btnBackContent.ForeColor = "White"; $btnBackContent.FlatAppearance.MouseOverBackColor = "#555555"; $btnBackContent.FlatAppearance.MouseDownBackColor = "#777777"
    $ui.BtnBackContent = $btnBackContent # [SALVANDO]

    $pnlHeader.Controls.AddRange(@($lblGridTitle, $btnNewComp, $btnBackContent))
    $pnlContent.Controls.Add($pnlHeader, 0, 0)

    $dgv = New-Object System.Windows.Forms.DataGridView; $dgv.Dock = "Fill"; $dgv.AllowUserToAddRows = $false; $dgv.ReadOnly = $true; $dgv.SelectionMode = "FullRowSelect"; $dgv.MultiSelect = $false; $dgv.RowHeadersVisible = $false
    $dgv.AllowUserToResizeColumns = $false; $dgv.AllowUserToResizeRows = $false
    $dgv.BackgroundColor = $theme.Background; $dgv.GridColor = $theme.ButtonBack; $dgv.BorderStyle = "None"; $dgv.ColumnHeadersVisible = $false 
    $dgv.DefaultCellStyle.BackColor = $theme.Background; $dgv.DefaultCellStyle.ForeColor = $theme.TextMain; $dgv.DefaultCellStyle.SelectionBackColor = $theme.Background; $dgv.DefaultCellStyle.SelectionForeColor = $theme.TextMain; $dgv.DefaultCellStyle.WrapMode = [System.Windows.Forms.DataGridViewTriState]::True; 
    $dgv.DefaultCellStyle.Font = $script:fontCompGridC # <--- REUTILIZA A FONTE
    $dgv.AutoSizeRowsMode = [System.Windows.Forms.DataGridViewAutoSizeRowsMode]::AllCells; $dgv.AutoSizeColumnsMode = "Fill"
    
    $pnlContent.Controls.Add($dgv, 0, 1)
    $ui.Dgv = $dgv # [SALVANDO]

    return $ui
}

function Set-View {
    param (
        $ui,
        [string]$ViewName # "Menu", "WeaponsMenu", "Content"
    )

    $ui.PnlMenu.Visible = $false
    $ui.PnlWeaponsMenu.Visible = $false
    $ui.PnlContent.Visible = $false

    switch ($ViewName) {
        "Menu"        { $ui.PnlMenu.Visible = $true }
        "WeaponsMenu" { $ui.PnlWeaponsMenu.Visible = $true }
        "Content"     { $ui.PnlContent.Visible = $true }
    }
}

function Register-CompEvents {
    param ($ui)

    $ui = $script:CompUI # Forca uso da global atualizada

    $ui.Form.KeyPreview = $true
    
    # [IMPORTANTE] Garante que o painel tenha foco para receber o ESC
    if ($ui.RootPanel) { $ui.RootPanel.Focus() }

    $ui.BtnAdv.Enabled = $true
    
    # Navegacao
    $ui.BtnAdv.Add_Click({ Start-AdvancedCompFeature -ui $script:CompUI })
    $ui.BtnMasks.Add_Click({ Start-MaskFeature -ui $script:CompUI })
    $ui.BtnCompArmas.Add_Click({ Set-View -ui $script:CompUI -ViewName "WeaponsMenu" })
    $ui.BtnBasic.Add_Click({ Start-WeaponFeature -ui $script:CompUI })
    
    $ui.BtnNewComp.Add_Click({
        if ($script:CompUI.LblGridTitle.Text -eq "Comparacao Avancada") {
            Start-AdvancedCompFeature -ui $script:CompUI
        } else {
            Start-WeaponFeature -ui $script:CompUI
        }
    })

    # Logica Global de Voltar
    $script:GoBackLogic = {
        $ui = $script:CompUI
        if ($ui.PnlContent.Visible) {
            if ($ui.LblGridTitle.Text -eq "Comparacao Avancada") { $script:AdvFilterState = $null }
            if ($ui.LblGridTitle.Text -like "Compatibilidade*") { Set-View -ui $ui -ViewName "Menu" } 
            else { Set-View -ui $ui -ViewName "WeaponsMenu" }
        }
        elseif ($ui.PnlWeaponsMenu.Visible) { 
            Set-View -ui $ui -ViewName "Menu" 
        }
        elseif ($ui.PnlMenu.Visible) {
            # [CORREÇÃO] Remove o evento de teclado antes de fechar para não duplicar
            if ($script:CompKeyDown) { $ui.Form.remove_KeyDown($script:CompKeyDown) }
            
            # --- LIMPEZA DE MEMÓRIA SEGURA ---
            if ($ui.RootPanel) { 
                $ui.RootPanel.Dispose() 
                $script:CompUI = $null # Liberta a variável global
            } else { 
                $ui.Form.Close() 
            }
        }
    }

    $ui.BtnBackMain.Add_Click($script:GoBackLogic)
    $ui.BtnBackSub.Add_Click($script:GoBackLogic)
    $ui.BtnBackContent.Add_Click($script:GoBackLogic)
    
    $ui.Dgv.Add_SelectionChanged({ $script:CompUI.Dgv.ClearSelection() })
    
    # [CORREÇÃO DEFINITIVA DO ESC]
    # Remove qualquer evento anterior para não acumular
    if ($script:CompKeyDown) { $ui.Form.remove_KeyDown($script:CompKeyDown) }

    # Define o evento usando a sintaxe robusta param($sender, $e)
    $script:CompKeyDown = { 
        param($sender, $e)
        if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) { 
            & $script:GoBackLogic 
        } 
    }
    
    # Adiciona o novo evento
    $ui.Form.Add_KeyDown($script:CompKeyDown)
}

function Show-ComparisonForm {
    param ($MainForm)

    # 1. Cria o painel na janela principal e salva na global
    Initialize-CompVisuals -MainForm $MainForm
    
    # 2. Conecta os eventos usando a global
    Register-CompEvents
}

function Start-MaskFeature {
    param ($ui)

    # 1. Configura Visual
    Set-View -ui $ui -ViewName "Content"
    $ui.BtnNewComp.Visible = $false
    $ui.LblGridTitle.Text = "Compatibilidade: Mascaras x Capacetes"
    
    # 2. Configura Grid (Limpa tudo)
    $ui.Dgv.DataSource = $null; $ui.Dgv.Columns.Clear(); $ui.Dgv.Rows.Clear()
    $ui.Dgv.ColumnCount = 5
    $ui.Dgv.ScrollBars = "Vertical" # Scroll normal para mascaras
    $ui.Dgv.AutoSizeRowsMode = [System.Windows.Forms.DataGridViewAutoSizeRowsMode]::AllCells

    # [CORRECAO: REMOVIDO CODIGO DE TABLELAYOUT QUE CAUSAVA ERRO]

    # 3. Processamento de Dados
    $rawData = Get-MaskCompatibilityData
    
    # Cabecalho Manual
    $hIdx = $ui.Dgv.Rows.Add()
    $rowH = $ui.Dgv.Rows[$hIdx]
    $rowH.Cells[0].Value = "Mascara"; $rowH.Cells[1].Value = "Capacetes Compativeis"
    $rowH.Cells[3].Value = "Mascara"; $rowH.Cells[4].Value = "Capacetes Compativeis"
    $rowH.DefaultCellStyle.BackColor = $theme.ButtonBack
    $rowH.DefaultCellStyle.ForeColor = $theme.OrangeAccent
    $rowH.DefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

    for ($i = 0; $i -lt $rawData.Count; $i += 2) {
        $itemL = $rawData[$i]; $itemR = if ($i + 1 -lt $rawData.Count) { $rawData[$i+1] } else { $null }
        $rowIndex = $ui.Dgv.Rows.Add()
        $row = $ui.Dgv.Rows[$rowIndex]
        $row.Cells[0].Value = $itemL.DisplayMascara; $row.Cells[1].Value = $itemL.CapacetesCompativeis
        $row.Cells[2].Value = "" 
        if ($itemR) { $row.Cells[3].Value = $itemR.DisplayMascara; $row.Cells[4].Value = $itemR.CapacetesCompativeis } 
    }
    
    $ui.Dgv.Columns[0].FillWeight = 25; $ui.Dgv.Columns[1].FillWeight = 25
    $ui.Dgv.Columns[2].FillWeight = 2 
    $ui.Dgv.Columns[3].FillWeight = 25; $ui.Dgv.Columns[4].FillWeight = 25
}

function Start-WeaponFeature {
    param ($ui)

    # 1. Selecao
    $selectedWeapons = Show-WeaponSelectorDialog -theme $theme
    if ($selectedWeapons.Count -lt 2) { return } 

    # 2. Configura Visual
    Set-View -ui $ui -ViewName "Content"
    $ui.BtnNewComp.Visible = $true
    
    # [ALTERACAO 1] Mudanca do Titulo
    $ui.LblGridTitle.Text = "Comparação Básica"
    
    # 3. Configura Grid
    $ui.Dgv.DataSource = $null; $ui.Dgv.Columns.Clear(); $ui.Dgv.Rows.Clear()
    $ui.Dgv.ColumnCount = 11 
    $ui.Dgv.AutoSizeRowsMode = [System.Windows.Forms.DataGridViewAutoSizeRowsMode]::None
    $ui.Dgv.ScrollBars = "Vertical" 

    # Pesos de Coluna
    $ui.Dgv.Columns[0].FillWeight = 16; $ui.Dgv.Columns[1].FillWeight = 5; $ui.Dgv.Columns[2].FillWeight = 13
    $ui.Dgv.Columns[3].FillWeight = 5; $ui.Dgv.Columns[4].FillWeight = 13; $ui.Dgv.Columns[5].FillWeight = 5
    $ui.Dgv.Columns[6].FillWeight = 13; $ui.Dgv.Columns[7].FillWeight = 5; $ui.Dgv.Columns[8].FillWeight = 13
    $ui.Dgv.Columns[9].FillWeight = 5; $ui.Dgv.Columns[10].FillWeight = 13

    # --- SECAO 1: ARMAS ---
    $wHeadIdx = $ui.Dgv.Rows.Add()
    $wRow = $ui.Dgv.Rows[$wHeadIdx]
    $wRow.Cells[0].Value = "ATRIBUTO"
    $wRow.Cells[0].Style.ForeColor = $theme.OrangeAccent
    
    for ($i = 0; $i -lt $selectedWeapons.Count; $i++) {
        $colIndex = 2 + ($i * 2) 
        $wRow.Cells[$colIndex].Value = $selectedWeapons[$i].NomeItem
        $wRow.Cells[$colIndex].Style.ForeColor = $theme.OrangeAccent
        $wRow.Cells[$colIndex].Style.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    }
    $wRow.DefaultCellStyle.BackColor = $theme.PanelBack 
    $wRow.Height = 40

    $attributes = @(
        @{ Label="Classe"; Prop="Classe"; IsNum=$false; TransMap=$global:WeaponClassToPortugueseMap },
        @{ Label="Calibre"; Prop="Calibre"; IsNum=$false },
        @{ Label="Recuo Vertical"; Prop="RecuoVertical"; IsNum=$true },
        @{ Label="Recuo Horizontal"; Prop="RecuoHorizontal"; IsNum=$true },
        @{ Label="Ergonomia"; Prop="Ergonomia"; IsNum=$true },
        @{ Label="Estabilidade"; Prop="EstabilidadeArma"; IsNum=$true },
        @{ Label="Precisão"; Prop="Precisao"; IsNum=$true },
        @{ Label="Hip-Fire"; Prop="EstabilidadeHipFire"; IsNum=$true },
        @{ Label="Alcance"; Prop="Alcance"; IsNum=$true },
        @{ Label="Velocidade"; Prop="VelocidadeBocal"; IsNum=$true },
        @{ Label="Disparo"; Prop="ModoDisparo"; IsNum=$false; TransMap=$global:FireModeTrans },
        @{ Label="Cadência"; Prop="Cadencia"; IsNum=$true },
        @{ Label="Poder Fogo"; Prop="PoderFogo"; IsNum=$true; Map=$global:PoderFogoMap; TransMap=$global:FirePowerTrans },
        @{ Label="Melhoria Cano"; Prop="TipoCano"; IsNum=$true; Map=$global:CanoMap; TransMap=$global:BarrelTrans }
    )

    foreach ($attr in $attributes) {
        $idx = $ui.Dgv.Rows.Add(); $r = $ui.Dgv.Rows[$idx]
        $r.Cells[0].Value = $attr.Label; $r.Cells[0].Style.ForeColor = $theme.TextDim
        $r.Height = 25
        
        $valuesForCalc = @()
        for ($i = 0; $i -lt $selectedWeapons.Count; $i++) {
            $w = $selectedWeapons[$i]; $valRaw = $w.($attr.Prop); $valNum = 0
            if ($attr.IsNum) { if ($attr.Map) { if ($attr.Map.ContainsKey($valRaw)) { $valNum = $attr.Map[$valRaw] } } else { $valNum = [int]$valRaw }; $valuesForCalc += $valNum }
        }
        $stats = if ($valuesForCalc.Count -gt 0) { $valuesForCalc | Measure-Object -Minimum -Maximum } else { $null }

        for ($i = 0; $i -lt $selectedWeapons.Count; $i++) {
            $colIndex = 2 + ($i * 2)
            $w = $selectedWeapons[$i]; $valRaw = $w.($attr.Prop)
            $valDisplay = $valRaw
            if ($attr.TransMap -and $attr.TransMap.ContainsKey($valRaw)) { $valDisplay = $attr.TransMap[$valRaw] }
            
            $r.Cells[$colIndex].Value = $valDisplay
            if ($attr.IsNum -and $stats -and $stats.Minimum -ne $stats.Maximum) {
                $valNum = 0
                if ($attr.Map) { if ($attr.Map.ContainsKey($valRaw)) { $valNum = $attr.Map[$valRaw] } } else { $valNum = [int]$valRaw }
                if ($valNum -eq $stats.Maximum) { $r.Cells[$colIndex].Style.ForeColor = [System.Drawing.Color]::LightGreen }
                elseif ($valNum -eq $stats.Minimum) { $r.Cells[$colIndex].Style.ForeColor = [System.Drawing.Color]::IndianRed }
            }
        }
    }
    $ui.Dgv.Rows.Add() | Out-Null

    # --- SECAO 2: MUNICAO ---
    $dbPath = Get-DatabasePath; $ammoCsv = Join-Path -Path $dbPath -ChildPath "Ammo.csv"
    $allAmmo = @(); if (Test-Path $ammoCsv) { $allAmmo = Import-Csv -Path $ammoCsv -Delimiter ";" -Encoding UTF8 }
    $uniqueCalibers = $selectedWeapons.Calibre | Select-Object -Unique | Sort-Object
    # Adicionado "Médio" à lista para garantir a cor e a ordem correta com ou sem acento
    $chanceWeights = @{ "Very High"=5; "High"=4; "Medium"=3; "Low"=2; "Very Low"=1; "Alto"=4; "Médio"=3; "Medio"=3; "Baixo"=2 }

    $globalStats = @{}; $globalAmmoList = @()
    foreach ($cal in $uniqueCalibers) {
        foreach ($a in $allAmmo) {
            if ($a.Calibre -eq $cal) {
                $lvl = if($a.NivelPenetracao){$a.NivelPenetracao}elseif($a.NiveldePenetracao){$a.NiveldePenetracao}else{0}
                $pen = if($a.ValorPenetracao){$a.ValorPenetracao}elseif($a.Penetracao){$a.Penetracao}else{0}
                $danoStr = if($a.DanoBase){$a.DanoBase}else{"0"}
                $danoBlind = if($a.DanoArmadura){$a.DanoArmadura}elseif($a.DanoBlindagem){$a.DanoBlindagem}else{0}
                $vel = if($a.Velocidade){$a.Velocidade}else{0}
                $prec = if($a.Precisao){$a.Precisao}else{0}
                $crv = if($a.RecuoVertical){$a.RecuoVertical}else{0}
                $crh = if($a.RecuoHorizontal){$a.RecuoHorizontal}else{0}
                $danoInt = 0; if ($danoStr -match '\((?<v>\d+)\)') { $danoInt = [int]$Matches['v'] } else { $cl = $danoStr -replace '[^\d]',''; if($cl){$danoInt=[int]$cl} }
                $chanceRaw = if($a.ChanceFerir){$a.ChanceFerir}else{"//////"}
                $chanceDisplay = $chanceRaw; if ($global:FirePowerTrans.ContainsKey($chanceRaw)) { $chanceDisplay = $global:FirePowerTrans[$chanceRaw] }
                $chanceInt = 0; if ($chanceWeights.ContainsKey($chanceRaw)) { $chanceInt = $chanceWeights[$chanceRaw] } elseif ($chanceWeights.ContainsKey($chanceDisplay)) { $chanceInt = $chanceWeights[$chanceDisplay] }

                $globalAmmoList += [PSCustomObject]@{ Lv=[int]$lvl; Pen=[int]$pen; DanoInt=$danoInt; DanoBlind=[int]$danoBlind; Vel=[int]$vel; Prec=[int]$prec; CRV=[int]$crv; CRH=[int]$crh; ChanceInt=$chanceInt }
            }
        }
    }
    $propsA = @("Lv", "Pen", "DanoInt", "DanoBlind", "Vel", "Prec", "CRV", "CRH", "ChanceInt")
    foreach ($p in $propsA) { if ($globalAmmoList.Count -gt 0) { $globalStats[$p] = $globalAmmoList | Measure-Object -Property $p -Minimum -Maximum } }

    function Set-ColorGlobal($cell, $val, $statKey) {
        if ($globalStats.ContainsKey($statKey)) {
            $s = $globalStats[$statKey]
            if ($s.Minimum -ne $s.Maximum) {
                if ($val -eq $s.Maximum) { $cell.Style.ForeColor = [System.Drawing.Color]::LightGreen }
                elseif ($val -eq $s.Minimum) { $cell.Style.ForeColor = [System.Drawing.Color]::IndianRed }
            }
        }
    }

    foreach ($cal in $uniqueCalibers) {
        $wepsName = ($selectedWeapons | Where-Object { $_.Calibre -eq $cal }).NomeItem -join " / "
        $sepIdx = $ui.Dgv.Rows.Add(); $sepRow = $ui.Dgv.Rows[$sepIdx]
        $sepRow.Cells[0].Value = "MUNIÇÕES: $wepsName ($cal)"
        
        # [ALTERACAO 2] Aumentada a grossura da linha (Height) de 35 para 50
        $sepRow.DefaultCellStyle.BackColor = $theme.ButtonBack; 
        $sepRow.DefaultCellStyle.ForeColor = [System.Drawing.Color]::Cyan; 
        $sepRow.DefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold); 
        $sepRow.Height = 50 

        $headIdx = $ui.Dgv.Rows.Add(); $hRow = $ui.Dgv.Rows[$headIdx]
        $cols = @("Munição", "Lv", "Pen", "Dano", "Blind", "Vel", "Prec", "CRV", "CRH", "", "Chance")
        for($c=0; $c -lt $cols.Count; $c++) { $hRow.Cells[$c].Value = $cols[$c]; $hRow.Cells[$c].Style.ForeColor = $theme.TextDim }
        $hRow.DefaultCellStyle.BackColor = $theme.Background; $hRow.DefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)

        $caliberAmmoList = @()
        foreach ($a in $allAmmo) {
            if ($a.Calibre -eq $cal) {
                $lvl = if($a.NivelPenetracao){$a.NivelPenetracao}elseif($a.NiveldePenetracao){$a.NiveldePenetracao}else{0}
                $pen = if($a.ValorPenetracao){$a.ValorPenetracao}elseif($a.Penetracao){$a.Penetracao}else{0}
                $danoStr = if($a.DanoBase){$a.DanoBase}else{"0"}
                $danoBlind = if($a.DanoArmadura){$a.DanoArmadura}elseif($a.DanoBlindagem){$a.DanoBlindagem}else{0}
                $vel = if($a.Velocidade){$a.Velocidade}else{0}
                $prec = if($a.Precisao){$a.Precisao}else{0}
                $crv = if($a.RecuoVertical){$a.RecuoVertical}else{0}
                $crh = if($a.RecuoHorizontal){$a.RecuoHorizontal}else{0}
                $danoInt = 0; if ($danoStr -match '\((?<v>\d+)\)') { $danoInt = [int]$Matches['v'] } else { $cl = $danoStr -replace '[^\d]',''; if($cl){$danoInt=[int]$cl} }
                $chanceRaw = if($a.ChanceFerir){$a.ChanceFerir}else{"//////"}
                $chanceDisplay = $chanceRaw; if ($global:FirePowerTrans.ContainsKey($chanceRaw)) { $chanceDisplay = $global:FirePowerTrans[$chanceRaw] }
                $chanceInt = 0; if ($chanceWeights.ContainsKey($chanceRaw)) { $chanceInt = $chanceWeights[$chanceRaw] } elseif ($chanceWeights.ContainsKey($chanceDisplay)) { $chanceInt = $chanceWeights[$chanceDisplay] }

                $caliberAmmoList += [PSCustomObject]@{ Nome=$a.NomeItem; Lv=[int]$lvl; Pen=[int]$pen; DanoDisplay=$danoStr; DanoInt=$danoInt; DanoBlind=[int]$danoBlind; Vel=[int]$vel; Prec=[int]$prec; CRV=[int]$crv; CRH=[int]$crh; ChanceDisplay=$chanceDisplay; ChanceInt=$chanceInt }
            }
        }
        $caliberAmmoList = $caliberAmmoList | Sort-Object Lv, Pen -Descending

        foreach ($a in $caliberAmmoList) {
            $rowIdx = $ui.Dgv.Rows.Add(); $r = $ui.Dgv.Rows[$rowIdx]
            $r.Cells[0].Value = $a.Nome; $r.Cells[0].Style.ForeColor = $theme.OrangeAccent
            $r.Cells[1].Value = $a.Lv; Set-ColorGlobal $r.Cells[1] $a.Lv "Lv"
            $r.Cells[2].Value = $a.Pen; Set-ColorGlobal $r.Cells[2] $a.Pen "Pen"
            $r.Cells[3].Value = $a.DanoDisplay; Set-ColorGlobal $r.Cells[3] $a.DanoInt "DanoInt"
            $r.Cells[4].Value = $a.DanoBlind; Set-ColorGlobal $r.Cells[4] $a.DanoBlind "DanoBlind"
            $r.Cells[5].Value = $a.Vel; Set-ColorGlobal $r.Cells[5] $a.Vel "Vel"
            $r.Cells[6].Value = $a.Prec; Set-ColorGlobal $r.Cells[6] $a.Prec "Prec"
            $r.Cells[7].Value = $a.CRV; Set-ColorGlobal $r.Cells[7] $a.CRV "CRV"
            $r.Cells[8].Value = $a.CRH; Set-ColorGlobal $r.Cells[8] $a.CRH "CRH"
            $r.Cells[9].Value = "" 
            $r.Cells[10].Value = $a.ChanceDisplay; Set-ColorGlobal $r.Cells[10] $a.ChanceInt "ChanceInt"
        }
        $ui.Dgv.Rows.Add() | Out-Null
    }
}

function Start-AdvancedCompFeature {
    param ($ui)

    # 1. Filtro com Memoria
    $filters = Show-AdvancedFilterDialog -theme $theme -InitialState $script:AdvFilterState
    if (-not $filters) { return }
    $script:AdvFilterState = $filters

    Set-View -ui $ui -ViewName "Content"
    $ui.BtnNewComp.Visible = $true
    $ui.LblGridTitle.Text = "Comparação Avançada"
    
    $ui.Dgv.DataSource = $null; $ui.Dgv.Columns.Clear(); $ui.Dgv.Rows.Clear()
    
    # [AJUSTE FINO] Reduzido CRH para 8 (Teste de limite)
    $cols = @(
        @{N="Nome da Arma"; W=20}, 
        @{N="Calibre"; W=10}, 
        @{N="CRV"; W=5}, 
        @{N="CRH"; W=8}, # <--- AJUSTADO PARA 8
        @{N="Ergo"; W=5}, 
        @{N="Esta.DA"; W=7}, 
        @{N="Prec"; W=5}, 
        @{N="Esta.SM"; W=7}, 
        @{N="Dis(m)"; W=6}, 
        @{N="Vel.bo"; W=6}, 
        @{N="Modo Disparo"; W=15}, 
        @{N="Cad"; W=5}, 
        @{N="Poder.DFG"; W=10}, 
        @{N="Melh.Cano"; W=10}
    )
    
    $ui.Dgv.ColumnCount = $cols.Count
    for($i=0; $i -lt $cols.Count; $i++) { $ui.Dgv.Columns[$i].FillWeight = $cols[$i].W }
    $ui.Dgv.ScrollBars = "Vertical"; $ui.Dgv.AutoSizeRowsMode = [System.Windows.Forms.DataGridViewAutoSizeRowsMode]::None

    $dbPath = Get-DatabasePath
    $allWeps = Import-Csv (Join-Path $dbPath "Weapons.csv") -Delimiter ";" -Encoding UTF8
    $allAmmo = Import-Csv (Join-Path $dbPath "Ammo.csv") -Delimiter ";" -Encoding UTF8

    $localModeTrans = $global:FireModeTrans.Clone()
    $localModeTrans["Semi, Full"] = "Semi, Auto"
    $localModeTrans["2-RB, Semi, Full"] = "2-RB, Semi, Auto"
    $localModeTrans["3-RB, Semi, Full"] = "3-RB, Semi, Auto"

    # Filtragem
    $validAmmo = $allAmmo | Where-Object { 
        $lvl = $_.NivelPenetracao; if(-not $lvl){$lvl=0}
        $chn = $_.ChanceFerir; if(-not $chn){$chn="//////"}
        $chnDisp = $chn; if ($global:FirePowerTrans.ContainsKey($chn)) { $chnDisp = $global:FirePowerTrans[$chn] }
        ($filters["Nivel"] -notcontains $lvl) -and ($filters["Chance"] -notcontains $chnDisp)
    }
    
    $validCalibers = $validAmmo.Calibre | Select -Unique
    $validCalibers = $validCalibers | Where-Object { $filters["Calibre"] -notcontains $_ }

    $validWeps = $allWeps | Where-Object {
        $cat = if($global:WeaponClassToPortugueseMap[$_.Classe]){$global:WeaponClassToPortugueseMap[$_.Classe]}else{$_.Classe}
        $modRaw = $_.ModoDisparo; $mod = if($localModeTrans[$modRaw]){$localModeTrans[$modRaw]}else{$modRaw}
        $pod = $_.PoderFogo; if($global:FirePowerTrans[$_.PoderFogo]){$pod=$global:FirePowerTrans[$_.PoderFogo]}
        $can = $_.TipoCano; if($global:BarrelTrans[$_.TipoCano]){$can=$global:BarrelTrans[$_.TipoCano]}

        ($validCalibers -contains $_.Calibre) -and ($filters["Categoria"] -notcontains $cat) -and
        ($filters["Modo"] -notcontains $mod) -and ($filters["Poder"] -notcontains $pod) -and ($filters["Cano"] -notcontains $can)
    }

    # Agrupamento (Calibre -> Categoria -> Nome)
    $validWeps = $validWeps | Sort-Object Calibre, @{e={if($global:WeaponClassToPortugueseMap[$_.Classe]){$global:WeaponClassToPortugueseMap[$_.Classe]}else{$_.Classe}}}, NomeItem

    # Estatisticas
    $statsW = @{}
    $validWepsList = @()
    $canoWeights = @{ "FB D-"=1; "Custom"=2; "FB"=2; "FB D+"=4; "Default +"=5; "R+"=6; "D+ R+"=7 }
    $poderWeights = @{ "Low"=1; "Mid-Low"=2; "Medium"=3; "Mid-High"=4; "High"=5; "Ultra High"=6 }

    function Get-FireModeWeight ($txt) {
        if ($txt -match "Auto") { return 3 } 
        if ($txt -eq "Semi" -or $txt -eq "Semi, 3-RB") { return 2 }
        return 1 
    }

    foreach ($w in $validWeps) {
        $modDisp = if($localModeTrans[$w.ModoDisparo]){$localModeTrans[$w.ModoDisparo]}else{$w.ModoDisparo}
        $modW = Get-FireModeWeight $modDisp
        $pfNum = 0; if ($poderWeights.ContainsKey($w.PoderFogo)) { $pfNum = $poderWeights[$w.PoderFogo] }
        $cnNum = 0; if ($canoWeights.ContainsKey($w.TipoCano)) { $cnNum = $canoWeights[$w.TipoCano] }
        
        $validWepsList += [PSCustomObject]@{
            W=$w; RecuoVertical=[int]$w.RecuoVertical; RecuoHorizontal=[int]$w.RecuoHorizontal
            Ergonomia=[int]$w.Ergonomia; EstabilidadeArma=[int]$w.EstabilidadeArma
            Precisao=[int]$w.Precisao; EstabilidadeHipFire=[int]$w.EstabilidadeHipFire
            Alcance=[int]$w.Alcance; VelocidadeBocal=[int]$w.VelocidadeBocal
            Cadencia=[int]$w.Cadencia; ModW=$modW; ModDisp=$modDisp
            PoderNum=$pfNum; CanoNum=$cnNum
        }
    }
    
    $propsW = @("RecuoVertical", "RecuoHorizontal", "Ergonomia", "EstabilidadeArma", "Precisao", "EstabilidadeHipFire", "Alcance", "VelocidadeBocal", "Cadencia", "PoderNum", "CanoNum")
    foreach ($p in $propsW) { if ($validWepsList.Count -gt 0) { $statsW[$p] = $validWepsList | Measure-Object -Property $p -Minimum -Maximum } }

    function Get-Color ($val, $statKey) {
        if ($statsW.ContainsKey($statKey)) {
            $s = $statsW[$statKey]
            if ($s.Minimum -ne $s.Maximum) {
                if ($val -eq $s.Maximum) { return [System.Drawing.Color]::LightGreen }
                if ($val -eq $s.Minimum) { return [System.Drawing.Color]::IndianRed }
            }
        }
        return $theme.TextMain
    }

    # Renderizacao Armas
    $hIdx = $ui.Dgv.Rows.Add(); $rowH = $ui.Dgv.Rows[$hIdx]
    for($i=0; $i -lt $cols.Count; $i++) { $rowH.Cells[$i].Value = $cols[$i].N }
    $rowH.DefaultCellStyle.BackColor = $theme.ButtonBack; $rowH.DefaultCellStyle.ForeColor = $theme.OrangeAccent; $rowH.DefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)

    foreach ($item in $validWepsList) {
        $w = $item.W
        $idx = $ui.Dgv.Rows.Add(); $r = $ui.Dgv.Rows[$idx]; $r.Height = 25
        
        $r.Cells[0].Value = $w.NomeItem; $r.Cells[0].Style.ForeColor = $theme.OrangeAccent
        $r.Cells[1].Value = $w.Calibre
        
        $r.Cells[2].Value = $item.RecuoVertical; $r.Cells[2].Style.ForeColor = Get-Color $item.RecuoVertical "RecuoVertical"
        $r.Cells[3].Value = $item.RecuoHorizontal; $r.Cells[3].Style.ForeColor = Get-Color $item.RecuoHorizontal "RecuoHorizontal"
        $r.Cells[4].Value = $item.Ergonomia; $r.Cells[4].Style.ForeColor = Get-Color $item.Ergonomia "Ergonomia"
        $r.Cells[5].Value = $item.EstabilidadeArma; $r.Cells[5].Style.ForeColor = Get-Color $item.EstabilidadeArma "EstabilidadeArma"
        $r.Cells[6].Value = $item.Precisao; $r.Cells[6].Style.ForeColor = Get-Color $item.Precisao "Precisao"
        $r.Cells[7].Value = $item.EstabilidadeHipFire; $r.Cells[7].Style.ForeColor = Get-Color $item.EstabilidadeHipFire "EstabilidadeHipFire"
        $r.Cells[8].Value = $item.Alcance; $r.Cells[8].Style.ForeColor = Get-Color $item.Alcance "Alcance"
        $r.Cells[9].Value = $item.VelocidadeBocal; $r.Cells[9].Style.ForeColor = Get-Color $item.VelocidadeBocal "VelocidadeBocal"
        
        $r.Cells[10].Value = $item.ModDisp
        if ($item.ModW -eq 3) { $r.Cells[10].Style.ForeColor = [System.Drawing.Color]::LightGreen }
        elseif ($item.ModW -eq 1) { $r.Cells[10].Style.ForeColor = [System.Drawing.Color]::IndianRed }
        
        $r.Cells[11].Value = $item.Cadencia; $r.Cells[11].Style.ForeColor = Get-Color $item.Cadencia "Cadencia"
        $r.Cells[12].Value = if($global:FirePowerTrans[$w.PoderFogo]){$global:FirePowerTrans[$w.PoderFogo]}else{$w.PoderFogo}
        $r.Cells[12].Style.ForeColor = Get-Color $item.PoderNum "PoderNum"
        
        $cnDisp = if($global:BarrelTrans[$w.TipoCano]){$global:BarrelTrans[$w.TipoCano]}else{$w.TipoCano}
        $r.Cells[13].Value = $cnDisp; $r.Cells[13].Style.ForeColor = Get-Color $item.CanoNum "CanoNum"
    }

    $ui.Dgv.Rows.Add() | Out-Null

    # Renderizacao Municao
    $sepIdx = $ui.Dgv.Rows.Add(); $sepRow = $ui.Dgv.Rows[$sepIdx]
    $sepRow.Cells[0].Value = "MUNIÇÕES COMPATÍVEIS (AGRUPADAS)"; $sepRow.DefaultCellStyle.BackColor = $theme.ButtonBack; $sepRow.DefaultCellStyle.ForeColor = [System.Drawing.Color]::Cyan
    
    $hIdx = $ui.Dgv.Rows.Add(); $hRow = $ui.Dgv.Rows[$hIdx]
    $hRow.Cells[0].Value = "Nome Munição"; $hRow.Cells[1].Value = "Lv"; $hRow.Cells[2].Value = "Pen"
    $hRow.Cells[3].Value = "Dano"; $hRow.Cells[4].Value = "Blind"; $hRow.Cells[5].Value = "Vel"
    $hRow.Cells[6].Value = "Prec"; $hRow.Cells[7].Value = "CRV"; $hRow.Cells[8].Value = "CRH"
    $hRow.Cells[9].Value = "Chance"; $hRow.Cells[10].Value = "Calibre"
    $hRow.DefaultCellStyle.BackColor = $theme.Background; $hRow.DefaultCellStyle.ForeColor = $theme.TextDim

    $chanceWeights = @{ "Very High"=5; "High"=4; "Medium"=3; "Low"=2; "Very Low"=1; "Alto"=4; "Medio"=3; "Baixo"=2; "//////"=0 }
    
    $validAmmoList = @()
    foreach ($a in $validAmmo) {
        $danoStr = if($a.DanoBase){$a.DanoBase}else{"0"}
        $danoInt = 0; if ($danoStr -match '\((?<v>\d+)\)') { $danoInt = [int]$Matches['v'] } else { $cl = $danoStr -replace '[^\d]',''; if($cl){$danoInt=[int]$cl} }
        $chanceRaw = if($a.ChanceFerir){$a.ChanceFerir}else{"//////"}
        $chanceInt = 0; if ($chanceWeights.ContainsKey($chanceRaw)) { $chanceInt = $chanceWeights[$chanceRaw] }
        
        $validAmmoList += [PSCustomObject]@{
            A=$a; Lv=[int]$a.NivelPenetracao; Pen=[int]$a.Penetracao; DanoInt=$danoInt; DanoDisp=$danoStr
            Blind=[int]$a.DanoBlindagem; Vel=[int]$a.Velocidade; Prec=[int]$a.Precisao
            CRV=[int]$a.RecuoVertical; CRH=[int]$a.RecuoHorizontal; ChanceInt=$chanceInt
        }
    }
    
    $statsA = @{}
    $propsA = @("Lv", "Pen", "DanoInt", "Blind", "Vel", "Prec", "CRV", "CRH", "ChanceInt")
    foreach ($p in $propsA) { if ($validAmmoList.Count -gt 0) { $statsA[$p] = $validAmmoList | Measure-Object -Property $p -Minimum -Maximum } }

    function Get-ColorAmmo ($val, $statKey) {
        if ($statsA.ContainsKey($statKey)) {
            $s = $statsA[$statKey]
            if ($s.Minimum -ne $s.Maximum) {
                if ($val -eq $s.Maximum) { return [System.Drawing.Color]::LightGreen }
                if ($val -eq $s.Minimum) { return [System.Drawing.Color]::IndianRed }
            }
        }
        return $theme.TextMain
    }

    $validAmmoList = $validAmmoList | Sort-Object Lv, Pen -Descending

    foreach ($item in $validAmmoList) {
        $a = $item.A
        $idx = $ui.Dgv.Rows.Add(); $r = $ui.Dgv.Rows[$idx]
        
        $r.Cells[0].Value = $a.NomeItem; $r.Cells[0].Style.ForeColor = $theme.OrangeAccent
        
        $r.Cells[1].Value = $item.Lv; $r.Cells[1].Style.ForeColor = Get-ColorAmmo $item.Lv "Lv"
        $r.Cells[2].Value = $item.Pen; $r.Cells[2].Style.ForeColor = Get-ColorAmmo $item.Pen "Pen"
        $r.Cells[3].Value = $item.DanoDisp; $r.Cells[3].Style.ForeColor = Get-ColorAmmo $item.DanoInt "DanoInt"
        $r.Cells[4].Value = $item.Blind; $r.Cells[4].Style.ForeColor = Get-ColorAmmo $item.Blind "Blind"
        $r.Cells[5].Value = $item.Vel; $r.Cells[5].Style.ForeColor = Get-ColorAmmo $item.Vel "Vel"
        $r.Cells[6].Value = $item.Prec; $r.Cells[6].Style.ForeColor = Get-ColorAmmo $item.Prec "Prec"
        $r.Cells[7].Value = $item.CRV; $r.Cells[7].Style.ForeColor = Get-ColorAmmo $item.CRV "CRV"
        $r.Cells[8].Value = $item.CRH; $r.Cells[8].Style.ForeColor = Get-ColorAmmo $item.CRH "CRH"
        
        $chanceRaw = if($a.ChanceFerir){$a.ChanceFerir}else{"//////"}
        $chanceDisplay = $chanceRaw; if ($global:FirePowerTrans.ContainsKey($chanceRaw)) { $chanceDisplay = $global:FirePowerTrans[$chanceRaw] }
        $r.Cells[9].Value = $chanceDisplay; $r.Cells[9].Style.ForeColor = Get-ColorAmmo $item.ChanceInt "ChanceInt"
        $r.Cells[10].Value = $a.Calibre
    }
}

function Show-AdvancedFilterDialog {
    param(
        $theme,
        $InitialState
    )

    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = "Filtro Avançado (Laranja = Você Excluiu | Cinza = Auto-Excluído)"
    $dlg.Size = New-Object System.Drawing.Size(1200, 600)
    $dlg.StartPosition = "CenterParent"
    $dlg.FormBorderStyle = "FixedDialog"
    $dlg.MaximizeBox = $false
    $dlg.BackColor = $theme.PanelBack
    $dlg.ForeColor = $theme.TextMain

    # 1. Dados
    $dbPath = Get-DatabasePath
    $wPath = Join-Path $dbPath "Weapons.csv"; $aPath = Join-Path $dbPath "Ammo.csv"
    if (-not (Test-Path $wPath) -or -not (Test-Path $aPath)) { 
        $dlg.Dispose() # Segurança: Limpa se sair prematuramente
        return $null 
    }
    
    $rawWeapons = Import-Csv $wPath -Delimiter ";" -Encoding UTF8
    $rawAmmo = Import-Csv $aPath -Delimiter ";" -Encoding UTF8

    # Pre-processamento
    $dataW = @(); foreach($w in $rawWeapons) {
        $cat = if($global:WeaponClassToPortugueseMap[$w.Classe]){$global:WeaponClassToPortugueseMap[$w.Classe]}else{$w.Classe}
        $mod = $w.ModoDisparo
        if ($mod -eq "Semi, Full") { $mod = "Semi, Auto" }
        elseif ($mod -eq "2-RB, Semi, Full") { $mod = "2-RB, Semi, Auto" }
        elseif ($mod -eq "3-RB, Semi, Full") { $mod = "3-RB, Semi, Auto" }
        elseif ($global:FireModeTrans[$mod]) { $mod = $global:FireModeTrans[$mod] }
        $pod = $w.PoderFogo; if($global:FirePowerTrans[$w.PoderFogo]){$pod=$global:FirePowerTrans[$w.PoderFogo]}
        $can = $w.TipoCano; if($global:BarrelTrans[$w.TipoCano]){$can=$global:BarrelTrans[$w.TipoCano]}
        $dataW += [PSCustomObject]@{ Cat=$cat; Cal=$w.Calibre; Mod=$mod; Pod=$pod; Can=$can }
    }
    
    $dataA = @(); foreach($a in $rawAmmo) {
        $lvl = $a.NivelPenetracao; if(-not $lvl){$lvl="0"}
        $chn = $a.ChanceFerir; if(-not $chn){$chn="//////"}
        $chnDisp = $chn; if ($global:FirePowerTrans.ContainsKey($chn)) { $chnDisp = $global:FirePowerTrans[$chn] }
        $dataA += [PSCustomObject]@{ Cal=$a.Calibre; Lvl=[string]$lvl; Chn=$chnDisp }
    }

    # 2. Estado do Filtro
    $tempFilters = @{}
    $colKeys = @("Categoria", "Calibre", "Modo", "Poder", "Cano", "Nivel", "Chance")
    
    $isStateValid = ($InitialState -and ($InitialState -is [System.Collections.IDictionary]))

    foreach ($k in $colKeys) {
        if ($isStateValid -and $InitialState.ContainsKey($k)) {
            $tempFilters[$k] = [System.Collections.ArrayList]@($InitialState[$k])
        } else {
            $tempFilters[$k] = New-Object System.Collections.ArrayList
        }
    }

    # Listas Base - AQUI FOI FEITA A CORREÇÃO DE ACENTOS PARA BATER CERTO COM OS MAPAS GLOBAIS
    $lists = @{
        "Categoria" = ($dataW.Cat | Select -Unique | Sort)
        "Calibre"   = (($dataW.Cal + $dataA.Cal) | Select -Unique | Sort)
        "Modo"      = @("A.Bombeamento","A.Ferrolho","3-RB","Semi","Semi, 3-RB","Auto","Semi, Auto","2-RB, Semi, Auto","3-RB, Semi, Auto")
        "Poder"     = @("Baixo","Médio-Baixo","Médio","Médio-Alto","Alto","Ultra-alto")
        "Cano"      = @("CF D-","Custom","CF","CF D+","Padrão +","A+","D+ A+") 
        "Nivel"     = ($dataA.Lvl | Select -Unique | Sort)
        "Chance"    = @("//////","Baixo","Médio","Alto")
    }

    # 3. Layout
    $mainLayout = New-Object System.Windows.Forms.TableLayoutPanel
    $mainLayout.Dock = "Top"; $mainLayout.Height = 480
    $mainLayout.ColumnCount = 7
    for($i=0; $i -lt 7; $i++){ $mainLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 14.28))) | Out-Null }
    
    $visualState = @{} 
    $allCheckBoxes = @()

    # 4. Logica de Atualizacao
    $UpdateUI = {
        # 1. Pega o que o usuario permitiu (nao clicou)
        $validLevels  = $lists["Nivel"] | Where-Object { $tempFilters["Nivel"] -notcontains $_ }
        $validChances = $lists["Chance"] | Where-Object { $tempFilters["Chance"] -notcontains $_ }
        $validCats    = $lists["Categoria"] | Where-Object { $tempFilters["Categoria"] -notcontains $_ }
        $validMods    = $lists["Modo"] | Where-Object { $tempFilters["Modo"] -notcontains $_ }
        $validPods    = $lists["Poder"] | Where-Object { $tempFilters["Poder"] -notcontains $_ } 
        $validCans    = $lists["Cano"] | Where-Object { $tempFilters["Cano"] -notcontains $_ }   
        $userValidCalibers = $lists["Calibre"] | Where-Object { $tempFilters["Calibre"] -notcontains $_ }

        # 2. Filtra Municoes apenas pelas propriedades de Municao
        $filteredAmmo = $dataA | Where-Object { ($validLevels -contains $_.Lvl) -and ($validChances -contains $_.Chn) }
        $calsFromAmmo = $filteredAmmo.Cal | Select -Unique

        # 3. Filtra Armas apenas pelas propriedades de Arma
        $filteredWeps = $dataW | Where-Object {
            ($validCats -contains $_.Cat) -and ($validMods -contains $_.Mod) -and
            ($validPods -contains $_.Pod) -and ($validCans -contains $_.Can)
        }
        $calsFromWeps = $filteredWeps.Cal | Select -Unique

        # 4. O Ponto de Encontro (Interseccao Bidirecional)
        $trueSurvivingCalibers = $userValidCalibers | Where-Object { ($calsFromAmmo -contains $_) -and ($calsFromWeps -contains $_) }

        # 5. Corta os sobreviventes finais usando a lista oficial de calibres
        $survivingWeapons = $filteredWeps | Where-Object { $trueSurvivingCalibers -contains $_.Cal }
        $survivingAmmo    = $filteredAmmo | Where-Object { $trueSurvivingCalibers -contains $_.Cal }
        
        # 6. Mapeia o que sobrou para definir o que fica Cinza (Auto-Excluido)
        $liveCats = $survivingWeapons.Cat | Select -Unique
        $liveMods = $survivingWeapons.Mod | Select -Unique
        $livePods = $survivingWeapons.Pod | Select -Unique
        $liveCans = $survivingWeapons.Can | Select -Unique
        
        $liveLvls = $survivingAmmo.Lvl | Select -Unique
        $liveChns = $survivingAmmo.Chn | Select -Unique
        
        $liveCals = $trueSurvivingCalibers

        $liveMap = @{
            "Categoria"=$liveCats; "Calibre"=$liveCals; "Modo"=$liveMods
            "Poder"=$livePods; "Cano"=$liveCans; "Nivel"=$liveLvls; "Chance"=$liveChns
        }

        # 7. Pinta os quadrados na tela
        foreach ($cb in $allCheckBoxes) {
            $prop = $cb.Tag.Prop; $val = $cb.Tag.Value; $uKey = $cb.Tag.UniqueKey
            
            if ($tempFilters[$prop].Contains($val)) {
                $visualState[$uKey] = 'M'
                $cb.Checked = $true
                $cb.ForeColor = $theme.OrangeAccent
                $cb.BackColor = [System.Drawing.Color]::Empty
                $cb.AutoCheck = $false 
            }
            elseif (-not ($liveMap[$prop] -contains $val)) {
                $visualState[$uKey] = 'A'
                $cb.Checked = $true
                $cb.ForeColor = $theme.TextDim 
                $cb.BackColor = $theme.ButtonBack 
            }
            else {
                $visualState[$uKey] = 'F'
                $cb.Checked = $false
                $cb.ForeColor = $theme.TextMain
                $cb.BackColor = [System.Drawing.Color]::Empty
            }
        }
    }

    # 5. Construcao das Colunas
    $colOrder = @("Categoria", "Calibre", "Modo", "Poder", "Cano", "Nivel", "Chance")
    $colTitles = @("Categoria", "Calibre", "Modo Disparo", "Poder Fogo", "Melh. Cano", "Nível Pen", "Chance Ferir")
    
    for ($i = 0; $i -lt 7; $i++) {
        $key = $colOrder[$i]
        $title = $colTitles[$i]
        
        $gb = New-Object System.Windows.Forms.GroupBox; $gb.Text = $title; $gb.Dock = "Fill"; $gb.ForeColor = $theme.OrangeAccent
        $flow = New-Object System.Windows.Forms.FlowLayoutPanel; $flow.Dock = "Fill"; $flow.FlowDirection = "TopDown"; $flow.AutoScroll = $true; $flow.WrapContents = $false
        
        foreach ($val in $lists[$key]) {
            $cb = New-Object System.Windows.Forms.CheckBox
            $cb.Text = "$val"
            $cb.AutoSize = $true
            $cb.ForeColor = $theme.TextMain
            $cb.Tag = @{ Prop=$key; Value="$val"; UniqueKey="${key}_$val" }
            
            $cb.Add_Click({ param($s, $e)
                $p = $s.Tag.Prop; $v = $s.Tag.Value; $k = $s.Tag.UniqueKey
                $st = $visualState[$k]
                
                if ($st -eq 'A') { 
                    $s.Checked = $true 
                    return 
                }
                
                if ($tempFilters[$p].Contains($v)) {
                    $tempFilters[$p].Remove($v)
                } else {
                    $tempFilters[$p].Add($v) | Out-Null
                }
                & $UpdateUI
            })
            
            $flow.Controls.Add($cb)
            $allCheckBoxes += $cb
        }
        $gb.Controls.Add($flow)
        $mainLayout.Controls.Add($gb, $i, 0)
    }

    & $UpdateUI

    $btnPanel = New-Object System.Windows.Forms.Panel; $btnPanel.Dock = "Bottom"; $btnPanel.Height = 60; $btnPanel.BackColor = $theme.Background
    
    $btnReset = New-Object System.Windows.Forms.Button; $btnReset.Text = "Resetar"; $btnReset.Size = "150, 40"; $btnReset.Location = "400, 10"
    $btnReset.FlatStyle = "Flat"; $btnReset.BackColor = $theme.ButtonBack; $btnReset.ForeColor = $theme.TextMain
    $btnReset.Add_Click({ 
        foreach ($k in $tempFilters.Keys) { $tempFilters[$k].Clear() }
        & $UpdateUI 
    })

    $btnOk = New-Object System.Windows.Forms.Button; $btnOk.Text = "CONFIRMAR"; $btnOk.DialogResult = "OK"; $btnOk.Size = "150, 40"; $btnOk.Location = "560, 10"
    $btnOk.FlatStyle = "Flat"; $btnOk.BackColor = $theme.OrangeAccent; $btnOk.ForeColor = $theme.Background
    
    $btnPanel.Controls.AddRange(@($btnReset, $btnOk))
    $dlg.Controls.AddRange(@($mainLayout, $btnPanel))

    $res = $dlg.ShowDialog()

    if ($res -eq "OK") {
        $finalFilters = @{}
        foreach ($k in $tempFilters.Keys) {
            $list = @(); foreach ($i in $tempFilters[$k]) { $list += $i }
            $finalFilters[$k] = $list
        }
        $dlg.Dispose() # --- CORREÇÃO MEMORY LEAK ---
        return $finalFilters
    }
    
    $dlg.Dispose() # --- CORREÇÃO MEMORY LEAK (Caso clique em Cancelar ou Fechar a janela) ---
    return $null
}

function Show-WeaponSelectorDialog {
    param($theme)
    
    $fSel = New-Object System.Windows.Forms.Form
    $fSel.Text = "Selecione as Armas"
    $fSel.Size = New-Object System.Drawing.Size(500, 400)
    $fSel.StartPosition = "CenterParent"
    $fSel.BackColor = $theme.PanelBack
    $fSel.ForeColor = $theme.TextMain
    $fSel.FormBorderStyle = "FixedToolWindow"

    $dbPath = Get-DatabasePath
    $csvPath = Join-Path -Path $dbPath -ChildPath "Weapons.csv"
    if (-not (Test-Path $csvPath)) { 
        [System.Windows.Forms.MessageBox]::Show("Weapons.csv não encontrado.")
        $fSel.Dispose() # --- CORREÇÃO MEMORY LEAK ---
        return @() 
    }
    $allWeapons = Import-Csv -Path $csvPath -Delimiter ";" -Encoding UTF8

    # UI Elements
    $lblClass = New-Object System.Windows.Forms.Label; $lblClass.Text = "Classe:"; $lblClass.Location = "20, 20"; $lblClass.AutoSize = $true; $lblClass.ForeColor = $theme.OrangeAccent
    $cbClass = New-Object System.Windows.Forms.ComboBox; $cbClass.Location = "20, 45"; $cbClass.Width = 200; $cbClass.DropDownStyle = "DropDownList"; $cbClass.BackColor = $theme.ButtonBack; $cbClass.ForeColor = $theme.TextMain; $cbClass.FlatStyle = "Flat"
    
    $lblWep = New-Object System.Windows.Forms.Label; $lblWep.Text = "Arma:"; $lblWep.Location = "240, 20"; $lblWep.AutoSize = $true; $lblWep.ForeColor = $theme.OrangeAccent
    $cbWep = New-Object System.Windows.Forms.ComboBox; $cbWep.Location = "240, 45"; $cbWep.Width = 220; $cbWep.DropDownStyle = "DropDownList"; $cbWep.BackColor = $theme.ButtonBack; $cbWep.ForeColor = $theme.TextMain; $cbWep.FlatStyle = "Flat"

    $btnAdd = New-Object System.Windows.Forms.Button; $btnAdd.Text = "Adicionar à Lista"; $btnAdd.Location = "20, 80"; $btnAdd.Width = 330; $btnAdd.FlatStyle = "Flat"; $btnAdd.BackColor = $theme.ButtonBack; $btnAdd.FlatAppearance.BorderColor = $theme.TextDim
    $btnReset = New-Object System.Windows.Forms.Button; $btnReset.Text = "Limpar"; $btnReset.Location = "360, 80"; $btnReset.Width = 100; $btnReset.FlatStyle = "Flat"; $btnReset.BackColor = "#3a2e2e"; $btnReset.ForeColor = "#ff9999"; $btnReset.FlatAppearance.BorderColor = "#884444"

    $lbSelected = New-Object System.Windows.Forms.ListBox; $lbSelected.Location = "20, 120"; $lbSelected.Size = "440, 150"; $lbSelected.BackColor = $theme.Background; $lbSelected.ForeColor = $theme.TextMain; $lbSelected.BorderStyle = "FixedSingle"
    
    # [ALTERACAO] Texto e logica ajustados para 5 armas
    $btnConfirm = New-Object System.Windows.Forms.Button; $btnConfirm.Text = "COMPARAR (Mín 2, Máx 5)"; $btnConfirm.Location = "20, 300"; $btnConfirm.Size = "200, 40"; $btnConfirm.FlatStyle = "Flat"; $btnConfirm.BackColor = $theme.OrangeAccent; $btnConfirm.ForeColor = $theme.Background; $btnConfirm.Enabled = $false
    
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Cancelar"; $btnCancel.Location = "260, 300"; $btnCancel.Size = "200, 40"; $btnCancel.FlatStyle = "Flat"; $btnCancel.BackColor = $theme.ButtonBack; $btnCancel.ForeColor = $theme.TextMain; $btnCancel.Add_Click({ $fSel.DialogResult = "Cancel"; $fSel.Close() })

    # Logica
    $selectedObjs = New-Object System.Collections.ArrayList

    $cbClass.Items.Add("-- Selecione a Classe --") | Out-Null
    $classes = $allWeapons | Select-Object -ExpandProperty Classe -Unique | Sort-Object
    foreach ($c in $classes) { 
        $display = if ($global:WeaponClassToPortugueseMap[$c]) { $global:WeaponClassToPortugueseMap[$c] } else { $c }
        $cbClass.Items.Add($display) | Out-Null
    }
    $cbClass.SelectedIndex = 0
    $cbWep.Items.Add("-- Selecione a Arma --") | Out-Null; $cbWep.SelectedIndex = 0

    $cbClass.Add_SelectedIndexChanged({
        $cbWep.Items.Clear()
        if ($cbClass.SelectedIndex -gt 0) {
            $selDisplay = $cbClass.SelectedItem
            $originalClass = $classes | Where-Object { ($global:WeaponClassToPortugueseMap[$_] -eq $selDisplay) -or ($_ -eq $selDisplay) } | Select-Object -First 1
            $currentNames = New-Object System.Collections.ArrayList; foreach ($s in $selectedObjs) { $currentNames.Add($s.NomeItem) | Out-Null }
            $weps = $allWeapons | Where-Object { $_.Classe -eq $originalClass -and $currentNames -notcontains $_.NomeItem } | Sort-Object NomeItem
            
            if ($weps.Count -eq 0) { $cbWep.Items.Add("Nenhuma arma disponível") | Out-Null } 
            else {
                $cbWep.Items.Add("-- Selecione a Arma --") | Out-Null
                foreach ($w in $weps) { $cbWep.Items.Add($w.NomeItem) | Out-Null }
            }
        } else { $cbWep.Items.Add("-- Selecione a Arma --") | Out-Null }
        $cbWep.SelectedIndex = 0
    })

    $btnAdd.Add_Click({
        # [ALTERACAO] Limite aumentado para 5
        if ($cbWep.SelectedIndex -gt 0 -and $cbWep.SelectedItem -notlike "Nenhuma arma*" -and $selectedObjs.Count -lt 5) {
            $wName = $cbWep.SelectedItem
            $alreadyExists = $false; foreach ($s in $selectedObjs) { if ($s.NomeItem -eq $wName) { $alreadyExists = $true } }

            if (-not $alreadyExists) {
                $wObj = $allWeapons | Where-Object { $_.NomeItem -eq $wName } | Select-Object -First 1
                $selectedObjs.Add($wObj) | Out-Null
                $lbSelected.Items.Add("$($wObj.NomeItem) ($($wObj.Calibre))") | Out-Null
                
                $cbWep.Items.Remove($wName)
                if ($cbWep.Items.Count -eq 1) { $cbWep.Items[0] = "Nenhuma arma disponível" }
                $cbWep.SelectedIndex = 0
            }
        }
        $btnConfirm.Enabled = ($selectedObjs.Count -ge 2)
    })

    $btnReset.Add_Click({
        $selectedObjs.Clear(); $lbSelected.Items.Clear(); $cbClass.SelectedIndex = 0; 
        $cbWep.Items.Clear(); $cbWep.Items.Add("-- Selecione a Arma --") | Out-Null; $cbWep.SelectedIndex = 0
        $btnConfirm.Enabled = $false
    })

    $btnConfirm.Add_Click({ $fSel.DialogResult = "OK"; $fSel.Close() })
    $fSel.Controls.AddRange(@($lblClass, $cbClass, $lblWep, $cbWep, $btnAdd, $btnReset, $lbSelected, $btnConfirm, $btnCancel))
    $res = $fSel.ShowDialog()

    if ($res -eq "OK") { 
        $fSel.Dispose() # --- CORREÇÃO MEMORY LEAK ---
        return $selectedObjs.ToArray() 
    } else { 
        $fSel.Dispose() # --- CORREÇÃO MEMORY LEAK ---
        return @() 
    }
}

function Initialize-MainFormVisuals {
    param ($MainForm)

    $ui = @{}
    $ui.IsLoading = $false 
    $ui.Form = $MainForm 
    $ui.Form.KeyPreview = $true 
    
    # Tamanho da Janela
    $ui.Form.Size = New-Object System.Drawing.Size(1200, 850) 

    # --- PAINEL MESTRE ---
    $rootPanel = New-Object System.Windows.Forms.Panel
    $rootPanel.Dock = "Fill"
    $rootPanel.BackColor = $theme.Background
    $MainForm.Controls.Add($rootPanel)
    $rootPanel.BringToFront() 
    $ui.RootPanel = $rootPanel

    $mainToolTip = New-Object System.Windows.Forms.ToolTip; $mainToolTip.AutoPopDelay=10000; $mainToolTip.InitialDelay=500; $mainToolTip.ReshowDelay=500; $mainToolTip.ShowAlways=$true 
    $ui.ToolTip = $mainToolTip

    # Painéis Internos
    $pnlMenu = New-Object System.Windows.Forms.Panel; $pnlMenu.Dock = "Fill"; $pnlMenu.BackColor = $theme.Background
    $pnlContent = New-Object System.Windows.Forms.Panel; $pnlContent.Dock = "Fill"; $pnlContent.Visible = $false; $pnlContent.BackColor = $theme.Background
    $rootPanel.Controls.AddRange(@($pnlMenu, $pnlContent))
    $ui.PnlMenu = $pnlMenu; $ui.PnlContent = $pnlContent

    # Botão Voltar do Menu
    $btnVoltarMain = New-Object System.Windows.Forms.Button
    $btnVoltarMain.Text = "Voltar"; $btnVoltarMain.Location = "1030, 30"; $btnVoltarMain.Size = "100, 30"
    $btnVoltarMain.FlatStyle = "Flat"; $btnVoltarMain.BackColor = $theme.ButtonBack; $btnVoltarMain.ForeColor = $theme.TextMain
    $btnVoltarMain.FlatAppearance.BorderColor = $theme.TextDim
    $pnlMenu.Controls.Add($btnVoltarMain)
    $ui.BtnVoltarMain = $btnVoltarMain

    # [AJUSTE] GroupBox movido para X=7
    $gbControls = New-Object System.Windows.Forms.GroupBox; $gbControls.Text = "Filtros e Ordenação"; 
    $gbControls.Location = "7, 10"; $gbControls.Size = "1170, 80"; 
    $gbControls.ForeColor = $theme.TextMain; $gbControls.BackColor = $theme.PanelBack
    $ui.GbControls = $gbControls

    # Conteúdo do GroupBox (Mantido)
    $lblCat = New-Object System.Windows.Forms.Label; $lblCat.Text = "Categoria:"; $lblCat.Location = "10, 25"; $lblCat.AutoSize = $true; $lblCat.ForeColor = $theme.TextDim; $lblCat.Visible = $false
    $cbCat = New-Object System.Windows.Forms.ComboBox; $cbCat.Location = "75, 22"; $cbCat.Width = 180; $cbCat.DropDownStyle = "DropDownList"; $cbCat.BackColor = $theme.ButtonBack; $cbCat.ForeColor = $theme.TextMain; $cbCat.FlatStyle = "Flat"; $cbCat.Visible = $false
    $ui.LblCat = $lblCat; $ui.CbCat = $cbCat
    
    $lblCrit = New-Object System.Windows.Forms.Label; $lblCrit.Text = "Critério:"; $lblCrit.Location = "10, 25"; $lblCrit.AutoSize = $true; $lblCrit.ForeColor = $theme.TextDim
    $cbCriterio = New-Object System.Windows.Forms.ComboBox; $cbCriterio.Location = "65, 22"; $cbCriterio.Width = 200; $cbCriterio.DropDownStyle = "DropDownList"; $cbCriterio.BackColor = $theme.ButtonBack; $cbCriterio.ForeColor = $theme.TextMain; $cbCriterio.FlatStyle = "Flat"
    $lblOrd = New-Object System.Windows.Forms.Label; $lblOrd.Text = "Ordem:"; $lblOrd.Location = "280, 25"; $lblOrd.AutoSize = $true; $lblOrd.ForeColor = $theme.TextDim
    $cbOrdem = New-Object System.Windows.Forms.ComboBox; $cbOrdem.Location = "330, 22"; $cbOrdem.Width = 100; $cbOrdem.DropDownStyle = "DropDownList"; $cbOrdem.BackColor = $theme.ButtonBack; $cbOrdem.ForeColor = $theme.TextMain; $cbOrdem.FlatStyle = "Flat"
    $cbOrdem.Items.AddRange(@("Crescente", "Decrescente")); $cbOrdem.SelectedIndex = 0
    $ui.LblCrit = $lblCrit; $ui.CbCriterio = $cbCriterio; $ui.LblOrd = $lblOrd; $ui.CbOrdem = $cbOrdem

    $btnOcultar = New-Object System.Windows.Forms.Button; $btnOcultar.Text = "Filtros"; $btnOcultar.Location = "10, 50"; $btnOcultar.Size = "140, 25"; $btnOcultar.FlatStyle = "Flat"; $btnOcultar.BackColor = $theme.OrangeAccent; $btnOcultar.ForeColor = $theme.Background; $btnOcultar.FlatAppearance.BorderSize = 0
    $btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = "Salvar resultados"; $btnSave.Location = "160, 50"; $btnSave.Size = "120, 25"; $btnSave.FlatStyle = "Flat"; $btnSave.BackColor = $theme.ButtonBack; $btnSave.ForeColor = $theme.TextMain; $btnSave.FlatAppearance.BorderColor = $theme.OrangeAccent
    
    $btnVoltar = New-Object System.Windows.Forms.Button; $btnVoltar.Text = "Voltar"; $btnVoltar.Location = "1050, 30"; $btnVoltar.Size = "100, 30"; $btnVoltar.FlatStyle = "Flat"; $btnVoltar.BackColor = $theme.ButtonBack; $btnVoltar.ForeColor = $theme.TextMain; $btnVoltar.FlatAppearance.BorderColor = $theme.TextDim
    $lblCount = New-Object System.Windows.Forms.Label; $lblCount.Text = "Exibindo: 0 itens"; $lblCount.Location = "290, 52"; $lblCount.AutoSize = $true; $lblCount.ForeColor = $theme.OrangeAccent; $lblCount.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $ui.BtnOcultar = $btnOcultar; $ui.BtnSave = $btnSave; $ui.BtnVoltar = $btnVoltar; $ui.LblCount = $lblCount

    $lblAmmoCat = New-Object System.Windows.Forms.Label; $lblAmmoCat.Text = "Categoria:"; $lblAmmoCat.AutoSize = $true; $lblAmmoCat.ForeColor = $theme.TextDim; $lblAmmoCat.Visible = $false
    $cbAmmoCat  = New-Object System.Windows.Forms.ComboBox; $cbAmmoCat.Width = 140; $cbAmmoCat.DropDownStyle = "DropDownList"; $cbAmmoCat.BackColor = $theme.ButtonBack; $cbAmmoCat.ForeColor = $theme.TextMain; $cbAmmoCat.FlatStyle = "Flat"; $cbAmmoCat.Visible = $false
    $lblAmmoWep = New-Object System.Windows.Forms.Label; $lblAmmoWep.Text = "Arma:"; $lblAmmoWep.AutoSize = $true; $lblAmmoWep.ForeColor = $theme.TextDim; $lblAmmoWep.Visible = $false
    $btnAmmoWep = New-Object System.Windows.Forms.Button; $btnAmmoWep.Text = "Arma: Todas"; $btnAmmoWep.Width = 140; $btnAmmoWep.Height = 23; $btnAmmoWep.FlatStyle = "Flat"; $btnAmmoWep.BackColor = $theme.ButtonBack; $btnAmmoWep.ForeColor = $theme.TextMain; $btnAmmoWep.Visible = $false
    $btnAmmoWep.TextAlign = "MiddleLeft"
    $cmsAmmoWep = New-Object System.Windows.Forms.ContextMenuStrip; $cmsAmmoWep.RenderMode = "System"
    $btnAmmoReset = New-Object System.Windows.Forms.Button; $btnAmmoReset.Text = "Reset"; $btnAmmoReset.Size = "60, 25"; $btnAmmoReset.FlatStyle = "Flat"; $btnAmmoReset.BackColor = $theme.ButtonBack; $btnAmmoReset.ForeColor = $theme.OrangeAccent; $btnAmmoReset.Visible = $false
    $btnTop5 = New-Object System.Windows.Forms.Button; $btnTop5.Text = "Melhores calibres e munições"; $btnTop5.Size = "280, 25"; $btnTop5.FlatStyle = "Flat"; $btnTop5.BackColor = $theme.ButtonBack; $btnTop5.ForeColor = $theme.TextDim; $btnTop5.Visible = $false
    $ui.LblAmmoCat = $lblAmmoCat; $ui.CbAmmoCat = $cbAmmoCat; $ui.LblAmmoWep = $lblAmmoWep; $ui.BtnAmmoWep = $btnAmmoWep; $ui.CmsAmmoWep = $cmsAmmoWep; $ui.BtnAmmoReset = $btnAmmoReset; $ui.BtnTop5 = $btnTop5

    $gbControls.Controls.AddRange(@($lblCat, $cbCat, $lblCrit, $cbCriterio, $lblOrd, $cbOrdem, $btnOcultar, $btnSave, $lblCount, $btnVoltar, $lblAmmoCat, $cbAmmoCat, $lblAmmoWep, $btnAmmoWep, $btnAmmoReset, $btnTop5))

    # [AJUSTE] Grid movida para X=7 e Altura=710
    $dgv = New-Object System.Windows.Forms.DataGridView
    $dgv.Location = "7, 100"; $dgv.Size = "1170, 710"
    
    # Travas de usuario
    $dgv.AllowUserToAddRows = $false
    $dgv.AllowUserToDeleteRows = $false
    $dgv.AllowUserToResizeColumns = $false
    $dgv.AllowUserToResizeRows = $false    
    
    $dgv.ReadOnly = $true
    $dgv.SelectionMode = [System.Windows.Forms.DataGridViewSelectionMode]::FullRowSelect
    $dgv.MultiSelect = $false
    $dgv.RowHeadersVisible = $false
    $dgv.BackgroundColor = $theme.PanelBack
    $dgv.DefaultCellStyle.BackColor = $theme.PanelBack
    $dgv.DefaultCellStyle.ForeColor = $theme.TextMain
    $dgv.DefaultCellStyle.SelectionBackColor = $theme.PanelBack
    $dgv.DefaultCellStyle.SelectionForeColor = $theme.TextMain
    $dgv.GridColor = $theme.ButtonBack
    
    $dgv.ShowCellToolTips = $true
    $dgv.EnableHeadersVisualStyles = $false
    $dgv.ColumnHeadersDefaultCellStyle.BackColor = $theme.ButtonBack
    $dgv.ColumnHeadersDefaultCellStyle.ForeColor = $theme.TextMain
    $dgv.ColumnHeadersBorderStyle = [System.Windows.Forms.DataGridViewHeaderBorderStyle]::Single
    $dgv.ColumnHeadersHeightSizeMode = [System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode]::DisableResizing 
    
    $dgv.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill

    $ui.Dgv = $dgv
    $pnlContent.Controls.AddRange(@($gbControls, $dgv))
    
    return $ui
}

function Update-MainFormData {
    param ($ui)

    # --- CORREÇÃO MEMORY LEAK: Cria as fontes apenas 1 vez na memória ---
    if (-not $script:fontNormal) { $script:fontNormal = New-Object System.Drawing.Font("Segoe UI", 9) }
    if (-not $script:fontBold) { $script:fontBold = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold) }

    $ui.ActionUpdateGrid = {
        # 1. Recupera o modo atual
        $mode = $script:currentMode
        
        # Aborta se for munição (tem função própria)
        if ($mode -eq "Ammo") { return }

        # ====================================================
        # A. SELEÇÃO DE DADOS (COM PROTEÇÃO CONTRA CACHE VAZIO)
        # ====================================================
        $data = @()
        
        if ($mode -eq "Gastronomy") { 
            $cat = if ($ui.CbCat.SelectedItem) { $ui.CbCat.SelectedItem } elseif ($ui.CbCat.Items.Count -gt 0) { $ui.CbCat.Items[0] } else { $null }
            if ($cat) { $data = Get-GastronomyData -Category $cat }
        } 
        elseif ($mode -eq "Pharmaceutical") { 
            $cat = if ($ui.CbCat.SelectedItem) { $ui.CbCat.SelectedItem } elseif ($ui.CbCat.Items.Count -gt 0) { $ui.CbCat.Items[0] } else { $null }
            if ($cat) { $data = Get-PharmaceuticalData -Category $cat }
        }
        else {
            # Tenta pegar do Cache. Se estiver vazio, força o carregamento manual.
            if ($mode -eq "Weapon") { 
                $data = $script:cachedWeaponData
                if (!$data) { $data = Get-WeaponData; $script:cachedWeaponData = $data }
            }
            elseif ($mode -eq "Helmet") { 
                $data = $script:cachedHelmetData
                if (!$data) { $data = Get-HelmetData; $script:cachedHelmetData = $data }
            }
            elseif ($mode -eq "Armor") { 
                $data = $script:cachedArmorData
                if (!$data) { $data = Get-ArmorData; $script:cachedArmorData = $data }
            }
            elseif ($mode -eq "ArmoredRig") { 
                $data = $script:cachedRigData 
                if (!$data) { $data = Get-ArmoredRigData; $script:cachedRigData = $data }
            }
            elseif ($mode -eq "UnarmoredRig") { 
                $data = $script:cachedUnarmored 
                if (!$data) { $data = Get-UnarmoredRigData; $script:cachedUnarmored = $data }
            }
            elseif ($mode -eq "Backpack") { 
                $data = $script:cachedBackpack 
                if (!$data) { $data = Get-BackpackData; $script:cachedBackpack = $data }
            }
            elseif ($mode -eq "Headset") { 
                $data = $script:cachedHeadset 
                if (!$data) { $data = Get-HeadsetData; $script:cachedHeadset = $data }
            }
            elseif ($mode -eq "GasMask") { 
                $data = $script:cachedGasMask 
                if (!$data) { $data = Get-GasMaskData; $script:cachedGasMask = $data }
            }
            elseif ($mode -eq "Mask") { 
                $data = $script:cachedMask 
                if (!$data) { $data = Get-MaskData; $script:cachedMask = $data }
            }
            elseif ($mode -eq "Throwable") { 
                $data = $script:cachedThrowable 
                if (!$data) { $data = Get-ThrowableData; $script:cachedThrowable = $data }
            }
        }
        
        # ====================================================
        # B. FILTROS MANUAIS
        # ====================================================
        if ($script:manualFilters) {
            foreach ($k in $script:manualFilters.Keys) { 
                $f = $script:manualFilters[$k]
                if ($f.Count -gt 0) { 
                    $data = $data | Where-Object { $f -notcontains $_.($k) } 
                } 
            }
        }

        # ====================================================
        # C. ORDENAÇÃO
        # ====================================================
        $crit = $ui.CbCriterio.SelectedItem
        $ord  = $ui.CbOrdem.SelectedItem
        
        # Fallback para evitar erro de nulo na ordenação
        if (!$crit) { $crit = "Nome" }
        if (!$ord) { $ord = "Crescente" }

        $sorted = @()
        if ($mode -eq "Weapon") { $sorted = Sort-WeaponDataComplex -Data $data -Criterion $crit -Order $ord }
        elseif ($mode -eq "Helmet") { $sorted = Sort-HelmetDataComplex -Data $data -Criterion $crit -Order $ord }
        elseif ($mode -eq "Armor") { $sorted = Sort-ArmorDataComplex -Data $data -Criterion $crit -Order $ord }
        elseif ($mode -eq "ArmoredRig") { $sorted = Sort-ArmoredRigDataComplex -Data $data -Criterion $crit -Order $ord }
        elseif ($mode -eq "UnarmoredRig") { $sorted = Sort-UnarmoredRigDataComplex -Data $data -Criterion $crit -Order $ord }
        elseif ($mode -eq "Backpack") { $sorted = Sort-BackpackDataComplex -Data $data -Criterion $crit -Order $ord }
        elseif ($mode -eq "Headset") { $sorted = Sort-HeadsetDataComplex -Data $data -Criterion $crit -Order $ord }
        elseif ($mode -eq "GasMask") { $sorted = Sort-GasMaskDataComplex -Data $data -Criterion $crit -Order $ord }
        elseif ($mode -eq "Mask") { $sorted = Sort-MaskDataComplex -Data $data -Criterion $crit -Order $ord }
        elseif ($mode -eq "Throwable") { $sorted = Sort-ThrowableDataComplex -Data $data -Criterion $crit -Order $ord }
        elseif ($mode -eq "Gastronomy") { $sorted = Sort-GastronomyDataComplex -Data $data -Criterion $crit -Order $ord }
        else { $sorted = Sort-PharmaceuticalDataComplex -Data $data -Criterion $crit -Order $ord -Category $ui.CbCat.SelectedItem }

        $count = @($sorted).Count
        $ui.LblCount.Text = "Exibindo: $count itens"

        # ====================================================
        # D. CONSTRUÇÃO DA TABELA
        # ====================================================
        $table = New-Object System.Data.DataTable

        if ($mode -eq "Weapon") {
            $table.Columns.Add("Nome"); $table.Columns.Add("Classe"); $table.Columns.Add("Calibre"); $table.Columns.Add("CRV"); $table.Columns.Add("CRH"); $table.Columns.Add("Ergo"); $table.Columns.Add("Esta.DA"); $table.Columns.Add("Prec"); $table.Columns.Add("Esta.SM"); $table.Columns.Add("Dis(m)"); $table.Columns.Add("Vel.bo"); $table.Columns.Add("ModoDisparo"); $table.Columns.Add("Cad"); $table.Columns.Add("Poder.DFG"); $table.Columns.Add("Melh.Cano")
            foreach ($item in $sorted) { 
                $row = $table.NewRow(); $row["Nome"]=$item.Nome; $row["Classe"]=$item.ClasseDisplay; $row["Calibre"]=$item.Calibre; $row["CRV"]=$item.VerticalRecoil; $row["CRH"]=$item.HorizontalRecoil; $row["Ergo"]=$item.Ergonomia; $row["Esta.DA"]=$item.EstabilidadeArma; $row["Prec"]=$item.Precisao; $row["Esta.SM"]=$item.Estabilidade; $row["Dis(m)"]=$item.Alcance; $row["Vel.bo"]=$item.Velocidade; $row["ModoDisparo"]=$item.ModoDisparoDisplay; $row["Cad"]=$item.Cadencia; $row["Poder.DFG"]=$item.PoderFogoDisplay; $row["Melh.Cano"]=$item.CanoDisplay
                $table.Rows.Add($row) 
            }
        } 
        elseif ($mode -eq "Helmet") {
            $table.Columns.Add("Nome"); $table.Columns.Add("Peso"); $table.Columns.Add("Dur."); $table.Columns.Add("Cl"); $table.Columns.Add("Material"); $table.Columns.Add("Bloqueio"); $table.Columns.Add("Vel.M"); $table.Columns.Add("Ergo"); $table.Columns.Add("Área Protegida"); $table.Columns.Add("Ricoch"); $table.Columns.Add("Captad"); $table.Columns.Add("Red.Ru"); $table.Columns.Add("Acessório"); $table.Columns.Add("Cl Max Masc")
            foreach ($item in $sorted) { 
                $row = $table.NewRow(); $row["Nome"]=$item.Nome; $row["Peso"]=$item.Weight; $row["Dur."]=$item.Durability; $row["Cl"]=$item.ArmorClass; $row["Material"]=$item.MaterialDisplay; $row["Bloqueio"]=$item.BloqueioDisplay; $row["Vel.M"]=$item.MovementSpeed; $row["Ergo"]=$item.Ergonomics; $row["Área Protegida"]=$item.AreaDisplay; $row["Ricoch"]=$item.RicochDisplay; $row["Captad"]=$item.CaptadDisplay; $row["Red.Ru"]=$item.ReduRuDisplay; $row["Acessório"]=$item.AcessorioDisplay; $row["Cl Max Masc"]=$item.ClMaxMasc
                $table.Rows.Add($row) 
            }
        }
        elseif ($mode -eq "Armor") {
            $table.Columns.Add("Nome"); $table.Columns.Add("Peso"); $table.Columns.Add("Cl"); $table.Columns.Add("Dur."); $table.Columns.Add("Material"); $table.Columns.Add("Vel.M"); $table.Columns.Add("Ergo"); $table.Columns.Add("Área Protegida")
            foreach ($item in $sorted) { 
                $row = $table.NewRow(); $row["Nome"]=$item.Nome; $row["Peso"]=$item.WeightDisplay; $row["Cl"]=$item.ArmorClass; $row["Dur."]=$item.DurabilityDisplay; $row["Material"]=$item.MaterialDisplay; $row["Vel.M"]=$item.MovementSpeed; $row["Ergo"]=$item.Ergonomics; $row["Área Protegida"]=$item.AreaDisplay
                $table.Rows.Add($row) 
            }
        }
        elseif ($mode -eq "ArmoredRig") {
            $table.Columns.Add("Nome"); $table.Columns.Add("Peso"); $table.Columns.Add("Cl"); $table.Columns.Add("Dur."); $table.Columns.Add("Material"); $table.Columns.Add("Vel.M"); $table.Columns.Add("Ergo"); $table.Columns.Add("Esp"); $table.Columns.Add("Área Protegida"); $table.Columns.Add("Conj d. blocos (HxV)")
            foreach ($item in $sorted) { 
                $row = $table.NewRow(); $row["Nome"]=$item.Nome; $row["Peso"]=$item.WeightDisplay; $row["Cl"]=$item.ArmorClass; $row["Dur."]=$item.DurabilityDisplay; $row["Material"]=$item.MaterialDisplay; $row["Vel.M"]=$item.MovementSpeed; $row["Ergo"]=$item.Ergonomics; $row["Esp"]=$item.Storage; $row["Área Protegida"]=$item.AreaDisplay; $row["Conj d. blocos (HxV)"]=$item.LayoutDisplay
                $table.Rows.Add($row) 
            }
        }
        elseif ($mode -eq "UnarmoredRig") {
            $table.Columns.Add("Nome"); $table.Columns.Add("Peso"); $table.Columns.Add("Espaço"); $table.Columns.Add("Desdobrada"); $table.Columns.Add("Dobrada"); $table.Columns.Add("Conj d. blocos (HxV)"); $table.Columns.Add("+Armaz -Espaço")
            foreach ($item in $sorted) { 
                $row = $table.NewRow(); $row["Nome"]=$item.Nome; $row["Peso"]=$item.WeightDisplay; $row["Espaço"]=$item.Storage; $row["Desdobrada"]=$item.SizeUnfolded; $row["Dobrada"]=$item.SizeFolded; $row["Conj d. blocos (HxV)"]=$item.LayoutDisplay; $row["+Armaz -Espaço"]=$item.EfficiencyDisplay
                $table.Rows.Add($row) 
            }
        }
        elseif ($mode -eq "Backpack") {
            $table.Columns.Add("Nome"); $table.Columns.Add("Peso"); $table.Columns.Add("Espaço"); $table.Columns.Add("Desdobrada"); $table.Columns.Add("Dobrada"); $table.Columns.Add("Conj d. blocos (HxV)"); $table.Columns.Add("+Armaz -Espaço")
            foreach ($item in $sorted) { 
                $row = $table.NewRow(); $row["Nome"]=$item.Nome; $row["Peso"]=$item.WeightDisplay; $row["Espaço"]=$item.Storage; $row["Desdobrada"]=$item.SizeUnfolded; $row["Dobrada"]=$item.SizeFolded; $row["Conj d. blocos (HxV)"]=$item.LayoutDisplay; $row["+Armaz -Espaço"]=$item.EfficiencyDisplay
                $table.Rows.Add($row) 
            }
        }
        elseif ($mode -eq "Headset") {
            $table.Columns.Add("Nome"); $table.Columns.Add("Peso"); $table.Columns.Add("Captador de Som"); $table.Columns.Add("Redução de Ruído")
            foreach ($item in $sorted) { 
                $row = $table.NewRow(); $row["Nome"]=$item.Nome; $row["Peso"]=$item.WeightDisplay; $row["Captador de Som"]=$item.SoundPickup; $row["Redução de Ruído"]=$item.NoiseReduction
                $table.Rows.Add($row) 
            }
        }
        elseif ($mode -eq "GasMask") {
            $table.Columns.Add("Nome"); $table.Columns.Add("Peso"); $table.Columns.Add("Dur."); $table.Columns.Add("Anti-Veneno"); $table.Columns.Add("Anti-Flash")
            foreach ($item in $sorted) { 
                $row = $table.NewRow(); $row["Nome"]=$item.Nome; $row["Peso"]=$item.WeightDisplay; $row["Dur."]=$item.DurabilityDisplay; $row["Anti-Veneno"]=$item.AntiVeneno; $row["Anti-Flash"]=$item.AntiFlash
                $table.Rows.Add($row) 
            }
        }
        elseif ($mode -eq "Mask") {
            $table.Columns.Add("Nome"); $table.Columns.Add("Peso"); $table.Columns.Add("Dur."); $table.Columns.Add("Cl"); $table.Columns.Add("Material"); $table.Columns.Add("Chance de Ricochete")
            foreach ($item in $sorted) { 
                $row = $table.NewRow(); $row["Nome"]=$item.Nome; $row["Peso"]=$item.WeightDisplay; $row["Dur."]=$item.DurabilityDisplay; $row["Cl"]=$item.ArmorClass; $row["Material"]=$item.MaterialDisplay; $row["Chance de Ricochete"]=$item.RicocheteDisplay
                $table.Rows.Add($row) 
            }
        }
        elseif ($mode -eq "Throwable") {
            $table.Columns.Add("Nome"); $table.Columns.Add("Delay de Explosão"); $table.Columns.Add("Alcance"); $table.Columns.Add("Dano Blind"); $table.Columns.Add("Penetração"); $table.Columns.Add("Fragmentos"); $table.Columns.Add("Tipo Frags."); $table.Columns.Add("Tempo Efeito")
            foreach ($item in $sorted) { 
                $row = $table.NewRow(); $row["Nome"]=$item.Nome; $row["Delay de Explosão"]=$item.DelayExplosao; $row["Alcance"]=$item.Alcance; $row["Dano Blind"]=$item.DanoBlind; $row["Penetração"]=$item.Penetracao; $row["Fragmentos"]=$item.Fragmentos; $row["Tipo Frags."]=$item.TipoFrags; $row["Tempo Efeito"]=$item.TempoEfeito
                $table.Rows.Add($row) 
            }
        }
        elseif ($mode -eq "Gastronomy") {
            $table.Columns.Add("Nome"); $table.Columns.Add("Hidratação"); $table.Columns.Add("Energia"); $table.Columns.Add("Rec.Stamina"); $table.Columns.Add("Espaço (HxV)"); $table.Columns.Add("Hidrat.Slot"); $table.Columns.Add("Energ.Slot"); $table.Columns.Add("Delay")
            foreach ($item in $sorted) { 
                $row = $table.NewRow(); $row["Nome"]=$item.Nome; $row["Hidratação"]=$item.Hidratacao; $row["Energia"]=$item.Energia; $row["Rec.Stamina"]=$item.RecStamina; $row["Espaço (HxV)"]=$item.EspacoHV; $row["Hidrat.Slot"]=$item.HidratSlot; $row["Energ.Slot"]=$item.EnergSlot; $row["Delay"]=$item.Delay
                $table.Rows.Add($row) 
            }
        }
        else {
            # Modo Farmacêutico (Dinâmico)
            $config = Get-ViewConfig -Mode $mode -Category $ui.CbCat.SelectedItem
            foreach ($colName in $config.ColumnLayout.Keys) { if (-not $table.Columns.Contains($colName)) { $table.Columns.Add($colName) } }
            
            foreach ($item in $sorted) { 
                $row = $table.NewRow(); $row["Nome"] = $item.Nome
                if ($mode -eq "Pharmaceutical") {
                    if ($table.Columns.Contains("Usos")) { $row["Usos"] = $item.Usos }
                    if ($table.Columns.Contains("Duração")) { $row["Duração"] = $item.Duracao }
                    if ($table.Columns.Contains("Desidratação")) { $row["Desidratação"] = $item.Desidratacao }
                    if ($table.Columns.Contains("Tempo de Atraso")) { $row["Tempo de Atraso"] = $item.TempoAtraso }
                    if ($table.Columns.Contains("Dur. Max")) { $row["Dur. Max"] = $item.DurMax }
                    if ($table.Columns.Contains("Des. Max")) { $row["Des. Max"] = $item.DesMax }
                    if ($table.Columns.Contains("Custo Durabilidade")) { $row["Custo Durabilidade"] = $item.CustoDurabilidade }
                    if ($table.Columns.Contains("Rec. HP")) { $row["Rec. HP"] = $item.RecHP }
                    if ($table.Columns.Contains("Custo Dur.")) { $row["Custo Dur."] = $item.CustoDur }
                    if ($table.Columns.Contains("Espaco (HxV)")) { $row["Espaco (HxV)"] = $item.EspacoHV }
                    if ($table.Columns.Contains("Durabilidade")) { $row["Durabilidade"] = $item.Durabilidade }
                    if ($table.Columns.Contains("Vel. Cura")) { $row["Vel. Cura"] = $item.VelCura }
                    if ($table.Columns.Contains("Delay")) { $row["Delay"] = $item.Delay }
                    if ($table.Columns.Contains("Durab. p/ Slot")) { $row["Durab. p/ Slot"] = $item.DurabSlot }
                    if ($table.Columns.Contains("Efeito Principal")) { $row["Efeito Principal"] = $item.EfeitoPrincipal }
                    if ($table.Columns.Contains("Red. Energia")) { $row["Red. Energia"] = $item.RedEnergia }
                }
                $table.Rows.Add($row)
            }
        }

        # 1. Desliga o AutoSize antes de alterar a fonte de dados para evitar recalculos prematuros
        $ui.Dgv.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::None

        # --- CORREÇÃO MEMORY LEAK: Destrói a tabela antiga antes de colocar a nova ---
        if ($ui.Dgv.DataSource -is [System.Data.DataTable]) {
            $ui.Dgv.DataSource.Dispose()
        }

        # 2. Aplica a fonte de dados
        $ui.Dgv.DataSource = $table
        
        # 3. Define os pesos das colunas (SEM ligar o AutoSize ainda)
        $config = Get-ViewConfig -Mode $mode -Category $ui.CbCat.SelectedItem
        foreach ($col in $ui.Dgv.Columns) { 
            if ($config.ColumnLayout.Contains($col.Name)) { 
                $col.FillWeight = $config.ColumnLayout[$col.Name].W
                $col.MinimumWidth = $config.ColumnLayout[$col.Name].M 
            }
            if ($config.Tooltips.Contains($col.Name)) { $col.ToolTipText = $config.Tooltips[$col.Name] }
        }
        
        # Estilização visual (Fontes/Cores)
        foreach ($col in $ui.Dgv.Columns) { 
            $col.SortMode = "NotSortable"
            $col.DefaultCellStyle.ForeColor = $theme.TextMain
            
            # --- CORREÇÃO MEMORY LEAK: Usa a fonte em cache ---
            $col.DefaultCellStyle.Font = $script:fontNormal 
        }

        # 4. Agora que os pesos e dados estão prontos, liga o AutoSize GLOBALMENTE
        $ui.Dgv.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill

        # Highlight da coluna ordenada
        $targetCol = $crit
        if ($targetCol -eq "Alfabético") { $targetCol = "Nome" }
        
        if ($mode -eq "Weapon") { $targetCol = switch ($crit) { "Controle de Recuo Vertical"{"CRV"}; "Controle de Recuo Horizontal"{"CRH"}; "Ergonomia"{"Ergo"}; "Estabilidade da Arma"{"Esta.DA"}; "Precisão"{"Prec"}; "Estabilidade sem Mirar"{"Esta.SM"}; "Distância Efetiva"{"Dis(m)"}; "Velocidade de Saída"{"Vel.bo"}; "Modo de Disparo"{"ModoDisparo"}; "Cadência"{"Cad"}; "Poder de Fogo"{"Poder.DFG"}; "Melhoria de Cano"{"Melh.Cano"}; Default{"Nome"} } } 
        elseif ($mode -eq "Helmet") { $targetCol = switch ($crit) { "Peso"{"Peso"}; "Durabilidade"{"Dur."}; "Classe de Blindagem"{"Cl"}; "Bloqueio"{"Bloqueio"}; "Penalidade de Movimento"{"Vel.M"}; "Ergonomia"{"Ergo"}; "Área Protegida"{"Área Protegida"}; "Chance de Ricochete"{"Ricoch"}; "Captura de Som"{"Captad"}; "Redução de Ruído"{"Red.Ru"}; "Acessório"{"Acessório"}; "Classe Máxima da Máscara Compatível"{"Cl Max Masc"}; Default{"Nome"} } } 
        elseif ($mode -eq "Armor") { $targetCol = switch ($crit) { "Peso"{"Peso"}; "Classe de Blindagem"{"Cl"}; "Durabilidade"{"Dur."}; "Material"{"Material"}; "Penalidade de Movimento"{"Vel.M"}; "Ergonomia"{"Ergo"}; "Área Protegida"{"Área Protegida"}; Default{"Nome"} } } 
        elseif ($mode -eq "ArmoredRig") { $targetCol = switch ($crit) { "Peso"{"Peso"}; "Classe de Blindagem"{"Cl"}; "Durabilidade"{"Dur."}; "Penalidade de Movimento"{"Vel.M"}; "Ergonomia"{"Ergo"}; "Armazenamento"{"Esp"}; "Área Protegida"{"Área Protegida"}; "Conjunto de Blocos (HxV)"{"Conj d. blocos (HxV)"}; Default{"Nome"} } }
        elseif ($mode -eq "UnarmoredRig" -or $mode -eq "Backpack") { if ($crit -eq "Armazenamento") { $targetCol = "Espaço" }; if ($crit -eq "+Espaço p/ Armaz. -Espaço Consumido") { $targetCol = "+Armaz -Espaço" }; if ($crit -eq "Conjunto de Blocos (HxV)") { $targetCol = "Conj d. blocos (HxV)" } }
        elseif ($mode -eq "Gastronomy") { if ($crit -eq "Hidratação") { $targetCol = "Hidratação" }; if ($crit -eq "Energia") { $targetCol = "Energia" }; if ($crit -eq "Hidratação por Slot") { $targetCol = "Hidrat.Slot" }; if ($crit -eq "Energia por Slot") { $targetCol = "Energ.Slot" } }
        elseif ($mode -eq "Pharmaceutical") { if ($crit -eq "Duração Máxima") { $targetCol = "Dur. Max" }; if ($crit -eq "Recuperação por Uso") { $targetCol = "Rec. HP" }; if ($crit -eq "Espaço (HxV)") { $targetCol = "Espaco (HxV)" }; if ($crit -eq "Velocidade de Cura") { $targetCol = "Vel. Cura" }; if ($crit -eq "Durabilidade por Slot") { $targetCol = "Durab. p/ Slot" }; if ($crit -eq "Red. Energia") { $targetCol = "Red. Energia" }; if ($crit -eq "Duração") { $targetCol = "Duração" }; if ($crit -eq "Desidratação") { $targetCol = "Desidratação" }; if ($crit -eq "Padrão") { if ($ui.CbCat.SelectedItem -eq "Bandagem" -or $ui.CbCat.SelectedItem -eq "Nebulizador") { $targetCol = "Usos" }; if ($ui.CbCat.SelectedItem -eq "Estimulantes") { $targetCol = "Efeito Principal" } } }
        elseif ($mode -eq "Throwable") { $targetCol = switch ($crit) { "Delay de Explosão"{"Delay Explosão"}; "Alcance"{"Alcance"}; "Dano em Blindagem"{"Dano Blind"}; "Penetração"{"Penetração"}; "Fragmentos"{"Fragmentos"}; "Tipo de Frags."{"Tipo Frags."}; "Tempo de Efeito"{"Tempo Efeito"}; Default{"Nome"} } }
        elseif ($mode -eq "Mask") { $targetCol = switch ($crit) { "Peso"{"Peso"}; "Durabilidade"{"Dur."}; "Classe de Blindagem"{"Cl"}; "Chance de Ricochete"{"Chance de Ricochete"}; Default{"Nome"} } }
        elseif ($mode -eq "GasMask") { $targetCol = switch ($crit) { "Peso"{"Peso"}; "Durabilidade"{"Dur."}; "Anti-Veneno"{"Anti-Veneno"}; "Anti-Flash"{"Anti-Flash"}; Default{"Nome"} } }
        elseif ($mode -eq "Headset") { $targetCol = switch ($crit) { "Peso"{"Peso"}; "Captador de Som"{"Captador de Som"}; "Redução de Ruído"{"Redução de Ruído"}; Default{"Nome"} } }
        
        if ($ui.Dgv.Columns[$targetCol]) { 
            $ui.Dgv.Columns[$targetCol].DefaultCellStyle.ForeColor = $theme.OrangeAccent; 
            
            # --- CORREÇÃO MEMORY LEAK: Usa a fonte em cache ---
            $ui.Dgv.Columns[$targetCol].DefaultCellStyle.Font = $script:fontBold 
        }
    }

    # =============================================================================================
    # LÓGICA DA GRID DE MUNIÇÃO
    # =============================================================================================
    $ui.UpdateAmmoGrid = {
        $lvlF = $script:manualFilters["Lv"]; $calF = $script:manualFilters["Calibre"]; $wndF = $script:manualFilters["ChanceFerirDisplay"]
        $isFiltroActive = ($lvlF.Count -gt 0 -or $calF.Count -gt 0 -or $wndF.Count -gt 0)
        $isCatActive = ($script:ammoCategory -ne "Todas" -and $script:ammoCategory -ne $null)
        $isWepActive = ($script:ammoWeapon -ne "Todas" -and $script:ammoWeapon -ne $null)

        if ($isFiltroActive) { $ui.CbAmmoCat.Enabled = $false; $ui.BtnAmmoWep.Enabled = $false; $ui.BtnOcultar.Enabled = $true; $ui.BtnOcultar.BackColor = $theme.OrangeAccent } 
        else {
            if ($isCatActive) { $ui.BtnOcultar.Enabled = $false; $ui.BtnOcultar.BackColor = $theme.ButtonBack; $ui.CbAmmoCat.Enabled = $true; $ui.BtnAmmoWep.Enabled = $true }
            elseif ($isWepActive) { $ui.BtnOcultar.Enabled = $false; $ui.BtnOcultar.BackColor = $theme.ButtonBack; $ui.CbAmmoCat.Enabled = $false; $ui.BtnAmmoWep.Enabled = $true }
            else { $ui.BtnOcultar.Enabled = $true; $ui.BtnOcultar.BackColor = $theme.OrangeAccent; $ui.CbAmmoCat.Enabled = $true; $ui.BtnAmmoWep.Enabled = $true }
        }

        $filtered = $script:cachedAmmoData
        if ($isWepActive) { $w = $script:cachedWeaponData | Where-Object { $_.Nome -eq $script:ammoWeapon } | Select-Object -First 1; if ($w) { $filtered = $filtered | Where-Object { $_.Calibre -eq $w.Calibre } } } 
        elseif ($isCatActive) { $wepsInCat = $script:cachedWeaponData | Where-Object { $_.ClasseDisplay -eq $script:ammoCategory -or $_.Classe -eq $script:ammoCategory }; if ($wepsInCat) { $validCals = $wepsInCat | Select -Expand Calibre -Unique; $filtered = $filtered | Where-Object { $validCals -contains $_.Calibre } } } 
        elseif ($isFiltroActive) { if ($lvlF.Count -gt 0) { $filtered = $filtered | Where-Object { $lvlF -notcontains $_.Lv } }; if ($calF.Count -gt 0) { $filtered = $filtered | Where-Object { $calF -notcontains $_.Calibre } }; if ($wndF.Count -gt 0) { $filtered = $filtered | Where-Object { $wndF -notcontains $_.ChanceFerirDisplay } } }

        $script:isTop5Allowed = $true; $reasons = @()
        if ($isWepActive) { $reasons += "Arma definida (Defina como 'Todas')" }; if ($ui.CbCriterio.SelectedItem -eq "Alfabético") { $reasons += "Critério Alfabético (Escolha um critério de desempenho)" }
        if ($reasons.Count -gt 0) { $script:isTop5Allowed = $false; $ui.BtnTop5.Text = "Melhores calibres e munições (Bloqueado)"; $ui.BtnTop5.Enabled = $true; $ui.BtnTop5.BackColor = $theme.ButtonBack; $ui.BtnTop5.ForeColor = $theme.TextDim; $ui.ToolTip.SetToolTip($ui.BtnTop5, "Indisponível: " + ($reasons -join " E ")) } 
        else { $script:isTop5Allowed = $true; $ui.BtnTop5.Text = "Melhores calibres e munições"; $ui.BtnTop5.Enabled = $true; $ui.BtnTop5.BackColor = $theme.ButtonBack; $ui.BtnTop5.ForeColor = $theme.OrangeAccent; $ui.ToolTip.SetToolTip($ui.BtnTop5, "Visualizar Top 5 melhores calibres baseados no filtro atual.") }

        $isDesc = ($ui.CbOrdem.SelectedItem -eq "Decrescente")
        if ($ui.CbCriterio.SelectedItem -eq "Dano de Blindagem") { $filtered = $filtered | Select-Object *, @{ Name = 'SortScore'; Expression = { ([long]$_.DanoArmaduraNum * 10000000) + ([long]$_.Lv * 100000) + ([long]$_.PenetracaoNum * 1000) + [long]$_.DanoBaseNum } }; $sorted = $filtered | Sort-Object -Property @{ Expression="SortScore"; Descending=$isDesc } } 
        else { $sorted = Sort-AmmoDataComplex -Data $filtered -Criterion $ui.CbCriterio.SelectedItem -Order $ui.CbOrdem.SelectedItem }

        $count = @($sorted).Count; $ui.LblCount.Text = "Exibindo: $count itens"
        $table = New-Object System.Data.DataTable
        $table.Columns.Add("Nome"); $table.Columns.Add("Lv"); $table.Columns.Add("Pen"); $table.Columns.Add("Dano Base"); $table.Columns.Add("Dano blindag"); $table.Columns.Add("Vel(m/s)"); $table.Columns.Add("Prec"); $table.Columns.Add("CRV"); $table.Columns.Add("CRH"); $table.Columns.Add("Chance Ferir"); $table.Columns.Add("Calibre")
        foreach ($item in $sorted) { $row = $table.NewRow(); $row["Nome"]=$item.Nome; $row["Lv"]=$item.Lv; $row["Pen"]=$item.Penetracao; $row["Dano Base"]=$item.DanoBase; $row["Dano blindag"]=$item.DanoArmadura; $row["Vel(m/s)"]=$item.Velocidade; $row["Prec"]=$item.Precisao; $row["CRV"]=$item.RecuoVert; $row["CRH"]=$item.RecuoHoriz; $row["Chance Ferir"]=$item.ChanceFerirDisplay; $row["Calibre"]=$item.Calibre; $table.Rows.Add($row) }
        
        $ui.Dgv.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::None

        # --- CORREÇÃO MEMORY LEAK: Destrói a tabela antiga de munições ---
        if ($ui.Dgv.DataSource -is [System.Data.DataTable]) {
            $ui.Dgv.DataSource.Dispose()
        }

        $ui.Dgv.DataSource = $table
        
        $layout = @{ "Nome"=@{W=20;M=150}; "Lv"=@{W=5;M=30}; "Pen"=@{W=5;M=40}; "Dano Base"=@{W=10;M=80}; "Dano blindag"=@{W=10;M=80}; "Vel(m/s)"=@{W=8;M=60}; "Prec"=@{W=5;M=40}; "CRV"=@{W=5;M=40}; "CRH"=@{W=5;M=40}; "Chance Ferir"=@{W=10;M=80}; "Calibre"=@{W=10;M=80} }
        foreach ($col in $ui.Dgv.Columns) { 
            if ($layout.ContainsKey($col.Name)) { 
                $col.FillWeight = $layout[$col.Name].W; 
                $col.MinimumWidth = $layout[$col.Name].M 
            }
        }
        
        $ui.Dgv.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill

        foreach ($col in $ui.Dgv.Columns) { 
            $col.SortMode = "NotSortable"; 
            $col.DefaultCellStyle.ForeColor = $theme.TextMain; 
            # --- CORREÇÃO MEMORY LEAK: Usa a fonte em cache ---
            $col.DefaultCellStyle.Font = $script:fontNormal 
        }
        
        $targetCol = switch ($ui.CbCriterio.SelectedItem) { "Nível de Penetração"{"Lv"}; "Penetração"{"Pen"}; "Dano Base"{"Dano Base"}; "Dano de Blindagem"{"Dano blindag"}; "Velocidade Inicial"{"Vel(m/s)"}; "Precisão"{"Prec"}; "Controle de Recuo Vertical"{"CRV"}; "Controle de Recuo Horizontal"{"CRH"}; "Chance de Ferir"{"Chance Ferir"}; Default{"Nome"} }
        if ($ui.Dgv.Columns[$targetCol]) { 
            $ui.Dgv.Columns[$targetCol].DefaultCellStyle.ForeColor = $theme.OrangeAccent; 
            # --- CORREÇÃO MEMORY LEAK: Usa a fonte em cache ---
            $ui.Dgv.Columns[$targetCol].DefaultCellStyle.Font = $script:fontBold 
        }
    }
}

function Register-MainFormEvents {
    param ($ui) 

    # --- Lógica de Saída ---
    $script:SearchUI.ExitAction = {
        $script:SearchUI.Form.remove_KeyDown($script:mainFormKeyDown)
        $script:SearchUI.RootPanel.Dispose()
    }

    $script:mainFormKeyDown = { 
        param($sender, $e)
        if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) { 
            if ($script:SearchUI.PnlContent.Visible) { 
                $script:SearchUI.PnlContent.Visible = $false
                $script:SearchUI.PnlMenu.Visible = $true 
            } else {
                & $script:SearchUI.ExitAction
            }
        } 
    }
    $script:SearchUI.Form.add_KeyDown($script:mainFormKeyDown)
    $script:SearchUI.BtnVoltarMain.Add_Click($script:SearchUI.ExitAction)

    # --- AÇÕES DA GRID (ATUALIZADAS PARA X=7, W=1170, H=710) ---
    
    $script:SearchUI.ActionOpenGrid = {
        $ui = $script:SearchUI 
        
        $ui.IsLoading = $true
        $script:manualFilters.Clear(); $ui.CbCriterio.Items.Clear()
        $ui.CbCat.Tag = "Loading"
        $ui.LblAmmoCat.Visible = $false; $ui.CbAmmoCat.Visible = $false; $ui.LblAmmoWep.Visible = $false; $ui.BtnAmmoWep.Visible = $false; $ui.BtnAmmoReset.Visible = $false; $ui.BtnTop5.Visible = $false
        
        # [AJUSTE SINCRONIZADO]
        $ui.GbControls.Size = New-Object System.Drawing.Size(1170, 80)
        $ui.Dgv.Location = New-Object System.Drawing.Point(7, 100)
        $ui.Dgv.Size = New-Object System.Drawing.Size(1170, 710) 
        
        $ui.BtnOcultar.Location = "10, 50"; $ui.BtnSave.Location = "160, 50"; $ui.LblCount.Location = "290, 52"
        
        $ui.CbCat.Items.Clear()
        if ($script:currentMode -eq "Gastronomy") { 
            $ui.CbCat.Items.AddRange(@("Todas as comidas e bebidas", "Bebida", "Comida")); $ui.CbCat.SelectedIndex = 0; $ui.LblCat.Visible = $true; $ui.CbCat.Visible = $true 
            $ui.LblCrit.Location = "270, 25"; $ui.CbCriterio.Location = "320, 22"; $ui.CbCriterio.Width = 150; $ui.LblOrd.Location = "490, 25"; $ui.CbOrdem.Location = "540, 22"
        } elseif ($script:currentMode -eq "Pharmaceutical") { 
            # NÃO ALTERAR: Estas chaves têm de ficar sem acento para não quebrar o Get-PharmaceuticalData e o Get-ViewConfig
            $ui.CbCat.Items.AddRange(@("Analgesico", "Bandagem", "Kit cirurgico", "Nebulizador", "Kit medico", "Estimulantes")); $ui.CbCat.SelectedIndex = 0; $ui.LblCat.Visible = $true; $ui.CbCat.Visible = $true 
            $ui.LblCrit.Location = "270, 25"; $ui.CbCriterio.Location = "320, 22"; $ui.CbCriterio.Width = 150; $ui.LblOrd.Location = "490, 25"; $ui.CbOrdem.Location = "540, 22"
        } else {
            $ui.LblCat.Visible = $false; $ui.CbCat.Visible = $false; $ui.LblCrit.Location = "10, 25"; $ui.CbCriterio.Location = "65, 22"; $ui.CbCriterio.Width = 200; $ui.LblOrd.Location = "280, 25"; $ui.CbOrdem.Location = "330, 22"
        }
        $ui.CbCat.Tag = "Ready" 
        
        $ui.InitializeGrid = {
             $ui = $script:SearchUI
             $ui.Dgv.DataSource = $null; $ui.CbCriterio.Items.Clear()
             $catSelection = $null
             if ($script:currentMode -eq "Pharmaceutical" -or $script:currentMode -eq "Gastronomy") { if ($ui.CbCat.SelectedItem) { $catSelection = $ui.CbCat.SelectedItem } elseif ($ui.CbCat.Items.Count -gt 0) { $catSelection = $ui.CbCat.Items[0] } }
             $config = Get-ViewConfig -Mode $script:currentMode -Category $catSelection
             $ui.CbCriterio.Items.AddRange($config.Criteria)
             $ui.BtnOcultar.Text = $config.BtnFilterText
             if ($config.Criteria.Count -eq 1 -and $config.Criteria[0] -eq "Padrão") { $ui.CbCriterio.Enabled = $false; $ui.CbCriterio.BackColor = $theme.ButtonBack; $ui.CbCriterio.ForeColor = $theme.TextDim } else { $ui.CbCriterio.Enabled = $true; $ui.CbCriterio.BackColor = $theme.ButtonBack; $ui.CbCriterio.ForeColor = $theme.TextMain }
             
             if ($script:currentMode -eq "Gastronomy" -or $script:currentMode -eq "UnarmoredRig" -or $script:currentMode -eq "Backpack" -or $script:currentMode -eq "Headset" -or $script:currentMode -eq "GasMask" -or $script:currentMode -eq "Mask" -or $script:currentMode -eq "Throwable") { 
                 $ui.BtnOcultar.Enabled = $false; $ui.BtnOcultar.BackColor = $theme.ButtonBack; $ui.BtnOcultar.ForeColor = $theme.TextDim 
             } else { 
                 $ui.BtnOcultar.Enabled = $true; $ui.BtnOcultar.BackColor = $theme.OrangeAccent; $ui.BtnOcultar.ForeColor = $theme.Background 
             }
             if ($ui.CbCriterio.Items.Count -gt 0) { $ui.CbCriterio.SelectedIndex = 0 }
        }
        
        & $ui.InitializeGrid
        $ui.IsLoading = $false
        
        $ui.PnlMenu.Visible = $false; $ui.PnlContent.Visible = $true
        & $ui.ActionUpdateGrid
    }

    $script:SearchUI.ActionOpenAmmoGrid = {
        $ui = $script:SearchUI
        $ui.IsLoading = $true

        $script:manualFilters.Clear(); $keys = @("Lv", "Calibre", "ChanceFerirDisplay"); foreach ($k in $keys) { if (-not $script:manualFilters.ContainsKey($k)) { $script:manualFilters[$k] = [System.Collections.ArrayList]@() } }
        $ui.CbCriterio.Items.Clear()
        
        # [AQUI FOI APLICADA A CORREÇÃO DE ACENTUAÇÃO DAS MUNIÇÕES]
        $criteria = @("Alfabético", "Nível de Penetração", "Penetração", "Dano Base", "Dano de Blindagem", "Velocidade Inicial", "Precisão", "Controle de Recuo Vertical", "Controle de Recuo Horizontal", "Chance de Ferir")
        $ui.CbCriterio.Items.AddRange($criteria); $ui.CbCriterio.SelectedIndex = 0
        $ui.BtnOcultar.Text = "Filtros (Munições)"
        
        $ui.LblCat.Visible = $false; $ui.CbCat.Visible = $false
        $ui.LblAmmoCat.Visible = $true; $ui.CbAmmoCat.Visible = $true; $ui.LblAmmoWep.Visible = $true; $ui.BtnAmmoWep.Visible = $true; $ui.BtnAmmoReset.Visible = $true; $ui.BtnTop5.Visible = $true
        
        # [AJUSTE SINCRONIZADO] Munições: X=7, W=1170, H=690
        $ui.GbControls.Size = New-Object System.Drawing.Size(1170, 100)
        $ui.Dgv.Location = New-Object System.Drawing.Point(7, 120)
        $ui.Dgv.Size = New-Object System.Drawing.Size(1170, 690)
        
        $ui.LblCrit.Location = "10, 25"; $ui.CbCriterio.Location = "65, 22"; $ui.CbCriterio.Width = 200; $ui.LblOrd.Location = "280, 25"; $ui.CbOrdem.Location = "330, 22"; $ui.CbOrdem.Width = 100
        $ui.BtnOcultar.Location = "450, 21"; $ui.BtnOcultar.Width = 150 
        $ui.LblAmmoCat.Location = "10, 60"; $ui.CbAmmoCat.Location = "75, 57"; $ui.CbAmmoCat.Width = 190
        $ui.LblAmmoWep.Location = "280, 60"; $ui.BtnAmmoWep.Location = "330, 57"; $ui.BtnAmmoWep.Width = 190
        $ui.BtnAmmoReset.Location = "530, 56"; $ui.BtnAmmoReset.Width = 60
        $ui.BtnTop5.Location = "650, 21"; $ui.BtnTop5.Width = 280; $ui.BtnSave.Location = "650, 56"; $ui.LblCount.Location = "780, 58"
        
        # Atualiza APENAS se estiver vazio (Evita piscar/recarregar indevido)
        if ($ui.CbAmmoCat.Items.Count -eq 0) {
            $ui.CbAmmoCat.Items.Add("Todas"); 
            if ($script:cachedWeaponData) {
                $cats = New-Object System.Collections.Generic.HashSet[string]
                foreach ($w in $script:cachedWeaponData) { 
                    if ($w.ClasseDisplay) { $cats.Add($w.ClasseDisplay) | Out-Null } 
                    elseif ($w.Classe) { $cats.Add($w.Classe) | Out-Null } 
                }
                $sortedCats = [Linq.Enumerable]::OrderBy([string[]]$cats, [Func[string,string]]{ $args[0] })
                $ui.CbAmmoCat.Items.AddRange([object[]]$sortedCats)
            }
            $ui.CbAmmoCat.SelectedIndex = 0
        }
        
        # [CORREÇÃO DO BUG "TODAS" PERSISTENTE]
        # Limpamos o menu e recriamos a estrutura do zero, garantindo que o evento de clique é anexado corretamente.
        $ui.CmsAmmoWep.Items.Clear() 
        $itmAll = $ui.CmsAmmoWep.Items.Add("Todas")
        $itmAll.Add_Click({ 
            $ui = $script:SearchUI
            $script:ammoWeapon = "Todas"
            $ui.BtnAmmoWep.Text = "Arma: Todas"
            & $ui.UpdateAmmoGrid 
        })
        $ui.CmsAmmoWep.Items.Add("-") | Out-Null # Adiciona um separador visual
        
        if ($script:cachedWeaponData) {
            if ($script:ammoCategory -eq "Todas") {
                $grouped = $script:cachedWeaponData | Group-Object ClasseDisplay | Sort-Object Name
                foreach ($g in $grouped) { 
                    $catItem = $ui.CmsAmmoWep.Items.Add($g.Name)
                    $sortedWeps = $g.Group | Sort-Object Nome
                    foreach ($w in $sortedWeps) { 
                        $wepItem = $catItem.DropDownItems.Add($w.Nome)
                        $wepItem.Add_Click({ 
                            $ui=$script:SearchUI; 
                            $script:ammoWeapon = $this.Text; 
                            $ui.BtnAmmoWep.Text = "Arma: $($this.Text)"; 
                            & $ui.UpdateAmmoGrid 
                        }) 
                    } 
                }
            } else {
                $wepsInCat = $script:cachedWeaponData | Where-Object { ($_.ClasseDisplay -eq $script:ammoCategory) -or ($_.Classe -eq $script:ammoCategory) } | Sort-Object Nome 
                foreach ($w in $wepsInCat) { 
                    $wepItem = $ui.CmsAmmoWep.Items.Add($w.Nome)
                    $wepItem.Add_Click({ 
                        $ui=$script:SearchUI; 
                        $script:ammoWeapon = $this.Text; 
                        $ui.BtnAmmoWep.Text = "Arma: $($this.Text)"; 
                        & $ui.UpdateAmmoGrid 
                    }) 
                }
            }
        }
        
        $ui.IsLoading = $false
        
        $ui.PnlMenu.Visible = $false; $ui.PnlContent.Visible = $true
        & $ui.UpdateAmmoGrid
    }

    $script:SearchUI.CbCat.Add_SelectedIndexChanged({ 
        $ui = $script:SearchUI
        if ($ui.CbCat.Tag -eq "Loading" -or $ui.IsLoading) { return }
        & $ui.InitializeGrid; & $ui.ActionUpdateGrid 
    }) 
    
    $script:SearchUI.CbCriterio.Add_SelectedIndexChanged({ 
        $ui = $script:SearchUI
        if ($ui.IsLoading) { return }
        if($script:currentMode -eq "Ammo"){ & $ui.UpdateAmmoGrid }else{ & $ui.ActionUpdateGrid } 
    })
    
    $script:SearchUI.CbOrdem.Add_SelectedIndexChanged({ 
        $ui = $script:SearchUI
        if ($ui.IsLoading) { return }
        $script:mainOrdem = $ui.CbOrdem.SelectedItem; 
        if($script:currentMode -eq "Ammo"){ & $ui.UpdateAmmoGrid }else{ & $ui.ActionUpdateGrid } 
    })
    
    $script:SearchUI.Dgv.Add_SelectionChanged({ $script:SearchUI.Dgv.ClearSelection() })
    $script:SearchUI.BtnSave.Add_Click({ Save-ToCSV -Grid $script:SearchUI.Dgv })
    
    $script:SearchUI.BtnVoltar.Add_Click({ 
        $script:SearchUI.PnlContent.Visible = $false
        $script:SearchUI.PnlMenu.Visible = $true 
    })
    
    $script:SearchUI.BtnOcultar.Add_Click({ 
        $ui = $script:SearchUI
        if ($script:currentMode -eq "Ammo") { Show-AmmoFilterDialog -ThemeColors $theme; & $ui.UpdateAmmoGrid }
        elseif ($script:currentMode -eq "Weapon") { Show-WeaponFilterDialog -Data $script:cachedWeaponData -ThemeColors $theme; & $ui.ActionUpdateGrid }
        elseif ($script:currentMode -eq "Helmet") { Show-HelmetFilterDialog -Data $script:cachedHelmetData -ThemeColors $theme; & $ui.ActionUpdateGrid }
        elseif ($script:currentMode -eq "Armor") { Show-ArmorFilterDialog -Data $script:cachedArmorData -ThemeColors $theme; & $ui.ActionUpdateGrid }
        elseif ($script:currentMode -eq "ArmoredRig") { Show-ArmoredRigFilterDialog -Data $script:cachedRigData -ThemeColors $theme; & $ui.ActionUpdateGrid }
        else { & $ui.ActionUpdateGrid }
    })

    $script:SearchUI.CbAmmoCat.Add_SelectedIndexChanged({ 
        $ui = $script:SearchUI
        if ($ui.IsLoading) { return }
        $script:ammoCategory = $ui.CbAmmoCat.SelectedItem
        $script:ammoWeapon = "Todas"
        $ui.BtnAmmoWep.Text = "Arma: Todas"
        # Não chamamos ActionOpenAmmoGrid completo, pois ele reseta a combo de categorias.
        # Apenas reconstruímos o menu de armas e chamamos a atualização da grid.
        
        $ui.CmsAmmoWep.Items.Clear()
        $itmAll = $ui.CmsAmmoWep.Items.Add("Todas")
        $itmAll.Add_Click({ 
            $ui=$script:SearchUI; 
            $script:ammoWeapon = "Todas"; 
            $ui.BtnAmmoWep.Text = "Arma: Todas"; 
            & $ui.UpdateAmmoGrid 
        })
        $ui.CmsAmmoWep.Items.Add("-") | Out-Null
        
        if ($script:cachedWeaponData) {
            if ($script:ammoCategory -eq "Todas") {
                $grouped = $script:cachedWeaponData | Group-Object ClasseDisplay | Sort-Object Name
                foreach ($g in $grouped) { 
                    $catItem = $ui.CmsAmmoWep.Items.Add($g.Name)
                    $sortedWeps = $g.Group | Sort-Object Nome
                    foreach ($w in $sortedWeps) { 
                        $wepItem = $catItem.DropDownItems.Add($w.Nome)
                        $wepItem.Add_Click({ 
                            $ui=$script:SearchUI; 
                            $script:ammoWeapon = $this.Text; 
                            $ui.BtnAmmoWep.Text = "Arma: $($this.Text)"; 
                            & $ui.UpdateAmmoGrid 
                        }) 
                    } 
                }
            } else {
                $wepsInCat = $script:cachedWeaponData | Where-Object { ($_.ClasseDisplay -eq $script:ammoCategory) -or ($_.Classe -eq $script:ammoCategory) } | Sort-Object Nome 
                foreach ($w in $wepsInCat) { 
                    $wepItem = $ui.CmsAmmoWep.Items.Add($w.Nome)
                    $wepItem.Add_Click({ 
                        $ui=$script:SearchUI; 
                        $script:ammoWeapon = $this.Text; 
                        $ui.BtnAmmoWep.Text = "Arma: $($this.Text)"; 
                        & $ui.UpdateAmmoGrid 
                    }) 
                }
            }
        }
        & $ui.UpdateAmmoGrid 
    })
    
    $script:SearchUI.BtnAmmoWep.Add_Click({ $script:SearchUI.CmsAmmoWep.Show($script:SearchUI.BtnAmmoWep, 0, $script:SearchUI.BtnAmmoWep.Height) })
    
    $script:SearchUI.BtnAmmoReset.Add_Click({ 
        $ui = $script:SearchUI
        $script:ammoCategory="Todas"
        $script:ammoWeapon="Todas"
        $ui.CbAmmoCat.SelectedItem = "Todas"
        $ui.BtnAmmoWep.Text = "Arma: Todas"
        if ($script:manualFilters.ContainsKey("Lv")) { $script:manualFilters["Lv"].Clear() }
        if ($script:manualFilters.ContainsKey("Calibre")) { $script:manualFilters["Calibre"].Clear() }
        if ($script:manualFilters.ContainsKey("ChanceFerirDisplay")) { $script:manualFilters["ChanceFerirDisplay"].Clear() }
        & $ui.ActionOpenAmmoGrid 
    })
    
    $script:SearchUI.BtnTop5.Add_Click({ if ($script:isTop5Allowed) { Show-Top5AmmoDialog } })
}

function Build-MainFormMenu {
    
    # [AJUSTE VISUAL] Titulo Centralizado (Aproximadamente)
    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "Busca de Itens com Filtro"
    $lblTitle.Location = "50, 50"; $lblTitle.AutoSize = $true
    $lblTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFA500")
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 22, [System.Drawing.FontStyle]::Bold)
    $script:SearchUI.PnlMenu.Controls.Add($lblTitle)

    function New-MenuBtn ($txt, $x, $y, $code) {
        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $txt; $btn.Size = "300, 45"; $btn.Location = "$x, $y"
        $btn.FlatStyle = "Flat"; $btn.BackColor = $theme.ButtonBack; $btn.ForeColor = $theme.TextMain; $btn.FlatAppearance.BorderColor = $theme.OrangeAccent
        $btn.Add_Click($code)
        $script:SearchUI.PnlMenu.Controls.Add($btn)
    }

    # [AJUSTE VISUAL] Novas Coordenadas para tela 1200x850
    # Centro da tela é 600. Botão tem 300. Centro do botão é 150.
    # Coluna do Meio X = 600 - 150 = 450.
    # Gap = 40px.
    # Coluna Esquerda X = 450 - 300 - 40 = 110.
    # Coluna Direita X = 450 + 300 + 40 = 790.
    
    $startY = 160 # Baixei um pouco para aproveitar a altura extra (850)
    $gapY   = 55
    
    $col1X = 110
    $col2X = 450
    $col3X = 790

    New-MenuBtn "Busca de Armas"                     $col1X ($startY + 0*$gapY) { $script:currentMode = "Weapon"; & $script:SearchUI.ActionOpenGrid }
    New-MenuBtn "Busca de Munição"                   $col2X ($startY + 0*$gapY) { $script:currentMode = "Ammo"; & $script:SearchUI.ActionOpenAmmoGrid }
    New-MenuBtn "Busca de Granadas"                  $col3X ($startY + 0*$gapY) { $script:currentMode = "Throwable"; & $script:SearchUI.ActionOpenGrid }

    New-MenuBtn "Busca de Capacetes"                 $col1X ($startY + 1*$gapY) { $script:currentMode = "Helmet"; & $script:SearchUI.ActionOpenGrid }
    New-MenuBtn "Busca de Máscaras"                  $col2X ($startY + 1*$gapY) { $script:currentMode = "Mask"; & $script:SearchUI.ActionOpenGrid }
    New-MenuBtn "Busca de Máscaras de Gás"           $col3X ($startY + 1*$gapY) { $script:currentMode = "GasMask"; & $script:SearchUI.ActionOpenGrid }

    New-MenuBtn "Busca de Fones de Ouvido (Headsets)" $col1X ($startY + 2*$gapY) { $script:currentMode = "Headset"; & $script:SearchUI.ActionOpenGrid }
    New-MenuBtn "Busca de Coletes Balísticos"        $col2X ($startY + 2*$gapY) { $script:currentMode = "Armor"; & $script:SearchUI.ActionOpenGrid }
    New-MenuBtn "Busca de Coletes Blindados (Rigs)"  $col3X ($startY + 2*$gapY) { $script:currentMode = "ArmoredRig"; & $script:SearchUI.ActionOpenGrid }

    New-MenuBtn "Busca de Coletes Não Blindados"     $col1X ($startY + 3*$gapY) { $script:currentMode = "UnarmoredRig"; & $script:SearchUI.ActionOpenGrid }
    New-MenuBtn "Busca de Mochilas"                  $col2X ($startY + 3*$gapY) { $script:currentMode = "Backpack"; & $script:SearchUI.ActionOpenGrid }
    New-MenuBtn "Busca Farmacêutica"                 $col3X ($startY + 3*$gapY) { $script:currentMode = "Pharmaceutical"; & $script:SearchUI.ActionOpenGrid }

    New-MenuBtn "Busca Gastronômica"                 $col2X ($startY + 4*$gapY) { $script:currentMode = "Gastronomy"; & $script:SearchUI.ActionOpenGrid }
}

function Show-MainForm {
    param($MainForm) # Recebe a janela principal

    # 0. Dados
    $script:currentMode = "Weapon"; $script:ammoCategory = "Todas"; $script:ammoWeapon = "Todas"; $script:isTop5Allowed = $false; if ($null -eq $script:manualFilters) { $script:manualFilters = @{} }
    $script:cachedWeaponData = if (Get-Command Get-WeaponData -ErrorAction SilentlyContinue) { Get-WeaponData } else { @() }
    # ... (outros caches de dados mantidos iguais) ...
    $script:cachedAmmoData   = if (Get-Command Get-AmmoData -ErrorAction SilentlyContinue) { Get-AmmoData } else { @() }

    # [CORREÇÃO] Salva a UI em uma variável de script para persistir na memória
    $script:SearchUI = Initialize-MainFormVisuals -MainForm $MainForm

    # 2. Dados
    Update-MainFormData -ui $script:SearchUI

    # 3. Eventos
    Register-MainFormEvents -ui $script:SearchUI

    # 4. Menu
    Build-MainFormMenu -ui $script:SearchUI

    # [IMPORTANTE] Removemos o ShowDialog(). 
    # O painel já foi adicionado ao MainForm e está visível. O script termina aqui, mas o painel fica.
}

# ===================================================================================
# 4. O ARQUITETO (VISUAL PRINCIPAL 1200x850)
# ===================================================================================
function Initialize-MainVisuals {
    $ui = @{}
    $form = New-Object System.Windows.Forms.Form
    $form.SuspendLayout()

    $form.Text = "Arena Breakout Infinite - Database Offline (ABIDB)"
    $form.Size = New-Object System.Drawing.Size(1200, 850)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = $theme.Background
    $form.ForeColor = $theme.TextMain
    $form.FormBorderStyle = "FixedSingle"
    $form.MaximizeBox = $false
    
    # =========================================================================
    # --- ÍCONE DINÂMICO E721 (COM DETEÇÃO DE MODO CLARO/ESCURO E GESTÃO GDI) ---
    # =========================================================================
    try {
        $iconFont = New-Object System.Drawing.Font("Segoe MDL2 Assets", 40, [System.Drawing.FontStyle]::Regular)
        $bmp = New-Object System.Drawing.Bitmap(64, 64)
        $gfx = [System.Drawing.Graphics]::FromImage($bmp)
        
        # Qualidade máxima (Anti-Aliasing)
        $gfx.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
        
        # 1. Lê o registo para saber se a barra de tarefas do Windows é Clara ou Escura
        $isLightTaskbar = $false
        try {
            $regKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
            $sysTheme = Get-ItemPropertyValue -Path $regKey -Name "SystemUsesLightTheme" -ErrorAction Stop
            if ($sysTheme -eq 1) { $isLightTaskbar = $true }
        } catch { }

        # 2. Se for modo Claro, pinta de Preto. Se for modo Escuro, pinta de Branco.
        $iconColor = if ($isLightTaskbar) { [System.Drawing.Color]::Black } else { [System.Drawing.Color]::White }
        $brush = New-Object System.Drawing.SolidBrush($iconColor)
        
        # 3. Desenha o símbolo E721 (centrado na tela 64x64)
        $gfx.DrawString([char]0xE721, $iconFont, $brush, 4, 4) 
        
        # 4. Aplica na janela
        $hIcon = $bmp.GetHicon()
        $form.Icon = [System.Drawing.Icon]::FromHandle($hIcon)

        # 5. LIMPEZA IMEDIATA: Destrói todas as ferramentas de desenho da memória
        $gfx.Dispose()
        $bmp.Dispose()
        $iconFont.Dispose()
        $brush.Dispose()
    } catch {
        # Fallback silencioso: se der erro, usa o ícone padrão
    }
    # =========================================================================

    $ui.Form = $form

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "ARENA BREAKOUT INFINITE"
    $lblTitle.AutoSize = $true
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 24, [System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = $theme.TextMain
    $lblTitle.Location = New-Object System.Drawing.Point(370, 80)
    $form.Controls.Add($lblTitle)

    $lblSub = New-Object System.Windows.Forms.Label
    $lblSub.Text = "DATABASE OFFLINE (ABIDB)"
    $lblSub.AutoSize = $true
    $lblSub.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    $lblSub.ForeColor = $theme.OrangeAccent
    $lblSub.Location = New-Object System.Drawing.Point(425, 130)
    $form.Controls.Add($lblSub)
    
    $lblVer = New-Object System.Windows.Forms.Label
    $lblVer.Text = "Versao: $AppVersion"
    $lblVer.AutoSize = $true
    $lblVer.ForeColor = $theme.TextDim
    $lblVer.Location = New-Object System.Drawing.Point(20, 780)
    $form.Controls.Add($lblVer)

    $lblCreator = New-Object System.Windows.Forms.Label
    $lblCreator.Text = "Dev: Fabiopsyduck"
    $lblCreator.AutoSize = $true
    $lblCreator.ForeColor = $theme.TextDim
    $lblCreator.Location = New-Object System.Drawing.Point(1050, 780)
    $form.Controls.Add($lblCreator)

    $pnlButtons = New-Object System.Windows.Forms.Panel
    $pnlButtons.Size = New-Object System.Drawing.Size(400, 450)
    $pnlButtons.Location = New-Object System.Drawing.Point(400, 230)
    $pnlButtons.BackColor = $theme.Background
    $form.Controls.Add($pnlButtons)
    $ui.PnlButtons = $pnlButtons

    $form.ResumeLayout()
    return $ui
}

# ===================================================================================
# 5. O NAVEGADOR (MENU)
# ===================================================================================
function Build-MainMenu {
    param ($ui, $events)
    function New-MenuBtn {
        param ($Text, $Y_Pos, $ActionKey)
        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $Text; $btn.Size = "380, 50"; $btn.Location = "10, $Y_Pos"; $btn.FlatStyle = "Flat"; $btn.BackColor = $theme.ButtonBack; $btn.ForeColor = $theme.TextMain; $btn.Font = New-Object System.Drawing.Font("Segoe UI", 11); $btn.Cursor = "Hand"; $btn.FlatAppearance.BorderColor = $theme.OrangeAccent; $btn.FlatAppearance.BorderSize = 1
        if ($events.ContainsKey($ActionKey)) { $btn.Add_Click($events[$ActionKey]) }
        return $btn
    }

    $ui.PnlButtons.Controls.Add((New-MenuBtn "Busca de Itens com Filtro" 10 "OpenDatabase"))
    $ui.PnlButtons.Controls.Add((New-MenuBtn "Comparação e Compatibilidade" 75 "OpenCompare"))
    $ui.PnlButtons.Controls.Add((New-MenuBtn "Gerenciar Banco de Dados" 140 "OpenManage"))
    $ui.PnlButtons.Controls.Add((New-MenuBtn "Verificar Atualizações" 205 "CheckUpdates"))
    
    $btnExit = New-MenuBtn "Sair" 360 "ExitApp"
    $btnExit.BackColor = "#252525"; $btnExit.ForeColor = "#ff6666"; $btnExit.FlatAppearance.BorderColor = "#ff6666"
    $ui.PnlButtons.Controls.Add($btnExit)
}

# ===================================================================================
# MÓDULO: GERENCIADOR DE BANCO DE DADOS (JANELA INDEPENDENTE)
# ===================================================================================

# ===================================================================================
# MÓDULO: FERRAMENTAS GLOBAIS DO GERENCIADOR
# ===================================================================================

function Show-SelectionDialog {
    param($Title, $Prompt, $Options = @())

    $fSel = New-Object System.Windows.Forms.Form
    $fSel.Text = $Title; $fSel.Size = New-Object System.Drawing.Size(400, 500); $fSel.StartPosition = "CenterParent"; $fSel.BackColor = $theme.PanelBack; $fSel.ForeColor = $theme.TextMain; $fSel.FormBorderStyle = "FixedDialog"; $fSel.MaximizeBox = $false; $fSel.MinimizeBox = $false

    $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $Prompt; $lbl.Location = "20, 10"; $lbl.Size = "340, 20"; $lbl.ForeColor = $theme.OrangeAccent
    $lst = New-Object System.Windows.Forms.ListBox; $lst.Location = "20, 40"; $lst.Size = "340, 360"; $lst.BackColor = $theme.ButtonBack; $lst.ForeColor = $theme.TextMain; $lst.BorderStyle = "FixedSingle"
    
    # --- CORREÇÃO MEMORY LEAK: Reutiliza a fonte global se existir, senão cria e a janela limpa o controlo ---
    if ($script:fontNormal) { $lst.Font = New-Object System.Drawing.Font("Segoe UI", 10) }
    
    foreach ($opt in $Options) { $lst.Items.Add($opt) | Out-Null }

    $btnOk = New-Object System.Windows.Forms.Button; $btnOk.Text = "Confirmar"; $btnOk.DialogResult = "OK"; $btnOk.Location = "190, 410"; $btnOk.Size = "100, 35"; $btnOk.FlatStyle = "Flat"; $btnOk.BackColor = $theme.OrangeAccent; $btnOk.ForeColor = $theme.Background
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Cancelar"; $btnCancel.DialogResult = "Cancel"; $btnCancel.Location = "295, 410"; $btnCancel.Size = "80, 35"; $btnCancel.FlatStyle = "Flat"; $btnCancel.BackColor = $theme.ButtonBack; $btnCancel.ForeColor = $theme.TextMain

    $fSel.Controls.AddRange(@($lbl, $lst, $btnOk, $btnCancel))
    $fSel.AcceptButton = $btnOk; $fSel.CancelButton = $btnCancel
    
    # 1. Mostra a janela e captura a ação (OK ou Cancel)
    $res = $fSel.ShowDialog()
    
    # 2. Guarda a seleção antes de destruir a janela
    $selecao = $lst.SelectedItem
    
    # 3. --- CORREÇÃO MEMORY LEAK: Destrói a janela ---
    $fSel.Dispose()
    
    # 4. Devolve o valor (se tiver clicado OK)
    if ($res -eq "OK") { return $selecao }
    return $null
}

function Show-InputDialog {
    param($Title, $Prompt, $DefaultText = "", $ForbiddenList = @())

    $fInput = New-Object System.Windows.Forms.Form
    $fInput.Text = $Title
    $fInput.Size = New-Object System.Drawing.Size(400, 220)
    $fInput.StartPosition = "CenterParent"
    $fInput.BackColor = $theme.PanelBack
    $fInput.ForeColor = $theme.TextMain
    $fInput.FormBorderStyle = "FixedDialog"
    $fInput.MaximizeBox = $false
    $fInput.MinimizeBox = $false

    $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $Prompt; $lbl.Location = "20, 20"; $lbl.Size = "340, 20"; $lbl.ForeColor = $theme.OrangeAccent
    $txt = New-Object System.Windows.Forms.TextBox; $txt.Location = "20, 50"; $txt.Size = "340, 30"; $txt.Text = $DefaultText; $txt.BackColor = $theme.ButtonBack; $txt.ForeColor = $theme.TextMain; $txt.BorderStyle = "FixedSingle"
    
    $lblError = New-Object System.Windows.Forms.Label; $lblError.Text = ""; $lblError.Location = "20, 85"; $lblError.Size = "340, 20"; $lblError.ForeColor = $theme.RedAlert; $lblError.Visible = $false
    
    $timerError = New-Object System.Windows.Forms.Timer; $timerError.Interval = 3000
    $timerError.Add_Tick({ $lblError.Visible = $false; $timerError.Stop() })

    $btnOk = New-Object System.Windows.Forms.Button; $btnOk.Text = "OK"; $btnOk.Location = "190, 130"; $btnOk.Size = "80, 30"; $btnOk.FlatStyle = "Flat"; $btnOk.BackColor = $theme.OrangeAccent; $btnOk.ForeColor = $theme.Background
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Cancelar"; $btnCancel.DialogResult = "Cancel"; $btnCancel.Location = "280, 130"; $btnCancel.Size = "80, 30"; $btnCancel.FlatStyle = "Flat"; $btnCancel.BackColor = $theme.ButtonBack; $btnCancel.ForeColor = $theme.TextMain

    $btnOk.Add_Click({
        $val = $txt.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($val)) { $fInput.DialogResult = "Cancel"; $fInput.Close(); return }
        if ($val -ne $DefaultText -and $ForbiddenList -contains $val) {
            $lblError.Text = "Erro: O nome '$val' já existe!"; $lblError.Visible = $true
            $txt.Text = ""; $txt.Focus()
            $timerError.Start()
        } else {
            $fInput.DialogResult = "OK"; $fInput.Close()
        }
    })

    $fInput.Controls.AddRange(@($lbl, $txt, $lblError, $btnOk, $btnCancel))
    $fInput.AcceptButton = $btnOk; $fInput.CancelButton = $btnCancel
    
    # 1. Mostra a janela e captura o resultado
    $res = $fInput.ShowDialog()
    
    # 2. Guarda o texto inserido
    $textoFinal = $txt.Text.Trim()
    
    # 3. --- CORREÇÃO MEMORY LEAK: Destrói o timer e o formulário ---
    $timerError.Dispose()
    $fInput.Dispose()
    
    # 4. Devolve o valor se for OK
    if ($res -eq "OK") { return $textoFinal }
    return $null
}

function Test-KeyRestriction {
    param (
        [System.Windows.Forms.TextBox]$Control,
        [char]$Char,
        [string]$Mode
    )

    # 1. Permite teclas de controle (Backspace, Delete, Setas, etc)
    if ([char]::IsControl($Char)) { return $true }

    # 2. Simula o texto futuro (O que aconteceria se deixassemos a tecla passar)
    $idx = $Control.SelectionStart
    $currentText = $Control.Text
    # Remove texto selecionado se houver (comportamento de overwrite)
    if ($Control.SelectionLength -gt 0) {
        $currentText = $currentText.Remove($idx, $Control.SelectionLength)
    }
    $newText = $currentText.Insert($idx, $Char.ToString())
    
    $isValid = $false

    switch ($Mode) {
        # --- NOVA REGRA DO DANO DE MUNICÃƒO (Portado de Get-DanoBase) ---
        'ammo_damage_strict' {
            # 1. Permite atÃ© 3 dÃ­gitos (ex: 1, 12, 123)
            # 2. Permite formato XXx (ex: 26x) APENAS se tiver 2 digitos antes
            # 3. Permite formato XXxY (ex: 26x8) APENAS 1 digito depois
            if ($newText -match '^\d{1,3}$|^\d{2}[xX]\d?$') { 
                $isValid = $true 
            }
        }

        # --- MODOS NUMÃ‰RICOS E FÃSICOS ---
        'numeric_2-9_max_value' {
            # Regra: Primeiro digito 2-9, depois 0-9.
            if ($currentText.Length -eq 0) { if ($Char -match '[2-9]') { $isValid = $true } } 
            else { if ($Char -match '[0-9]') { $isValid = $true } }
        }
        'precision' { 
            # Valida se o texto futuro parece "+", "+1", "+10"
            if ($newText -match '^\+$' -or $newText -match '^\+[0-9]+$') { $isValid = $true }
        }
        'recoil' { 
            # Permite apenas se o resultado for +, -, +10, -10, 0 (e nÃ£o 01)
            if ($newText -match '^[+-]$' -or $newText -match '^[+-][0-9]+$' -or $newText -eq '0') { $isValid = $true }
        }
        'numeric' { $isValid = ($Char -match '[0-9]') }
        'penetration' { 
            # Apenas 0-7 e apenas 1 caractere
            if ($newText -match '^[0-7]$') { $isValid = $true } 
        }
        'armor' { 
            # Permite inteiros ou decimais. Ex: 10, 10.5
            if ($Char -eq '.') { 
                if ($currentText -notmatch '\.' -and $currentText.Length -gt 0) { $isValid = $true }
            } 
            elseif ($Char -match '[0-9]') { $isValid = $true } 
        }
        
        # --- MODOS DE INTERVALO RESTRITO ---
        'numeric_1_9' { if ($newText -match '^[1-9]$') { $isValid = $true } }
        'numeric_1_4' { if ($newText -match '^[1-4]$') { $isValid = $true } }
        'numeric_1_6' { if ($newText -match '^[1-6]$') { $isValid = $true } }
        
        'numeric_no_leading_zero' { 
            if ($currentText.Length -eq 0) { if ($Char -match '[1-9]') { $isValid = $true } } 
            else { if ($Char -match '[0-9]') { $isValid = $true } } 
        }
        'numeric_allow_zero_single' { 
            # Permite 0, 1, 10... mas nÃ£o 01
            if ($currentText -eq '0') { $isValid = $false } # Bloqueia digitar depois do 0
            elseif ($currentText.Length -eq 0) { if ($Char -match '[0-9]') { $isValid = $true } } 
            else { if ($Char -match '[0-9]') { $isValid = $true } } 
        }

        # --- MODOS DE STATUS VITAIS (STRICT) ---
        'dehydration_strict' { 
            # Regra antiga: ComeÃ§a com -, numeros, max 100
            if ($newText -eq '-') { $isValid = $true }
            elseif ($newText -match '^-[0-9]+$') {
                $num = [int]$newText 
                if ($num -ge -100) { $isValid = $true } 
            }
        }
        'hydration_strict' { 
            # Regra antiga: 0 OU +X OU -X. Valor absoluto <= 100.
            if ($newText -eq '0') { $isValid = $true }
            elseif ($newText -match '^[+-]$') { $isValid = $true }
            elseif ($newText -match '^[+-][0-9]+$') {
                 $numPart = [int]$newText.Substring(1)
                 if ($numPart -le 100) { $isValid = $true }
            }
        }
        'energy_negative_only' { 
            if ($newText -match '^-$' -or $newText -match '^-[0-9]+$') { $isValid = $true }
        }
        'percentage_negative' { 
            # Ex: -10, -5. NÃ£o aceita 0 sozinho nem -0.
            if ($newText -match '^-$') { $isValid = $true }
            elseif ($newText -match '^-[1-9][0-9]*$') { $isValid = $true }
        }
        
        # [NOVO] Adicionado para corrigir erro em Capacetes (Ergonomia)
        'numeric_negative_no_leading_zero' {
            # Regra: Deve ser negativo e nÃ£o ter zero Ã  esquerda (ex: -10 ok, -05 nÃ£o)
            if ($newText -eq '-') { $isValid = $true }
            elseif ($newText -match '^-[1-9][0-9]*$') { $isValid = $true }
        }

        # --- MODOS DECIMAIS ESPECÃFICOS ---
        'decimal_fixed' { 
            if ($Char -eq '.') { if ($currentText -notmatch '\.' -and $currentText.Length -gt 0) { $isValid = $true } }
            elseif ($Char -match '[0-9]') { 
                if ($newText -match '^\d{1,2}(\.\d?)?$') { $isValid = $true } 
            } 
        }
        'decimal_1_2' { if ($newText -match '^\d(\.\d{0,2})?$') { $isValid = $true } }
        'decimal_2_1_fixed' { if ($newText -match '^[1-9]\d?(\.\d?)?$') { $isValid = $true } }
        'decimal_2_2' { if ($newText -match '^\d{1,2}(\.\d{0,2})?$') { $isValid = $true } }
        'decimal_3_1_fixed' { if ($newText -match '^\d{1,3}(\.\d?)?$') { $isValid = $true } }
        'decimal_3_2' { if ($newText -match '^\d{1,3}(\.\d{0,2})?$') { $isValid = $true } }
        
        # --- MODOS DE ITENS ESPECÃFICOS ---
        'decimal_durability_fixed' { if ($newText -match '^[1-9]\d{0,2}(\.0?)?$') { $isValid = $true } }
        'decimal_weight' { if ($newText -match '^[1-9]\d{0,1}(\.\d{0,2})?$') { $isValid = $true } }
        'decimal_mask_weight' { if ($newText -match '^\d(\.\d{0,2})?$') { $isValid = $true } }
        'decimal_mask_durability' { if ($newText -match '^\d{1,2}(\.0?)?$') { $isValid = $true } }
        'numeric_2_digits_no_leading_zero' { if ($newText -match '^[1-9]\d?$') { $isValid = $true } }
        'decimal_gasmask_weight' { if ($newText -match '^0(\.\d{0,2})?$') { $isValid = $true } }
        'decimal_headset_weight' { if ($newText -match '^0(\.\d{0,2})?$') { $isValid = $true } }
        'decimal_unarmored_weight' { if ($newText -match '^\d(\.\d{0,2})?$') { $isValid = $true } }
        'decimal_backpack_weight' { if ($newText -match '^\d{1,2}(\.\d{0,2})?$') { $isValid = $true } }
        
        default { $isValid = $false } 
    }

    return $isValid
}

function Add-Validation {
        param($Control, [string]$Mode)
        $Control.Tag = $Mode 
        
        $Control.ContextMenu = New-Object System.Windows.Forms.ContextMenu
        $Control.Add_KeyDown({
            if (($_.Control -and $_.KeyCode -eq 'V') -or ($_.Shift -and $_.KeyCode -eq 'Insert')) {
                $_.SuppressKeyPress = $true
            }
        })

        $kp = {
            $allowed = Test-KeyRestriction -Control $this -Char $_.KeyChar -Mode $this.Tag
            if (-not $allowed) { $_.Handled = $true } 
        }.GetNewClosure()
        $Control.Add_KeyPress($kp)
    }

function Test-CaliberUsage {
    param($calName)
    $dbPath = Get-DatabasePath
    $ammoPath = Join-Path $dbPath "Ammo.csv"; $wepPath = Join-Path $dbPath "Weapons.csv"
    if (Test-Path $ammoPath) { if ((Import-Csv $ammoPath -Delimiter ";" -Encoding UTF8 | Where-Object { $_.Calibre -eq $calName })) { return $true } }
    if (Test-Path $wepPath) { if ((Import-Csv $wepPath -Delimiter ";" -Encoding UTF8 | Where-Object { $_.Calibre -eq $calName })) { return $true } }
    return $false
}

function Start-WeaponEditor {
    param (
        $ui,
        $EditItem = $null
    )

    # 1. Janela Popup
    $fEdit = New-Object System.Windows.Forms.Form
    $fEdit.Size = New-Object System.Drawing.Size(950, 850)
    $fEdit.StartPosition = "CenterParent"
    $fEdit.BackColor = $global:theme.PanelBack
    $fEdit.ForeColor = $global:theme.TextMain
    $fEdit.FormBorderStyle = "FixedDialog"
    $fEdit.MaximizeBox = $false
    $fEdit.MinimizeBox = $false
    $fEdit.Text = if ($EditItem) { "Editar Arma: $($EditItem.NomeItem)" } else { "Adicionar Nova Arma" }

    # 2. Paineis
    $pnlContent = New-Object System.Windows.Forms.Panel; $pnlContent.Dock = "Fill"; $pnlContent.AutoScroll = $true; $pnlContent.Padding = New-Object System.Windows.Forms.Padding(0, 0, 0, 80)
    $fEdit.Controls.Add($pnlContent)

    $pnlButtons = New-Object System.Windows.Forms.Panel; $pnlButtons.Dock = "Bottom"; $pnlButtons.Height = 70; $pnlButtons.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $fEdit.Controls.Add($pnlButtons)

    # --- LAYOUT LOCAL ---
    $layout = @{ RowL = 0; RowR = 0; Col1_X = 30; Col2_X = 480; FieldWidth = 400; RowHeight = 65 }

    function Add-Field {
        param($LabelText, $Control, [int]$Column)
        $x = if ($Column -eq 1) { $layout.Col1_X } else { $layout.Col2_X }
        $r = if ($Column -eq 1) { $layout.RowL } else { $layout.RowR }
        $y = 20 + ($r * $layout.RowHeight)

        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $LabelText; $lbl.Location = "$x, $y"; $lbl.AutoSize = $true; $lbl.ForeColor = $global:theme.OrangeAccent
        $pnlContent.Controls.Add($lbl)
        
        if ($Control) {
            $Control.Location = "$x, $($y + 25)"; $Control.Size = "$($layout.FieldWidth), 30"
            $Control.BackColor = $global:theme.ButtonBack; $Control.ForeColor = $global:theme.TextMain
            if ($Control -is [System.Windows.Forms.TextBox]) { $Control.BorderStyle = "FixedSingle" }
            if ($Control -is [System.Windows.Forms.ComboBox]) { $Control.FlatStyle = "Flat" }
            $pnlContent.Controls.Add($Control)
        }
        
        $currentY = $y + 25
        if ($Column -eq 1) { $layout.RowL++ } else { $layout.RowR++ }
        return $currentY
    }

    # --- VALIDACAO ---
    function Add-Validation {
        param($Control, [string]$Mode)
        $Control.Tag = $Mode 
        
        $Control.ContextMenu = New-Object System.Windows.Forms.ContextMenu
        $Control.Add_KeyDown({
            if (($_.Control -and $_.KeyCode -eq 'V') -or ($_.Shift -and $_.KeyCode -eq 'Insert')) {
                $_.SuppressKeyPress = $true
            }
        })

        $kp = {
            $allowed = Test-KeyRestriction -Control $this -Char $_.KeyChar -Mode $this.Tag
            if (-not $allowed) { $_.Handled = $true } 
        }.GetNewClosure()
        $Control.Add_KeyPress($kp)
    }

    # --- HELPER PLACEHOLDER ---
    $placeholderText = "Selecione os dados aqui"
    
    function Setup-Combo {
        param($Combo, $Items, $IsMap=$false)
        $Combo.Items.Clear()
        $Combo.Items.Add($placeholderText) | Out-Null
        
        if ($IsMap) { foreach ($k in $Items.Keys) { $Combo.Items.Add($k)|Out-Null } }
        else { foreach ($i in $Items) { $Combo.Items.Add($i)|Out-Null } }
        
        $Combo.SelectedIndex = 0 
        
        $Combo.Add_DropDown({
            if ($this.Items.Count -gt 0 -and $this.Items[0] -eq "Selecione os dados aqui") {
                $this.Items.RemoveAt(0)
            }
        })
    }

    # --- MAPAS ---
    $classMap = [Ordered]@{ "Rifle de assalto"="ASSAULT RIFLE"; "Submetralhadora"="SUBMACHINE GUN"; "Carabina"="CARBINE"; "Fuzil DMR"="MARKSMAN RIFLE"; "Rifle de ferrolho"="BOLT-ACTION RIFLE"; "Escopeta"="SHOTGUN"; "Metralhadora leve"="LIGHT MACHINE GUN"; "Pistola"="PISTOL" }
    $powerMap = [Ordered]@{ "Baixo"="Low"; "Inferior"="Mid-Low"; "Médio"="Medium"; "Superior"="Mid-High"; "Alto"="High"; "Ultra-alto"="Ultra High" }
    
    $barrelCustomMap = [Ordered]@{ "Customização apenas"="Custom"; "Alcance"="R+"; "Dano"="D+"; "Alcance + Dano"="D+ R+"; "Padrão é o melhor (Default +)"="Default +" }
    $barrelFixedMap = [Ordered]@{ "Dano inalterado (Padrão)"="FB"; "Dano reduzido"="FB D-"; "Dano amplificado"="FB D+" }

    $modesFullData    = @("Selecione o modo aqui", "Semi", "Full", "2-RB", "3-RB", "Pump-Action", "Bolt-Action")
    $modesFullDisplay = @("Selecione o modo aqui", "Semi", "Auto", "2-RB", "3-RB", "Ação de Bombeamento", "Ação de Ferrolho")
    $modesRestrictedDisplay = @("Selecione o modo aqui", "Semi", "Auto", "2-RB", "3-RB")

    # ==========================
    # COLUNA 1 (Esquerda)
    # ==========================
    $txtName = New-Object System.Windows.Forms.TextBox; $txtName.MaxLength = 17; if ($EditItem) { $txtName.Text = $EditItem.NomeItem }
    Add-Field -LabelText "Qual é o nome da arma?" -Control $txtName -Column 1

    # 1. CLASSE (Com Placeholder)
    $cmbClass = New-Object System.Windows.Forms.ComboBox; $cmbClass.DropDownStyle = "DropDownList"
    Setup-Combo -Combo $cmbClass -Items $classMap -IsMap $true
    if ($EditItem) { $k = $classMap.Keys | Where {$classMap[$_] -eq $EditItem.Classe}; if($k){$cmbClass.SelectedItem=$k} }
    Add-Field -LabelText "Qual é a classe da arma?" -Control $cmbClass -Column 1

    # 2. CALIBRE (Com Placeholder)
    $cmbCaliber = New-Object System.Windows.Forms.ComboBox; $cmbCaliber.DropDownStyle = "DropDownList"
    $calPath = Join-Path (Get-DatabasePath) "Caliber.csv"
    $calList = @(); if (Test-Path $calPath) { $calList = @(Import-Csv $calPath -Delimiter ";" -Encoding UTF8 | Select -Expand CalibreName | Sort) }
    Setup-Combo -Combo $cmbCaliber -Items $calList
    if ($EditItem) { $cmbCaliber.SelectedItem = $EditItem.Calibre }
    Add-Field -LabelText "Qual é o calibre da arma?" -Control $cmbCaliber -Column 1

    # Stats Esquerda
    $leftStats = [Ordered]@{ 
        "Qual é o controle de recuo vertical?"   = @{ Prop="RecuoVertical";      Mode="numeric"; MaxLen=3 }
        "Qual é o controle de recuo horizontal?" = @{ Prop="RecuoHorizontal";    Mode="numeric"; MaxLen=3 } 
        "Qual é a ergonomia?"                    = @{ Prop="Ergonomia";          Mode="numeric"; MaxLen=3 }
        "Qual é a estabilidade de arma?"         = @{ Prop="EstabilidadeArma";   Mode="numeric"; MaxLen=3 }
        "Qual é a precisão?"                     = @{ Prop="Precisao";           Mode="numeric"; MaxLen=3 }
    }
    $txtStats = @{}
    foreach ($k in $leftStats.Keys) { $txt = New-Object System.Windows.Forms.TextBox; $txt.MaxLength = $leftStats[$k].MaxLen; Add-Validation -Control $txt -Mode $leftStats[$k].Mode; if ($EditItem) { $p = $leftStats[$k].Prop; $txt.Text = $EditItem.$p }; Add-Field -LabelText $k -Control $txt -Column 1; $txtStats[$k] = $txt }

    # ==========================
    # COLUNA 2 (Direita)
    # ==========================
    # Stats Direita
    $rightStats = [Ordered]@{
        "Qual é a estabilidade sem mirar?" = @{ Prop="EstabilidadeHipFire"; Mode="numeric"; MaxLen=3 }
        "Qual é a distância efetiva?"      = @{ Prop="Alcance";             Mode="numeric"; MaxLen=4 } 
        "Qual é a velocidade do bocal?"    = @{ Prop="VelocidadeBocal";     Mode="numeric"; MaxLen=4 }
    }
    foreach ($k in $rightStats.Keys) { $txt = New-Object System.Windows.Forms.TextBox; $txt.MaxLength = $rightStats[$k].MaxLen; Add-Validation -Control $txt -Mode $rightStats[$k].Mode; if ($EditItem) { $p = $rightStats[$k].Prop; $txt.Text = $EditItem.$p }; Add-Field -LabelText $k -Control $txt -Column 2; $txtStats[$k] = $txt }

    # --- MODOS DE DISPARO ---
    
    # 3. QUANTIDADE MODOS (Com Placeholder)
    $cmbModeQty = New-Object System.Windows.Forms.ComboBox; $cmbModeQty.DropDownStyle = "DropDownList"
    # Adiciona itens manualmente para controlar placeholder
    $cmbModeQty.Items.Add($placeholderText) | Out-Null
    $cmbModeQty.Items.AddRange(@("1", "2", "3"))
    $cmbModeQty.SelectedIndex = 0
    
    # Evento para remover placeholder
    $cmbModeQty.Add_DropDown({
        if ($this.Items.Count -gt 0 -and $this.Items[0] -eq "Selecione os dados aqui") {
            $this.Items.RemoveAt(0)
        }
    })

    $qtyY = Add-Field -LabelText "Quantos modos de disparo?" -Control $cmbModeQty -Column 2

    $pnlModes = New-Object System.Windows.Forms.FlowLayoutPanel
    $pnlModes.Location = "$($layout.Col2_X), $($qtyY + 40)"
    $pnlModes.Size = "$($layout.FieldWidth), 110"
    $pnlModes.FlowDirection = "TopDown"
    $pnlModes.WrapContents = $false
    $pnlModes.AutoSize = $true
    $pnlContent.Controls.Add($pnlModes)
    
    $layout.RowR += 2.4

    $dynamicModeCombos = New-Object System.Collections.ArrayList

    $refreshListsBlock = {
        # Se ainda estiver no placeholder, nao faz nada
        if ($cmbModeQty.SelectedItem -eq $placeholderText -or -not $cmbModeQty.SelectedItem) { return }

        $qty = [int]$cmbModeQty.SelectedItem
        $masterList = if ($qty -eq 1) { $modesFullDisplay } else { $modesRestrictedDisplay }

        foreach ($targetCB in $dynamicModeCombos) {
            $currentSelection = $targetCB.SelectedItem
            $usedByOthers = @()
            foreach ($otherCB in $dynamicModeCombos) {
                if ($otherCB -ne $targetCB -and $otherCB.SelectedItem -ne $null -and $otherCB.SelectedItem -ne "Selecione o modo aqui") {
                    $usedByOthers += $otherCB.SelectedItem
                }
            }
            $targetCB.Items.Clear()
            $targetCB.Items.Add("Selecione o modo aqui") | Out-Null
            foreach ($item in $masterList) {
                if ($item -ne "Selecione o modo aqui" -and $item -notin $usedByOthers) {
                    $targetCB.Items.Add($item) | Out-Null
                }
            }
            if ($currentSelection -and $targetCB.Items.Contains($currentSelection)) {
                $targetCB.SelectedItem = $currentSelection
            } else { $targetCB.SelectedIndex = 0 }
        }
    }.GetNewClosure()

    $modeQtyEvent = {
        # Se for placeholder, limpa tudo
        if ($cmbModeQty.SelectedItem -eq $placeholderText -or -not $cmbModeQty.SelectedItem) {
            $pnlModes.Controls.Clear(); $dynamicModeCombos.Clear(); return
        }

        $pnlModes.Controls.Clear()
        $dynamicModeCombos.Clear()
        $qty = [int]$cmbModeQty.SelectedItem
        
        $initialList = if ($qty -eq 1) { $modesFullDisplay } else { $modesRestrictedDisplay }
        
        for ($i = 0; $i -lt $qty; $i++) {
            $lbl = New-Object System.Windows.Forms.Label
            $lbl.Text = "Modo $($i+1):"; $lbl.AutoSize = $true; $lbl.ForeColor = $global:theme.TextDim
            $pnlModes.Controls.Add($lbl)

            $cb = New-Object System.Windows.Forms.ComboBox
            $cb.DropDownStyle = "DropDownList"; $cb.Width = 380; $cb.BackColor = $global:theme.ButtonBack; $cb.ForeColor = $global:theme.TextMain; $cb.FlatStyle = "Flat"
            
            $cb.Add_SelectionChangeCommitted($refreshListsBlock)
            
            foreach ($m in $initialList) { $cb.Items.Add($m) | Out-Null }
            $cb.SelectedIndex = 0 

            $pnlModes.Controls.Add($cb)
            $dynamicModeCombos.Add($cb) | Out-Null
        }
    }.GetNewClosure()

    $cmbModeQty.Add_SelectionChangeCommitted($modeQtyEvent)
    # Importante: Ocultar placeholder altera o index, entao usamos SelectionChangeCommitted

    if ($EditItem) {
        # [CORREÇÃO] Forçamos @() para garantir que seja array, mesmo com 1 item
        $curModes = @($EditItem.ModoDisparo -split "," | ForEach-Object { $_.Trim() })
        
        $qty = $curModes.Count
        if ($qty -gt 3) { $qty = 3 }
        if ($qty -lt 1) { $qty = 1 }
        
        # Remove placeholder antes de setar valor (pra nao bugar index)
        if ($cmbModeQty.Items[0] -eq $placeholderText) { $cmbModeQty.Items.RemoveAt(0) }
        
        # Seleciona a quantidade correta no combo
        $cmbModeQty.SelectedItem = "$qty" 
        
        # Dispara evento manualmente pra criar os combos dinâmicos
        & $modeQtyEvent
        
        for ($i = 0; $i -lt $qty; $i++) {
            $dataCode = $curModes[$i]
            $idx = $modesFullData.IndexOf($dataCode)
            
            # Se não achou pelo código exato, tenta achar pelo Display Name (fallback)
            if ($idx -lt 0) { $idx = $modesFullDisplay.IndexOf($dataCode) }

            if ($idx -ge 0) {
                $displayName = $modesFullDisplay[$idx]
                if ($i -lt $dynamicModeCombos.Count) { 
                    $dynamicModeCombos[$i].SelectedItem = $displayName 
                }
            }
        }
        & $refreshListsBlock
    }

    # Campos Finais
    $txtCad = New-Object System.Windows.Forms.TextBox; $txtCad.MaxLength = 4; Add-Validation -Control $txtCad -Mode "numeric"; if ($EditItem) { $txtCad.Text = $EditItem.Cadencia }
    Add-Field -LabelText "Qual é a cadência?" -Control $txtCad -Column 2; $txtStats["Qual é a cadência?"] = $txtCad

    # 4. PODER FOGO (Com Placeholder)
    $cmbPower = New-Object System.Windows.Forms.ComboBox; $cmbPower.DropDownStyle = "DropDownList"
    Setup-Combo -Combo $cmbPower -Items $powerMap -IsMap $true
    if ($EditItem) { $k = $powerMap.Keys | Where {$powerMap[$_] -eq $EditItem.PoderFogo}; if($k){$cmbPower.SelectedItem=$k} }
    Add-Field -LabelText "Poder de Fogo?" -Control $cmbPower -Column 2

    # --- CONFIGURACAO DO CANO ---
    $grpBarrel = New-Object System.Windows.Forms.GroupBox
    $grpBarrel.Text = "Configuração do Cano"
    $grpBarrel.ForeColor = $global:theme.OrangeAccent
    $grpY = 20 + ($layout.RowR * $layout.RowHeight)
    $grpBarrel.Location = "$($layout.Col2_X), $grpY"
    $grpBarrel.Size = "$($layout.FieldWidth), 110"
    $pnlContent.Controls.Add($grpBarrel)

    # [ALTERAÇÃO AQUI] Mensagem alterada conforme solicitado
    $lblQ1 = New-Object System.Windows.Forms.Label; $lblQ1.Text = "O cano pode ser mudado?"; $lblQ1.AutoSize = $true; $lblQ1.Location = "10, 20"; $lblQ1.ForeColor = $global:theme.TextMain
    $grpBarrel.Controls.Add($lblQ1)

    $rbYes = New-Object System.Windows.Forms.RadioButton; $rbYes.Text = "Sim"; $rbYes.Location = "220, 18"; $rbYes.AutoSize = $true; $rbYes.ForeColor = $global:theme.TextMain
    $rbNo = New-Object System.Windows.Forms.RadioButton; $rbNo.Text = "Não"; $rbNo.Location = "280, 18"; $rbNo.AutoSize = $true; $rbNo.ForeColor = $global:theme.TextMain
    $grpBarrel.Controls.Add($rbYes); $grpBarrel.Controls.Add($rbNo)

    $lblQ2 = New-Object System.Windows.Forms.Label; $lblQ2.Text = "Selecione o detalhe:"; $lblQ2.AutoSize = $true; $lblQ2.Location = "10, 50"; $lblQ2.ForeColor = $global:theme.TextMain
    $grpBarrel.Controls.Add($lblQ2)

    # 5. DETALHES CANO (Com Placeholder)
    $cmbBarrelDetails = New-Object System.Windows.Forms.ComboBox
    $cmbBarrelDetails.DropDownStyle = "DropDownList"; $cmbBarrelDetails.Location = "10, 70"; $cmbBarrelDetails.Width = 380; $cmbBarrelDetails.BackColor = $global:theme.ButtonBack; $cmbBarrelDetails.ForeColor = $global:theme.TextMain; $cmbBarrelDetails.FlatStyle = "Flat"
    $grpBarrel.Controls.Add($cmbBarrelDetails)
    
    # Evento do combo do cano
    $cmbBarrelDetails.Add_DropDown({
        if ($this.Items.Count -gt 0 -and $this.Items[0] -eq "Selecione os dados aqui") {
            $this.Items.RemoveAt(0)
        }
    })

    $updateBarrelUI = {
        $cmbBarrelDetails.Items.Clear()
        $cmbBarrelDetails.Items.Add($placeholderText) | Out-Null
        
        if ($rbYes.Checked) {
            $lblQ2.Text = "O que o cano pode melhorar?"
            foreach ($k in $barrelCustomMap.Keys) { $cmbBarrelDetails.Items.Add($k) | Out-Null }
        } else {
            $lblQ2.Text = "O cano fixo altera o dano?"
            foreach ($k in $barrelFixedMap.Keys) { $cmbBarrelDetails.Items.Add($k) | Out-Null }
        }
        $cmbBarrelDetails.SelectedIndex = 0
    }.GetNewClosure()

    $rbYes.Add_CheckedChanged({ if ($rbYes.Checked) { & $updateBarrelUI } })
    $rbNo.Add_CheckedChanged({ if ($rbNo.Checked) { & $updateBarrelUI } })

    # Carregar Cano na Edicao
    if ($EditItem) {
        $code = $EditItem.TipoCano
        $foundCustom = $barrelCustomMap.Keys | Where-Object { $barrelCustomMap[$_] -eq $code }
        if ($foundCustom) {
            $rbYes.Checked = $true; & $updateBarrelUI
            if ($cmbBarrelDetails.Items[0] -eq $placeholderText) { $cmbBarrelDetails.Items.RemoveAt(0) }
            $cmbBarrelDetails.SelectedItem = $foundCustom
        } else {
            $foundFixed = $barrelFixedMap.Keys | Where-Object { $barrelFixedMap[$_] -eq $code }
            if ($foundFixed) { 
                $rbNo.Checked = $true; & $updateBarrelUI
                if ($cmbBarrelDetails.Items[0] -eq $placeholderText) { $cmbBarrelDetails.Items.RemoveAt(0) }
                $cmbBarrelDetails.SelectedItem = $foundFixed 
            } 
            else { $rbNo.Checked = $true; & $updateBarrelUI }
        }
    } else { $rbNo.Checked = $true; & $updateBarrelUI }

    $lblSpacer = New-Object System.Windows.Forms.Label; $lblSpacer.Location = "0, $($layout.RowR * $layout.RowHeight + 150)"; $lblSpacer.Height = 10; $pnlContent.Controls.Add($lblSpacer)

    # --- BOTOES ---
    $btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = "Salvar"; $btnSave.Location = "330, 15"; $btnSave.Size = "120, 40"; $btnSave.FlatStyle = "Flat"; $btnSave.BackColor = $global:theme.GreenSuccess; $btnSave.ForeColor = $global:theme.Background
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Cancelar"; $btnCancel.Location = "500, 15"; $btnCancel.Size = "120, 40"; $btnCancel.FlatStyle = "Flat"; $btnCancel.BackColor = $global:theme.ButtonBack; $btnCancel.ForeColor = $global:theme.TextMain
    $pnlButtons.Controls.AddRange(@($btnSave, $btnCancel)); $fEdit.AcceptButton = $btnSave; $fEdit.CancelButton = $btnCancel

    # --- SALVAR ---
    $btnSave.Add_Click({
        $isValid = $true 

        if ([string]::IsNullOrWhiteSpace($txtName.Text)) { $isValid = $false }
        
        if ($isValid) {
            foreach ($key in $txtStats.Keys) {
                if ([string]::IsNullOrWhiteSpace($txtStats[$key].Text)) { $isValid = $false; break }
            }
        }

        # Valida Placeholders
        if ($isValid) {
            if (-not $cmbClass.SelectedItem -or $cmbClass.SelectedItem -eq $placeholderText) { $isValid = $false }
            elseif (-not $cmbCaliber.SelectedItem -or $cmbCaliber.SelectedItem -eq $placeholderText) { $isValid = $false }
            elseif (-not $cmbPower.SelectedItem -or $cmbPower.SelectedItem -eq $placeholderText) { $isValid = $false }
            elseif (-not $cmbBarrelDetails.SelectedItem -or $cmbBarrelDetails.SelectedItem -eq $placeholderText) { $isValid = $false }
            elseif (-not $cmbModeQty.SelectedItem -or $cmbModeQty.SelectedItem -eq $placeholderText) { $isValid = $false }
        }

        if ($isValid) {
            foreach ($cb in $dynamicModeCombos) {
                if (-not $cb.SelectedItem -or $cb.SelectedItem -eq "Selecione o modo aqui") {
                    $isValid = $false; break
                }
            }
        }

        if (-not $isValid) { [System.Windows.Forms.MessageBox]::Show("Complete o formulário corretamente.`nVerifique se não há campos vazios ou 'Selecione os dados aqui'.", "Erro", "OK", "Warning"); return }

        $csvPath = Join-Path (Get-DatabasePath) "Weapons.csv"
        $allWeapons = @(); if (Test-Path $csvPath) { $allWeapons = @(Import-Csv $csvPath -Delimiter ";" -Encoding UTF8) }
        $newName = $txtName.Text.Trim()
        
        if ((-not $EditItem) -or ($EditItem.NomeItem -ne $newName)) { 
            if ($allWeapons.NomeItem -contains $newName) { [System.Windows.Forms.MessageBox]::Show("Nome já existe!", "Erro", "OK", "Error"); return } 
        }

        $finalModesData = @()
        foreach ($cb in $dynamicModeCombos) {
            $idx = $modesFullDisplay.IndexOf($cb.SelectedItem)
            if ($idx -ge 0) { $finalModesData += $modesFullData[$idx] }
        }
        
        $barrelCode = ""
        if ($rbYes.Checked) { $barrelCode = $barrelCustomMap[$cmbBarrelDetails.SelectedItem] } 
        else { $barrelCode = $barrelFixedMap[$cmbBarrelDetails.SelectedItem] }

        $newItemData = [Ordered]@{
            NomeItem = $newName; Classe = $classMap[$cmbClass.SelectedItem]; Calibre = $cmbCaliber.SelectedItem
            RecuoVertical = $txtStats["Qual é o controle de recuo vertical?"].Text; RecuoHorizontal = $txtStats["Qual é o controle de recuo horizontal?"].Text
            Ergonomia = $txtStats["Qual é a ergonomia?"].Text; Precisao = $txtStats["Qual é a precisão?"].Text
            EstabilidadeHipFire = $txtStats["Qual é a estabilidade sem mirar?"].Text; Alcance = $txtStats["Qual é a distância efetiva?"].Text
            VelocidadeBocal = $txtStats["Qual é a velocidade do bocal?"].Text; 
            ModoDisparo = ($finalModesData -join ", ")
            Cadencia = $txtStats["Qual é a cadência?"].Text; PoderFogo = $powerMap[$cmbPower.SelectedItem]
            TipoCano = $barrelCode; EstabilidadeArma = $txtStats["Qual é a estabilidade de arma?"].Text
        }

        if ($EditItem) { for ($i = 0; $i -lt $allWeapons.Count; $i++) { if ($allWeapons[$i].NomeItem -eq $EditItem.NomeItem) { $allWeapons[$i] = [PSCustomObject]$newItemData; break } } } else { $allWeapons += [PSCustomObject]$newItemData }
        $allWeapons | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8; $fEdit.DialogResult = "OK"; $fEdit.Close()
    })

    $fEdit.ShowDialog() | Out-Null
    
    # --- CORREÇÃO MEMORY LEAK: Liberta os recursos da janela da RAM ---
    $fEdit.Dispose()
}

function Start-AmmoEditor {
    param (
        $ui,
        $EditItem = $null
    )

    # 1. Janela Popup
    $fEdit = New-Object System.Windows.Forms.Form
    $fEdit.Size = New-Object System.Drawing.Size(950, 750)
    $fEdit.StartPosition = "CenterParent"
    $fEdit.BackColor = $global:theme.PanelBack
    $fEdit.ForeColor = $global:theme.TextMain
    $fEdit.FormBorderStyle = "FixedDialog"
    $fEdit.MaximizeBox = $false
    $fEdit.MinimizeBox = $false
    $fEdit.Text = if ($EditItem) { "Editar Munição: $($EditItem.NomeItem)" } else { "Adicionar Nova Munição" }

    # 2. Paineis
    $pnlContent = New-Object System.Windows.Forms.Panel; $pnlContent.Dock = "Fill"; $pnlContent.AutoScroll = $true; $pnlContent.Padding = New-Object System.Windows.Forms.Padding(0, 0, 0, 80)
    $fEdit.Controls.Add($pnlContent)

    $pnlButtons = New-Object System.Windows.Forms.Panel; $pnlButtons.Dock = "Bottom"; $pnlButtons.Height = 70; $pnlButtons.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $fEdit.Controls.Add($pnlButtons)

    # --- LAYOUT LOCAL ---
    $layout = @{ RowL = 0; RowR = 0; Col1_X = 30; Col2_X = 480; FieldWidth = 400; RowHeight = 65 }

    function Add-Field {
        param($LabelText, $Control, [int]$Column)
        $x = if ($Column -eq 1) { $layout.Col1_X } else { $layout.Col2_X }
        $r = if ($Column -eq 1) { $layout.RowL } else { $layout.RowR }
        $y = 20 + ($r * $layout.RowHeight)

        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $LabelText; $lbl.Location = "$x, $y"; $lbl.AutoSize = $true; $lbl.ForeColor = $global:theme.OrangeAccent
        $pnlContent.Controls.Add($lbl)
        
        if ($Control) {
            $Control.Location = "$x, $($y + 25)"; $Control.Size = "$($layout.FieldWidth), 30"
            $Control.BackColor = $global:theme.ButtonBack; $Control.ForeColor = $global:theme.TextMain
            if ($Control -is [System.Windows.Forms.TextBox]) { $Control.BorderStyle = "FixedSingle" }
            if ($Control -is [System.Windows.Forms.ComboBox]) { $Control.FlatStyle = "Flat" }
            $pnlContent.Controls.Add($Control)
        }
        
        $currentY = $y + 25
        if ($Column -eq 1) { $layout.RowL++ } else { $layout.RowR++ }
        return $currentY
    }

    # --- VALIDACAO (INTEGRADA COM BLOQUEIO DE COLAGEM) ---
    function Add-Validation {
        param($Control, [string]$Mode)
        $Control.Tag = $Mode 
        
        # 1. Bloqueia Menu de Contexto (Botão Direito)
        $Control.ContextMenu = New-Object System.Windows.Forms.ContextMenu

        # 2. Bloqueia Ctrl+V e Shift+Insert (Colagem via Teclado)
        $Control.Add_KeyDown({
            if (($_.Control -and $_.KeyCode -eq 'V') -or ($_.Shift -and $_.KeyCode -eq 'Insert')) {
                $_.SuppressKeyPress = $true
            }
        })

        # 3. Validação caractere a caractere (Existente)
        $kp = {
            $allowed = Test-KeyRestriction -Control $this -Char $_.KeyChar -Mode $this.Tag
            if (-not $allowed) { $_.Handled = $true } 
        }.GetNewClosure()
        $Control.Add_KeyPress($kp)
    }

    # --- [NOVO] HELPER PLACEHOLDER ---
    $placeholderText = "Selecione os dados aqui"
    
    function Setup-Combo {
        param($Combo, $Items, $IsMap=$false)
        $Combo.Items.Clear()
        $Combo.Items.Add($placeholderText) | Out-Null
        
        if ($IsMap) { foreach ($k in $Items.Keys) { $Combo.Items.Add($k)|Out-Null } }
        else { foreach ($i in $Items) { $Combo.Items.Add($i)|Out-Null } }
        
        $Combo.SelectedIndex = 0 
        
        $Combo.Add_DropDown({
            if ($this.Items.Count -gt 0 -and $this.Items[0] -eq "Selecione os dados aqui") {
                $this.Items.RemoveAt(0)
            }
        })
    }

    # --- DADOS E MAPAS ---
    $woundMap = [Ordered]@{
        "Não sei ou o jogo não informa" = "//////"
        "Baixo"                         = "Low"
        "Médio"                         = "Medium"
        "Alto"                          = "High"
    }

    # ==========================
    # COLUNA 1 (Esquerda)
    # ==========================
     
    # 1. Nome
    $txtName = New-Object System.Windows.Forms.TextBox; $txtName.MaxLength = 19
    if ($EditItem) { $txtName.Text = $EditItem.NomeItem }
    Add-Field -LabelText "Qual é o nome da munição:" -Control $txtName -Column 1

    # 2. Calibre
    $cmbCaliber = New-Object System.Windows.Forms.ComboBox; $cmbCaliber.DropDownStyle = "DropDownList"
    $calPath = Join-Path (Get-DatabasePath) "Caliber.csv"
    $calList = @()
    if (Test-Path $calPath) { 
        $calList = @(Import-Csv $calPath -Delimiter ";" -Encoding UTF8 | Select -Expand CalibreName | Sort)
    }
    
    Setup-Combo -Combo $cmbCaliber -Items $calList
    
    if ($EditItem) { $cmbCaliber.SelectedItem = $EditItem.Calibre }
    
    Add-Field -LabelText "Qual é o calibre dessa munição?" -Control $cmbCaliber -Column 1

    # 3. Nível de Penetração (0-7)
    $txtPenLevel = New-Object System.Windows.Forms.TextBox; $txtPenLevel.MaxLength = 1
    Add-Validation -Control $txtPenLevel -Mode "penetration"
    if ($EditItem) { $txtPenLevel.Text = $EditItem.NivelPenetracao } 
    Add-Field -LabelText "Nível de penetração (0-7):" -Control $txtPenLevel -Column 1

    # 4. Valor de Penetração
    $txtPenVal = New-Object System.Windows.Forms.TextBox; $txtPenVal.MaxLength = 2
    Add-Validation -Control $txtPenVal -Mode "numeric"
    if ($EditItem) { $txtPenVal.Text = $EditItem.Penetracao }
    Add-Field -LabelText "Valor de penetração:" -Control $txtPenVal -Column 1

    # 5. Dano Base (Lógica Estrita + Feedback Visual)
    $txtBaseDmg = New-Object System.Windows.Forms.TextBox
    Add-Validation -Control $txtBaseDmg -Mode "ammo_damage_strict"
    $txtBaseDmg.Add_Leave({
        $val = $this.Text.Trim()
        if ($val -match '^(\d+)\s*[xX]\s*(\d+)$') {
            $dmgA = [int]$Matches[1]; $dmgB = [int]$Matches[2]
            $total = $dmgA * $dmgB
            $this.Text = "$val ($total)"
        }
    }.GetNewClosure())

    if ($EditItem) { $txtBaseDmg.Text = $EditItem.DanoBase }
    Add-Field -LabelText "Dano Base (Formatos: 274 ou 26x8):" -Control $txtBaseDmg -Column 1

    # ==========================
    # COLUNA 2 (Direita)
    # ==========================

    # 1. Dano de Blindagem
    $txtArmorDmg = New-Object System.Windows.Forms.TextBox; $txtArmorDmg.MaxLength = 4
    Add-Validation -Control $txtArmorDmg -Mode "armor"
    if ($EditItem) { $txtArmorDmg.Text = $EditItem.DanoBlindagem }
    Add-Field -LabelText "Dano de blindagem:" -Control $txtArmorDmg -Column 2

    # 2. Velocidade
    $txtVelocity = New-Object System.Windows.Forms.TextBox; $txtVelocity.MaxLength = 4
    Add-Validation -Control $txtVelocity -Mode "numeric"
    if ($EditItem) { $txtVelocity.Text = $EditItem.Velocidade }
    Add-Field -LabelText "Velocidade (m/s):" -Control $txtVelocity -Column 2

    # 3. Precisão
    $txtAccuracy = New-Object System.Windows.Forms.TextBox; $txtAccuracy.MaxLength = 3 
    Add-Validation -Control $txtAccuracy -Mode "precision"
    if ($EditItem) { $txtAccuracy.Text = $EditItem.Precisao }
    Add-Field -LabelText "Precisão (Formato: +NÚMEROS):" -Control $txtAccuracy -Column 2

    # 4. Recuo Vertical
    $txtRecVert = New-Object System.Windows.Forms.TextBox; $txtRecVert.MaxLength = 3
    Add-Validation -Control $txtRecVert -Mode "recoil"
    if ($EditItem) { $txtRecVert.Text = $EditItem.RecuoVertical }
    Add-Field -LabelText "Recuo Vertical (Formato: +NÚMEROS, -NÚMEROS ou 0):" -Control $txtRecVert -Column 2

    # 5. Recuo Horizontal
    $txtRecHorz = New-Object System.Windows.Forms.TextBox; $txtRecHorz.MaxLength = 3
    Add-Validation -Control $txtRecHorz -Mode "recoil"
    if ($EditItem) { $txtRecHorz.Text = $EditItem.RecuoHorizontal }
    Add-Field -LabelText "Recuo Horizontal (Formato: +NÚMEROS, -NÚMEROS ou 0):" -Control $txtRecHorz -Column 2

    # 6. Chance de Ferir
    $cmbWound = New-Object System.Windows.Forms.ComboBox; $cmbWound.DropDownStyle = "DropDownList"
    
    Setup-Combo -Combo $cmbWound -Items $woundMap -IsMap $true
    
    if ($EditItem) { 
        $foundWound = $woundMap.Keys | Where-Object { $woundMap[$_] -eq $EditItem.ChanceFerir }
        if ($foundWound) { $cmbWound.SelectedItem = $foundWound }
    }
    Add-Field -LabelText "Chance de ferir?" -Control $cmbWound -Column 2

    $lblSpacer = New-Object System.Windows.Forms.Label; $lblSpacer.Location = "0, $($layout.RowR * $layout.RowHeight + 100)"; $lblSpacer.Height = 10; $pnlContent.Controls.Add($lblSpacer)

    # --- BOTOES ---
    $btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = "Salvar"; $btnSave.Location = "330, 15"; $btnSave.Size = "120, 40"; $btnSave.FlatStyle = "Flat"; $btnSave.BackColor = $global:theme.GreenSuccess; $btnSave.ForeColor = $global:theme.Background
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Cancelar"; $btnCancel.Location = "500, 15"; $btnCancel.Size = "120, 40"; $btnCancel.FlatStyle = "Flat"; $btnCancel.BackColor = $global:theme.ButtonBack; $btnCancel.ForeColor = $global:theme.TextMain
    $pnlButtons.Controls.AddRange(@($btnSave, $btnCancel)); $fEdit.AcceptButton = $btnSave; $fEdit.CancelButton = $btnCancel

    # --- SALVAR ---
    $btnSave.Add_Click({
        $isValid = $true

        # 1. Validacao de Campos Obrigatorios
        if ([string]::IsNullOrWhiteSpace($txtName.Text)) { $isValid = $false }
        
        # Validação de Combo Calibre (Placeholder)
        if (-not $cmbCaliber.SelectedItem -or $cmbCaliber.SelectedItem -eq $placeholderText) { $isValid = $false }
        
        # Valida TextBoxes Genericos
        $allTextBoxes = @($txtPenLevel, $txtPenVal, $txtBaseDmg, $txtArmorDmg, $txtVelocity, $txtAccuracy, $txtRecVert, $txtRecHorz)
        foreach ($ctrl in $allTextBoxes) {
            if ([string]::IsNullOrWhiteSpace($ctrl.Text)) { $isValid = $false; break }
        }

        # Validação de Combo Chance Ferir (Placeholder)
        if (-not $cmbWound.SelectedItem -or $cmbWound.SelectedItem -eq $placeholderText) { $isValid = $false }

        if (-not $isValid) { [System.Windows.Forms.MessageBox]::Show("Complete o formulário corretamente.`nVerifique se não há campos vazios ou 'Selecione os dados aqui'.", "Erro", "OK", "Warning"); return }

        # 2. Check Duplicata (Nome + Calibre)
        $csvPath = Join-Path (Get-DatabasePath) "Ammo.csv"
        $allAmmo = @(); if (Test-Path $csvPath) { $allAmmo = @(Import-Csv $csvPath -Delimiter ";" -Encoding UTF8) }
        
        $newName = $txtName.Text.Trim()
        $newCaliber = $cmbCaliber.SelectedItem

        if ((-not $EditItem) -or ($EditItem.NomeItem -ne $newName) -or ($EditItem.Calibre -ne $newCaliber)) {
            foreach ($item in $allAmmo) {
                if ($item.NomeItem -eq $newName -and $item.Calibre -eq $newCaliber) {
                    [System.Windows.Forms.MessageBox]::Show("Munição já existe para este calibre!", "Erro", "OK", "Error"); return
                }
            }
        }

        # 3. Processamento Final (Calcula dano se ainda não foi calculado)
        $finalBaseDmg = $txtBaseDmg.Text.Trim()
        if ($finalBaseDmg -match '^(\d+)\s*[xX]\s*(\d+)$') {
            $dmgA = [int]$Matches[1]; $dmgB = [int]$Matches[2]
            $total = $dmgA * $dmgB
            $finalBaseDmg = "$finalBaseDmg ($total)"
        }

        # 4. Criar Objeto
        $newItemData = [Ordered]@{
            NomeItem        = $newName
            Calibre         = $newCaliber
            DanoBase        = $finalBaseDmg
            DanoBlindagem   = $txtArmorDmg.Text
            Penetracao      = $txtPenVal.Text
            Velocidade      = $txtVelocity.Text
            Precisao        = $txtAccuracy.Text
            RecuoVertical   = $txtRecVert.Text
            RecuoHorizontal = $txtRecHorz.Text
            NivelPenetracao = $txtPenLevel.Text
            ChanceFerir     = $woundMap[$cmbWound.SelectedItem]
        }

        # 5. Salvar/Atualizar CSV
        if ($EditItem) {
            for ($i = 0; $i -lt $allAmmo.Count; $i++) {
                if ($allAmmo[$i].NomeItem -eq $EditItem.NomeItem -and $allAmmo[$i].Calibre -eq $EditItem.Calibre) {
                    $allAmmo[$i] = [PSCustomObject]$newItemData
                    break
                }
            }
        } else {
            $allAmmo += [PSCustomObject]$newItemData
        }

        $allAmmo | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
        $fEdit.DialogResult = "OK"
        $fEdit.Close()
    })

    $fEdit.ShowDialog() | Out-Null
    
    # --- CORREÇÃO MEMORY LEAK: Limpeza segura do Form de Edição ---
    $fEdit.Dispose()
}

function Start-ThrowableEditor {
    param (
        $ui,
        $EditItem = $null
    )

    # 1. Configuração da Janela
    $fEdit = New-Object System.Windows.Forms.Form
    $fEdit.Size = New-Object System.Drawing.Size(950, 750)
    $fEdit.StartPosition = "CenterParent"
    $fEdit.BackColor = $global:theme.PanelBack
    $fEdit.ForeColor = $global:theme.TextMain
    $fEdit.FormBorderStyle = "FixedDialog"
    $fEdit.MaximizeBox = $false
    $fEdit.MinimizeBox = $false
    $fEdit.Text = if ($EditItem) { "Editar Arremessável: $($EditItem.NomeItem)" } else { "Adicionar Novo Arremessável" }

    # 2. Paineis
    $pnlContent = New-Object System.Windows.Forms.Panel; $pnlContent.Dock = "Fill"; $pnlContent.AutoScroll = $true; $pnlContent.Padding = New-Object System.Windows.Forms.Padding(0, 0, 0, 80)
    $fEdit.Controls.Add($pnlContent)

    $pnlButtons = New-Object System.Windows.Forms.Panel; $pnlButtons.Dock = "Bottom"; $pnlButtons.Height = 70; $pnlButtons.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $fEdit.Controls.Add($pnlButtons)

    # --- LAYOUT ---
    $layout = @{ RowL = 0; RowR = 0; Col1_X = 30; Col2_X = 480; FieldWidth = 400; RowHeight = 65 }

    function Add-Field {
        param($LabelText, $Control, [int]$Column)
        $x = if ($Column -eq 1) { $layout.Col1_X } else { $layout.Col2_X }
        $r = if ($Column -eq 1) { $layout.RowL } else { $layout.RowR }
        $y = 20 + ($r * $layout.RowHeight)

        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $LabelText; $lbl.Location = "$x, $y"; $lbl.AutoSize = $true; $lbl.ForeColor = $global:theme.OrangeAccent
        $pnlContent.Controls.Add($lbl)
        
        if ($Control) {
            $Control.Location = "$x, $($y + 25)"; $Control.Size = "$($layout.FieldWidth), 30"
            $Control.BackColor = $global:theme.ButtonBack; $Control.ForeColor = $global:theme.TextMain
            if ($Control -is [System.Windows.Forms.TextBox]) { $Control.BorderStyle = "FixedSingle" }
            if ($Control -is [System.Windows.Forms.ComboBox]) { $Control.FlatStyle = "Flat" }
            $pnlContent.Controls.Add($Control)
        }
        
        if ($Column -eq 1) { $layout.RowL++ } else { $layout.RowR++ }
    }

    # --- VALIDACAO ---
    function Add-Validation {
        param($Control, [string]$Mode)
        $Control.Tag = $Mode 
        $Control.ContextMenu = New-Object System.Windows.Forms.ContextMenu
        $Control.Add_KeyDown({
            if (($_.Control -and $_.KeyCode -eq 'V') -or ($_.Shift -and $_.KeyCode -eq 'Insert')) {
                $_.SuppressKeyPress = $true
            }
        })
        $kp = {
            $allowed = Test-KeyRestriction -Control $this -Char $_.KeyChar -Mode $this.Tag
            if (-not $allowed) { $_.Handled = $true } 
        }.GetNewClosure()
        $Control.Add_KeyPress($kp)
    }

    # --- HELPER DE PLACEHOLDER ---
    $placeholderText = "Selecione os dados aqui"
    
    function Setup-Combo {
        param($Combo, $Map)
        $Combo.Items.Clear()
        $Combo.Items.Add($placeholderText) | Out-Null
        foreach ($k in $Map.Keys) { $Combo.Items.Add($k)|Out-Null }
        $Combo.SelectedIndex = 0 
        
        # Evento para ocultar o placeholder ao clicar
        $Combo.Add_DropDown({
            if ($this.Items.Count -gt 0 -and $this.Items[0] -eq "Selecione os dados aqui") {
                $this.Items.RemoveAt(0)
            }
        })
    }

    # --- MAPAS DE DADOS ---
    $rangeMap = [Ordered]@{ "Padrão"="Standard"; "Longo"="Large"; "Muito longo"="Very Large"; "Não é informado"="/////" }
    $levelMap = [Ordered]@{ "Padrão"="Standard"; "Superior"="Mid-High"; "Não é informado"="/////" } 
    $fragQtyMap = [Ordered]@{ "Pequeno"="Small"; "Grande"="Large"; "Não é informado"="/////" }
    $fragTypeMap = [Ordered]@{ "Peça de aço"="Steel Piece"; "Peça de ferro"="Iron Piece"; "Não é informado"="/////" }

    # ==========================
    # COLUNA 1
    # ==========================

    # 1. Nome
    $txtName = New-Object System.Windows.Forms.TextBox; $txtName.MaxLength = 23
    if ($EditItem) { $txtName.Text = $EditItem.NomeItem }
    Add-Field -LabelText "Qual é o nome do arremessável?" -Control $txtName -Column 1

    # [NOVO] Painel de Pergunta sobre Delay
    $grpDelayQ = New-Object System.Windows.Forms.Panel; $grpDelayQ.Height=30; $grpDelayQ.Width=400
    $rbDelayYes = New-Object System.Windows.Forms.RadioButton; $rbDelayYes.Text="Sim"; $rbDelayYes.Location="0,5"; $rbDelayYes.Width=50; $rbDelayYes.ForeColor=$global:theme.TextMain
    $rbDelayNo = New-Object System.Windows.Forms.RadioButton; $rbDelayNo.Text="Não"; $rbDelayNo.Location="60,5"; $rbDelayNo.Width=50; $rbDelayNo.ForeColor=$global:theme.TextMain
    $grpDelayQ.Controls.AddRange(@($rbDelayYes, $rbDelayNo))
    
    Add-Field -LabelText "O arremessável tem delay de explosão?" -Control $grpDelayQ -Column 1

    # 2. Delay 1
    $txtDelay1 = New-Object System.Windows.Forms.TextBox; $txtDelay1.MaxLength = 4
    Add-Validation -Control $txtDelay1 -Mode "decimal_fixed"
    Add-Field -LabelText "Qual é o primeiro delay de explosão? (ex: 1.2)" -Control $txtDelay1 -Column 1

    # 3. Delay 2
    $txtDelay2 = New-Object System.Windows.Forms.TextBox; $txtDelay2.MaxLength = 4
    Add-Validation -Control $txtDelay2 -Mode "decimal_fixed"
    Add-Field -LabelText "Qual é o segundo delay de explosão? (ex: 1.3)" -Control $txtDelay2 -Column 1

    # Lógica de Controle dos Campos de Delay
    $toggleDelayFields = {
        if ($rbDelayNo.Checked) {
            $txtDelay1.Text = "0.0"
            $txtDelay2.Text = "0.0"
            $txtDelay1.Enabled = $false
            $txtDelay2.Enabled = $false
            $txtDelay1.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
            $txtDelay2.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
        } else {
            $txtDelay1.Enabled = $true
            $txtDelay2.Enabled = $true
            $txtDelay1.BackColor = $global:theme.ButtonBack
            $txtDelay2.BackColor = $global:theme.ButtonBack
            # Limpa se for 0.0 apenas para facilitar a edicao, senao mantem o valor
            if ($txtDelay1.Text -eq "0.0") { $txtDelay1.Text = "" }
            if ($txtDelay2.Text -eq "0.0") { $txtDelay2.Text = "" }
        }
    }.GetNewClosure()

    $rbDelayYes.Add_CheckedChanged($toggleDelayFields)
    $rbDelayNo.Add_CheckedChanged($toggleDelayFields)

    # Preencher valores ao carregar
    if ($EditItem -and $EditItem.DelayExplosao) {
        $parts = $EditItem.DelayExplosao -split ' - '
        $val1 = if ($parts.Count -ge 1) { $parts[0] } else { "" }
        $val2 = if ($parts.Count -ge 2) { $parts[1] } else { "" }
        
        $txtDelay1.Text = $val1
        $txtDelay2.Text = $val2

        # Se ambos forem 0.0, marca como Não, caso contrario Sim
        if ($val1 -eq "0.0" -and $val2 -eq "0.0") {
            $rbDelayNo.Checked = $true
        } else {
            $rbDelayYes.Checked = $true
        }
    } else {
        # Padrão para novo item: Sim (comportamento padrao antigo) ou Não? Vamos deixar Sim para nao bloquear sem querer.
        $rbDelayYes.Checked = $true 
    }
    
    # Executa a logica visual inicial baseada no check
    & $toggleDelayFields

    # 4. Alcance (Com Placeholder)
    $cmbRange = New-Object System.Windows.Forms.ComboBox; $cmbRange.DropDownStyle = "DropDownList"
    Setup-Combo -Combo $cmbRange -Map $rangeMap
    if ($EditItem) { 
        $k = $rangeMap.Keys | Where {$rangeMap[$_] -eq $EditItem.Alcance}
        if($k){$cmbRange.SelectedItem=$k}
    }
    Add-Field -LabelText "Qual é o alcance efetivo?" -Control $cmbRange -Column 1

    # 5. Dano Blindagem
    $cmbArmorDmg = New-Object System.Windows.Forms.ComboBox; $cmbArmorDmg.DropDownStyle = "DropDownList"
    Setup-Combo -Combo $cmbArmorDmg -Map $levelMap
    if ($EditItem) { 
        $k = $levelMap.Keys | Where {$levelMap[$_] -eq $EditItem.DanoBlindagem}
        if($k){$cmbArmorDmg.SelectedItem=$k}
    }
    Add-Field -LabelText "Qual é o dano de blindagem?" -Control $cmbArmorDmg -Column 1

    # ==========================
    # COLUNA 2
    # ==========================

    # 6. Penetração
    $cmbPen = New-Object System.Windows.Forms.ComboBox; $cmbPen.DropDownStyle = "DropDownList"
    Setup-Combo -Combo $cmbPen -Map $levelMap
    if ($EditItem) { 
        $k = $levelMap.Keys | Where {$levelMap[$_] -eq $EditItem.Penetracao}
        if($k){$cmbPen.SelectedItem=$k}
    }
    Add-Field -LabelText "Qual é o efeito de penetração?" -Control $cmbPen -Column 2

    # 7. Fragmentos
    $cmbFrags = New-Object System.Windows.Forms.ComboBox; $cmbFrags.DropDownStyle = "DropDownList"
    Setup-Combo -Combo $cmbFrags -Map $fragQtyMap
    if ($EditItem) { 
        $k = $fragQtyMap.Keys | Where {$fragQtyMap[$_] -eq $EditItem.Fragmentos}
        if($k){$cmbFrags.SelectedItem=$k}
    }
    Add-Field -LabelText "Qual é a quantidade de fragmentos?" -Control $cmbFrags -Column 2

    # 8. Tipo Fragmentos
    $cmbFragType = New-Object System.Windows.Forms.ComboBox; $cmbFragType.DropDownStyle = "DropDownList"
    Setup-Combo -Combo $cmbFragType -Map $fragTypeMap
    if ($EditItem) { 
        $k = $fragTypeMap.Keys | Where {$fragTypeMap[$_] -eq $EditItem.TipoFragmento}
        if($k){$cmbFragType.SelectedItem=$k}
    }
    Add-Field -LabelText "Qual é o tipo de fragmentos?" -Control $cmbFragType -Column 2

    # 9. Tempo de Efeito
    $txtEffect = New-Object System.Windows.Forms.TextBox; $txtEffect.MaxLength = 4
    Add-Validation -Control $txtEffect -Mode "decimal_fixed"
    if ($EditItem) { $txtEffect.Text = $EditItem.TempoEfeito }
    Add-Field -LabelText "Qual é o tempo de efeito? (ex: 12.3)" -Control $txtEffect -Column 2

    # --- EVENTO INTELIGENTE DE RESET EM GRUPO ---
    # Se qualquer um dos 4 campos for definido como "Não é informado", TODOS viram "Não é informado"
    $resetLogic = {
        if ($this.SelectedItem -eq "Não é informado") {
            $cmbArmorDmg.SelectedItem  = "Não é informado"
            $cmbPen.SelectedItem       = "Não é informado"
            $cmbFrags.SelectedItem     = "Não é informado"
            $cmbFragType.SelectedItem  = "Não é informado"
        }
    }.GetNewClosure()

    # Aplica o evento a todos os 4 campos
    $cmbArmorDmg.Add_SelectionChangeCommitted($resetLogic)
    $cmbPen.Add_SelectionChangeCommitted($resetLogic)
    $cmbFrags.Add_SelectionChangeCommitted($resetLogic)
    $cmbFragType.Add_SelectionChangeCommitted($resetLogic)

    # --- BOTOES ---
    $btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = "Salvar"; $btnSave.Location = "330, 15"; $btnSave.Size = "120, 40"; $btnSave.FlatStyle = "Flat"; $btnSave.BackColor = $global:theme.GreenSuccess; $btnSave.ForeColor = $global:theme.Background
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Cancelar"; $btnCancel.Location = "500, 15"; $btnCancel.Size = "120, 40"; $btnCancel.FlatStyle = "Flat"; $btnCancel.BackColor = $global:theme.ButtonBack; $btnCancel.ForeColor = $global:theme.TextMain
    $pnlButtons.Controls.AddRange(@($btnSave, $btnCancel)); $fEdit.AcceptButton = $btnSave; $fEdit.CancelButton = $btnCancel

    # --- LOGICA SALVAR ---
    $btnSave.Add_Click({
        $isValid = $true
        
        if ([string]::IsNullOrWhiteSpace($txtName.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtDelay1.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtDelay2.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtEffect.Text)) { $isValid = $false }

        # Verifica se algum combo ainda esta no placeholder ou nulo
        $combos = @($cmbRange, $cmbArmorDmg, $cmbPen, $cmbFrags, $cmbFragType)
        foreach ($cb in $combos) {
            if (-not $cb.SelectedItem -or $cb.SelectedItem -eq $placeholderText) {
                $isValid = $false; break
            }
        }

        if (-not $isValid) { [System.Windows.Forms.MessageBox]::Show("Complete o formulário.`nVerifique se não há campos vazios ou 'Selecione os dados aqui'.", "Erro", "OK", "Warning"); return }

        $csvPath = Join-Path (Get-DatabasePath) "Throwables.csv"
        $allThrowables = @(); if (Test-Path $csvPath) { $allThrowables = @(Import-Csv $csvPath -Delimiter ";" -Encoding UTF8) }
        
        $newName = $txtName.Text.Trim()
        
        if ((-not $EditItem) -or ($EditItem.NomeItem -ne $newName)) {
            if ($allThrowables.NomeItem -contains $newName) { 
                [System.Windows.Forms.MessageBox]::Show("O arremessável '$newName' já existe!", "Erro", "OK", "Error"); return 
            }
        }

        $finalDelay = "$($txtDelay1.Text) - $($txtDelay2.Text)"

        $newItemData = [Ordered]@{
            NomeItem      = $newName
            DelayExplosao = $finalDelay
            Alcance       = $rangeMap[$cmbRange.SelectedItem]
            DanoBlindagem = $levelMap[$cmbArmorDmg.SelectedItem]
            Penetracao    = $levelMap[$cmbPen.SelectedItem]
            Fragmentos    = $fragQtyMap[$cmbFrags.SelectedItem]
            TipoFragmento = $fragTypeMap[$cmbFragType.SelectedItem]
            TempoEfeito   = $txtEffect.Text
        }

        if ($EditItem) {
            for ($i = 0; $i -lt $allThrowables.Count; $i++) {
                if ($allThrowables[$i].NomeItem -eq $EditItem.NomeItem) {
                    $allThrowables[$i] = [PSCustomObject]$newItemData
                    break
                }
            }
        } else {
            $allThrowables += [PSCustomObject]$newItemData
        }

        $allThrowables | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
        $fEdit.DialogResult = "OK"
        $fEdit.Close()
    })

    $fEdit.ShowDialog() | Out-Null
    
    # --- CORREÇÃO MEMORY LEAK: Liberta a janela da RAM ---
    $fEdit.Dispose()
}

function Start-HelmetEditor {
    param (
        $ui,
        $EditItem = $null
    )

    # 1. Janela
    $fEdit = New-Object System.Windows.Forms.Form
    $fEdit.Size = New-Object System.Drawing.Size(950, 850)
    $fEdit.StartPosition = "CenterParent"
    $fEdit.BackColor = $global:theme.PanelBack
    $fEdit.ForeColor = $global:theme.TextMain
    $fEdit.FormBorderStyle = "FixedDialog"
    $fEdit.MaximizeBox = $false
    $fEdit.MinimizeBox = $false
    $fEdit.Text = if ($EditItem) { "Editar Capacete: $($EditItem.NomeItem)" } else { "Adicionar Novo Capacete" }

    # 2. Paineis
    $pnlContent = New-Object System.Windows.Forms.Panel; $pnlContent.Dock = "Fill"; $pnlContent.AutoScroll = $true; $pnlContent.Padding = New-Object System.Windows.Forms.Padding(0, 0, 0, 80)
    $fEdit.Controls.Add($pnlContent)

    $pnlButtons = New-Object System.Windows.Forms.Panel; $pnlButtons.Dock = "Bottom"; $pnlButtons.Height = 70; $pnlButtons.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $fEdit.Controls.Add($pnlButtons)

    # --- LAYOUT ---
    $layout = @{ RowL = 0; RowR = 0; Col1_X = 30; Col2_X = 480; FieldWidth = 400; RowHeight = 65 }

    function Add-Field {
        param($LabelText, $Control, [int]$Column)
        $x = if ($Column -eq 1) { $layout.Col1_X } else { $layout.Col2_X }
        $r = if ($Column -eq 1) { $layout.RowL } else { $layout.RowR }
        $y = 20 + ($r * $layout.RowHeight)

        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $LabelText; $lbl.Location = "$x, $y"; $lbl.AutoSize = $true; $lbl.ForeColor = $global:theme.OrangeAccent
        $pnlContent.Controls.Add($lbl)
        
        if ($Control) {
            $Control.Location = "$x, $($y + 25)"; $Control.Size = "$($layout.FieldWidth), 30"
            $Control.BackColor = $global:theme.ButtonBack; $Control.ForeColor = $global:theme.TextMain
            if ($Control -is [System.Windows.Forms.TextBox]) { $Control.BorderStyle = "FixedSingle" }
            if ($Control -is [System.Windows.Forms.ComboBox]) { $Control.FlatStyle = "Flat" }
            $pnlContent.Controls.Add($Control)
        }
        
        if ($Column -eq 1) { $layout.RowL++ } else { $layout.RowR++ }
    }

    # --- VALIDACAO ---
    function Add-Validation {
        param($Control, [string]$Mode)
        $Control.Tag = $Mode 
        $Control.ContextMenu = New-Object System.Windows.Forms.ContextMenu
        $Control.Add_KeyDown({
            if (($_.Control -and $_.KeyCode -eq 'V') -or ($_.Shift -and $_.KeyCode -eq 'Insert')) { $_.SuppressKeyPress = $true }
        })
        $kp = {
            $allowed = Test-KeyRestriction -Control $this -Char $_.KeyChar -Mode $this.Tag
            if (-not $allowed) { $_.Handled = $true } 
        }.GetNewClosure()
        $Control.Add_KeyPress($kp)
    }

    # --- HELPER DE PLACEHOLDER ---
    $placeholderText = "Selecione os dados aqui"
    
    function Setup-Combo {
        param($Combo, $Map)
        $Combo.Items.Add($placeholderText) | Out-Null
        foreach ($k in $Map.Keys) { $Combo.Items.Add($k)|Out-Null }
        $Combo.SelectedIndex = 0 
        
        $Combo.Add_DropDown({
            if ($this.Items.Count -gt 0 -and $this.Items[0] -eq "Selecione os dados aqui") {
                $this.Items.RemoveAt(0)
            }
        })
    }

    # --- MAPAS DE DADOS ---
    $materialMap = [Ordered]@{ "Aramida"="Aramid"; "Polietileno"="Polyethylene"; "Aço endurecido"="Hardened Steel"; "Composto"="Composite"; "Alumínio"="Aluminum"; "Titânio"="Titanium" }
    $soundBlockMap = [Ordered]@{ "Não tem bloqueio sonoro"="/////"; "Ligeiro"="Low"; "Normal"="Moderate"; "Grave"="Severe" }
    $protectedMap = [Ordered]@{ "Cabeça"="Head"; "Cabeça, Ouvidos"="Head, Ears"; "Cabeça, Ouvidos, Rosto"="Head, Ears, Face" }
    $ricochetMap = [Ordered]@{ "Baixo"="Low"; "Médio"="Medium"; "Alto"="High" }
    $soundPickupMap = [Ordered]@{ "Fraco"="Bad"; "Médio"="Medium" }
    $noiseRedMap = [Ordered]@{ "Fraco"="Bad"; "Médio"="Medium"; "Forte"="Strong" }
    
    $accMapFull = [Ordered]@{ 
        "Não aceita máscaras ou equipamentos táticos"="/////" 
        "Aceita Equipamento Tático"="TE"
        "Aceita Máscara"="Mask"
        "Aceita Máscara e Equipamento Tático"="Mask, TE"
    }
    $accMapRestricted = [Ordered]@{
        "Não aceita máscaras ou equipamentos táticos"="/////"
        "Aceita Equipamento Tático"="TE"
    }

    # ==========================
    # COLUNA 1
    # ==========================

    # 1. Nome
    $txtName = New-Object System.Windows.Forms.TextBox; $txtName.MaxLength = 32
    if ($EditItem) { $txtName.Text = $EditItem.NomeItem }
    Add-Field -LabelText "Qual é o nome do capacete?" -Control $txtName -Column 1

    # 2. Peso
    $txtWeight = New-Object System.Windows.Forms.TextBox; $txtWeight.MaxLength = 4
    Add-Validation -Control $txtWeight -Mode "decimal_1_2"
    if ($EditItem) { $txtWeight.Text = $EditItem.Peso }
    Add-Field -LabelText "Qual é o peso do capacete? (Ex: 1.20)" -Control $txtWeight -Column 1

    # 3. Durabilidade
    $txtDurab = New-Object System.Windows.Forms.TextBox; $txtDurab.MaxLength = 4
    Add-Validation -Control $txtDurab -Mode "decimal_2_1_fixed"
    if ($EditItem) { $txtDurab.Text = $EditItem.Durabilidade }
    Add-Field -LabelText "Qual é a Durabilidade? (Ex: 10.0)" -Control $txtDurab -Column 1

    # 4. Classe Blindagem
    $txtClass = New-Object System.Windows.Forms.TextBox; $txtClass.MaxLength = 1
    Add-Validation -Control $txtClass -Mode "numeric_1_6"
    if ($EditItem) { $txtClass.Text = $EditItem.ClasseBlindagem }
    Add-Field -LabelText "Qual é a Classe de Blindagem? (1-6)" -Control $txtClass -Column 1

    # 5. Material
    $cmbMat = New-Object System.Windows.Forms.ComboBox; $cmbMat.DropDownStyle = "DropDownList"
    Setup-Combo -Combo $cmbMat -Map $materialMap
    if ($EditItem) { 
        $k=$materialMap.Keys|Where{$materialMap[$_] -eq $EditItem.Material}
        if($k){$cmbMat.SelectedItem=$k} 
    }
    Add-Field -LabelText "Qual é o Material?" -Control $cmbMat -Column 1

    # 6. Bloqueio Sonoro
    $cmbSoundBlock = New-Object System.Windows.Forms.ComboBox; $cmbSoundBlock.DropDownStyle = "DropDownList"
    Setup-Combo -Combo $cmbSoundBlock -Map $soundBlockMap
    if ($EditItem) { 
        $k=$soundBlockMap.Keys|Where{$soundBlockMap[$_] -eq $EditItem.BloqueioSom}
        if($k){$cmbSoundBlock.SelectedItem=$k}
    }
    Add-Field -LabelText "Tem Bloqueio Sonoro no capacete?" -Control $cmbSoundBlock -Column 1

    # 7. Velocidade Movimento
    $grpSpeed = New-Object System.Windows.Forms.Panel; $grpSpeed.Height=60; $grpSpeed.Width=400
    $rbSpdYes = New-Object System.Windows.Forms.RadioButton; $rbSpdYes.Text="Sim"; $rbSpdYes.Location="0,5"; $rbSpdYes.Width=50; $rbSpdYes.ForeColor=$global:theme.TextMain
    $rbSpdNo = New-Object System.Windows.Forms.RadioButton; $rbSpdNo.Text="Não"; $rbSpdNo.Location="60,5"; $rbSpdNo.Width=50; $rbSpdNo.ForeColor=$global:theme.TextMain
    $txtSpdVal = New-Object System.Windows.Forms.TextBox; $txtSpdVal.Location="120,3"; $txtSpdVal.Width=50; $txtSpdVal.MaxLength=3; $txtSpdVal.Visible=$false
    Add-Validation -Control $txtSpdVal -Mode "percentage_negative"
    $lblSpd = New-Object System.Windows.Forms.Label; $lblSpd.Text="%"; $lblSpd.Location="175,5"; $lblSpd.ForeColor=$global:theme.TextDim; $lblSpd.Visible=$false
    $grpSpeed.Controls.AddRange(@($rbSpdYes, $rbSpdNo, $txtSpdVal, $lblSpd))

    $rbSpdYes.Add_CheckedChanged({ $txtSpdVal.Visible=$rbSpdYes.Checked; $lblSpd.Visible=$rbSpdYes.Checked })
    if ($EditItem -and $EditItem.PenalidadeMovimento -ne "/////") { 
        $rbSpdYes.Checked=$true; $txtSpdVal.Text = $EditItem.PenalidadeMovimento -replace '%','' 
    } else { $rbSpdNo.Checked=$true }
    Add-Field -LabelText "O capacete altera a velocidade de Movimento? (Ex: -10)" -Control $grpSpeed -Column 1

    # ==========================
    # COLUNA 2
    # ==========================

    # 8. Ergonomia
    $grpErgo = New-Object System.Windows.Forms.Panel; $grpErgo.Height=60; $grpErgo.Width=400
    $rbErgoYes = New-Object System.Windows.Forms.RadioButton; $rbErgoYes.Text="Sim"; $rbErgoYes.Location="0,5"; $rbErgoYes.Width=50; $rbErgoYes.ForeColor=$global:theme.TextMain
    $rbErgoNo = New-Object System.Windows.Forms.RadioButton; $rbErgoNo.Text="Não"; $rbErgoNo.Location="60,5"; $rbErgoNo.Width=50; $rbErgoNo.ForeColor=$global:theme.TextMain
    $txtErgoVal = New-Object System.Windows.Forms.TextBox; $txtErgoVal.Location="120,3"; $txtErgoVal.Width=50; $txtErgoVal.MaxLength=3; $txtErgoVal.Visible=$false
    Add-Validation -Control $txtErgoVal -Mode "numeric_negative_no_leading_zero"
    $grpErgo.Controls.AddRange(@($rbErgoYes, $rbErgoNo, $txtErgoVal))
    
    $rbErgoYes.Add_CheckedChanged({ $txtErgoVal.Visible = $rbErgoYes.Checked })
    if ($EditItem -and $EditItem.Ergonomia -ne "/////") { $rbErgoYes.Checked=$true; $txtErgoVal.Text=$EditItem.Ergonomia } else { $rbErgoNo.Checked=$true }
    Add-Field -LabelText "O capacete afeta ergonomia? (Ex: -10)" -Control $grpErgo -Column 2

    # 9. Area Protegida
    $cmbProt = New-Object System.Windows.Forms.ComboBox; $cmbProt.DropDownStyle = "DropDownList"
    Setup-Combo -Combo $cmbProt -Map $protectedMap
    if ($EditItem) { 
        $k=$protectedMap.Keys|Where{$protectedMap[$_] -eq $EditItem.AreaProtegida}
        if($k){$cmbProt.SelectedItem=$k}
    }
    Add-Field -LabelText "O capacete protegem quais partes da cabeça?" -Control $cmbProt -Column 2

    # 10. Ricochete
    $cmbRico = New-Object System.Windows.Forms.ComboBox; $cmbRico.DropDownStyle = "DropDownList"
    Setup-Combo -Combo $cmbRico -Map $ricochetMap
    if ($EditItem) { 
        $k=$ricochetMap.Keys|Where{$ricochetMap[$_] -eq $EditItem.Ricochete}
        if($k){$cmbRico.SelectedItem=$k}
    }
    Add-Field -LabelText "Qual é a chance do capacete ricochetear?" -Control $cmbRico -Column 2

    # 11. Headset Embutido
    $grpHeadset = New-Object System.Windows.Forms.Panel; $grpHeadset.Height=60; $grpHeadset.Width=400
    $rbHeadYes = New-Object System.Windows.Forms.RadioButton; $rbHeadYes.Text="Sim"; $rbHeadYes.Location="0,5"; $rbHeadYes.Width=50; $rbHeadYes.ForeColor=$global:theme.TextMain
    $rbHeadNo = New-Object System.Windows.Forms.RadioButton; $rbHeadNo.Text="Não"; $rbHeadNo.Location="60,5"; $rbHeadNo.Width=50; $rbHeadNo.ForeColor=$global:theme.TextMain
    $grpHeadset.Controls.AddRange(@($rbHeadYes, $rbHeadNo))
    
    if ($EditItem) { if($EditItem.TemHeadset -eq "Sim"){$rbHeadYes.Checked=$true}else{$rbHeadNo.Checked=$true} } else { $rbHeadNo.Checked=$true }
    Add-Field -LabelText "O capacete tem fone de ouvido embutido?" -Control $grpHeadset -Column 2

    # 12. Captacao Som
    $cmbPickup = New-Object System.Windows.Forms.ComboBox; $cmbPickup.DropDownStyle = "DropDownList"
    Setup-Combo -Combo $cmbPickup -Map $soundPickupMap
    if ($EditItem) { $k=$soundPickupMap.Keys|Where{$soundPickupMap[$_] -eq $EditItem.CaptacaoSom}; if($k){$cmbPickup.SelectedItem=$k} }
    Add-Field -LabelText "Qual é a potência de captura de som?" -Control $cmbPickup -Column 2

    # 13. Reducao Ruido
    $cmbNoise = New-Object System.Windows.Forms.ComboBox; $cmbNoise.DropDownStyle = "DropDownList"
    Setup-Combo -Combo $cmbNoise -Map $noiseRedMap
    if ($EditItem) { $k=$noiseRedMap.Keys|Where{$noiseRedMap[$_] -eq $EditItem.ReducaoRuido}; if($k){$cmbNoise.SelectedItem=$k} }
    Add-Field -LabelText "Qual é a potência de redução de Ruido?" -Control $cmbNoise -Column 2

    # 14. Acessorio
    $cmbAcc = New-Object System.Windows.Forms.ComboBox; $cmbAcc.DropDownStyle = "DropDownList"
    # Inicialmente vazio, preenchido pela logica dinamica
    Add-Field -LabelText "Acessório Funcional" -Control $cmbAcc -Column 2

    # --- LOGICA DINAMICA ---
    
    # Atualiza lista de acessorios
    $updateAccList = {
        $sel = $cmbAcc.SelectedItem
        $cmbAcc.Items.Clear()
        $cmbAcc.Items.Add($placeholderText) | Out-Null # Adiciona Placeholder
        
        # Recria evento de dropdown pois limpar itens remove eventos em alguns contextos
        $cmbAcc.Add_DropDown({
            if ($this.Items.Count -gt 0 -and $this.Items[0] -eq "Selecione os dados aqui") {
                $this.Items.RemoveAt(0)
            }
        })

        if (-not $cmbProt.SelectedItem -or $cmbProt.SelectedItem -eq $placeholderText) { 
            # Se nao selecionou protecao, usa lista completa por padrao
            foreach ($k in $accMapFull.Keys) { $cmbAcc.Items.Add($k)|Out-Null }
        } else {
            $currentProt = $protectedMap[$cmbProt.SelectedItem]
            $mapToUse = if ($currentProt -eq "Head, Ears, Face") { $accMapRestricted } else { $accMapFull }
            foreach ($k in $mapToUse.Keys) { $cmbAcc.Items.Add($k)|Out-Null }
        }
        
        if ($sel -and $cmbAcc.Items.Contains($sel)) { $cmbAcc.SelectedItem = $sel }
        else { $cmbAcc.SelectedIndex = 0 } # Volta pro placeholder
    }.GetNewClosure()

    $cmbProt.Add_SelectionChangeCommitted($updateAccList)
    # Tambem atualiza quando dropdown de protecao fecha (caso remova o placeholder)
    $cmbProt.Add_DropDownClosed($updateAccList) 

    # Logica de Bloqueio Sonoro vs Headset
    $updateAudio = {
        if (-not $cmbSoundBlock.SelectedItem -or $cmbSoundBlock.SelectedItem -eq $placeholderText) { 
            # Se nao selecionou bloqueio, assume padrao (habilitado)
            $grpHeadset.Enabled = $true
        } else {
            $blockVal = $soundBlockMap[$cmbSoundBlock.SelectedItem]
            if ($blockVal -ne "/////") {
                $rbHeadNo.Checked = $true
                $grpHeadset.Enabled = $false
            } else {
                $grpHeadset.Enabled = $true
            }
        }

        if ($rbHeadYes.Checked) {
            $cmbPickup.Enabled = $true
            $cmbNoise.Enabled = $true
        } else {
            $cmbPickup.Enabled = $false; $cmbPickup.SelectedIndex = 0 # Reset p/ placeholder
            $cmbNoise.Enabled = $false; $cmbNoise.SelectedIndex = 0 # Reset p/ placeholder
        }
    }.GetNewClosure()

    $cmbSoundBlock.Add_SelectionChangeCommitted($updateAudio)
    # Importante: Atualizar tambem no fechamento do dropdown caso placeholder suma
    $cmbSoundBlock.Add_DropDownClosed($updateAudio) 
    
    $rbHeadYes.Add_CheckedChanged($updateAudio)
    $rbHeadNo.Add_CheckedChanged($updateAudio)

    # Executa logica inicial
    # Recarrega acessorios (inicializacao correta)
    if ($EditItem) { 
        $k=$accMapFull.Keys|Where{$accMapFull[$_] -eq $EditItem.Acessorio}
        if($k){ 
            # Forca adicao dos itens primeiro
            foreach ($key in $accMapFull.Keys) { $cmbAcc.Items.Add($key)|Out-Null }
            $cmbAcc.SelectedItem=$k 
        } else { & $updateAccList }
    } else { & $updateAccList }
    
    & $updateAudio

    # --- BOTOES ---
    $btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = "Salvar"; $btnSave.Location = "330, 15"; $btnSave.Size = "120, 40"; $btnSave.FlatStyle = "Flat"; $btnSave.BackColor = $global:theme.GreenSuccess; $btnSave.ForeColor = $global:theme.Background
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Cancelar"; $btnCancel.Location = "500, 15"; $btnCancel.Size = "120, 40"; $btnCancel.FlatStyle = "Flat"; $btnCancel.BackColor = $global:theme.ButtonBack; $btnCancel.ForeColor = $global:theme.TextMain
    $pnlButtons.Controls.AddRange(@($btnSave, $btnCancel)); $fEdit.AcceptButton = $btnSave; $fEdit.CancelButton = $btnCancel

    # --- SALVAR ---
    $btnSave.Add_Click({
        $isValid = $true
        
        # Validacoes Basicas
        if ([string]::IsNullOrWhiteSpace($txtName.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtWeight.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtDurab.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtClass.Text)) { $isValid = $false }
        
        # Validacoes de Combos (Nao podem ser nulos nem Placeholder)
        if (-not $cmbMat.SelectedItem -or $cmbMat.SelectedItem -eq $placeholderText) { $isValid = $false }
        if (-not $cmbSoundBlock.SelectedItem -or $cmbSoundBlock.SelectedItem -eq $placeholderText) { $isValid = $false }
        if (-not $cmbProt.SelectedItem -or $cmbProt.SelectedItem -eq $placeholderText) { $isValid = $false }
        if (-not $cmbRico.SelectedItem -or $cmbRico.SelectedItem -eq $placeholderText) { $isValid = $false }
        if (-not $cmbAcc.SelectedItem -or $cmbAcc.SelectedItem -eq $placeholderText) { $isValid = $false }
        
        # Valida Paineis Sim/Nao
        if ($rbErgoYes.Checked -and [string]::IsNullOrWhiteSpace($txtErgoVal.Text)) { $isValid = $false }
        if ($rbSpdYes.Checked -and [string]::IsNullOrWhiteSpace($txtSpdVal.Text)) { $isValid = $false }
        
        # Valida Audio se habilitado
        if ($rbHeadYes.Checked) {
            if (-not $cmbPickup.SelectedItem -or $cmbPickup.SelectedItem -eq $placeholderText) { $isValid = $false }
            if (-not $cmbNoise.SelectedItem -or $cmbNoise.SelectedItem -eq $placeholderText) { $isValid = $false }
        }

        if (-not $isValid) { [System.Windows.Forms.MessageBox]::Show("Complete o formulário corretamente.`nVerifique se não há campos vazios ou 'Selecione os dados aqui'.", "Erro", "OK", "Warning"); return }

        # Dados Finais
        $finalErgo = if ($rbErgoYes.Checked) { $txtErgoVal.Text } else { "/////" }
        $finalSpd  = if ($rbSpdYes.Checked) { "$($txtSpdVal.Text)%" } else { "/////" }
        
        # [MANTIDO COMO ORIGINAL] - Gravação em CSV
        $finalHeadset = if ($rbHeadYes.Checked) { "Sim" } else { "Nao" }
        $finalPickup  = if ($rbHeadYes.Checked) { $soundPickupMap[$cmbPickup.SelectedItem] } else { "/////" }
        $finalNoise   = if ($rbHeadYes.Checked) { $noiseRedMap[$cmbNoise.SelectedItem] } else { "/////" }

        $newItemData = [Ordered]@{
            NomeItem            = $txtName.Text.Trim()
            Peso                = $txtWeight.Text
            Durabilidade        = $txtDurab.Text
            ClasseBlindagem     = $txtClass.Text
            Material            = $materialMap[$cmbMat.SelectedItem]
            BloqueioSom         = $soundBlockMap[$cmbSoundBlock.SelectedItem]
            PenalidadeMovimento = $finalSpd
            Ergonomia           = $finalErgo
            AreaProtegida       = $protectedMap[$cmbProt.SelectedItem]
            Ricochete           = $ricochetMap[$cmbRico.SelectedItem]
            TemHeadset          = $finalHeadset
            CaptacaoSom         = $finalPickup
            ReducaoRuido        = $finalNoise
            Acessorio           = $accMapFull[$cmbAcc.SelectedItem]
        }

        $csvPath = Join-Path (Get-DatabasePath) "Helmets.csv"
        $allItems = @(); if (Test-Path $csvPath) { $allItems = @(Import-Csv $csvPath -Delimiter ";" -Encoding UTF8) }

        if ((-not $EditItem) -or ($EditItem.NomeItem -ne $newItemData.NomeItem)) {
            if ($allItems.NomeItem -contains $newItemData.NomeItem) { [System.Windows.Forms.MessageBox]::Show("Nome já existe!", "Erro", "OK", "Error"); return }
        }

        if ($EditItem) {
            for ($i = 0; $i -lt $allItems.Count; $i++) {
                if ($allItems[$i].NomeItem -eq $EditItem.NomeItem) { $allItems[$i] = [PSCustomObject]$newItemData; break }
            }
        } else { $allItems += [PSCustomObject]$newItemData }

        $allItems | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
        $fEdit.DialogResult = "OK"; $fEdit.Close()
    })

    $fEdit.ShowDialog() | Out-Null
    
    # --- CORREÇÃO MEMORY LEAK: Limpa o form da RAM ---
    $fEdit.Dispose()
}

function Start-BodyArmorEditor {
    param (
        $ui,
        $EditItem = $null
    )

    # 1. Janela
    $fEdit = New-Object System.Windows.Forms.Form
    $fEdit.Size = New-Object System.Drawing.Size(950, 750)
    $fEdit.StartPosition = "CenterParent"
    $fEdit.BackColor = $global:theme.PanelBack
    $fEdit.ForeColor = $global:theme.TextMain
    $fEdit.FormBorderStyle = "FixedDialog"
    $fEdit.MaximizeBox = $false
    $fEdit.MinimizeBox = $false
    $fEdit.Text = if ($EditItem) { "Editar Colete Balístico: $($EditItem.NomeItem)" } else { "Adicionar Novo Colete Balístico" }

    # 2. Paineis
    $pnlContent = New-Object System.Windows.Forms.Panel; $pnlContent.Dock = "Fill"; $pnlContent.AutoScroll = $true; $pnlContent.Padding = New-Object System.Windows.Forms.Padding(0, 0, 0, 80)
    $fEdit.Controls.Add($pnlContent)

    $pnlButtons = New-Object System.Windows.Forms.Panel; $pnlButtons.Dock = "Bottom"; $pnlButtons.Height = 70; $pnlButtons.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $fEdit.Controls.Add($pnlButtons)

    # --- LAYOUT ---
    $layout = @{ RowL = 0; RowR = 0; Col1_X = 30; Col2_X = 480; FieldWidth = 400; RowHeight = 65 }

    function Add-Field {
        param($LabelText, $Control, [int]$Column)
        $x = if ($Column -eq 1) { $layout.Col1_X } else { $layout.Col2_X }
        $r = if ($Column -eq 1) { $layout.RowL } else { $layout.RowR }
        $y = 20 + ($r * $layout.RowHeight)

        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $LabelText; $lbl.Location = "$x, $y"; $lbl.AutoSize = $true; $lbl.ForeColor = $global:theme.OrangeAccent
        $pnlContent.Controls.Add($lbl)
        
        if ($Control) {
            $Control.Location = "$x, $($y + 25)"; $Control.Size = "$($layout.FieldWidth), 30"
            $Control.BackColor = $global:theme.ButtonBack; $Control.ForeColor = $global:theme.TextMain
            if ($Control -is [System.Windows.Forms.TextBox]) { $Control.BorderStyle = "FixedSingle" }
            if ($Control -is [System.Windows.Forms.ComboBox]) { $Control.FlatStyle = "Flat" }
            $pnlContent.Controls.Add($Control)
        }
        
        if ($Column -eq 1) { $layout.RowL++ } else { $layout.RowR++ }
    }

    # --- VALIDACAO ---
    function Add-Validation {
        param($Control, [string]$Mode)
        $Control.Tag = $Mode 
        $Control.ContextMenu = New-Object System.Windows.Forms.ContextMenu
        $Control.Add_KeyDown({
            if (($_.Control -and $_.KeyCode -eq 'V') -or ($_.Shift -and $_.KeyCode -eq 'Insert')) { $_.SuppressKeyPress = $true }
        })
        $kp = {
            $allowed = Test-KeyRestriction -Control $this -Char $_.KeyChar -Mode $this.Tag
            if (-not $allowed) { $_.Handled = $true } 
        }.GetNewClosure()
        $Control.Add_KeyPress($kp)
    }

    # --- MAPAS ---
    $materialMap = [Ordered]@{ "Aramida"="Aramid"; "Polietileno"="Polyethylene"; "Aço endurecido"="Hardened Steel"; "Composto"="Composite"; "Alumínio"="Aluminum"; "Titânio"="Titanium"; "Cerâmica"="Ceramic" }
    $protectedMap = [Ordered]@{ 
        "Tórax"="Chest"
        "Tórax, Abdômen Superior"="Chest, Upper Abdomen"
        "Tórax, Ombro, Abdômen Superior"="Chest, Shoulder, Upper Abdomen"
        "Tórax, Abdômen Superior, Abdômen Inferior"="Chest, Upper Abdomen, Lower Abdomen"
        "Tórax, Ombro, Abdômen Superior, Abdômen Inferior"="Chest, Shoulder, Upper Abdomen, Lower Abdomen" 
    }
    
    $placeholderText = "Selecione os dados aqui"

    # ==========================
    # COLUNA 1
    # ==========================

    # 1. Nome
    $txtName = New-Object System.Windows.Forms.TextBox; $txtName.MaxLength = 42
    if ($EditItem) { $txtName.Text = $EditItem.NomeItem }
    Add-Field -LabelText "Qual é o nome do colete?" -Control $txtName -Column 1

    # 2. Peso
    $txtWeight = New-Object System.Windows.Forms.TextBox; $txtWeight.MaxLength = 5 
    Add-Validation -Control $txtWeight -Mode "decimal_weight"
    if ($EditItem) { $txtWeight.Text = $EditItem.Peso }
    Add-Field -LabelText "Qual é o peso do colete? (Ex: 6.20 ou 11.80)" -Control $txtWeight -Column 1

    # 3. Durabilidade
    $txtDurab = New-Object System.Windows.Forms.TextBox; $txtDurab.MaxLength = 5 
    Add-Validation -Control $txtDurab -Mode "decimal_durability_fixed"
    if ($EditItem) { $txtDurab.Text = $EditItem.Durabilidade }
    Add-Field -LabelText "Qual é a Durabilidade do colete? (Ex: 85.0)" -Control $txtDurab -Column 1

    # 4. Classe
    $txtClass = New-Object System.Windows.Forms.TextBox; $txtClass.MaxLength = 1
    Add-Validation -Control $txtClass -Mode "numeric_1_6"
    if ($EditItem) { $txtClass.Text = $EditItem.ClasseBlindagem }
    Add-Field -LabelText "Qual é a Classe de Blindagem? (1-6)" -Control $txtClass -Column 1

    # ==========================
    # COLUNA 2
    # ==========================

    # 5. Material
    $cmbMat = New-Object System.Windows.Forms.ComboBox; $cmbMat.DropDownStyle = "DropDownList"
    
    # Adiciona placeholder e itens
    $cmbMat.Items.Add($placeholderText) | Out-Null
    foreach ($k in $materialMap.Keys) { $cmbMat.Items.Add($k)|Out-Null }
    
    if ($EditItem) { 
        $k=$materialMap.Keys|Where{$materialMap[$_] -eq $EditItem.Material}
        if($k){$cmbMat.SelectedItem=$k} else {$cmbMat.SelectedIndex=0}
    } else { $cmbMat.SelectedIndex = 0 } # Seleciona placeholder se for novo
    
    # Evento para remover placeholder ao abrir
    $cmbMat.Add_DropDown({
        if ($this.Items.Count -gt 0 -and $this.Items[0] -eq "Selecione os dados aqui") {
            $this.Items.RemoveAt(0)
        }
    })

    Add-Field -LabelText "Qual é o Material do colete?" -Control $cmbMat -Column 2

    # 6. Velocidade Movimento (Sim/Nao)
    $grpSpeed = New-Object System.Windows.Forms.Panel; $grpSpeed.Height=60; $grpSpeed.Width=400
    $rbSpdYes = New-Object System.Windows.Forms.RadioButton; $rbSpdYes.Text="Sim"; $rbSpdYes.Location="0,5"; $rbSpdYes.Width=50; $rbSpdYes.ForeColor=$global:theme.TextMain
    $rbSpdNo = New-Object System.Windows.Forms.RadioButton; $rbSpdNo.Text="Não"; $rbSpdNo.Location="60,5"; $rbSpdNo.Width=50; $rbSpdNo.ForeColor=$global:theme.TextMain
    $txtSpdVal = New-Object System.Windows.Forms.TextBox; $txtSpdVal.Location="120,3"; $txtSpdVal.Width=50; $txtSpdVal.MaxLength=3; $txtSpdVal.Visible=$false
    Add-Validation -Control $txtSpdVal -Mode "percentage_negative"
    $lblSpd = New-Object System.Windows.Forms.Label; $lblSpd.Text="%"; $lblSpd.Location="175,5"; $lblSpd.ForeColor=$global:theme.TextDim; $lblSpd.Visible=$false
    $grpSpeed.Controls.AddRange(@($rbSpdYes, $rbSpdNo, $txtSpdVal, $lblSpd))

    $rbSpdYes.Add_CheckedChanged({ $txtSpdVal.Visible=$rbSpdYes.Checked; $lblSpd.Visible=$rbSpdYes.Checked })
    if ($EditItem -and $EditItem.PenalidadeMovimento -ne "/////") { 
        $rbSpdYes.Checked=$true; $txtSpdVal.Text = $EditItem.PenalidadeMovimento -replace '%','' 
    } else { $rbSpdNo.Checked=$true }
    
    Add-Field -LabelText "O colete afeta a velocidade de Movimento? (Ex: -10)" -Control $grpSpeed -Column 2

    # 7. Ergonomia (Sim/Nao)
    $grpErgo = New-Object System.Windows.Forms.Panel; $grpErgo.Height=60; $grpErgo.Width=400
    $rbErgoYes = New-Object System.Windows.Forms.RadioButton; $rbErgoYes.Text="Sim"; $rbErgoYes.Location="0,5"; $rbErgoYes.Width=50; $rbErgoYes.ForeColor=$global:theme.TextMain
    $rbErgoNo = New-Object System.Windows.Forms.RadioButton; $rbErgoNo.Text="Não"; $rbErgoNo.Location="60,5"; $rbErgoNo.Width=50; $rbErgoNo.ForeColor=$global:theme.TextMain
    $txtErgoVal = New-Object System.Windows.Forms.TextBox; $txtErgoVal.Location="120,3"; $txtErgoVal.Width=50; $txtErgoVal.MaxLength=3; $txtErgoVal.Visible=$false
    Add-Validation -Control $txtErgoVal -Mode "numeric_negative_no_leading_zero"
    $grpErgo.Controls.AddRange(@($rbErgoYes, $rbErgoNo, $txtErgoVal))
    
    $rbErgoYes.Add_CheckedChanged({ $txtErgoVal.Visible=$rbErgoYes.Checked })
    if ($EditItem -and $EditItem.Ergonomia -ne "/////") { $rbErgoYes.Checked=$true; $txtErgoVal.Text=$EditItem.Ergonomia } else { $rbErgoNo.Checked=$true }
    
    Add-Field -LabelText "O colete afeta a Ergonomia? (Ex: -10)" -Control $grpErgo -Column 2

    # 8. Area Protegida
    $cmbProt = New-Object System.Windows.Forms.ComboBox; $cmbProt.DropDownStyle = "DropDownList"
    
    # Adiciona placeholder e itens
    $cmbProt.Items.Add($placeholderText) | Out-Null
    foreach ($k in $protectedMap.Keys) { $cmbProt.Items.Add($k)|Out-Null }
    
    if ($EditItem) { 
        $k=$protectedMap.Keys|Where{$protectedMap[$_] -eq $EditItem.AreaProtegida}
        if($k){$cmbProt.SelectedItem=$k} else {$cmbProt.SelectedIndex = 0}
    } else { $cmbProt.SelectedIndex = 0 } # Seleciona placeholder se for novo

    # Evento para remover placeholder ao abrir
    $cmbProt.Add_DropDown({
        if ($this.Items.Count -gt 0 -and $this.Items[0] -eq "Selecione os dados aqui") {
            $this.Items.RemoveAt(0)
        }
    })

    Add-Field -LabelText "O colete protege quais partes do corpo?" -Control $cmbProt -Column 2

    # --- BOTOES ---
    $btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = "Salvar"; $btnSave.Location = "330, 15"; $btnSave.Size = "120, 40"; $btnSave.FlatStyle = "Flat"; $btnSave.BackColor = $global:theme.GreenSuccess; $btnSave.ForeColor = $global:theme.Background
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Cancelar"; $btnCancel.Location = "500, 15"; $btnCancel.Size = "120, 40"; $btnCancel.FlatStyle = "Flat"; $btnCancel.BackColor = $global:theme.ButtonBack; $btnCancel.ForeColor = $global:theme.TextMain
    $pnlButtons.Controls.AddRange(@($btnSave, $btnCancel)); $fEdit.AcceptButton = $btnSave; $fEdit.CancelButton = $btnCancel

    # --- SALVAR ---
    $btnSave.Add_Click({
        $isValid = $true
        
        if ([string]::IsNullOrWhiteSpace($txtName.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtWeight.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtDurab.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtClass.Text)) { $isValid = $false }
        
        # Validacao do Placeholder
        if (-not $cmbMat.SelectedItem -or $cmbMat.SelectedItem -eq $placeholderText) { $isValid = $false }
        if (-not $cmbProt.SelectedItem -or $cmbProt.SelectedItem -eq $placeholderText) { $isValid = $false }
        
        if ($rbSpdYes.Checked -and [string]::IsNullOrWhiteSpace($txtSpdVal.Text)) { $isValid = $false }
        if ($rbErgoYes.Checked -and [string]::IsNullOrWhiteSpace($txtErgoVal.Text)) { $isValid = $false }

        if (-not $isValid) { [System.Windows.Forms.MessageBox]::Show("Complete o formulário corretamente.`nVerifique se não há campos vazios ou 'Selecione os dados aqui'.", "Erro", "OK", "Warning"); return }

        $finalSpd = if ($rbSpdYes.Checked) { "$($txtSpdVal.Text)%" } else { "/////" }
        $finalErgo = if ($rbErgoYes.Checked) { $txtErgoVal.Text } else { "/////" }

        $newItemData = [Ordered]@{
            NomeItem            = $txtName.Text.Trim()
            Peso                = $txtWeight.Text
            Durabilidade        = $txtDurab.Text
            ClasseBlindagem     = $txtClass.Text
            Material            = $materialMap[$cmbMat.SelectedItem]
            PenalidadeMovimento = $finalSpd
            Ergonomia           = $finalErgo
            AreaProtegida       = $protectedMap[$cmbProt.SelectedItem]
        }

        $csvPath = Join-Path (Get-DatabasePath) "Bodyarmors.csv"
        $allItems = @(); if (Test-Path $csvPath) { $allItems = @(Import-Csv $csvPath -Delimiter ";" -Encoding UTF8) }

        if ((-not $EditItem) -or ($EditItem.NomeItem -ne $newItemData.NomeItem)) {
            if ($allItems.NomeItem -contains $newItemData.NomeItem) { [System.Windows.Forms.MessageBox]::Show("Nome já existe!", "Erro", "OK", "Error"); return }
        }

        if ($EditItem) {
            for ($i = 0; $i -lt $allItems.Count; $i++) {
                if ($allItems[$i].NomeItem -eq $EditItem.NomeItem) { $allItems[$i] = [PSCustomObject]$newItemData; break }
            }
        } else { $allItems += [PSCustomObject]$newItemData }

        $allItems | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
        $fEdit.DialogResult = "OK"; $fEdit.Close()
    })

    $fEdit.ShowDialog() | Out-Null
    
    # --- CORREÇÃO MEMORY LEAK: Limpa o form da RAM ---
    $fEdit.Dispose()
}

function Start-UnarmoredRigEditor {
    param (
        $ui,
        $EditItem = $null
    )

    # 1. Janela
    $fEdit = New-Object System.Windows.Forms.Form
    $fEdit.Size = New-Object System.Drawing.Size(950, 750)
    $fEdit.StartPosition = "CenterParent"
    $fEdit.BackColor = $global:theme.PanelBack
    $fEdit.ForeColor = $global:theme.TextMain
    $fEdit.FormBorderStyle = "FixedDialog"
    $fEdit.MaximizeBox = $false
    $fEdit.MinimizeBox = $false
    $fEdit.Text = if ($EditItem) { "Editar Colete Não Blindado: $($EditItem.NomeItem)" } else { "Adicionar Novo Colete Não Blindado" }

    # 2. Paineis
    $pnlContent = New-Object System.Windows.Forms.Panel; $pnlContent.Dock = "Fill"; $pnlContent.AutoScroll = $true; $pnlContent.Padding = New-Object System.Windows.Forms.Padding(0, 0, 0, 80)
    $fEdit.Controls.Add($pnlContent)

    $pnlButtons = New-Object System.Windows.Forms.Panel; $pnlButtons.Dock = "Bottom"; $pnlButtons.Height = 70; $pnlButtons.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $fEdit.Controls.Add($pnlButtons)

    # --- LAYOUT ---
    $layout = @{ RowL = 0; RowR = 0; Col1_X = 30; Col2_X = 480; FieldWidth = 400; RowHeight = 65 }

    function Add-Field {
        param($LabelText, $Control, [int]$Column)
        $x = if ($Column -eq 1) { $layout.Col1_X } else { $layout.Col2_X }
        $r = if ($Column -eq 1) { $layout.RowL } else { $layout.RowR }
        $y = 20 + ($r * $layout.RowHeight)

        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $LabelText; $lbl.Location = "$x, $y"; $lbl.AutoSize = $true; $lbl.ForeColor = $global:theme.OrangeAccent
        $pnlContent.Controls.Add($lbl)
        
        if ($Control) {
            $Control.Location = "$x, $($y + 25)"; $Control.Size = "$($layout.FieldWidth), 30"
            $Control.BackColor = $global:theme.ButtonBack; $Control.ForeColor = $global:theme.TextMain
            if ($Control -is [System.Windows.Forms.TextBox]) { $Control.BorderStyle = "FixedSingle" }
            $pnlContent.Controls.Add($Control)
        }
        
        if ($Column -eq 1) { $layout.RowL++ } else { $layout.RowR++ }
    }

    # --- VALIDACAO ---
    function Add-Validation {
        param($Control, [string]$Mode)
        $Control.Tag = $Mode 
        $Control.ContextMenu = New-Object System.Windows.Forms.ContextMenu
        $Control.Add_KeyDown({
            if (($_.Control -and $_.KeyCode -eq 'V') -or ($_.Shift -and $_.KeyCode -eq 'Insert')) { $_.SuppressKeyPress = $true }
        })
        $kp = {
            $allowed = Test-KeyRestriction -Control $this -Char $_.KeyChar -Mode $this.Tag
            if (-not $allowed) { $_.Handled = $true } 
        }.GetNewClosure()
        $Control.Add_KeyPress($kp)
    }

    # ==========================
    # COLUNA 1 (Dados Basicos)
    # ==========================

    # 1. Nome
    $txtName = New-Object System.Windows.Forms.TextBox; $txtName.MaxLength = 42
    if ($EditItem) { $txtName.Text = $EditItem.NomeItem }
    Add-Field -LabelText "Qual é o nome do colete não blindado?" -Control $txtName -Column 1

    # 2. Peso
    $txtWeight = New-Object System.Windows.Forms.TextBox; $txtWeight.MaxLength = 5
    Add-Validation -Control $txtWeight -Mode "decimal_unarmored_weight"
    if ($EditItem) { $txtWeight.Text = $EditItem.Peso }
    Add-Field -LabelText "Qual é o peso? (Ex: 2.50)" -Control $txtWeight -Column 1

    # 3. Espaco
    $txtSpace = New-Object System.Windows.Forms.TextBox; $txtSpace.MaxLength = 2
    Add-Validation -Control $txtSpace -Mode "numeric"
    if ($EditItem) { $txtSpace.Text = $EditItem.EspacoTotal }
    Add-Field -LabelText "Qual é o espaço de armazenamento? (Ex: 20)" -Control $txtSpace -Column 1

    # [NOVO] Pergunta sobre Detalhes Opcionais
    $grpDetails = New-Object System.Windows.Forms.Panel; $grpDetails.Height=30; $grpDetails.Width=400
    $rbDetYes = New-Object System.Windows.Forms.RadioButton; $rbDetYes.Text="Sim"; $rbDetYes.Location="0,5"; $rbDetYes.Width=50; $rbDetYes.ForeColor=$global:theme.TextMain
    $rbDetNo = New-Object System.Windows.Forms.RadioButton; $rbDetNo.Text="Não"; $rbDetNo.Location="60,5"; $rbDetNo.Width=50; $rbDetNo.ForeColor=$global:theme.TextMain
    $grpDetails.Controls.AddRange(@($rbDetYes, $rbDetNo))
    
    Add-Field -LabelText "Deseja adicionar detalhes de tamanho e blocos?" -Control $grpDetails -Column 1

    # --- TAMANHOS (Lógica NxM) ---
    function Create-SizeInput {
        param($GroupLabel, [ref]$H_Ref, [ref]$V_Ref, $InitialValue)
        
        $pnl = New-Object System.Windows.Forms.Panel; $pnl.Height = 35; $pnl.Width = 400
        
        $lblX = New-Object System.Windows.Forms.Label; $lblX.Text = "Horiz:"; $lblX.Location = "0,8"; $lblX.AutoSize = $true; $lblX.ForeColor = $global:theme.TextDim
        $txtH = New-Object System.Windows.Forms.TextBox; $txtH.Location = "45,5"; $txtH.Width = 30; $txtH.MaxLength = 1; $txtH.BackColor=$global:theme.ButtonBack; $txtH.ForeColor=$global:theme.TextMain; $txtH.BorderStyle="FixedSingle"
        Add-Validation -Control $txtH -Mode "numeric_1_9"
        
        $lblY = New-Object System.Windows.Forms.Label; $lblY.Text = "Vert:"; $lblY.Location = "90,8"; $lblY.AutoSize = $true; $lblY.ForeColor = $global:theme.TextDim
        $txtV = New-Object System.Windows.Forms.TextBox; $txtV.Location = "130,5"; $txtV.Width = 30; $txtV.MaxLength = 1; $txtV.BackColor=$global:theme.ButtonBack; $txtV.ForeColor=$global:theme.TextMain; $txtV.BorderStyle="FixedSingle"
        Add-Validation -Control $txtV -Mode "numeric_1_9"

        $pnl.Controls.AddRange(@($lblX, $txtH, $lblY, $txtV))
        Add-Field -LabelText $GroupLabel -Control $pnl -Column 1
        
        if ($InitialValue -match '(\d)x(\d)') {
            $txtH.Text = $Matches[1]; $txtV.Text = $Matches[2]
        }
        
        $H_Ref.Value = $txtH; $V_Ref.Value = $txtV
        return $pnl
    }

    $txtUnfH = $null; $txtUnfV = $null
    $pnlUnf = Create-SizeInput -GroupLabel "Tamanho Desdobrado (H x V)" -H_Ref ([ref]$txtUnfH) -V_Ref ([ref]$txtUnfV) -InitialValue $EditItem.TamanhoDesdobrada

    $txtFoldH = $null; $txtFoldV = $null
    $pnlFold = Create-SizeInput -GroupLabel "Tamanho Dobrado (H x V)" -H_Ref ([ref]$txtFoldH) -V_Ref ([ref]$txtFoldV) -InitialValue $EditItem.TamanhoDobrada

    # ==========================
    # COLUNA 2 (Layout Interno Complexo)
    # ==========================
    
    $lblLayout = New-Object System.Windows.Forms.Label; $lblLayout.Text = "Conjuntos de Blocos Internos"; $lblLayout.ForeColor = $global:theme.OrangeAccent; $lblLayout.AutoSize = $true
    $lblLayout.Location = "$($layout.Col2_X), 20"; $pnlContent.Controls.Add($lblLayout)

    # Lista Visual dos Blocos
    $lstSets = New-Object System.Windows.Forms.ListBox; $lstSets.Location = "$($layout.Col2_X), 45"; $lstSets.Width = 400; $lstSets.Height = 150
    $lstSets.BackColor = $global:theme.ButtonBack; $lstSets.ForeColor = $global:theme.TextMain; $lstSets.BorderStyle = "FixedSingle"
    $pnlContent.Controls.Add($lstSets)

    # Controles para Adicionar Bloco
    $grpAddSet = New-Object System.Windows.Forms.GroupBox; $grpAddSet.Text = "Adicionar Conjunto"; $grpAddSet.ForeColor = $global:theme.TextDim
    $grpAddSet.Location = "$($layout.Col2_X), 200"; $grpAddSet.Size = "400, 100"
    $pnlContent.Controls.Add($grpAddSet)

    $lblSetH = New-Object System.Windows.Forms.Label; $lblSetH.Text = "H:"; $lblSetH.Location = "10, 25"; $lblSetH.AutoSize = $true; $lblSetH.ForeColor = $global:theme.TextMain
    $txtSetH = New-Object System.Windows.Forms.TextBox; $txtSetH.Location = "30, 22"; $txtSetH.Width = 30; $txtSetH.MaxLength = 1; $txtSetH.BackColor=$global:theme.ButtonBack; $txtSetH.ForeColor=$global:theme.TextMain; $txtSetH.BorderStyle="FixedSingle"
    Add-Validation -Control $txtSetH -Mode "numeric_1_9"
    
    $lblSetV = New-Object System.Windows.Forms.Label; $lblSetV.Text = "V:"; $lblSetV.Location = "70, 25"; $lblSetV.AutoSize = $true; $lblSetV.ForeColor = $global:theme.TextMain
    $txtSetV = New-Object System.Windows.Forms.TextBox; $txtSetV.Location = "90, 22"; $txtSetV.Width = 30; $txtSetV.MaxLength = 1; $txtSetV.BackColor=$global:theme.ButtonBack; $txtSetV.ForeColor=$global:theme.TextMain; $txtSetV.BorderStyle="FixedSingle"
    Add-Validation -Control $txtSetV -Mode "numeric_1_9"

    $lblRep = New-Object System.Windows.Forms.Label; $lblRep.Text = "Repetições:"; $lblRep.Location = "140, 25"; $lblRep.AutoSize = $true; $lblRep.ForeColor = $global:theme.TextMain
    $txtRep = New-Object System.Windows.Forms.TextBox; $txtRep.Location = "210, 22"; $txtRep.Width = 30; $txtRep.MaxLength = 2; $txtRep.Text = "1"; $txtRep.BackColor=$global:theme.ButtonBack; $txtRep.ForeColor=$global:theme.TextMain; $txtRep.BorderStyle="FixedSingle"
    Add-Validation -Control $txtRep -Mode "numeric_no_leading_zero"

    $btnAddSet = New-Object System.Windows.Forms.Button; $btnAddSet.Text = "Adicionar"; $btnAddSet.Location = "260, 20"; $btnAddSet.Width = 80; $btnAddSet.FlatStyle = "Flat"; $btnAddSet.BackColor = $global:theme.GreenSuccess; $btnAddSet.ForeColor = $global:theme.Background
    
    $btnRemSet = New-Object System.Windows.Forms.Button; $btnRemSet.Text = "Remover Selecionado"; $btnRemSet.Location = "260, 55"; $btnRemSet.Width = 130; $btnRemSet.FlatStyle = "Flat"; $btnRemSet.BackColor = $global:theme.RedAlert; $btnRemSet.ForeColor = "White"

    $grpAddSet.Controls.AddRange(@($lblSetH, $txtSetH, $lblSetV, $txtSetV, $lblRep, $txtRep, $btnAddSet, $btnRemSet))

    # [NOVO] Lógica de Ativação/Desativação
    $toggleOptional = {
        $enabled = $rbDetYes.Checked
        $color = if ($enabled) { $global:theme.ButtonBack } else { [System.Drawing.Color]::FromArgb(50, 50, 50) }
        
        # Campos de Tamanho
        foreach ($c in @($txtUnfH, $txtUnfV, $txtFoldH, $txtFoldV)) { 
            $c.Enabled = $enabled; $c.BackColor = $color 
            if (-not $enabled) { $c.Text = "" }
        }
        
        # Lista e Controles
        $lstSets.Enabled = $enabled; $lstSets.BackColor = $color
        $grpAddSet.Enabled = $enabled
        $btnAddSet.Enabled = $enabled
        $btnRemSet.Enabled = $enabled
        
        if (-not $enabled) { $lstSets.Items.Clear() }
    }.GetNewClosure()

    $rbDetYes.Add_CheckedChanged($toggleOptional)
    $rbDetNo.Add_CheckedChanged($toggleOptional)

    # Carregar Layout Existente
    if ($EditItem -and $EditItem.LayoutInterno -ne "/////") {
        $parts = $EditItem.LayoutInterno -split ", "
        foreach ($p in $parts) { $lstSets.Items.Add($p) | Out-Null }
        $rbDetYes.Checked = $true
    } else {
        $rbDetNo.Checked = $true
    }
    
    # Aplica estado inicial
    & $toggleOptional

    # Eventos do Layout Interno
    $btnAddSet.Add_Click({
        if ([string]::IsNullOrWhiteSpace($txtSetH.Text) -or [string]::IsNullOrWhiteSpace($txtSetV.Text)) { return }
        $h = $txtSetH.Text; $v = $txtSetV.Text
        $rep = if ([string]::IsNullOrWhiteSpace($txtRep.Text)) { 1 } else { [int]$txtRep.Text }
        
        $itemStr = "${h}x${v}"
        if ($rep -gt 1) { $itemStr = "($rep)$itemStr" }
        
        $lstSets.Items.Add($itemStr) | Out-Null
        $txtSetH.Clear(); $txtSetV.Clear(); $txtRep.Text = "1"; $txtSetH.Focus()
    })

    $btnRemSet.Add_Click({
        if ($lstSets.SelectedIndex -ge 0) {
            $lstSets.Items.RemoveAt($lstSets.SelectedIndex)
        }
    })

    # --- BOTOES FINAIS ---
    $btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = "Salvar"; $btnSave.Location = "330, 15"; $btnSave.Size = "120, 40"; $btnSave.FlatStyle = "Flat"; $btnSave.BackColor = $global:theme.GreenSuccess; $btnSave.ForeColor = $global:theme.Background
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Cancelar"; $btnCancel.Location = "500, 15"; $btnCancel.Size = "120, 40"; $btnCancel.FlatStyle = "Flat"; $btnCancel.BackColor = $global:theme.ButtonBack; $btnCancel.ForeColor = $global:theme.TextMain
    $pnlButtons.Controls.AddRange(@($btnSave, $btnCancel)); $fEdit.AcceptButton = $btnSave; $fEdit.CancelButton = $btnCancel

    # --- SALVAR ---
    $btnSave.Add_Click({
        $isValid = $true
        
        # Validacoes Obrigatorias
        if ([string]::IsNullOrWhiteSpace($txtName.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtWeight.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtSpace.Text)) { $isValid = $false }
        
        # Validacoes Condicionais (Opcionais)
        if ($rbDetYes.Checked) {
            if ([string]::IsNullOrWhiteSpace($txtUnfH.Text) -or [string]::IsNullOrWhiteSpace($txtUnfV.Text)) { $isValid = $false }
            if ([string]::IsNullOrWhiteSpace($txtFoldH.Text) -or [string]::IsNullOrWhiteSpace($txtFoldV.Text)) { $isValid = $false }
            if ($lstSets.Items.Count -eq 0) { $isValid = $false; [System.Windows.Forms.MessageBox]::Show("Se você escolheu adicionar detalhes, deve adicionar pelo menos um conjunto de blocos!", "Erro", "OK", "Warning"); return }
        }

        if (-not $isValid) { [System.Windows.Forms.MessageBox]::Show("Preencha todos os campos obrigatórios.", "Erro", "OK", "Warning"); return }

        # Processa Tamanhos (Opcionais -> /////)
        $finalUnfolded = "/////"
        $finalFolded = "/////"
        $finalLayout = "/////"

        if ($rbDetYes.Checked) {
            $finalUnfolded = "$($txtUnfH.Text)x$($txtUnfV.Text)"
            $finalFolded   = "$($txtFoldH.Text)x$($txtFoldV.Text)"
            $sets = @(); foreach ($item in $lstSets.Items) { $sets += $item }
            $finalLayout = $sets -join ", "
        }

        $newItemData = [Ordered]@{
            NomeItem          = $txtName.Text.Trim()
            Peso              = $txtWeight.Text
            EspacoTotal       = $txtSpace.Text
            TamanhoDesdobrada = $finalUnfolded
            TamanhoDobrada    = $finalFolded
            LayoutInterno     = $finalLayout
        }

        $csvPath = Join-Path (Get-DatabasePath) "Unarmoredrigs.csv"
        $allItems = @(); if (Test-Path $csvPath) { $allItems = @(Import-Csv $csvPath -Delimiter ";" -Encoding UTF8) }

        if ((-not $EditItem) -or ($EditItem.NomeItem -ne $newItemData.NomeItem)) {
            if ($allItems.NomeItem -contains $newItemData.NomeItem) { [System.Windows.Forms.MessageBox]::Show("Nome já existe!", "Erro", "OK", "Error"); return }
        }

        if ($EditItem) {
            for ($i = 0; $i -lt $allItems.Count; $i++) {
                if ($allItems[$i].NomeItem -eq $EditItem.NomeItem) { $allItems[$i] = [PSCustomObject]$newItemData; break }
            }
        } else { $allItems += [PSCustomObject]$newItemData }

        $allItems | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
        $fEdit.DialogResult = "OK"; $fEdit.Close()
    })

    $fEdit.ShowDialog() | Out-Null
    
    # --- CORREÇÃO MEMORY LEAK: Liberta o formulário da RAM ---
    $fEdit.Dispose()
}

function Start-ArmoredRigEditor {
    param (
        $ui,
        $EditItem = $null
    )

    # 1. Janela
    $fEdit = New-Object System.Windows.Forms.Form
    $fEdit.Size = New-Object System.Drawing.Size(950, 850)
    $fEdit.StartPosition = "CenterParent"
    $fEdit.BackColor = $global:theme.PanelBack
    $fEdit.ForeColor = $global:theme.TextMain
    $fEdit.FormBorderStyle = "FixedDialog"
    $fEdit.MaximizeBox = $false
    $fEdit.MinimizeBox = $false
    $fEdit.Text = if ($EditItem) { "Editar Colete Blindado: $($EditItem.NomeItem)" } else { "Adicionar Novo Colete Blindado" }

    # 2. Paineis
    $pnlContent = New-Object System.Windows.Forms.Panel; $pnlContent.Dock = "Fill"; $pnlContent.AutoScroll = $true; $pnlContent.Padding = New-Object System.Windows.Forms.Padding(0, 0, 0, 80)
    $fEdit.Controls.Add($pnlContent)

    $pnlButtons = New-Object System.Windows.Forms.Panel; $pnlButtons.Dock = "Bottom"; $pnlButtons.Height = 70; $pnlButtons.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $fEdit.Controls.Add($pnlButtons)

    # --- LAYOUT ---
    $layout = @{ RowL = 0; RowR = 0; Col1_X = 30; Col2_X = 480; FieldWidth = 400; RowHeight = 65 }

    function Add-Field {
        param($LabelText, $Control, [int]$Column)
        $x = if ($Column -eq 1) { $layout.Col1_X } else { $layout.Col2_X }
        $r = if ($Column -eq 1) { $layout.RowL } else { $layout.RowR }
        $y = 20 + ($r * $layout.RowHeight)

        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $LabelText; $lbl.Location = "$x, $y"; $lbl.AutoSize = $true; $lbl.ForeColor = $global:theme.OrangeAccent
        $pnlContent.Controls.Add($lbl)
        
        if ($Control) {
            $Control.Location = "$x, $($y + 25)"; $Control.Size = "$($layout.FieldWidth), 30"
            $Control.BackColor = $global:theme.ButtonBack; $Control.ForeColor = $global:theme.TextMain
            if ($Control -is [System.Windows.Forms.TextBox]) { $Control.BorderStyle = "FixedSingle" }
            if ($Control -is [System.Windows.Forms.ComboBox]) { $Control.FlatStyle = "Flat" }
            $pnlContent.Controls.Add($Control)
        }
        
        if ($Column -eq 1) { $layout.RowL++ } else { $layout.RowR++ }
    }

    # --- VALIDACAO ---
    function Add-Validation {
        param($Control, [string]$Mode)
        $Control.Tag = $Mode 
        $Control.ContextMenu = New-Object System.Windows.Forms.ContextMenu
        $Control.Add_KeyDown({
            if (($_.Control -and $_.KeyCode -eq 'V') -or ($_.Shift -and $_.KeyCode -eq 'Insert')) { $_.SuppressKeyPress = $true }
        })
        $kp = {
            $allowed = Test-KeyRestriction -Control $this -Char $_.KeyChar -Mode $this.Tag
            if (-not $allowed) { $_.Handled = $true } 
        }.GetNewClosure()
        $Control.Add_KeyPress($kp)
    }

    # --- MAPAS ---
    $materialMap = [Ordered]@{ "Aramida"="Aramid"; "Polietileno"="Polyethylene"; "Aço endurecido"="Hardened Steel"; "Composto"="Composite"; "Alumínio"="Aluminum"; "Titânio"="Titanium"; "Cerâmica"="Ceramic" }
    $protectedMap = [Ordered]@{ 
        "Tórax"="Chest"
        "Tórax, Abdômen Superior"="Chest, Upper Abdomen"
        "Tórax, Abdômen Superior, Abdômen Inferior"="Chest, Upper Abdomen, Lower Abdomen"
        "Tórax, Ombro, Abdômen Superior, Abdômen Inferior"="Chest, Shoulder, Upper Abdomen, Lower Abdomen" 
    }
    
    $placeholderText = "Selecione os dados aqui"

    # ==========================
    # COLUNA 1 (Dados Fisicos + Velocidade)
    # ==========================

    # 1. Nome
    $txtName = New-Object System.Windows.Forms.TextBox; $txtName.MaxLength = 32
    if ($EditItem) { $txtName.Text = $EditItem.NomeItem }
    Add-Field -LabelText "Qual é o nome do colete blindado?" -Control $txtName -Column 1

    # 2. Peso
    $txtWeight = New-Object System.Windows.Forms.TextBox; $txtWeight.MaxLength = 5 
    Add-Validation -Control $txtWeight -Mode "decimal_weight"
    if ($EditItem) { $txtWeight.Text = $EditItem.Peso }
    Add-Field -LabelText "Qual é o peso? (Ex: 6.20)" -Control $txtWeight -Column 1

    # 3. Durabilidade
    $txtDurab = New-Object System.Windows.Forms.TextBox; $txtDurab.MaxLength = 5 
    Add-Validation -Control $txtDurab -Mode "decimal_durability_fixed"
    if ($EditItem) { $txtDurab.Text = $EditItem.Durabilidade }
    Add-Field -LabelText "Qual é a Durabilidade? (Ex: 85.0)" -Control $txtDurab -Column 1

    # 4. Classe Blindagem
    $txtClass = New-Object System.Windows.Forms.TextBox; $txtClass.MaxLength = 1
    Add-Validation -Control $txtClass -Mode "numeric_1_6"
    if ($EditItem) { $txtClass.Text = $EditItem.ClasseBlindagem }
    Add-Field -LabelText "Qual é a Classe de Blindagem? (1-6)" -Control $txtClass -Column 1

    # 5. Material
    $cmbMat = New-Object System.Windows.Forms.ComboBox; $cmbMat.DropDownStyle = "DropDownList"
    
    # Adiciona placeholder e itens
    $cmbMat.Items.Add($placeholderText) | Out-Null
    foreach ($k in $materialMap.Keys) { $cmbMat.Items.Add($k)|Out-Null }
    
    if ($EditItem) { 
        $k=$materialMap.Keys|Where{$materialMap[$_] -eq $EditItem.Material}
        if($k){$cmbMat.SelectedItem=$k} else {$cmbMat.SelectedIndex=0}
    } else { $cmbMat.SelectedIndex = 0 } 
    
    # Evento para remover placeholder ao abrir
    $cmbMat.Add_DropDown({
        if ($this.Items.Count -gt 0 -and $this.Items[0] -eq "Selecione os dados aqui") {
            $this.Items.RemoveAt(0)
        }
    })

    Add-Field -LabelText "Qual é o Material?" -Control $cmbMat -Column 1

    # 6. Velocidade Movimento
    $grpSpeed = New-Object System.Windows.Forms.Panel; $grpSpeed.Height=60; $grpSpeed.Width=400
    $rbSpdYes = New-Object System.Windows.Forms.RadioButton; $rbSpdYes.Text="Sim"; $rbSpdYes.Location="0,5"; $rbSpdYes.Width=50; $rbSpdYes.ForeColor=$global:theme.TextMain
    $rbSpdNo = New-Object System.Windows.Forms.RadioButton; $rbSpdNo.Text="Não"; $rbSpdNo.Location="60,5"; $rbSpdNo.Width=50; $rbSpdNo.ForeColor=$global:theme.TextMain
    $txtSpdVal = New-Object System.Windows.Forms.TextBox; $txtSpdVal.Location="120,3"; $txtSpdVal.Width=50; $txtSpdVal.MaxLength=3; $txtSpdVal.Visible=$false
    Add-Validation -Control $txtSpdVal -Mode "percentage_negative"
    $lblSpd = New-Object System.Windows.Forms.Label; $lblSpd.Text="%"; $lblSpd.Location="175,5"; $lblSpd.ForeColor=$global:theme.TextDim; $lblSpd.Visible=$false
    $grpSpeed.Controls.AddRange(@($rbSpdYes, $rbSpdNo, $txtSpdVal, $lblSpd))

    $rbSpdYes.Add_CheckedChanged({ $txtSpdVal.Visible=$rbSpdYes.Checked; $lblSpd.Visible=$rbSpdYes.Checked })
    if ($EditItem -and $EditItem.PenalidadeMovimento -ne "/////") { 
        $rbSpdYes.Checked=$true; $txtSpdVal.Text = $EditItem.PenalidadeMovimento -replace '%','' 
    } else { $rbSpdNo.Checked=$true }
    Add-Field -LabelText "Afeta a velocidade de Movimento? (Ex: -10)" -Control $grpSpeed -Column 1

    # ==========================
    # COLUNA 2 (Ergo + Espaco + Area + Layout)
    # ==========================

    # 7. Ergonomia
    $grpErgo = New-Object System.Windows.Forms.Panel; $grpErgo.Height=60; $grpErgo.Width=400
    $rbErgoYes = New-Object System.Windows.Forms.RadioButton; $rbErgoYes.Text="Sim"; $rbErgoYes.Location="0,5"; $rbErgoYes.Width=50; $rbErgoYes.ForeColor=$global:theme.TextMain
    $rbErgoNo = New-Object System.Windows.Forms.RadioButton; $rbErgoNo.Text="Não"; $rbErgoNo.Location="60,5"; $rbErgoNo.Width=50; $rbErgoNo.ForeColor=$global:theme.TextMain
    $txtErgoVal = New-Object System.Windows.Forms.TextBox; $txtErgoVal.Location="120,3"; $txtErgoVal.Width=50; $txtErgoVal.MaxLength=3; $txtErgoVal.Visible=$false
    Add-Validation -Control $txtErgoVal -Mode "numeric_negative_no_leading_zero"
    $grpErgo.Controls.AddRange(@($rbErgoYes, $rbErgoNo, $txtErgoVal))
    
    $rbErgoYes.Add_CheckedChanged({ $txtErgoVal.Visible = $rbErgoYes.Checked })
    if ($EditItem -and $EditItem.Ergonomia -ne "/////") { $rbErgoYes.Checked=$true; $txtErgoVal.Text=$EditItem.Ergonomia } else { $rbErgoNo.Checked=$true }
    Add-Field -LabelText "Afeta a Ergonomia? (Ex: -10)" -Control $grpErgo -Column 2

    # 8. Espaco Armazenamento
    $txtSpace = New-Object System.Windows.Forms.TextBox; $txtSpace.MaxLength = 2
    Add-Validation -Control $txtSpace -Mode "numeric"
    if ($EditItem) { $txtSpace.Text = $EditItem.EspacoArmazenamento }
    Add-Field -LabelText "Espaço de armazenamento (Ex: 20):" -Control $txtSpace -Column 2

    # 9. Area Protegida
    $cmbProt = New-Object System.Windows.Forms.ComboBox; $cmbProt.DropDownStyle = "DropDownList"
    
    # Adiciona placeholder e itens
    $cmbProt.Items.Add($placeholderText) | Out-Null
    foreach ($k in $protectedMap.Keys) { $cmbProt.Items.Add($k)|Out-Null }
    
    if ($EditItem) { 
        $k=$protectedMap.Keys|Where{$protectedMap[$_] -eq $EditItem.AreaProtegida}
        if($k){$cmbProt.SelectedItem=$k} else {$cmbProt.SelectedIndex = 0}
    } else { $cmbProt.SelectedIndex = 0 }

    # Evento para remover placeholder ao abrir
    $cmbProt.Add_DropDown({
        if ($this.Items.Count -gt 0 -and $this.Items[0] -eq "Selecione os dados aqui") {
            $this.Items.RemoveAt(0)
        }
    })

    Add-Field -LabelText "Quais partes do corpo protege?" -Control $cmbProt -Column 2

    # [NOVO] Pergunta sobre Detalhes Opcionais
    # Adicionada aqui (fim da coluna 2, antes do layout)
    $grpDetails = New-Object System.Windows.Forms.Panel; $grpDetails.Height=30; $grpDetails.Width=400
    $rbDetYes = New-Object System.Windows.Forms.RadioButton; $rbDetYes.Text="Sim"; $rbDetYes.Location="0,5"; $rbDetYes.Width=50; $rbDetYes.ForeColor=$global:theme.TextMain
    $rbDetNo = New-Object System.Windows.Forms.RadioButton; $rbDetNo.Text="Não"; $rbDetNo.Location="60,5"; $rbDetNo.Width=50; $rbDetNo.ForeColor=$global:theme.TextMain
    $grpDetails.Controls.AddRange(@($rbDetYes, $rbDetNo))
    
    # Ajuste manual de posição vertical para inserir entre "Area Protegida" e "Blocos Internos"
    $layout.RowR += 0.2
    Add-Field -LabelText "Deseja adicionar detalhes de tamanho e blocos?" -Control $grpDetails -Column 2

    # --- LAYOUT INTERNO ---
    $lblLayout = New-Object System.Windows.Forms.Label; $lblLayout.Text = "Blocos Internos (Ex: 2x3)"; $lblLayout.ForeColor = $global:theme.OrangeAccent; $lblLayout.AutoSize = $true
    $lblLayout.Location = "$($layout.Col2_X), $($layout.RowR * 65 + 40)"; $pnlContent.Controls.Add($lblLayout)

    $lstSets = New-Object System.Windows.Forms.ListBox; $lstSets.Location = "$($layout.Col2_X), $($layout.RowR * 65 + 65)"; $lstSets.Width = 400; $lstSets.Height = 100
    $lstSets.BackColor = $global:theme.ButtonBack; $lstSets.ForeColor = $global:theme.TextMain; $lstSets.BorderStyle = "FixedSingle"
    $pnlContent.Controls.Add($lstSets)

    $grpAddSet = New-Object System.Windows.Forms.GroupBox; $grpAddSet.Text = "Adicionar Conjunto"; $grpAddSet.ForeColor = $global:theme.TextDim
    $grpAddSet.Location = "$($layout.Col2_X), $($layout.RowR * 65 + 170)"; $grpAddSet.Size = "400, 100" 
    $pnlContent.Controls.Add($grpAddSet)

    $lblSetH = New-Object System.Windows.Forms.Label; $lblSetH.Text = "H:"; $lblSetH.Location = "10, 25"; $lblSetH.AutoSize = $true; $lblSetH.ForeColor = $global:theme.TextMain
    $txtSetH = New-Object System.Windows.Forms.TextBox; $txtSetH.Location = "30, 22"; $txtSetH.Width = 30; $txtSetH.MaxLength = 1; $txtSetH.BackColor=$global:theme.ButtonBack; $txtSetH.ForeColor=$global:theme.TextMain; $txtSetH.BorderStyle="FixedSingle"
    Add-Validation -Control $txtSetH -Mode "numeric_1_9"
    
    $lblSetV = New-Object System.Windows.Forms.Label; $lblSetV.Text = "V:"; $lblSetV.Location = "70, 25"; $lblSetV.AutoSize = $true; $lblSetV.ForeColor = $global:theme.TextMain
    $txtSetV = New-Object System.Windows.Forms.TextBox; $txtSetV.Location = "90, 22"; $txtSetV.Width = 30; $txtSetV.MaxLength = 1; $txtSetV.BackColor=$global:theme.ButtonBack; $txtSetV.ForeColor=$global:theme.TextMain; $txtSetV.BorderStyle="FixedSingle"
    Add-Validation -Control $txtSetV -Mode "numeric_1_9"

    $lblRep = New-Object System.Windows.Forms.Label; $lblRep.Text = "Repetições:"; $lblRep.Location = "140, 25"; $lblRep.AutoSize = $true; $lblRep.ForeColor = $global:theme.TextMain
    $txtRep = New-Object System.Windows.Forms.TextBox; $txtRep.Location = "210, 22"; $txtRep.Width = 30; $txtRep.MaxLength = 2; $txtRep.Text = "1"; $txtRep.BackColor=$global:theme.ButtonBack; $txtRep.ForeColor=$global:theme.TextMain; $txtRep.BorderStyle="FixedSingle"
    Add-Validation -Control $txtRep -Mode "numeric_no_leading_zero"

    $btnAddSet = New-Object System.Windows.Forms.Button; $btnAddSet.Text = "Adicionar"; $btnAddSet.Location = "260, 20"; $btnAddSet.Width = 80; $btnAddSet.FlatStyle = "Flat"; $btnAddSet.BackColor = $global:theme.GreenSuccess; $btnAddSet.ForeColor = $global:theme.Background
    $btnRemSet = New-Object System.Windows.Forms.Button; $btnRemSet.Text = "Remover Selecionado"; $btnRemSet.Location = "260, 55"; $btnRemSet.Width = 130; $btnRemSet.FlatStyle = "Flat"; $btnRemSet.BackColor = $global:theme.RedAlert; $btnRemSet.ForeColor = "White"

    $grpAddSet.Controls.AddRange(@($lblSetH, $txtSetH, $lblSetV, $txtSetV, $lblRep, $txtRep, $btnAddSet, $btnRemSet))

    # [NOVO] Lógica de Ativação/Desativação
    $toggleOptional = {
        $enabled = $rbDetYes.Checked
        $color = if ($enabled) { $global:theme.ButtonBack } else { [System.Drawing.Color]::FromArgb(50, 50, 50) }
        
        # Lista e Controles
        $lstSets.Enabled = $enabled; $lstSets.BackColor = $color
        $grpAddSet.Enabled = $enabled
        $btnAddSet.Enabled = $enabled
        $btnRemSet.Enabled = $enabled
        
        if (-not $enabled) { $lstSets.Items.Clear() }
    }.GetNewClosure()

    $rbDetYes.Add_CheckedChanged($toggleOptional)
    $rbDetNo.Add_CheckedChanged($toggleOptional)

    # Carregar Layout Existente
    if ($EditItem -and $EditItem.LayoutInterno -ne "/////") {
        $parts = $EditItem.LayoutInterno -split ", "
        foreach ($p in $parts) { $lstSets.Items.Add($p) | Out-Null }
        $rbDetYes.Checked = $true
    } else {
        $rbDetNo.Checked = $true
    }
    
    # Aplica estado inicial
    & $toggleOptional

    # Eventos do Layout
    $btnAddSet.Add_Click({
        if ([string]::IsNullOrWhiteSpace($txtSetH.Text) -or [string]::IsNullOrWhiteSpace($txtSetV.Text)) { return }
        $h = $txtSetH.Text; $v = $txtSetV.Text
        $rep = if ([string]::IsNullOrWhiteSpace($txtRep.Text)) { 1 } else { [int]$txtRep.Text }
        
        $itemStr = "${h}x${v}"
        if ($rep -gt 1) { $itemStr = "($rep)$itemStr" }
        
        $lstSets.Items.Add($itemStr) | Out-Null
        $txtSetH.Clear(); $txtSetV.Clear(); $txtRep.Text = "1"; $txtSetH.Focus()
    })

    $btnRemSet.Add_Click({ if ($lstSets.SelectedIndex -ge 0) { $lstSets.Items.RemoveAt($lstSets.SelectedIndex) } })

    # --- BOTOES ---
    $btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = "Salvar"; $btnSave.Location = "330, 15"; $btnSave.Size = "120, 40"; $btnSave.FlatStyle = "Flat"; $btnSave.BackColor = $global:theme.GreenSuccess; $btnSave.ForeColor = $global:theme.Background
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Cancelar"; $btnCancel.Location = "500, 15"; $btnCancel.Size = "120, 40"; $btnCancel.FlatStyle = "Flat"; $btnCancel.BackColor = $global:theme.ButtonBack; $btnCancel.ForeColor = $global:theme.TextMain
    $pnlButtons.Controls.AddRange(@($btnSave, $btnCancel)); $fEdit.AcceptButton = $btnSave; $fEdit.CancelButton = $btnCancel

    # --- SALVAR ---
    $btnSave.Add_Click({
        $isValid = $true
        
        # Validacoes Obrigatorias
        if ([string]::IsNullOrWhiteSpace($txtName.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtWeight.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtDurab.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtClass.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtSpace.Text)) { $isValid = $false }
        
        # Validacao do Placeholder
        if (-not $cmbMat.SelectedItem -or $cmbMat.SelectedItem -eq $placeholderText) { $isValid = $false }
        if (-not $cmbProt.SelectedItem -or $cmbProt.SelectedItem -eq $placeholderText) { $isValid = $false }
        
        if ($rbSpdYes.Checked -and [string]::IsNullOrWhiteSpace($txtSpdVal.Text)) { $isValid = $false }
        if ($rbErgoYes.Checked -and [string]::IsNullOrWhiteSpace($txtErgoVal.Text)) { $isValid = $false }

        # Validacao Opcional
        if ($rbDetYes.Checked) {
            if ($lstSets.Items.Count -eq 0) { 
                $isValid = $false
                [System.Windows.Forms.MessageBox]::Show("Se você escolheu adicionar detalhes, deve adicionar pelo menos um conjunto de blocos!", "Erro", "OK", "Warning"); return 
            }
        }

        if (-not $isValid) { [System.Windows.Forms.MessageBox]::Show("Complete o formulário.`nVerifique se não há campos vazios ou 'Selecione os dados aqui'.", "Erro", "OK", "Warning"); return }

        $finalSpd = if ($rbSpdYes.Checked) { "$($txtSpdVal.Text)%" } else { "/////" }
        $finalErgo = if ($rbErgoYes.Checked) { $txtErgoVal.Text } else { "/////" }
        
        $finalLayout = if ($rbDetYes.Checked) {
            $sets = @(); foreach ($item in $lstSets.Items) { $sets += $item }
            $sets -join ", "
        } else { "/////" }

        $newItemData = [Ordered]@{
            NomeItem            = $txtName.Text.Trim()
            Peso                = $txtWeight.Text
            Durabilidade        = $txtDurab.Text
            ClasseBlindagem     = $txtClass.Text
            Material            = $materialMap[$cmbMat.SelectedItem]
            PenalidadeMovimento = $finalSpd
            Ergonomia           = $finalErgo
            EspacoArmazenamento = $txtSpace.Text
            AreaProtegida       = $protectedMap[$cmbProt.SelectedItem]
            LayoutInterno       = $finalLayout
        }

        $csvPath = Join-Path (Get-DatabasePath) "Armoredrigs.csv"
        $allItems = @(); if (Test-Path $csvPath) { $allItems = @(Import-Csv $csvPath -Delimiter ";" -Encoding UTF8) }

        if ((-not $EditItem) -or ($EditItem.NomeItem -ne $newItemData.NomeItem)) {
            if ($allItems.NomeItem -contains $newItemData.NomeItem) { [System.Windows.Forms.MessageBox]::Show("Nome já existe!", "Erro", "OK", "Error"); return }
        }

        if ($EditItem) {
            for ($i = 0; $i -lt $allItems.Count; $i++) {
                if ($allItems[$i].NomeItem -eq $EditItem.NomeItem) { $allItems[$i] = [PSCustomObject]$newItemData; break }
            }
        } else { $allItems += [PSCustomObject]$newItemData }

        $allItems | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
        $fEdit.DialogResult = "OK"; $fEdit.Close()
    })

    $fEdit.ShowDialog() | Out-Null

    # --- CORREÇÃO MEMORY LEAK: Liberta a janela da RAM ---
    $fEdit.Dispose()
}

function Start-BackpackEditor {
    param (
        $ui,
        $EditItem = $null
    )

    # 1. Janela
    $fEdit = New-Object System.Windows.Forms.Form
    $fEdit.Size = New-Object System.Drawing.Size(950, 750)
    $fEdit.StartPosition = "CenterParent"
    $fEdit.BackColor = $global:theme.PanelBack
    $fEdit.ForeColor = $global:theme.TextMain
    $fEdit.FormBorderStyle = "FixedDialog"
    $fEdit.MaximizeBox = $false
    $fEdit.MinimizeBox = $false
    $fEdit.Text = if ($EditItem) { "Editar Mochila: $($EditItem.NomeItem)" } else { "Adicionar Nova Mochila" }

    # 2. Paineis
    $pnlContent = New-Object System.Windows.Forms.Panel; $pnlContent.Dock = "Fill"; $pnlContent.AutoScroll = $true; $pnlContent.Padding = New-Object System.Windows.Forms.Padding(0, 0, 0, 80)
    $fEdit.Controls.Add($pnlContent)

    $pnlButtons = New-Object System.Windows.Forms.Panel; $pnlButtons.Dock = "Bottom"; $pnlButtons.Height = 70; $pnlButtons.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $fEdit.Controls.Add($pnlButtons)

    # --- LAYOUT ---
    $layout = @{ RowL = 0; RowR = 0; Col1_X = 30; Col2_X = 480; FieldWidth = 400; RowHeight = 65 }

    function Add-Field {
        param($LabelText, $Control, [int]$Column)
        $x = if ($Column -eq 1) { $layout.Col1_X } else { $layout.Col2_X }
        $r = if ($Column -eq 1) { $layout.RowL } else { $layout.RowR }
        $y = 20 + ($r * $layout.RowHeight)

        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $LabelText; $lbl.Location = "$x, $y"; $lbl.AutoSize = $true; $lbl.ForeColor = $global:theme.OrangeAccent
        $pnlContent.Controls.Add($lbl)
        
        if ($Control) {
            $Control.Location = "$x, $($y + 25)"; $Control.Size = "$($layout.FieldWidth), 30"
            $Control.BackColor = $global:theme.ButtonBack; $Control.ForeColor = $global:theme.TextMain
            if ($Control -is [System.Windows.Forms.TextBox]) { $Control.BorderStyle = "FixedSingle" }
            $pnlContent.Controls.Add($Control)
        }
        
        if ($Column -eq 1) { $layout.RowL++ } else { $layout.RowR++ }
    }

    # --- VALIDACAO ---
    function Add-Validation {
        param($Control, [string]$Mode)
        $Control.Tag = $Mode 
        $Control.ContextMenu = New-Object System.Windows.Forms.ContextMenu
        $Control.Add_KeyDown({
            if (($_.Control -and $_.KeyCode -eq 'V') -or ($_.Shift -and $_.KeyCode -eq 'Insert')) { $_.SuppressKeyPress = $true }
        })
        $kp = {
            $allowed = Test-KeyRestriction -Control $this -Char $_.KeyChar -Mode $this.Tag
            if (-not $allowed) { $_.Handled = $true } 
        }.GetNewClosure()
        $Control.Add_KeyPress($kp)
    }

    # ==========================
    # COLUNA 1 (Dados Basicos)
    # ==========================

    # 1. Nome
    $txtName = New-Object System.Windows.Forms.TextBox; $txtName.MaxLength = 36
    if ($EditItem) { $txtName.Text = $EditItem.NomeItem }
    Add-Field -LabelText "Qual é o nome da mochila?" -Control $txtName -Column 1

    # 2. Peso
    $txtWeight = New-Object System.Windows.Forms.TextBox; $txtWeight.MaxLength = 5 
    Add-Validation -Control $txtWeight -Mode "decimal_backpack_weight" 
    if ($EditItem) { $txtWeight.Text = $EditItem.Peso }
    Add-Field -LabelText "Qual é o peso da mochila? (Exemplo: 2.50)" -Control $txtWeight -Column 1

    # 3. Espaco
    $txtSpace = New-Object System.Windows.Forms.TextBox; $txtSpace.MaxLength = 2
    Add-Validation -Control $txtSpace -Mode "numeric"
    if ($EditItem) { $txtSpace.Text = $EditItem.EspacoTotal }
    Add-Field -LabelText "Qual é o espaço da mochila? (Exemplo: 20)" -Control $txtSpace -Column 1

    # [NOVO] Pergunta sobre Detalhes Opcionais
    $grpDetails = New-Object System.Windows.Forms.Panel; $grpDetails.Height=30; $grpDetails.Width=400
    $rbDetYes = New-Object System.Windows.Forms.RadioButton; $rbDetYes.Text="Sim"; $rbDetYes.Location="0,5"; $rbDetYes.Width=50; $rbDetYes.ForeColor=$global:theme.TextMain
    $rbDetNo = New-Object System.Windows.Forms.RadioButton; $rbDetNo.Text="Não"; $rbDetNo.Location="60,5"; $rbDetNo.Width=50; $rbDetNo.ForeColor=$global:theme.TextMain
    $grpDetails.Controls.AddRange(@($rbDetYes, $rbDetNo))
    
    Add-Field -LabelText "Deseja adicionar detalhes de tamanho e blocos?" -Control $grpDetails -Column 1

    # --- TAMANHOS ---
    function Create-SizeInput {
        param($GroupLabel, [ref]$H_Ref, [ref]$V_Ref, $InitialValue)
        
        $pnl = New-Object System.Windows.Forms.Panel; $pnl.Height = 35; $pnl.Width = 400
        
        $lblX = New-Object System.Windows.Forms.Label; $lblX.Text = "Horiz:"; $lblX.Location = "0,8"; $lblX.AutoSize = $true; $lblX.ForeColor = $global:theme.TextDim
        $txtH = New-Object System.Windows.Forms.TextBox; $txtH.Location = "45,5"; $txtH.Width = 30; $txtH.MaxLength = 1; $txtH.BackColor=$global:theme.ButtonBack; $txtH.ForeColor=$global:theme.TextMain; $txtH.BorderStyle="FixedSingle"
        Add-Validation -Control $txtH -Mode "numeric_1_9"
        
        $lblY = New-Object System.Windows.Forms.Label; $lblY.Text = "Vert:"; $lblY.Location = "90,8"; $lblY.AutoSize = $true; $lblY.ForeColor = $global:theme.TextDim
        $txtV = New-Object System.Windows.Forms.TextBox; $txtV.Location = "130,5"; $txtV.Width = 30; $txtV.MaxLength = 1; $txtV.BackColor=$global:theme.ButtonBack; $txtV.ForeColor=$global:theme.TextMain; $txtV.BorderStyle="FixedSingle"
        Add-Validation -Control $txtV -Mode "numeric_1_9"

        $pnl.Controls.AddRange(@($lblX, $txtH, $lblY, $txtV))
        Add-Field -LabelText $GroupLabel -Control $pnl -Column 1
        
        if ($InitialValue -match '(\d)x(\d)') {
            $txtH.Text = $Matches[1]; $txtV.Text = $Matches[2]
        }
        
        $H_Ref.Value = $txtH; $V_Ref.Value = $txtV
        return $pnl
    }

    $txtUnfH = $null; $txtUnfV = $null
    $pnlUnf = Create-SizeInput -GroupLabel "Tamanho Desdobrado (H x V)" -H_Ref ([ref]$txtUnfH) -V_Ref ([ref]$txtUnfV) -InitialValue $EditItem.TamanhoDesdobrada

    $txtFoldH = $null; $txtFoldV = $null
    $pnlFold = Create-SizeInput -GroupLabel "Tamanho Dobrado (H x V)" -H_Ref ([ref]$txtFoldH) -V_Ref ([ref]$txtFoldV) -InitialValue $EditItem.TamanhoDobrada

    # ==========================
    # COLUNA 2 (Layout Interno)
    # ==========================
    
    $lblLayout = New-Object System.Windows.Forms.Label; $lblLayout.Text = "Conjuntos de Blocos Internos"; $lblLayout.ForeColor = $global:theme.OrangeAccent; $lblLayout.AutoSize = $true
    $lblLayout.Location = "$($layout.Col2_X), 20"; $pnlContent.Controls.Add($lblLayout)

    $lstSets = New-Object System.Windows.Forms.ListBox; $lstSets.Location = "$($layout.Col2_X), 45"; $lstSets.Width = 400; $lstSets.Height = 150
    $lstSets.BackColor = $global:theme.ButtonBack; $lstSets.ForeColor = $global:theme.TextMain; $lstSets.BorderStyle = "FixedSingle"
    $pnlContent.Controls.Add($lstSets)

    $grpAddSet = New-Object System.Windows.Forms.GroupBox; $grpAddSet.Text = "Adicionar Conjunto"; $grpAddSet.ForeColor = $global:theme.TextDim
    $grpAddSet.Location = "$($layout.Col2_X), 200"; $grpAddSet.Size = "400, 100"
    $pnlContent.Controls.Add($grpAddSet)

    $lblSetH = New-Object System.Windows.Forms.Label; $lblSetH.Text = "H:"; $lblSetH.Location = "10, 25"; $lblSetH.AutoSize = $true; $lblSetH.ForeColor = $global:theme.TextMain
    $txtSetH = New-Object System.Windows.Forms.TextBox; $txtSetH.Location = "30, 22"; $txtSetH.Width = 30; $txtSetH.MaxLength = 1; $txtSetH.BackColor=$global:theme.ButtonBack; $txtSetH.ForeColor=$global:theme.TextMain; $txtSetH.BorderStyle="FixedSingle"
    Add-Validation -Control $txtSetH -Mode "numeric_1_9"
    
    $lblSetV = New-Object System.Windows.Forms.Label; $lblSetV.Text = "V:"; $lblSetV.Location = "70, 25"; $lblSetV.AutoSize = $true; $lblSetV.ForeColor = $global:theme.TextMain
    $txtSetV = New-Object System.Windows.Forms.TextBox; $txtSetV.Location = "90, 22"; $txtSetV.Width = 30; $txtSetV.MaxLength = 1; $txtSetV.BackColor=$global:theme.ButtonBack; $txtSetV.ForeColor=$global:theme.TextMain; $txtSetV.BorderStyle="FixedSingle"
    Add-Validation -Control $txtSetV -Mode "numeric_1_9"

    $lblRep = New-Object System.Windows.Forms.Label; $lblRep.Text = "Repetições:"; $lblRep.Location = "140, 25"; $lblRep.AutoSize = $true; $lblRep.ForeColor = $global:theme.TextMain
    $txtRep = New-Object System.Windows.Forms.TextBox; $txtRep.Location = "210, 22"; $txtRep.Width = 30; $txtRep.MaxLength = 2; $txtRep.Text = "1"; $txtRep.BackColor=$global:theme.ButtonBack; $txtRep.ForeColor=$global:theme.TextMain; $txtRep.BorderStyle="FixedSingle"
    Add-Validation -Control $txtRep -Mode "numeric_no_leading_zero"

    $btnAddSet = New-Object System.Windows.Forms.Button; $btnAddSet.Text = "Adicionar"; $btnAddSet.Location = "260, 20"; $btnAddSet.Width = 80; $btnAddSet.FlatStyle = "Flat"; $btnAddSet.BackColor = $global:theme.GreenSuccess; $btnAddSet.ForeColor = $global:theme.Background
    $btnRemSet = New-Object System.Windows.Forms.Button; $btnRemSet.Text = "Remover Selecionado"; $btnRemSet.Location = "260, 55"; $btnRemSet.Width = 130; $btnRemSet.FlatStyle = "Flat"; $btnRemSet.BackColor = $global:theme.RedAlert; $btnRemSet.ForeColor = "White"

    $grpAddSet.Controls.AddRange(@($lblSetH, $txtSetH, $lblSetV, $txtSetV, $lblRep, $txtRep, $btnAddSet, $btnRemSet))

    # [NOVO] Lógica de Ativação/Desativação dos Campos Opcionais
    $toggleOptional = {
        $enabled = $rbDetYes.Checked
        $color = if ($enabled) { $global:theme.ButtonBack } else { [System.Drawing.Color]::FromArgb(50, 50, 50) }
        
        # Campos de Tamanho
        foreach ($c in @($txtUnfH, $txtUnfV, $txtFoldH, $txtFoldV)) { 
            $c.Enabled = $enabled; $c.BackColor = $color 
            if (-not $enabled) { $c.Text = "" } # Limpa se desabilitar
        }
        
        # Lista e Controles de Adicao
        $lstSets.Enabled = $enabled; $lstSets.BackColor = $color
        $grpAddSet.Enabled = $enabled
        $btnAddSet.Enabled = $enabled
        $btnRemSet.Enabled = $enabled
        
        if (-not $enabled) { $lstSets.Items.Clear() } # Limpa lista se desabilitar
    }.GetNewClosure()

    $rbDetYes.Add_CheckedChanged($toggleOptional)
    $rbDetNo.Add_CheckedChanged($toggleOptional)

    # Lógica de Carregamento Inicial
    if ($EditItem -and $EditItem.LayoutInterno -ne "/////") {
        $parts = $EditItem.LayoutInterno -split ", "
        foreach ($p in $parts) { $lstSets.Items.Add($p) | Out-Null }
        $rbDetYes.Checked = $true
    } else {
        $rbDetNo.Checked = $true # Padrão é NAO (Opcional)
    }
    
    # Aplica o estado visual inicial
    & $toggleOptional

    # Eventos Layout
    $btnAddSet.Add_Click({
        if ([string]::IsNullOrWhiteSpace($txtSetH.Text) -or [string]::IsNullOrWhiteSpace($txtSetV.Text)) { return }
        $h = $txtSetH.Text; $v = $txtSetV.Text
        $rep = if ([string]::IsNullOrWhiteSpace($txtRep.Text)) { 1 } else { [int]$txtRep.Text }
        
        $itemStr = "${h}x${v}"
        if ($rep -gt 1) { $itemStr = "($rep)$itemStr" }
        
        $lstSets.Items.Add($itemStr) | Out-Null
        $txtSetH.Clear(); $txtSetV.Clear(); $txtRep.Text = "1"; $txtSetH.Focus()
    })

    $btnRemSet.Add_Click({ if ($lstSets.SelectedIndex -ge 0) { $lstSets.Items.RemoveAt($lstSets.SelectedIndex) } })

    # --- BOTOES ---
    $btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = "Salvar"; $btnSave.Location = "330, 15"; $btnSave.Size = "120, 40"; $btnSave.FlatStyle = "Flat"; $btnSave.BackColor = $global:theme.GreenSuccess; $btnSave.ForeColor = $global:theme.Background
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Cancelar"; $btnCancel.Location = "500, 15"; $btnCancel.Size = "120, 40"; $btnCancel.FlatStyle = "Flat"; $btnCancel.BackColor = $global:theme.ButtonBack; $btnCancel.ForeColor = $global:theme.TextMain
    $pnlButtons.Controls.AddRange(@($btnSave, $btnCancel)); $fEdit.AcceptButton = $btnSave; $fEdit.CancelButton = $btnCancel

    # --- SALVAR ---
    $btnSave.Add_Click({
        $isValid = $true
        
        # 1. Validação SEMPRE Obrigatória
        if ([string]::IsNullOrWhiteSpace($txtName.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtWeight.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtSpace.Text)) { $isValid = $false }
        
        # 2. Validação Condicional (Se Sim, obriga preencher)
        if ($rbDetYes.Checked) {
            if ([string]::IsNullOrWhiteSpace($txtUnfH.Text) -or [string]::IsNullOrWhiteSpace($txtUnfV.Text)) { $isValid = $false }
            if ([string]::IsNullOrWhiteSpace($txtFoldH.Text) -or [string]::IsNullOrWhiteSpace($txtFoldV.Text)) { $isValid = $false }
            if ($lstSets.Items.Count -eq 0) { $isValid = $false; [System.Windows.Forms.MessageBox]::Show("Se você escolheu adicionar detalhes, deve adicionar pelo menos um conjunto de blocos!", "Erro", "OK", "Warning"); return }
        }

        if (-not $isValid) { [System.Windows.Forms.MessageBox]::Show("Preencha todos os campos obrigatórios.", "Erro", "OK", "Warning"); return }

        # Define os valores finais
        $finalUnfolded = "/////"
        $finalFolded = "/////"
        $finalLayout = "/////"

        if ($rbDetYes.Checked) {
            $finalUnfolded = "$($txtUnfH.Text)x$($txtUnfV.Text)"
            $finalFolded   = "$($txtFoldH.Text)x$($txtFoldV.Text)"
            $sets = @(); foreach ($item in $lstSets.Items) { $sets += $item }
            $finalLayout = $sets -join ", "
        }

        $newItemData = [Ordered]@{
            NomeItem          = $txtName.Text.Trim()
            Peso              = $txtWeight.Text
            EspacoTotal       = $txtSpace.Text
            TamanhoDesdobrada = $finalUnfolded
            TamanhoDobrada    = $finalFolded
            LayoutInterno     = $finalLayout
        }

        $csvPath = Join-Path (Get-DatabasePath) "Backpacks.csv"
        $allItems = @(); if (Test-Path $csvPath) { $allItems = @(Import-Csv $csvPath -Delimiter ";" -Encoding UTF8) }

        if ((-not $EditItem) -or ($EditItem.NomeItem -ne $newItemData.NomeItem)) {
            if ($allItems.NomeItem -contains $newItemData.NomeItem) { [System.Windows.Forms.MessageBox]::Show("Nome já existe!", "Erro", "OK", "Error"); return }
        }

        if ($EditItem) {
            for ($i = 0; $i -lt $allItems.Count; $i++) {
                if ($allItems[$i].NomeItem -eq $EditItem.NomeItem) { $allItems[$i] = [PSCustomObject]$newItemData; break }
            }
        } else { $allItems += [PSCustomObject]$newItemData }

        $allItems | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
        $fEdit.DialogResult = "OK"; $fEdit.Close()
    })

    $fEdit.ShowDialog() | Out-Null
    
    # --- CORREÇÃO MEMORY LEAK: Liberta os recursos da janela da RAM ---
    $fEdit.Dispose()
}

function Start-MaskEditor {
    param (
        $ui,
        $EditItem = $null
    )

    # 1. Janela
    $fEdit = New-Object System.Windows.Forms.Form
    $fEdit.Size = New-Object System.Drawing.Size(950, 750)
    $fEdit.StartPosition = "CenterParent"
    $fEdit.BackColor = $global:theme.PanelBack
    $fEdit.ForeColor = $global:theme.TextMain
    $fEdit.FormBorderStyle = "FixedDialog"
    $fEdit.MaximizeBox = $false
    $fEdit.MinimizeBox = $false
    $fEdit.Text = if ($EditItem) { "Editar Máscara: $($EditItem.NomeItem)" } else { "Adicionar Nova Máscara" }

    # 2. Paineis
    $pnlContent = New-Object System.Windows.Forms.Panel; $pnlContent.Dock = "Fill"; $pnlContent.AutoScroll = $true; $pnlContent.Padding = New-Object System.Windows.Forms.Padding(0, 0, 0, 80)
    $fEdit.Controls.Add($pnlContent)

    $pnlButtons = New-Object System.Windows.Forms.Panel; $pnlButtons.Dock = "Bottom"; $pnlButtons.Height = 70; $pnlButtons.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $fEdit.Controls.Add($pnlButtons)

    # --- LAYOUT ---
    $layout = @{ RowL = 0; RowR = 0; Col1_X = 30; Col2_X = 480; FieldWidth = 400; RowHeight = 65 }

    function Add-Field {
        param($LabelText, $Control, [int]$Column)
        $x = if ($Column -eq 1) { $layout.Col1_X } else { $layout.Col2_X }
        $r = if ($Column -eq 1) { $layout.RowL } else { $layout.RowR }
        $y = 20 + ($r * $layout.RowHeight)

        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $LabelText; $lbl.Location = "$x, $y"; $lbl.AutoSize = $true; $lbl.ForeColor = $global:theme.OrangeAccent
        $pnlContent.Controls.Add($lbl)
        
        if ($Control) {
            $Control.Location = "$x, $($y + 25)"; $Control.Size = "$($layout.FieldWidth), 30"
            $Control.BackColor = $global:theme.ButtonBack; $Control.ForeColor = $global:theme.TextMain
            if ($Control -is [System.Windows.Forms.TextBox]) { $Control.BorderStyle = "FixedSingle" }
            if ($Control -is [System.Windows.Forms.ComboBox]) { $Control.FlatStyle = "Flat" }
            $pnlContent.Controls.Add($Control)
        }
        
        if ($Column -eq 1) { $layout.RowL++ } else { $layout.RowR++ }
    }

    # --- VALIDACAO ---
    function Add-Validation {
        param($Control, [string]$Mode)
        $Control.Tag = $Mode 
        $Control.ContextMenu = New-Object System.Windows.Forms.ContextMenu
        $Control.Add_KeyDown({
            if (($_.Control -and $_.KeyCode -eq 'V') -or ($_.Shift -and $_.KeyCode -eq 'Insert')) { $_.SuppressKeyPress = $true }
        })
        $kp = {
            $allowed = Test-KeyRestriction -Control $this -Char $_.KeyChar -Mode $this.Tag
            if (-not $allowed) { $_.Handled = $true } 
        }.GetNewClosure()
        $Control.Add_KeyPress($kp)
    }

    # --- MAPAS DE DADOS ---
    $materialMap = [Ordered]@{ "Vidro"="Glass"; "Aço endurecido"="Hardened Steel"; "Composto"="Composite"; "Alumínio"="Aluminum" }
    $ricochetMap = [Ordered]@{ "Baixo"="Low"; "Médio"="Medium"; "Alto"="High" }
    
    $placeholderText = "Selecione os dados aqui"

    # ==========================
    # COLUNA 1
    # ==========================

    # 1. Nome
    $txtName = New-Object System.Windows.Forms.TextBox; $txtName.MaxLength = 38
    if ($EditItem) { $txtName.Text = $EditItem.NomeItem }
    Add-Field -LabelText "Qual é o nome da máscara?" -Control $txtName -Column 1

    # 2. Peso
    $txtWeight = New-Object System.Windows.Forms.TextBox; $txtWeight.MaxLength = 4
    Add-Validation -Control $txtWeight -Mode "decimal_mask_weight"
    if ($EditItem) { $txtWeight.Text = $EditItem.Peso }
    Add-Field -LabelText "Qual é o peso da máscara? (Exemplo: 1.20)" -Control $txtWeight -Column 1

    # 3. Durabilidade
    $txtDurab = New-Object System.Windows.Forms.TextBox; $txtDurab.MaxLength = 4
    Add-Validation -Control $txtDurab -Mode "decimal_mask_durability"
    if ($EditItem) { $txtDurab.Text = $EditItem.Durabilidade }
    Add-Field -LabelText "Qual é a Durabilidade da máscara? (Exemplo: 45.0)" -Control $txtDurab -Column 1

    # ==========================
    # COLUNA 2
    # ==========================

    # 4. Classe
    $txtClass = New-Object System.Windows.Forms.TextBox; $txtClass.MaxLength = 1
    Add-Validation -Control $txtClass -Mode "numeric_1_6"
    if ($EditItem) { $txtClass.Text = $EditItem.ClasseBlindagem }
    Add-Field -LabelText "Qual é a Classe da máscara? (1-6)" -Control $txtClass -Column 2

    # 5. Material
    $cmbMat = New-Object System.Windows.Forms.ComboBox; $cmbMat.DropDownStyle = "DropDownList"
    
    # Adiciona placeholder e itens
    $cmbMat.Items.Add($placeholderText) | Out-Null
    foreach ($k in $materialMap.Keys) { $cmbMat.Items.Add($k)|Out-Null }
    
    if ($EditItem) { 
        $k=$materialMap.Keys|Where{$materialMap[$_] -eq $EditItem.Material}
        if($k){$cmbMat.SelectedItem=$k} else {$cmbMat.SelectedIndex=0}
    } else { $cmbMat.SelectedIndex = 0 } # Seleciona o placeholder
    
    # EVENTO INTELIGENTE: Remove o placeholder ao abrir a lista
    $cmbMat.Add_DropDown({
        if ($this.Items.Count -gt 0 -and $this.Items[0] -eq "Selecione os dados aqui") {
            $this.Items.RemoveAt(0)
        }
    })
    
    Add-Field -LabelText "Qual é o Material da máscara?" -Control $cmbMat -Column 2

    # 6. Ricochete
    $cmbRico = New-Object System.Windows.Forms.ComboBox; $cmbRico.DropDownStyle = "DropDownList"
    
    # Adiciona placeholder e itens
    $cmbRico.Items.Add($placeholderText) | Out-Null
    foreach ($k in $ricochetMap.Keys) { $cmbRico.Items.Add($k)|Out-Null }
    
    if ($EditItem) { 
        $k=$ricochetMap.Keys|Where{$ricochetMap[$_] -eq $EditItem.Ricochete}
        if($k){$cmbRico.SelectedItem=$k} else {$cmbRico.SelectedIndex=0}
    } else { $cmbRico.SelectedIndex = 0 } # Seleciona o placeholder
    
    # EVENTO INTELIGENTE: Remove o placeholder ao abrir a lista
    $cmbRico.Add_DropDown({
        if ($this.Items.Count -gt 0 -and $this.Items[0] -eq "Selecione os dados aqui") {
            $this.Items.RemoveAt(0)
        }
    })
    
    Add-Field -LabelText "Qual é a chance da máscara ricochetear?" -Control $cmbRico -Column 2

    # --- BOTOES ---
    $btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = "Salvar"; $btnSave.Location = "330, 15"; $btnSave.Size = "120, 40"; $btnSave.FlatStyle = "Flat"; $btnSave.BackColor = $global:theme.GreenSuccess; $btnSave.ForeColor = $global:theme.Background
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Cancelar"; $btnCancel.Location = "500, 15"; $btnCancel.Size = "120, 40"; $btnCancel.FlatStyle = "Flat"; $btnCancel.BackColor = $global:theme.ButtonBack; $btnCancel.ForeColor = $global:theme.TextMain
    $pnlButtons.Controls.AddRange(@($btnSave, $btnCancel)); $fEdit.AcceptButton = $btnSave; $fEdit.CancelButton = $btnCancel

    # --- SALVAR ---
    $btnSave.Add_Click({
        $isValid = $true
        
        if ([string]::IsNullOrWhiteSpace($txtName.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtWeight.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtDurab.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtClass.Text)) { $isValid = $false }
        
        # Valida se os combos nao estao no placeholder ou vazios
        if (-not $cmbMat.SelectedItem -or $cmbMat.SelectedItem -eq $placeholderText) { $isValid = $false }
        if (-not $cmbRico.SelectedItem -or $cmbRico.SelectedItem -eq $placeholderText) { $isValid = $false }

        if (-not $isValid) { [System.Windows.Forms.MessageBox]::Show("Complete o formulário.`nVerifique se não há campos vazios ou 'Selecione os dados aqui'.", "Erro", "OK", "Warning"); return }

        $newItemData = [Ordered]@{
            NomeItem        = $txtName.Text.Trim()
            Peso            = $txtWeight.Text
            Durabilidade    = $txtDurab.Text
            ClasseBlindagem = $txtClass.Text
            Material        = $materialMap[$cmbMat.SelectedItem]
            Ricochete       = $ricochetMap[$cmbRico.SelectedItem]
        }

        $csvPath = Join-Path (Get-DatabasePath) "Masks.csv"
        $allItems = @(); if (Test-Path $csvPath) { $allItems = @(Import-Csv $csvPath -Delimiter ";" -Encoding UTF8) }

        if ((-not $EditItem) -or ($EditItem.NomeItem -ne $newItemData.NomeItem)) {
            if ($allItems.NomeItem -contains $newItemData.NomeItem) { [System.Windows.Forms.MessageBox]::Show("Nome já existe!", "Erro", "OK", "Error"); return }
        }

        if ($EditItem) {
            for ($i = 0; $i -lt $allItems.Count; $i++) {
                if ($allItems[$i].NomeItem -eq $EditItem.NomeItem) { $allItems[$i] = [PSCustomObject]$newItemData; break }
            }
        } else { $allItems += [PSCustomObject]$newItemData }

        $allItems | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
        $fEdit.DialogResult = "OK"; $fEdit.Close()
    })

    # --- EXECUÇÃO E LIMPEZA ---
    $fEdit.ShowDialog() | Out-Null
    $fEdit.Dispose() # --- CORREÇÃO MEMORY LEAK ---
}

function Start-GasMaskEditor {
    param (
        $ui,
        $EditItem = $null
    )

    # 1. Janela
    $fEdit = New-Object System.Windows.Forms.Form
    $fEdit.Size = New-Object System.Drawing.Size(950, 750)
    $fEdit.StartPosition = "CenterParent"
    $fEdit.BackColor = $global:theme.PanelBack
    $fEdit.ForeColor = $global:theme.TextMain
    $fEdit.FormBorderStyle = "FixedDialog"
    $fEdit.MaximizeBox = $false
    $fEdit.MinimizeBox = $false
    $fEdit.Text = if ($EditItem) { "Editar Máscara de Gás: $($EditItem.NomeItem)" } else { "Adicionar Nova Máscara de Gás" }

    # 2. Paineis
    $pnlContent = New-Object System.Windows.Forms.Panel; $pnlContent.Dock = "Fill"; $pnlContent.AutoScroll = $true; $pnlContent.Padding = New-Object System.Windows.Forms.Padding(0, 0, 0, 80)
    $fEdit.Controls.Add($pnlContent)

    $pnlButtons = New-Object System.Windows.Forms.Panel; $pnlButtons.Dock = "Bottom"; $pnlButtons.Height = 70; $pnlButtons.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $fEdit.Controls.Add($pnlButtons)

    # --- LAYOUT ---
    $layout = @{ RowL = 0; RowR = 0; Col1_X = 30; Col2_X = 480; FieldWidth = 400; RowHeight = 65 }

    function Add-Field {
        param($LabelText, $Control, [int]$Column)
        $x = if ($Column -eq 1) { $layout.Col1_X } else { $layout.Col2_X }
        $r = if ($Column -eq 1) { $layout.RowL } else { $layout.RowR }
        $y = 20 + ($r * $layout.RowHeight)

        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $LabelText; $lbl.Location = "$x, $y"; $lbl.AutoSize = $true; $lbl.ForeColor = $global:theme.OrangeAccent
        $pnlContent.Controls.Add($lbl)
        
        if ($Control) {
            $Control.Location = "$x, $($y + 25)"; $Control.Size = "$($layout.FieldWidth), 30"
            $Control.BackColor = $global:theme.ButtonBack; $Control.ForeColor = $global:theme.TextMain
            if ($Control -is [System.Windows.Forms.TextBox]) { $Control.BorderStyle = "FixedSingle" }
            if ($Control -is [System.Windows.Forms.ComboBox]) { $Control.FlatStyle = "Flat" }
            $pnlContent.Controls.Add($Control)
        }
        
        if ($Column -eq 1) { $layout.RowL++ } else { $layout.RowR++ }
    }

    # --- VALIDACAO ---
    function Add-Validation {
        param($Control, [string]$Mode)
        $Control.Tag = $Mode 
        $Control.ContextMenu = New-Object System.Windows.Forms.ContextMenu
        $Control.Add_KeyDown({
            if (($_.Control -and $_.KeyCode -eq 'V') -or ($_.Shift -and $_.KeyCode -eq 'Insert')) { $_.SuppressKeyPress = $true }
        })
        $kp = {
            $allowed = Test-KeyRestriction -Control $this -Char $_.KeyChar -Mode $this.Tag
            if (-not $allowed) { $_.Handled = $true } 
        }.GetNewClosure()
        $Control.Add_KeyPress($kp)
    }

    # --- MAPAS DE DADOS ---
    $venomMap = [Ordered]@{ "Fraco"="Bad"; "Médio"="Medium"; "Forte"="Strong" }
    $flashMap = [Ordered]@{ "Não possui defesa Anti-Flash"="/////"; "Fraco"="Bad"; "Médio"="Medium"; "Forte"="Strong" }
    
    $placeholderText = "Selecione os dados aqui"

    # ==========================
    # COLUNA 1
    # ==========================

    # 1. Nome
    $txtName = New-Object System.Windows.Forms.TextBox; $txtName.MaxLength = 36
    if ($EditItem) { $txtName.Text = $EditItem.NomeItem }
    Add-Field -LabelText "Qual é o nome da máscara de gás?" -Control $txtName -Column 1

    # 2. Peso
    $txtWeight = New-Object System.Windows.Forms.TextBox; $txtWeight.MaxLength = 4
    Add-Validation -Control $txtWeight -Mode "decimal_gasmask_weight"
    if ($EditItem) { $txtWeight.Text = $EditItem.Peso }
    Add-Field -LabelText "Qual é o peso da máscara de gás? (Exemplo: 0.50)" -Control $txtWeight -Column 1

    # 3. Durabilidade
    $txtDurab = New-Object System.Windows.Forms.TextBox; $txtDurab.MaxLength = 2
    Add-Validation -Control $txtDurab -Mode "numeric_2_digits_no_leading_zero"
    if ($EditItem) { $txtDurab.Text = $EditItem.Durabilidade }
    Add-Field -LabelText "Qual é a Durabilidade? (Exemplo: 45)" -Control $txtDurab -Column 1

    # ==========================
    # COLUNA 2
    # ==========================

    # 4. Anti-Veneno
    $cmbVenom = New-Object System.Windows.Forms.ComboBox; $cmbVenom.DropDownStyle = "DropDownList"
    $cmbVenom.Items.Add($placeholderText) | Out-Null
    foreach ($k in $venomMap.Keys) { $cmbVenom.Items.Add($k)|Out-Null }
    
    if ($EditItem) { 
        $k=$venomMap.Keys|Where{$venomMap[$_] -eq $EditItem.AntiVeneno}
        if($k){$cmbVenom.SelectedItem=$k} else {$cmbVenom.SelectedIndex=0}
    } else { $cmbVenom.SelectedIndex = 0 }
    
    # [LOGICA DE OCULTAR PLACEHOLDER]
    $cmbVenom.Add_DropDown({
        if ($this.Items.Count -gt 0 -and $this.Items[0] -eq "Selecione os dados aqui") {
            $this.Items.RemoveAt(0)
        }
    })

    Add-Field -LabelText "Qual é o poder de Anti-Veneno?" -Control $cmbVenom -Column 2

    # 5. Anti-Flash
    $cmbFlash = New-Object System.Windows.Forms.ComboBox; $cmbFlash.DropDownStyle = "DropDownList"
    $cmbFlash.Items.Add($placeholderText) | Out-Null
    foreach ($k in $flashMap.Keys) { $cmbFlash.Items.Add($k)|Out-Null }
    
    if ($EditItem) { 
        $k=$flashMap.Keys|Where{$flashMap[$_] -eq $EditItem.AntiFlash}
        if($k){$cmbFlash.SelectedItem=$k} else {$cmbFlash.SelectedIndex=0}
    } else { $cmbFlash.SelectedIndex = 0 }

    # [LOGICA DE OCULTAR PLACEHOLDER]
    $cmbFlash.Add_DropDown({
        if ($this.Items.Count -gt 0 -and $this.Items[0] -eq "Selecione os dados aqui") {
            $this.Items.RemoveAt(0)
        }
    })
    
    Add-Field -LabelText "Qual é o poder de Anti-Flash?" -Control $cmbFlash -Column 2

    # --- BOTOES ---
    $btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = "Salvar"; $btnSave.Location = "330, 15"; $btnSave.Size = "120, 40"; $btnSave.FlatStyle = "Flat"; $btnSave.BackColor = $global:theme.GreenSuccess; $btnSave.ForeColor = $global:theme.Background
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Cancelar"; $btnCancel.Location = "500, 15"; $btnCancel.Size = "120, 40"; $btnCancel.FlatStyle = "Flat"; $btnCancel.BackColor = $global:theme.ButtonBack; $btnCancel.ForeColor = $global:theme.TextMain
    $pnlButtons.Controls.AddRange(@($btnSave, $btnCancel)); $fEdit.AcceptButton = $btnSave; $fEdit.CancelButton = $btnCancel

    # --- SALVAR ---
    $btnSave.Add_Click({
        $isValid = $true
        
        if ([string]::IsNullOrWhiteSpace($txtName.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtWeight.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtDurab.Text)) { $isValid = $false }
        
        # Valida se os combos nao estao no placeholder OU se estao vazios (caso o placeholder tenha sido removido)
        if (-not $cmbVenom.SelectedItem -or $cmbVenom.SelectedItem -eq $placeholderText) { $isValid = $false }
        if (-not $cmbFlash.SelectedItem -or $cmbFlash.SelectedItem -eq $placeholderText) { $isValid = $false }

        if (-not $isValid) { [System.Windows.Forms.MessageBox]::Show("Complete o formulário.`nVerifique se não há campos vazios ou 'Selecione os dados aqui'.", "Erro", "OK", "Warning"); return }

        $newItemData = [Ordered]@{
            NomeItem     = $txtName.Text.Trim()
            Peso         = $txtWeight.Text
            Durabilidade = $txtDurab.Text
            AntiVeneno   = $venomMap[$cmbVenom.SelectedItem]
            AntiFlash    = $flashMap[$cmbFlash.SelectedItem]
        }

        $csvPath = Join-Path (Get-DatabasePath) "Gasmasks.csv"
        $allItems = @(); if (Test-Path $csvPath) { $allItems = @(Import-Csv $csvPath -Delimiter ";" -Encoding UTF8) }

        if ((-not $EditItem) -or ($EditItem.NomeItem -ne $newItemData.NomeItem)) {
            if ($allItems.NomeItem -contains $newItemData.NomeItem) { [System.Windows.Forms.MessageBox]::Show("Nome já existe!", "Erro", "OK", "Error"); return }
        }

        if ($EditItem) {
            for ($i = 0; $i -lt $allItems.Count; $i++) {
                if ($allItems[$i].NomeItem -eq $EditItem.NomeItem) { $allItems[$i] = [PSCustomObject]$newItemData; break }
            }
        } else { $allItems += [PSCustomObject]$newItemData }

        $allItems | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
        $fEdit.DialogResult = "OK"; $fEdit.Close()
    })

    $fEdit.ShowDialog() | Out-Null
    
    # --- CORREÇÃO MEMORY LEAK: Limpa o form da RAM ---
    $fEdit.Dispose()
}

function Start-HeadsetEditor {
    param (
        $ui,
        $EditItem = $null
    )

    # 1. Janela
    $fEdit = New-Object System.Windows.Forms.Form
    $fEdit.Size = New-Object System.Drawing.Size(950, 750)
    $fEdit.StartPosition = "CenterParent"
    $fEdit.BackColor = $global:theme.PanelBack
    $fEdit.ForeColor = $global:theme.TextMain
    $fEdit.FormBorderStyle = "FixedDialog"
    $fEdit.MaximizeBox = $false
    $fEdit.MinimizeBox = $false
    $fEdit.Text = if ($EditItem) { "Editar Fone de Ouvido: $($EditItem.NomeItem)" } else { "Adicionar Novo Fone de Ouvido" }

    # 2. Paineis
    $pnlContent = New-Object System.Windows.Forms.Panel; $pnlContent.Dock = "Fill"; $pnlContent.AutoScroll = $true; $pnlContent.Padding = New-Object System.Windows.Forms.Padding(0, 0, 0, 80)
    $fEdit.Controls.Add($pnlContent)

    $pnlButtons = New-Object System.Windows.Forms.Panel; $pnlButtons.Dock = "Bottom"; $pnlButtons.Height = 70; $pnlButtons.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $fEdit.Controls.Add($pnlButtons)

    # --- LAYOUT ---
    $layout = @{ RowL = 0; RowR = 0; Col1_X = 30; Col2_X = 480; FieldWidth = 400; RowHeight = 65 }

    function Add-Field {
        param($LabelText, $Control, [int]$Column)
        $x = if ($Column -eq 1) { $layout.Col1_X } else { $layout.Col2_X }
        $r = if ($Column -eq 1) { $layout.RowL } else { $layout.RowR }
        $y = 20 + ($r * $layout.RowHeight)

        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $LabelText; $lbl.Location = "$x, $y"; $lbl.AutoSize = $true; $lbl.ForeColor = $global:theme.OrangeAccent
        $pnlContent.Controls.Add($lbl)
        
        if ($Control) {
            $Control.Location = "$x, $($y + 25)"; $Control.Size = "$($layout.FieldWidth), 30"
            $Control.BackColor = $global:theme.ButtonBack; $Control.ForeColor = $global:theme.TextMain
            if ($Control -is [System.Windows.Forms.TextBox]) { $Control.BorderStyle = "FixedSingle" }
            if ($Control -is [System.Windows.Forms.ComboBox]) { $Control.FlatStyle = "Flat" }
            $pnlContent.Controls.Add($Control)
        }
        
        if ($Column -eq 1) { $layout.RowL++ } else { $layout.RowR++ }
    }

    # --- VALIDACAO ---
    function Add-Validation {
        param($Control, [string]$Mode)
        $Control.Tag = $Mode 
        $Control.ContextMenu = New-Object System.Windows.Forms.ContextMenu
        $Control.Add_KeyDown({
            if (($_.Control -and $_.KeyCode -eq 'V') -or ($_.Shift -and $_.KeyCode -eq 'Insert')) { $_.SuppressKeyPress = $true }
        })
        $kp = {
            $allowed = Test-KeyRestriction -Control $this -Char $_.KeyChar -Mode $this.Tag
            if (-not $allowed) { $_.Handled = $true } 
        }.GetNewClosure()
        $Control.Add_KeyPress($kp)
    }

    # --- HELPER PLACEHOLDER ---
    $placeholderText = "Selecione os dados aqui"
    
    function Setup-Combo {
        param($Combo, $Map)
        $Combo.Items.Clear()
        $Combo.Items.Add($placeholderText) | Out-Null
        foreach ($k in $Map.Keys) { $Combo.Items.Add($k)|Out-Null }
        $Combo.SelectedIndex = 0 
        
        $Combo.Add_DropDown({
            if ($this.Items.Count -gt 0 -and $this.Items[0] -eq "Selecione os dados aqui") {
                $this.Items.RemoveAt(0)
            }
        })
    }

    # --- MAPAS DE DADOS ---
    $pickupMap = [Ordered]@{ "Fraco"="Bad"; "Médio"="Medium"; "Forte"="Strong" }
    $noiseMap  = [Ordered]@{ "Fraco"="Bad"; "Médio"="Medium"; "Forte"="Strong" }

    # ==========================
    # COLUNA 1
    # ==========================

    # 1. Nome
    $txtName = New-Object System.Windows.Forms.TextBox; $txtName.MaxLength = 32
    if ($EditItem) { $txtName.Text = $EditItem.NomeItem }
    Add-Field -LabelText "Qual é o nome do fone de ouvido?" -Control $txtName -Column 1

    # 2. Peso
    $txtWeight = New-Object System.Windows.Forms.TextBox; $txtWeight.MaxLength = 4
    Add-Validation -Control $txtWeight -Mode "decimal_headset_weight"
    if ($EditItem) { $txtWeight.Text = $EditItem.Peso }
    Add-Field -LabelText "Qual é o peso do fone de ouvido? (Exemplo: 0.55)" -Control $txtWeight -Column 1

    # ==========================
    # COLUNA 2
    # ==========================

    # 3. Captador de Som (Com Placeholder)
    $cmbPickup = New-Object System.Windows.Forms.ComboBox; $cmbPickup.DropDownStyle = "DropDownList"
    Setup-Combo -Combo $cmbPickup -Map $pickupMap
    
    if ($EditItem) { 
        $k=$pickupMap.Keys|Where{$pickupMap[$_] -eq $EditItem.CaptacaoSom}
        if($k){$cmbPickup.SelectedItem=$k}
    }
    
    Add-Field -LabelText "Qual é o poder do Captador de Som?" -Control $cmbPickup -Column 2

    # 4. Reducao de Ruido (Com Placeholder)
    $cmbNoise = New-Object System.Windows.Forms.ComboBox; $cmbNoise.DropDownStyle = "DropDownList"
    Setup-Combo -Combo $cmbNoise -Map $noiseMap
    
    if ($EditItem) { 
        $k=$noiseMap.Keys|Where{$noiseMap[$_] -eq $EditItem.ReducaoRuido}
        if($k){$cmbNoise.SelectedItem=$k}
    }
    
    Add-Field -LabelText "Qual é o poder de Redução de Ruido?" -Control $cmbNoise -Column 2

    # --- BOTOES ---
    $btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = "Salvar"; $btnSave.Location = "330, 15"; $btnSave.Size = "120, 40"; $btnSave.FlatStyle = "Flat"; $btnSave.BackColor = $global:theme.GreenSuccess; $btnSave.ForeColor = $global:theme.Background
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Cancelar"; $btnCancel.Location = "500, 15"; $btnCancel.Size = "120, 40"; $btnCancel.FlatStyle = "Flat"; $btnCancel.BackColor = $global:theme.ButtonBack; $btnCancel.ForeColor = $global:theme.TextMain
    $pnlButtons.Controls.AddRange(@($btnSave, $btnCancel)); $fEdit.AcceptButton = $btnSave; $fEdit.CancelButton = $btnCancel

    # --- SALVAR ---
    $btnSave.Add_Click({
        $isValid = $true
        
        if ([string]::IsNullOrWhiteSpace($txtName.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtWeight.Text)) { $isValid = $false }
        
        # Valida combos (Placeholder)
        if (-not $cmbPickup.SelectedItem -or $cmbPickup.SelectedItem -eq $placeholderText) { $isValid = $false }
        if (-not $cmbNoise.SelectedItem -or $cmbNoise.SelectedItem -eq $placeholderText) { $isValid = $false }

        if (-not $isValid) { [System.Windows.Forms.MessageBox]::Show("Complete o formulário.`nVerifique se não há campos vazios ou 'Selecione os dados aqui'.", "Erro", "OK", "Warning"); return }

        $newItemData = [Ordered]@{
            NomeItem     = $txtName.Text.Trim()
            Peso         = $txtWeight.Text
            CaptacaoSom  = $pickupMap[$cmbPickup.SelectedItem]
            ReducaoRuido = $noiseMap[$cmbNoise.SelectedItem]
        }

        $csvPath = Join-Path (Get-DatabasePath) "Headsets.csv"
        $allItems = @(); if (Test-Path $csvPath) { $allItems = @(Import-Csv $csvPath -Delimiter ";" -Encoding UTF8) }

        if ((-not $EditItem) -or ($EditItem.NomeItem -ne $newItemData.NomeItem)) {
            if ($allItems.NomeItem -contains $newItemData.NomeItem) { [System.Windows.Forms.MessageBox]::Show("Nome já existe!", "Erro", "OK", "Error"); return }
        }

        if ($EditItem) {
            for ($i = 0; $i -lt $allItems.Count; $i++) {
                if ($allItems[$i].NomeItem -eq $EditItem.NomeItem) { $allItems[$i] = [PSCustomObject]$newItemData; break }
            }
        } else { $allItems += [PSCustomObject]$newItemData }

        $allItems | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
        $fEdit.DialogResult = "OK"; $fEdit.Close()
    })

    $fEdit.ShowDialog() | Out-Null
    
    # --- CORREÇÃO MEMORY LEAK: Limpa o form da RAM ---
    $fEdit.Dispose()
}

function Start-PainkillerEditor {
    param (
        $ui,
        $EditItem = $null
    )

    # 1. Janela
    $fEdit = New-Object System.Windows.Forms.Form
    $fEdit.Size = New-Object System.Drawing.Size(950, 750)
    $fEdit.StartPosition = "CenterParent"
    $fEdit.BackColor = $global:theme.PanelBack
    $fEdit.ForeColor = $global:theme.TextMain
    $fEdit.FormBorderStyle = "FixedDialog"
    $fEdit.MaximizeBox = $false
    $fEdit.MinimizeBox = $false
    $fEdit.Text = if ($EditItem) { "Editar Analgésico: $($EditItem.NomeItem)" } else { "Adicionar Novo Analgésico" }

    # 2. Paineis
    $pnlContent = New-Object System.Windows.Forms.Panel; $pnlContent.Dock = "Fill"; $pnlContent.AutoScroll = $true; $pnlContent.Padding = New-Object System.Windows.Forms.Padding(0, 0, 0, 80)
    $fEdit.Controls.Add($pnlContent)

    $pnlButtons = New-Object System.Windows.Forms.Panel; $pnlButtons.Dock = "Bottom"; $pnlButtons.Height = 70; $pnlButtons.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $fEdit.Controls.Add($pnlButtons)

    # --- LAYOUT ---
    $layout = @{ RowL = 0; RowR = 0; Col1_X = 30; Col2_X = 480; FieldWidth = 400; RowHeight = 65 }

    function Add-Field {
        param($LabelText, $Control, [int]$Column)
        $x = if ($Column -eq 1) { $layout.Col1_X } else { $layout.Col2_X }
        $r = if ($Column -eq 1) { $layout.RowL } else { $layout.RowR }
        $y = 20 + ($r * $layout.RowHeight)

        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $LabelText; $lbl.Location = "$x, $y"; $lbl.AutoSize = $true; $lbl.ForeColor = $global:theme.OrangeAccent
        $pnlContent.Controls.Add($lbl)
        
        if ($Control) {
            $Control.Location = "$x, $($y + 25)"; $Control.Size = "$($layout.FieldWidth), 30"
            $Control.BackColor = $global:theme.ButtonBack; $Control.ForeColor = $global:theme.TextMain
            if ($Control -is [System.Windows.Forms.TextBox]) { $Control.BorderStyle = "FixedSingle" }
            if ($Control -is [System.Windows.Forms.ComboBox]) { $Control.FlatStyle = "Flat" }
            $pnlContent.Controls.Add($Control)
        }
        
        if ($Column -eq 1) { $layout.RowL++ } else { $layout.RowR++ }
    }

    # --- VALIDACAO ---
    function Add-Validation {
        param($Control, [string]$Mode)
        $Control.Tag = $Mode 
        $Control.ContextMenu = New-Object System.Windows.Forms.ContextMenu
        $Control.Add_KeyDown({
            if (($_.Control -and $_.KeyCode -eq 'V') -or ($_.Shift -and $_.KeyCode -eq 'Insert')) { $_.SuppressKeyPress = $true }
        })
        $kp = {
            $allowed = Test-KeyRestriction -Control $this -Char $_.KeyChar -Mode $this.Tag
            if (-not $allowed) { $_.Handled = $true } 
        }.GetNewClosure()
        $Control.Add_KeyPress($kp)
    }

    # ==========================
    # COLUNA 1
    # ==========================

    # 1. Nome
    $txtName = New-Object System.Windows.Forms.TextBox; $txtName.MaxLength = 25
    if ($EditItem) { $txtName.Text = $EditItem.NomeItem }
    Add-Field -LabelText "Qual é o nome do analgésico?" -Control $txtName -Column 1

    # 2. Usos
    $txtUses = New-Object System.Windows.Forms.TextBox; $txtUses.MaxLength = 1
    Add-Validation -Control $txtUses -Mode "numeric_1_9"
    if ($EditItem) { $txtUses.Text = $EditItem.Usos }
    Add-Field -LabelText "Quantas vezes pode ser usado? (1-9)" -Control $txtUses -Column 1

    # 3. Duracao
    $txtDur = New-Object System.Windows.Forms.TextBox; $txtDur.MaxLength = 3
    Add-Validation -Control $txtDur -Mode "numeric_no_leading_zero"
    if ($EditItem) { $txtDur.Text = $EditItem.Duracao }
    Add-Field -LabelText "Qual é a duração do efeito?" -Control $txtDur -Column 1

    # ==========================
    # COLUNA 2
    # ==========================

    # 4. Desidratacao (Logica Especial)
    $grpDehyd = New-Object System.Windows.Forms.Panel; $grpDehyd.Height=60; $grpDehyd.Width=400
    $rbYes = New-Object System.Windows.Forms.RadioButton; $rbYes.Text="Sim"; $rbYes.Location="0,5"; $rbYes.Width=50; $rbYes.ForeColor=$global:theme.TextMain
    $rbNo = New-Object System.Windows.Forms.RadioButton; $rbNo.Text="Não"; $rbNo.Location="60,5"; $rbNo.Width=50; $rbNo.ForeColor=$global:theme.TextMain
    
    $txtDehydVal = New-Object System.Windows.Forms.TextBox; $txtDehydVal.Location="120,3"; $txtDehydVal.Width=50; $txtDehydVal.MaxLength=4; $txtDehydVal.Visible=$false
    Add-Validation -Control $txtDehydVal -Mode "dehydration_strict"
    
    $grpDehyd.Controls.AddRange(@($rbYes, $rbNo, $txtDehydVal))
    
    $rbYes.Add_CheckedChanged({ $txtDehydVal.Visible = $rbYes.Checked })
    
    if ($EditItem -and $EditItem.Desidratacao -ne "/////") { 
        $rbYes.Checked=$true; $txtDehydVal.Text = $EditItem.Desidratacao 
    } else { $rbNo.Checked=$true }
    
    Add-Field -LabelText "Ele desidrata? (Ex: -100)" -Control $grpDehyd -Column 2

    # 5. Delay
    $txtDelay = New-Object System.Windows.Forms.TextBox; $txtDelay.MaxLength = 4
    Add-Validation -Control $txtDelay -Mode "decimal_fixed"
    if ($EditItem) { $txtDelay.Text = $EditItem.Delay }
    Add-Field -LabelText "Qual é o tempo de atraso? (ex: 1.2)" -Control $txtDelay -Column 2

    # --- BOTOES ---
    $btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = "Salvar"; $btnSave.Location = "330, 15"; $btnSave.Size = "120, 40"; $btnSave.FlatStyle = "Flat"; $btnSave.BackColor = $global:theme.GreenSuccess; $btnSave.ForeColor = $global:theme.Background
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Cancelar"; $btnCancel.Location = "500, 15"; $btnCancel.Size = "120, 40"; $btnCancel.FlatStyle = "Flat"; $btnCancel.BackColor = $global:theme.ButtonBack; $btnCancel.ForeColor = $global:theme.TextMain
    $pnlButtons.Controls.AddRange(@($btnSave, $btnCancel)); $fEdit.AcceptButton = $btnSave; $fEdit.CancelButton = $btnCancel

    # --- SALVAR ---
    $btnSave.Add_Click({
        $isValid = $true
        
        if ([string]::IsNullOrWhiteSpace($txtName.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtUses.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtDur.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtDelay.Text)) { $isValid = $false }
        
        if ($rbYes.Checked -and [string]::IsNullOrWhiteSpace($txtDehydVal.Text)) { $isValid = $false }

        if (-not $isValid) { [System.Windows.Forms.MessageBox]::Show("Complete o formulário corretamente.", "Erro", "OK", "Warning"); return }

        $finalDehyd = if ($rbYes.Checked) { $txtDehydVal.Text } else { "/////" }

        $newItemData = [Ordered]@{
            NomeItem     = $txtName.Text.Trim()
            Usos         = $txtUses.Text
            Duracao      = $txtDur.Text
            Desidratacao = $finalDehyd
            Delay        = $txtDelay.Text
        }

        $csvPath = Join-Path (Get-DatabasePath) "Painkillers.csv"
        $allItems = @(); if (Test-Path $csvPath) { $allItems = @(Import-Csv $csvPath -Delimiter ";" -Encoding UTF8) }

        if ((-not $EditItem) -or ($EditItem.NomeItem -ne $newItemData.NomeItem)) {
            if ($allItems.NomeItem -contains $newItemData.NomeItem) { [System.Windows.Forms.MessageBox]::Show("Nome já existe!", "Erro", "OK", "Error"); return }
        }

        if ($EditItem) {
            for ($i = 0; $i -lt $allItems.Count; $i++) {
                if ($allItems[$i].NomeItem -eq $EditItem.NomeItem) { $allItems[$i] = [PSCustomObject]$newItemData; break }
            }
        } else { $allItems += [PSCustomObject]$newItemData }

        $allItems | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
        $fEdit.DialogResult = "OK"; $fEdit.Close()
    })

    $fEdit.ShowDialog() | Out-Null

    # --- CORREÇÃO MEMORY LEAK ---
    $fEdit.Dispose()
}

function Start-BandageEditor {
    param (
        $ui,
        $EditItem = $null
    )

    # 1. Janela
    $fEdit = New-Object System.Windows.Forms.Form
    $fEdit.Size = New-Object System.Drawing.Size(950, 750)
    $fEdit.StartPosition = "CenterParent"
    $fEdit.BackColor = $global:theme.PanelBack
    $fEdit.ForeColor = $global:theme.TextMain
    $fEdit.FormBorderStyle = "FixedDialog"
    $fEdit.MaximizeBox = $false
    $fEdit.MinimizeBox = $false
    $fEdit.Text = if ($EditItem) { "Editar Bandagem: $($EditItem.NomeItem)" } else { "Adicionar Nova Bandagem" }

    # 2. Paineis
    $pnlContent = New-Object System.Windows.Forms.Panel; $pnlContent.Dock = "Fill"; $pnlContent.AutoScroll = $true; $pnlContent.Padding = New-Object System.Windows.Forms.Padding(0, 0, 0, 80)
    $fEdit.Controls.Add($pnlContent)

    $pnlButtons = New-Object System.Windows.Forms.Panel; $pnlButtons.Dock = "Bottom"; $pnlButtons.Height = 70; $pnlButtons.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $fEdit.Controls.Add($pnlButtons)

    # --- LAYOUT ---
    $layout = @{ RowL = 0; RowR = 0; Col1_X = 30; Col2_X = 480; FieldWidth = 400; RowHeight = 65 }

    function Add-Field {
        param($LabelText, $Control, [int]$Column)
        $x = if ($Column -eq 1) { $layout.Col1_X } else { $layout.Col2_X }
        $r = if ($Column -eq 1) { $layout.RowL } else { $layout.RowR }
        $y = 20 + ($r * $layout.RowHeight)

        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $LabelText; $lbl.Location = "$x, $y"; $lbl.AutoSize = $true; $lbl.ForeColor = $global:theme.OrangeAccent
        $pnlContent.Controls.Add($lbl)
        
        if ($Control) {
            $Control.Location = "$x, $($y + 25)"; $Control.Size = "$($layout.FieldWidth), 30"
            $Control.BackColor = $global:theme.ButtonBack; $Control.ForeColor = $global:theme.TextMain
            if ($Control -is [System.Windows.Forms.TextBox]) { $Control.BorderStyle = "FixedSingle" }
            if ($Control -is [System.Windows.Forms.ComboBox]) { $Control.FlatStyle = "Flat" }
            $pnlContent.Controls.Add($Control)
        }
        
        if ($Column -eq 1) { $layout.RowL++ } else { $layout.RowR++ }
    }

    # --- VALIDACAO ---
    function Add-Validation {
        param($Control, [string]$Mode)
        $Control.Tag = $Mode 
        $Control.ContextMenu = New-Object System.Windows.Forms.ContextMenu
        $Control.Add_KeyDown({
            if (($_.Control -and $_.KeyCode -eq 'V') -or ($_.Shift -and $_.KeyCode -eq 'Insert')) { $_.SuppressKeyPress = $true }
        })
        $kp = {
            $allowed = Test-KeyRestriction -Control $this -Char $_.KeyChar -Mode $this.Tag
            if (-not $allowed) { $_.Handled = $true } 
        }.GetNewClosure()
        $Control.Add_KeyPress($kp)
    }

    # ==========================
    # COLUNA 1
    # ==========================

    # 1. Nome
    $txtName = New-Object System.Windows.Forms.TextBox; $txtName.MaxLength = 25
    if ($EditItem) { $txtName.Text = $EditItem.NomeItem }
    Add-Field -LabelText "Qual é o nome da bandagem?" -Control $txtName -Column 1

    # 2. Usos
    $txtUses = New-Object System.Windows.Forms.TextBox; $txtUses.MaxLength = 1
    Add-Validation -Control $txtUses -Mode "numeric_1_9"
    if ($EditItem) { $txtUses.Text = $EditItem.Usos }
    Add-Field -LabelText "Quantas vezes pode ser usado? (1-9)" -Control $txtUses -Column 1

    # ==========================
    # COLUNA 2
    # ==========================

    # 3. Delay
    $txtDelay = New-Object System.Windows.Forms.TextBox; $txtDelay.MaxLength = 4
    Add-Validation -Control $txtDelay -Mode "decimal_fixed"
    if ($EditItem) { $txtDelay.Text = $EditItem.Delay }
    Add-Field -LabelText "Qual é o tempo de atraso? (ex: 1.2)" -Control $txtDelay -Column 2

    # 4. Custo Durabilidade (Simplificado)
    $txtCost = New-Object System.Windows.Forms.TextBox; $txtCost.MaxLength = 1
    Add-Validation -Control $txtCost -Mode "numeric_1_9"
    
    # Se for edição e não for "/////" (antigo Nao), carrega o valor
    if ($EditItem -and $EditItem.CustoDurabilidade -ne "/////") { 
        $txtCost.Text = $EditItem.CustoDurabilidade 
    }
    
    Add-Field -LabelText "Qual é o custo de durabilidade? (1-9)" -Control $txtCost -Column 2

    # --- BOTOES ---
    $btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = "Salvar"; $btnSave.Location = "330, 15"; $btnSave.Size = "120, 40"; $btnSave.FlatStyle = "Flat"; $btnSave.BackColor = $global:theme.GreenSuccess; $btnSave.ForeColor = $global:theme.Background
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Cancelar"; $btnCancel.Location = "500, 15"; $btnCancel.Size = "120, 40"; $btnCancel.FlatStyle = "Flat"; $btnCancel.BackColor = $global:theme.ButtonBack; $btnCancel.ForeColor = $global:theme.TextMain
    $pnlButtons.Controls.AddRange(@($btnSave, $btnCancel)); $fEdit.AcceptButton = $btnSave; $fEdit.CancelButton = $btnCancel

    # --- SALVAR ---
    $btnSave.Add_Click({
        $isValid = $true
        
        if ([string]::IsNullOrWhiteSpace($txtName.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtUses.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtDelay.Text)) { $isValid = $false }
        
        # Agora valida o campo direto
        if ([string]::IsNullOrWhiteSpace($txtCost.Text)) { $isValid = $false }

        if (-not $isValid) { [System.Windows.Forms.MessageBox]::Show("Complete o formulário corretamente.", "Erro", "OK", "Warning"); return }

        $newItemData = [Ordered]@{
            NomeItem          = $txtName.Text.Trim()
            Usos              = $txtUses.Text
            Delay             = $txtDelay.Text
            CustoDurabilidade = $txtCost.Text
        }

        $csvPath = Join-Path (Get-DatabasePath) "Bandages.csv"
        $allItems = @(); if (Test-Path $csvPath) { $allItems = @(Import-Csv $csvPath -Delimiter ";" -Encoding UTF8) }

        if ((-not $EditItem) -or ($EditItem.NomeItem -ne $newItemData.NomeItem)) {
            if ($allItems.NomeItem -contains $newItemData.NomeItem) { [System.Windows.Forms.MessageBox]::Show("Nome já existe!", "Erro", "OK", "Error"); return }
        }

        if ($EditItem) {
            for ($i = 0; $i -lt $allItems.Count; $i++) {
                if ($allItems[$i].NomeItem -eq $EditItem.NomeItem) { $allItems[$i] = [PSCustomObject]$newItemData; break }
            }
        } else { $allItems += [PSCustomObject]$newItemData }

        $allItems | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
        $fEdit.DialogResult = "OK"; $fEdit.Close()
    })

    $fEdit.ShowDialog() | Out-Null

    # --- CORREÇÃO MEMORY LEAK ---
    $fEdit.Dispose()
}

function Start-SurgicalKitEditor {
    param (
        $ui,
        $EditItem = $null
    )

    # 1. Janela
    $fEdit = New-Object System.Windows.Forms.Form
    $fEdit.Size = New-Object System.Drawing.Size(950, 750)
    $fEdit.StartPosition = "CenterParent"
    $fEdit.BackColor = $global:theme.PanelBack
    $fEdit.ForeColor = $global:theme.TextMain
    $fEdit.FormBorderStyle = "FixedDialog"
    $fEdit.MaximizeBox = $false
    $fEdit.MinimizeBox = $false
    $fEdit.Text = if ($EditItem) { "Editar Kit Cirúrgico: $($EditItem.NomeItem)" } else { "Adicionar Novo Kit Cirúrgico" }

    # 2. Paineis
    $pnlContent = New-Object System.Windows.Forms.Panel; $pnlContent.Dock = "Fill"; $pnlContent.AutoScroll = $true; $pnlContent.Padding = New-Object System.Windows.Forms.Padding(0, 0, 0, 80)
    $fEdit.Controls.Add($pnlContent)

    $pnlButtons = New-Object System.Windows.Forms.Panel; $pnlButtons.Dock = "Bottom"; $pnlButtons.Height = 70; $pnlButtons.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $fEdit.Controls.Add($pnlButtons)

    # --- LAYOUT ---
    $layout = @{ RowL = 0; RowR = 0; Col1_X = 30; Col2_X = 480; FieldWidth = 400; RowHeight = 65 }

    function Add-Field {
        param($LabelText, $Control, [int]$Column)
        $x = if ($Column -eq 1) { $layout.Col1_X } else { $layout.Col2_X }
        $r = if ($Column -eq 1) { $layout.RowL } else { $layout.RowR }
        $y = 20 + ($r * $layout.RowHeight)

        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $LabelText; $lbl.Location = "$x, $y"; $lbl.AutoSize = $true; $lbl.ForeColor = $global:theme.OrangeAccent
        $pnlContent.Controls.Add($lbl)
        
        if ($Control) {
            $Control.Location = "$x, $($y + 25)"; $Control.Size = "$($layout.FieldWidth), 30"
            $Control.BackColor = $global:theme.ButtonBack; $Control.ForeColor = $global:theme.TextMain
            if ($Control -is [System.Windows.Forms.TextBox]) { $Control.BorderStyle = "FixedSingle" }
            if ($Control -is [System.Windows.Forms.ComboBox]) { $Control.FlatStyle = "Flat" }
            $pnlContent.Controls.Add($Control)
        }
        
        if ($Column -eq 1) { $layout.RowL++ } else { $layout.RowR++ }
        return $y
    }

    # --- VALIDACAO ---
    function Add-Validation {
        param($Control, [string]$Mode)
        $Control.Tag = $Mode 
        $Control.ContextMenu = New-Object System.Windows.Forms.ContextMenu
        $Control.Add_KeyDown({
            if (($_.Control -and $_.KeyCode -eq 'V') -or ($_.Shift -and $_.KeyCode -eq 'Insert')) { $_.SuppressKeyPress = $true }
        })
        $kp = {
            $allowed = Test-KeyRestriction -Control $this -Char $_.KeyChar -Mode $this.Tag
            if (-not $allowed) { $_.Handled = $true } 
        }.GetNewClosure()
        $Control.Add_KeyPress($kp)
    }

    # Helper para input de tamanho (Horizontal x Vertical)
    function Create-SizeInput {
        param([string]$InitialVal)
        $p = New-Object System.Windows.Forms.Panel; $p.Height = 30; $p.Width = 400
        $lblX = New-Object System.Windows.Forms.Label; $lblX.Text = "x"; $lblX.AutoSize = $true; $lblX.ForeColor = $global:theme.TextMain; $lblX.Location = "60, 5"
        
        $txtH = New-Object System.Windows.Forms.TextBox; $txtH.Width = 50; $txtH.MaxLength = 1; $txtH.Location = "0, 3"
        Add-Validation -Control $txtH -Mode "numeric_1_4" # Max 4 blocos para items pequenos/medios
        
        $txtV = New-Object System.Windows.Forms.TextBox; $txtV.Width = 50; $txtV.MaxLength = 1; $txtV.Location = "80, 3"
        Add-Validation -Control $txtV -Mode "numeric_1_4"

        if ($InitialVal -match '(\d)x(\d)') {
            $txtH.Text = $Matches[1]; $txtV.Text = $Matches[2]
        }

        $p.Controls.AddRange(@($txtH, $lblX, $txtV))
        return @{ Panel=$p; TxtH=$txtH; TxtV=$txtV }
    }

    # ==========================
    # COLUNA 1
    # ==========================

    # 1. Nome
    $txtName = New-Object System.Windows.Forms.TextBox; $txtName.MaxLength = 32
    if ($EditItem) { $txtName.Text = $EditItem.NomeItem }
    Add-Field -LabelText "Qual é o nome do kit cirúrgico?" -Control $txtName -Column 1

    # 2. Usos
    $txtUses = New-Object System.Windows.Forms.TextBox; $txtUses.MaxLength = 2
    Add-Validation -Control $txtUses -Mode "numeric_no_leading_zero"
    if ($EditItem) { $txtUses.Text = $EditItem.Usos }
    Add-Field -LabelText "Quantas vezes pode ser usado?" -Control $txtUses -Column 1

    # 3. Delay
    $txtDelay = New-Object System.Windows.Forms.TextBox; $txtDelay.MaxLength = 4
    Add-Validation -Control $txtDelay -Mode "decimal_fixed"
    if ($EditItem) { $txtDelay.Text = $EditItem.Delay }
    Add-Field -LabelText "Qual é o tempo de atraso? (ex: 12.3)" -Control $txtDelay -Column 1

    # 4. Desidratacao (Logica Condicional)
    $grpDehyd = New-Object System.Windows.Forms.Panel; $grpDehyd.Height=60; $grpDehyd.Width=400
    $rbDehydYes = New-Object System.Windows.Forms.RadioButton; $rbDehydYes.Text="Sim"; $rbDehydYes.Location="0,5"; $rbDehydYes.Width=50; $rbDehydYes.ForeColor=$global:theme.TextMain
    $rbDehydNo = New-Object System.Windows.Forms.RadioButton; $rbDehydNo.Text="Não"; $rbDehydNo.Location="60,5"; $rbDehydNo.Width=50; $rbDehydNo.ForeColor=$global:theme.TextMain
    
    $txtDehydVal = New-Object System.Windows.Forms.TextBox; $txtDehydVal.Location="120,3"; $txtDehydVal.Width=50; $txtDehydVal.MaxLength=4; $txtDehydVal.Visible=$false
    Add-Validation -Control $txtDehydVal -Mode "dehydration_strict"
    
    $grpDehyd.Controls.AddRange(@($rbDehydYes, $rbDehydNo, $txtDehydVal))
    
    $rbDehydYes.Add_CheckedChanged({ $txtDehydVal.Visible = $rbDehydYes.Checked })
    
    if ($EditItem -and $EditItem.Desidratacao -ne "/////") { 
        $rbDehydYes.Checked=$true; $txtDehydVal.Text = $EditItem.Desidratacao 
    } else { $rbDehydNo.Checked=$true }
    
    Add-Field -LabelText "Ele desidrata? (Ex: -100)" -Control $grpDehyd -Column 1

    # ==========================
    # COLUNA 2
    # ==========================

    # 5. Recuperacao HP
    $txtHP = New-Object System.Windows.Forms.TextBox; $txtHP.MaxLength = 3
    Add-Validation -Control $txtHP -Mode "numeric_no_leading_zero"
    if ($EditItem) { $txtHP.Text = $EditItem.RecuperacaoHP }
    Add-Field -LabelText "Qual é a recuperação de HP?" -Control $txtHP -Column 2

    # 6. Custo Durabilidade (Simplificado)
    $txtCost = New-Object System.Windows.Forms.TextBox; $txtCost.MaxLength = 1
    Add-Validation -Control $txtCost -Mode "numeric_1_9"
    
    # Se for edição e não for "/////", carrega o valor
    if ($EditItem -and $EditItem.CustoDurabilidade -ne "/////") { 
        $txtCost.Text = $EditItem.CustoDurabilidade 
    }
    
    Add-Field -LabelText "Qual é o custo de durabilidade? (1-9)" -Control $txtCost -Column 2

    # 7. Tamanho (Horizontal x Vertical)
    $sizeObj = Create-SizeInput -InitialVal $EditItem.EspacoOcupado
    Add-Field -LabelText "Qual o tamanho ocupado? (Horiz x Vert)" -Control $sizeObj.Panel -Column 2

    # --- BOTOES ---
    $btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = "Salvar"; $btnSave.Location = "330, 15"; $btnSave.Size = "120, 40"; $btnSave.FlatStyle = "Flat"; $btnSave.BackColor = $global:theme.GreenSuccess; $btnSave.ForeColor = $global:theme.Background
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Cancelar"; $btnCancel.Location = "500, 15"; $btnCancel.Size = "120, 40"; $btnCancel.FlatStyle = "Flat"; $btnCancel.BackColor = $global:theme.ButtonBack; $btnCancel.ForeColor = $global:theme.TextMain
    $pnlButtons.Controls.AddRange(@($btnSave, $btnCancel)); $fEdit.AcceptButton = $btnSave; $fEdit.CancelButton = $btnCancel

    # --- SALVAR ---
    $btnSave.Add_Click({
        $isValid = $true
        
        if ([string]::IsNullOrWhiteSpace($txtName.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtUses.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtDelay.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtHP.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($sizeObj.TxtH.Text) -or [string]::IsNullOrWhiteSpace($sizeObj.TxtV.Text)) { $isValid = $false }
        
        if ($rbDehydYes.Checked -and [string]::IsNullOrWhiteSpace($txtDehydVal.Text)) { $isValid = $false }
        
        # Validação do novo campo direto
        if ([string]::IsNullOrWhiteSpace($txtCost.Text)) { $isValid = $false }

        if (-not $isValid) { [System.Windows.Forms.MessageBox]::Show("Complete o formulário corretamente.", "Erro", "OK", "Warning"); return }

        $finalDehyd = if ($rbDehydYes.Checked) { $txtDehydVal.Text } else { "/////" }
        $finalSize = "$($sizeObj.TxtH.Text)x$($sizeObj.TxtV.Text)"

        $newItemData = [Ordered]@{
            NomeItem          = $txtName.Text.Trim()
            Usos              = $txtUses.Text
            Delay             = $txtDelay.Text
            Desidratacao      = $finalDehyd
            RecuperacaoHP     = $txtHP.Text
            CustoDurabilidade = $txtCost.Text
            EspacoOcupado     = $finalSize
        }

        $csvPath = Join-Path (Get-DatabasePath) "Surgicalkit.csv"
        $allItems = @(); if (Test-Path $csvPath) { $allItems = @(Import-Csv $csvPath -Delimiter ";" -Encoding UTF8) }

        if ((-not $EditItem) -or ($EditItem.NomeItem -ne $newItemData.NomeItem)) {
            if ($allItems.NomeItem -contains $newItemData.NomeItem) { [System.Windows.Forms.MessageBox]::Show("Nome já existe!", "Erro", "OK", "Error"); return }
        }

        if ($EditItem) {
            for ($i = 0; $i -lt $allItems.Count; $i++) {
                if ($allItems[$i].NomeItem -eq $EditItem.NomeItem) { $allItems[$i] = [PSCustomObject]$newItemData; break }
            }
        } else { $allItems += [PSCustomObject]$newItemData }

        $allItems | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
        $fEdit.DialogResult = "OK"; $fEdit.Close()
    })

    $fEdit.ShowDialog() | Out-Null
    
    # --- CORREÇÃO MEMORY LEAK ---
    $fEdit.Dispose()
}

function Start-MedicalKitEditor {
    param (
        $ui,
        $EditItem = $null
    )

    # 1. Janela
    $fEdit = New-Object System.Windows.Forms.Form
    $fEdit.Size = New-Object System.Drawing.Size(950, 750)
    $fEdit.StartPosition = "CenterParent"
    $fEdit.BackColor = $global:theme.PanelBack
    $fEdit.ForeColor = $global:theme.TextMain
    $fEdit.FormBorderStyle = "FixedDialog"
    $fEdit.MaximizeBox = $false
    $fEdit.MinimizeBox = $false
    $fEdit.Text = if ($EditItem) { "Editar Kit Médico: $($EditItem.NomeItem)" } else { "Adicionar Novo Kit Médico" }

    # 2. Paineis
    $pnlContent = New-Object System.Windows.Forms.Panel; $pnlContent.Dock = "Fill"; $pnlContent.AutoScroll = $true; $pnlContent.Padding = New-Object System.Windows.Forms.Padding(0, 0, 0, 80)
    $fEdit.Controls.Add($pnlContent)

    $pnlButtons = New-Object System.Windows.Forms.Panel; $pnlButtons.Dock = "Bottom"; $pnlButtons.Height = 70; $pnlButtons.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $fEdit.Controls.Add($pnlButtons)

    # --- LAYOUT ---
    $layout = @{ RowL = 0; RowR = 0; Col1_X = 30; Col2_X = 480; FieldWidth = 400; RowHeight = 65 }

    function Add-Field {
        param($LabelText, $Control, [int]$Column)
        $x = if ($Column -eq 1) { $layout.Col1_X } else { $layout.Col2_X }
        $r = if ($Column -eq 1) { $layout.RowL } else { $layout.RowR }
        $y = 20 + ($r * $layout.RowHeight)

        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $LabelText; $lbl.Location = "$x, $y"; $lbl.AutoSize = $true; $lbl.ForeColor = $global:theme.OrangeAccent
        $pnlContent.Controls.Add($lbl)
        
        if ($Control) {
            $Control.Location = "$x, $($y + 25)"; $Control.Size = "$($layout.FieldWidth), 30"
            $Control.BackColor = $global:theme.ButtonBack; $Control.ForeColor = $global:theme.TextMain
            if ($Control -is [System.Windows.Forms.TextBox]) { $Control.BorderStyle = "FixedSingle" }
            if ($Control -is [System.Windows.Forms.ComboBox]) { $Control.FlatStyle = "Flat" }
            $pnlContent.Controls.Add($Control)
        }
        
        if ($Column -eq 1) { $layout.RowL++ } else { $layout.RowR++ }
        return $y
    }

    # --- VALIDACAO ---
    function Add-Validation {
        param($Control, [string]$Mode)
        $Control.Tag = $Mode 
        $Control.ContextMenu = New-Object System.Windows.Forms.ContextMenu
        $Control.Add_KeyDown({
            if (($_.Control -and $_.KeyCode -eq 'V') -or ($_.Shift -and $_.KeyCode -eq 'Insert')) { $_.SuppressKeyPress = $true }
        })
        $kp = {
            $allowed = Test-KeyRestriction -Control $this -Char $_.KeyChar -Mode $this.Tag
            if (-not $allowed) { $_.Handled = $true } 
        }.GetNewClosure()
        $Control.Add_KeyPress($kp)
    }

    # Helper para input de tamanho
    function Create-SizeInput {
        param([string]$InitialVal)
        $p = New-Object System.Windows.Forms.Panel; $p.Height = 30; $p.Width = 400
        $lblX = New-Object System.Windows.Forms.Label; $lblX.Text = "x"; $lblX.AutoSize = $true; $lblX.ForeColor = $global:theme.TextMain; $lblX.Location = "60, 5"
        
        $txtH = New-Object System.Windows.Forms.TextBox; $txtH.Width = 50; $txtH.MaxLength = 1; $txtH.Location = "0, 3"
        Add-Validation -Control $txtH -Mode "numeric_1_4"
        
        $txtV = New-Object System.Windows.Forms.TextBox; $txtV.Width = 50; $txtV.MaxLength = 1; $txtV.Location = "80, 3"
        Add-Validation -Control $txtV -Mode "numeric_1_4"

        if ($InitialVal -match '(\d)x(\d)') {
            $txtH.Text = $Matches[1]; $txtV.Text = $Matches[2]
        }

        $p.Controls.AddRange(@($txtH, $lblX, $txtV))
        return @{ Panel=$p; TxtH=$txtH; TxtV=$txtV }
    }

    # ==========================
    # COLUNA 1
    # ==========================

    # 1. Nome
    $txtName = New-Object System.Windows.Forms.TextBox; $txtName.MaxLength = 26
    if ($EditItem) { $txtName.Text = $EditItem.NomeItem }
    Add-Field -LabelText "Qual é o nome do kit médico?" -Control $txtName -Column 1

    # 2. Durabilidade
    $txtDurab = New-Object System.Windows.Forms.TextBox; $txtDurab.MaxLength = 4
    Add-Validation -Control $txtDurab -Mode "numeric_no_leading_zero"
    if ($EditItem) { $txtDurab.Text = $EditItem.DurabilidadeTotal }
    Add-Field -LabelText "Qual é a durabilidade do kit?" -Control $txtDurab -Column 1

    # 3. Desidratacao (Logica Condicional)
    $grpDehyd = New-Object System.Windows.Forms.Panel; $grpDehyd.Height=60; $grpDehyd.Width=400
    $rbDehydYes = New-Object System.Windows.Forms.RadioButton; $rbDehydYes.Text="Sim"; $rbDehydYes.Location="0,5"; $rbDehydYes.Width=50; $rbDehydYes.ForeColor=$global:theme.TextMain
    $rbDehydNo = New-Object System.Windows.Forms.RadioButton; $rbDehydNo.Text="Não"; $rbDehydNo.Location="60,5"; $rbDehydNo.Width=50; $rbDehydNo.ForeColor=$global:theme.TextMain
    
    $txtDehydVal = New-Object System.Windows.Forms.TextBox; $txtDehydVal.Location="120,3"; $txtDehydVal.Width=50; $txtDehydVal.MaxLength=4; $txtDehydVal.Visible=$false
    Add-Validation -Control $txtDehydVal -Mode "dehydration_strict"
    
    $grpDehyd.Controls.AddRange(@($rbDehydYes, $rbDehydNo, $txtDehydVal))
    
    $rbDehydYes.Add_CheckedChanged({ $txtDehydVal.Visible = $rbDehydYes.Checked })
    
    if ($EditItem -and $EditItem.Desidratacao -ne "/////") { 
        $rbDehydYes.Checked=$true; $txtDehydVal.Text = $EditItem.Desidratacao 
    } else { $rbDehydNo.Checked=$true }
    
    Add-Field -LabelText "Ele desidrata? (Ex: -100)" -Control $grpDehyd -Column 1

    # 4. Velocidade de Cura
    $txtSpeed = New-Object System.Windows.Forms.TextBox; $txtSpeed.MaxLength = 3
    Add-Validation -Control $txtSpeed -Mode "numeric_no_leading_zero"
    if ($EditItem) { $txtSpeed.Text = $EditItem.VelocidadeCura }
    Add-Field -LabelText "Qual é a velocidade de cura?" -Control $txtSpeed -Column 1

    # ==========================
    # COLUNA 2
    # ==========================

    # 5. Delay
    $txtDelay = New-Object System.Windows.Forms.TextBox; $txtDelay.MaxLength = 4
    Add-Validation -Control $txtDelay -Mode "decimal_fixed"
    if ($EditItem) { $txtDelay.Text = $EditItem.Delay }
    Add-Field -LabelText "Qual é o tempo de atraso? (ex: 1.2)" -Control $txtDelay -Column 2

    # 6. Custo por Uso
    $txtCost = New-Object System.Windows.Forms.TextBox; $txtCost.MaxLength = 3
    Add-Validation -Control $txtCost -Mode "numeric_allow_zero_single"
    if ($EditItem) { $txtCost.Text = $EditItem.CustoPorUso }
    Add-Field -LabelText "Qual é o custo de durabilidade?" -Control $txtCost -Column 2

    # 7. Tamanho (Horizontal x Vertical)
    $sizeObj = Create-SizeInput -InitialVal $EditItem.EspacoOcupado
    Add-Field -LabelText "Qual o tamanho ocupado? (Horiz x Vert)" -Control $sizeObj.Panel -Column 2

    # --- BOTOES ---
    $btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = "Salvar"; $btnSave.Location = "330, 15"; $btnSave.Size = "120, 40"; $btnSave.FlatStyle = "Flat"; $btnSave.BackColor = $global:theme.GreenSuccess; $btnSave.ForeColor = $global:theme.Background
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Cancelar"; $btnCancel.Location = "500, 15"; $btnCancel.Size = "120, 40"; $btnCancel.FlatStyle = "Flat"; $btnCancel.BackColor = $global:theme.ButtonBack; $btnCancel.ForeColor = $global:theme.TextMain
    $pnlButtons.Controls.AddRange(@($btnSave, $btnCancel)); $fEdit.AcceptButton = $btnSave; $fEdit.CancelButton = $btnCancel

    # --- SALVAR ---
    $btnSave.Add_Click({
        $isValid = $true
        
        if ([string]::IsNullOrWhiteSpace($txtName.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtDurab.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtSpeed.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtDelay.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtCost.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($sizeObj.TxtH.Text) -or [string]::IsNullOrWhiteSpace($sizeObj.TxtV.Text)) { $isValid = $false }
        
        if ($rbDehydYes.Checked -and [string]::IsNullOrWhiteSpace($txtDehydVal.Text)) { $isValid = $false }

        if (-not $isValid) { [System.Windows.Forms.MessageBox]::Show("Complete o formulário corretamente.", "Erro", "OK", "Warning"); return }

        $finalDehyd = if ($rbDehydYes.Checked) { $txtDehydVal.Text } else { "/////" }
        $finalSize = "$($sizeObj.TxtH.Text)x$($sizeObj.TxtV.Text)"

        $newItemData = [Ordered]@{
            NomeItem          = $txtName.Text.Trim()
            DurabilidadeTotal = $txtDurab.Text
            Desidratacao      = $finalDehyd
            VelocidadeCura    = $txtSpeed.Text
            Delay             = $txtDelay.Text
            CustoPorUso       = $txtCost.Text
            EspacoOcupado     = $finalSize
        }

        $csvPath = Join-Path (Get-DatabasePath) "Medicalkit.csv"
        $allItems = @(); if (Test-Path $csvPath) { $allItems = @(Import-Csv $csvPath -Delimiter ";" -Encoding UTF8) }

        if ((-not $EditItem) -or ($EditItem.NomeItem -ne $newItemData.NomeItem)) {
            if ($allItems.NomeItem -contains $newItemData.NomeItem) { [System.Windows.Forms.MessageBox]::Show("Nome já existe!", "Erro", "OK", "Error"); return }
        }

        if ($EditItem) {
            for ($i = 0; $i -lt $allItems.Count; $i++) {
                if ($allItems[$i].NomeItem -eq $EditItem.NomeItem) { $allItems[$i] = [PSCustomObject]$newItemData; break }
            }
        } else { $allItems += [PSCustomObject]$newItemData }

        $allItems | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
        $fEdit.DialogResult = "OK"; $fEdit.Close()
    })

    $fEdit.ShowDialog() | Out-Null
    
    # --- CORREÇÃO MEMORY LEAK ---
    $fEdit.Dispose()
}

function Start-NebulizerEditor {
    param (
        $ui,
        $EditItem = $null
    )

    # 1. Janela
    $fEdit = New-Object System.Windows.Forms.Form
    $fEdit.Size = New-Object System.Drawing.Size(950, 750)
    $fEdit.StartPosition = "CenterParent"
    $fEdit.BackColor = $global:theme.PanelBack
    $fEdit.ForeColor = $global:theme.TextMain
    $fEdit.FormBorderStyle = "FixedDialog"
    $fEdit.MaximizeBox = $false
    $fEdit.MinimizeBox = $false
    $fEdit.Text = if ($EditItem) { "Editar Nebulizador: $($EditItem.NomeItem)" } else { "Adicionar Novo Nebulizador" }

    # 2. Paineis
    $pnlContent = New-Object System.Windows.Forms.Panel; $pnlContent.Dock = "Fill"; $pnlContent.AutoScroll = $true; $pnlContent.Padding = New-Object System.Windows.Forms.Padding(0, 0, 0, 80)
    $fEdit.Controls.Add($pnlContent)

    $pnlButtons = New-Object System.Windows.Forms.Panel; $pnlButtons.Dock = "Bottom"; $pnlButtons.Height = 70; $pnlButtons.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $fEdit.Controls.Add($pnlButtons)

    # --- LAYOUT ---
    $layout = @{ RowL = 0; RowR = 0; Col1_X = 30; Col2_X = 480; FieldWidth = 400; RowHeight = 65 }

    function Add-Field {
        param($LabelText, $Control, [int]$Column)
        $x = if ($Column -eq 1) { $layout.Col1_X } else { $layout.Col2_X }
        $r = if ($Column -eq 1) { $layout.RowL } else { $layout.RowR }
        $y = 20 + ($r * $layout.RowHeight)

        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $LabelText; $lbl.Location = "$x, $y"; $lbl.AutoSize = $true; $lbl.ForeColor = $global:theme.OrangeAccent
        $pnlContent.Controls.Add($lbl)
        
        if ($Control) {
            $Control.Location = "$x, $($y + 25)"; $Control.Size = "$($layout.FieldWidth), 30"
            $Control.BackColor = $global:theme.ButtonBack; $Control.ForeColor = $global:theme.TextMain
            if ($Control -is [System.Windows.Forms.TextBox]) { $Control.BorderStyle = "FixedSingle" }
            if ($Control -is [System.Windows.Forms.ComboBox]) { $Control.FlatStyle = "Flat" }
            $pnlContent.Controls.Add($Control)
        }
        
        if ($Column -eq 1) { $layout.RowL++ } else { $layout.RowR++ }
    }

    # --- VALIDACAO ---
    function Add-Validation {
        param($Control, [string]$Mode)
        $Control.Tag = $Mode 
        $Control.ContextMenu = New-Object System.Windows.Forms.ContextMenu
        $Control.Add_KeyDown({
            if (($_.Control -and $_.KeyCode -eq 'V') -or ($_.Shift -and $_.KeyCode -eq 'Insert')) { $_.SuppressKeyPress = $true }
        })
        $kp = {
            $allowed = Test-KeyRestriction -Control $this -Char $_.KeyChar -Mode $this.Tag
            if (-not $allowed) { $_.Handled = $true } 
        }.GetNewClosure()
        $Control.Add_KeyPress($kp)
    }

    # ==========================
    # COLUNA 1
    # ==========================

    # 1. Nome
    $txtName = New-Object System.Windows.Forms.TextBox; $txtName.MaxLength = 25
    if ($EditItem) { $txtName.Text = $EditItem.NomeItem }
    Add-Field -LabelText "Qual é o nome do nebulizador?" -Control $txtName -Column 1

    # 2. Usos
    $txtUses = New-Object System.Windows.Forms.TextBox; $txtUses.MaxLength = 1
    Add-Validation -Control $txtUses -Mode "numeric_1_9"
    if ($EditItem) { $txtUses.Text = $EditItem.Usos }
    Add-Field -LabelText "Quantas vezes pode ser usado? (1-9)" -Control $txtUses -Column 1

    # ==========================
    # COLUNA 2
    # ==========================

    # 3. Delay
    $txtDelay = New-Object System.Windows.Forms.TextBox; $txtDelay.MaxLength = 4
    Add-Validation -Control $txtDelay -Mode "decimal_fixed"
    if ($EditItem) { $txtDelay.Text = $EditItem.Delay }
    Add-Field -LabelText "Qual é o tempo de atraso? (ex: 1.2)" -Control $txtDelay -Column 2

    # 4. Custo Durabilidade (Simplificado)
    $txtCost = New-Object System.Windows.Forms.TextBox; $txtCost.MaxLength = 1
    Add-Validation -Control $txtCost -Mode "numeric_1_9"
    
    # Se for edição e não for "/////" (antigo Nao), carrega o valor
    if ($EditItem -and $EditItem.CustoDurabilidade -ne "/////") { 
        $txtCost.Text = $EditItem.CustoDurabilidade 
    }
    
    Add-Field -LabelText "Qual é o custo de durabilidade? (1-9)" -Control $txtCost -Column 2

    # --- BOTOES ---
    $btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = "Salvar"; $btnSave.Location = "330, 15"; $btnSave.Size = "120, 40"; $btnSave.FlatStyle = "Flat"; $btnSave.BackColor = $global:theme.GreenSuccess; $btnSave.ForeColor = $global:theme.Background
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Cancelar"; $btnCancel.Location = "500, 15"; $btnCancel.Size = "120, 40"; $btnCancel.FlatStyle = "Flat"; $btnCancel.BackColor = $global:theme.ButtonBack; $btnCancel.ForeColor = $global:theme.TextMain
    $pnlButtons.Controls.AddRange(@($btnSave, $btnCancel)); $fEdit.AcceptButton = $btnSave; $fEdit.CancelButton = $btnCancel

    # --- SALVAR ---
    $btnSave.Add_Click({
        $isValid = $true
        
        if ([string]::IsNullOrWhiteSpace($txtName.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtUses.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtDelay.Text)) { $isValid = $false }
        
        # Agora valida o campo direto
        if ([string]::IsNullOrWhiteSpace($txtCost.Text)) { $isValid = $false }

        if (-not $isValid) { [System.Windows.Forms.MessageBox]::Show("Complete o formulário corretamente.", "Erro", "OK", "Warning"); return }

        $newItemData = [Ordered]@{
            NomeItem          = $txtName.Text.Trim()
            Usos              = $txtUses.Text
            Delay             = $txtDelay.Text
            CustoDurabilidade = $txtCost.Text
        }

        $csvPath = Join-Path (Get-DatabasePath) "Nebulizers.csv"
        $allItems = @(); if (Test-Path $csvPath) { $allItems = @(Import-Csv $csvPath -Delimiter ";" -Encoding UTF8) }

        if ((-not $EditItem) -or ($EditItem.NomeItem -ne $newItemData.NomeItem)) {
            if ($allItems.NomeItem -contains $newItemData.NomeItem) { [System.Windows.Forms.MessageBox]::Show("Nome já existe!", "Erro", "OK", "Error"); return }
        }

        if ($EditItem) {
            for ($i = 0; $i -lt $allItems.Count; $i++) {
                if ($allItems[$i].NomeItem -eq $EditItem.NomeItem) { $allItems[$i] = [PSCustomObject]$newItemData; break }
            }
        } else { $allItems += [PSCustomObject]$newItemData }

        $allItems | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
        $fEdit.DialogResult = "OK"; $fEdit.Close()
    })

    $fEdit.ShowDialog() | Out-Null
    
    # --- CORREÇÃO MEMORY LEAK ---
    $fEdit.Dispose()
}

function Start-StimulantEditor {
    param (
        $ui,
        $EditItem = $null
    )

    # 1. Janela
    $fEdit = New-Object System.Windows.Forms.Form
    $fEdit.Size = New-Object System.Drawing.Size(950, 750)
    $fEdit.StartPosition = "CenterParent"
    $fEdit.BackColor = $global:theme.PanelBack
    $fEdit.ForeColor = $global:theme.TextMain
    $fEdit.FormBorderStyle = "FixedDialog"
    $fEdit.MaximizeBox = $false
    $fEdit.MinimizeBox = $false
    $fEdit.Text = if ($EditItem) { "Editar Estimulante: $($EditItem.NomeItem)" } else { "Adicionar Novo Estimulante" }

    # 2. Paineis
    $pnlContent = New-Object System.Windows.Forms.Panel; $pnlContent.Dock = "Fill"; $pnlContent.AutoScroll = $true; $pnlContent.Padding = New-Object System.Windows.Forms.Padding(0, 0, 0, 80)
    $fEdit.Controls.Add($pnlContent)

    $pnlButtons = New-Object System.Windows.Forms.Panel; $pnlButtons.Dock = "Bottom"; $pnlButtons.Height = 70; $pnlButtons.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $fEdit.Controls.Add($pnlButtons)

    # --- LAYOUT ---
    $layout = @{ RowL = 0; RowR = 0; Col1_X = 30; Col2_X = 480; FieldWidth = 400; RowHeight = 65 }

    function Add-Field {
        param($LabelText, $Control, [int]$Column)
        $x = if ($Column -eq 1) { $layout.Col1_X } else { $layout.Col2_X }
        $r = if ($Column -eq 1) { $layout.RowL } else { $layout.RowR }
        $y = 20 + ($r * $layout.RowHeight)

        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $LabelText; $lbl.Location = "$x, $y"; $lbl.AutoSize = $true; $lbl.ForeColor = $global:theme.OrangeAccent
        $pnlContent.Controls.Add($lbl)
        
        if ($Control) {
            $Control.Location = "$x, $($y + 25)"; $Control.Size = "$($layout.FieldWidth), 30"
            $Control.BackColor = $global:theme.ButtonBack; $Control.ForeColor = $global:theme.TextMain
            if ($Control -is [System.Windows.Forms.TextBox]) { $Control.BorderStyle = "FixedSingle" }
            if ($Control -is [System.Windows.Forms.ComboBox]) { $Control.FlatStyle = "Flat" }
            $pnlContent.Controls.Add($Control)
        }
        
        if ($Column -eq 1) { $layout.RowL++ } else { $layout.RowR++ }
    }

    # --- VALIDACAO ---
    function Add-Validation {
        param($Control, [string]$Mode)
        $Control.Tag = $Mode 
        $Control.ContextMenu = New-Object System.Windows.Forms.ContextMenu
        $Control.Add_KeyDown({
            if (($_.Control -and $_.KeyCode -eq 'V') -or ($_.Shift -and $_.KeyCode -eq 'Insert')) { $_.SuppressKeyPress = $true }
        })
        $kp = {
            $allowed = Test-KeyRestriction -Control $this -Char $_.KeyChar -Mode $this.Tag
            if (-not $allowed) { $_.Handled = $true } 
        }.GetNewClosure()
        $Control.Add_KeyPress($kp)
    }
    
    # --- MAPAS ---
    # [ALTERAÇÃO AQUI] Nomes atualizados conforme pedido
    $effectMap = [Ordered]@{ 
        "Regeneração contínua"="Regeneration"; 
        "Stamina melhorada"="Stamina"; 
        "Força melhorada"="Strength" 
    }
    $placeholderText = "Selecione os dados aqui"

    # ==========================
    # COLUNA 1
    # ==========================

    # 1. Nome
    $txtName = New-Object System.Windows.Forms.TextBox; $txtName.MaxLength = 25
    if ($EditItem) { $txtName.Text = $EditItem.NomeItem }
    Add-Field -LabelText "Qual é o nome do estimulante?" -Control $txtName -Column 1

    # 2. Efeito Principal (Dropdown)
    $cmbEffect = New-Object System.Windows.Forms.ComboBox; $cmbEffect.DropDownStyle = "DropDownList"
    
    # Placeholder
    $cmbEffect.Items.Add($placeholderText) | Out-Null
    foreach ($k in $effectMap.Keys) { $cmbEffect.Items.Add($k)|Out-Null }
    
    if ($EditItem) { 
        $k=$effectMap.Keys|Where{$effectMap[$_] -eq $EditItem.EfeitoPrincipal}
        if($k){$cmbEffect.SelectedItem=$k} else {$cmbEffect.SelectedIndex=0}
    } else { $cmbEffect.SelectedIndex=0 }

    $cmbEffect.Add_DropDown({
        if ($this.Items.Count -gt 0 -and $this.Items[0] -eq "Selecione os dados aqui") {
            $this.Items.RemoveAt(0)
        }
    })
    
    Add-Field -LabelText "Qual é o efeito principal?" -Control $cmbEffect -Column 1

    # 3. Duracao
    $txtDur = New-Object System.Windows.Forms.TextBox; $txtDur.MaxLength = 4
    Add-Validation -Control $txtDur -Mode "numeric_no_leading_zero"
    if ($EditItem) { $txtDur.Text = $EditItem.Duracao }
    Add-Field -LabelText "Qual é a duração do efeito?" -Control $txtDur -Column 1

    # ==========================
    # COLUNA 2
    # ==========================

    # 4. Desidratacao (Condicional - Mantido como estava pois nao foi pedido alteracao)
    $grpDehyd = New-Object System.Windows.Forms.Panel; $grpDehyd.Height=60; $grpDehyd.Width=400
    $rbDehydYes = New-Object System.Windows.Forms.RadioButton; $rbDehydYes.Text="Sim"; $rbDehydYes.Location="0,5"; $rbDehydYes.Width=50; $rbDehydYes.ForeColor=$global:theme.TextMain
    $rbDehydNo = New-Object System.Windows.Forms.RadioButton; $rbDehydNo.Text="Não"; $rbDehydNo.Location="60,5"; $rbDehydNo.Width=50; $rbDehydNo.ForeColor=$global:theme.TextMain
    
    $txtDehydVal = New-Object System.Windows.Forms.TextBox; $txtDehydVal.Location="120,3"; $txtDehydVal.Width=50; $txtDehydVal.MaxLength=4; $txtDehydVal.Visible=$false
    Add-Validation -Control $txtDehydVal -Mode "dehydration_strict" # Permite negativos
    
    $grpDehyd.Controls.AddRange(@($rbDehydYes, $rbDehydNo, $txtDehydVal))
    
    $rbDehydYes.Add_CheckedChanged({ $txtDehydVal.Visible = $rbDehydYes.Checked })
    
    if ($EditItem -and $EditItem.Desidratacao -ne "/////") { 
        $rbDehydYes.Checked=$true; $txtDehydVal.Text = $EditItem.Desidratacao 
    } else { $rbDehydNo.Checked=$true }
    
    Add-Field -LabelText "Ele desidrata? (Ex: -100)" -Control $grpDehyd -Column 2

    # 5. Reducao Energia (Simplificado)
    # [ALTERAÇÃO AQUI] Removido Radio Buttons, agora é TextBox direto
    $txtEnergyVal = New-Object System.Windows.Forms.TextBox; $txtEnergyVal.MaxLength = 4
    Add-Validation -Control $txtEnergyVal -Mode "energy_negative_only" # Permite negativos
    
    # Se for edição e não for "/////", carrega o valor
    if ($EditItem -and $EditItem.ReducaoEnergia -ne "/////") { 
        $txtEnergyVal.Text = $EditItem.ReducaoEnergia 
    }
    
    Add-Field -LabelText "Qual é a redução de energia? (Ex: -10)" -Control $txtEnergyVal -Column 2

    # 6. Delay
    $txtDelay = New-Object System.Windows.Forms.TextBox; $txtDelay.MaxLength = 4
    Add-Validation -Control $txtDelay -Mode "decimal_fixed"
    if ($EditItem) { $txtDelay.Text = $EditItem.Delay }
    Add-Field -LabelText "Qual é o tempo de atraso? (ex: 1.2)" -Control $txtDelay -Column 2

    # --- BOTOES ---
    $btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = "Salvar"; $btnSave.Location = "330, 15"; $btnSave.Size = "120, 40"; $btnSave.FlatStyle = "Flat"; $btnSave.BackColor = $global:theme.GreenSuccess; $btnSave.ForeColor = $global:theme.Background
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Cancelar"; $btnCancel.Location = "500, 15"; $btnCancel.Size = "120, 40"; $btnCancel.FlatStyle = "Flat"; $btnCancel.BackColor = $global:theme.ButtonBack; $btnCancel.ForeColor = $global:theme.TextMain
    $pnlButtons.Controls.AddRange(@($btnSave, $btnCancel)); $fEdit.AcceptButton = $btnSave; $fEdit.CancelButton = $btnCancel

    # --- SALVAR ---
    $btnSave.Add_Click({
        $isValid = $true
        
        if ([string]::IsNullOrWhiteSpace($txtName.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtDur.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtDelay.Text)) { $isValid = $false }
        
        # Valida Campo Novo Direto
        if ([string]::IsNullOrWhiteSpace($txtEnergyVal.Text)) { $isValid = $false }

        # Valida Combo
        if (-not $cmbEffect.SelectedItem -or $cmbEffect.SelectedItem -eq $placeholderText) { $isValid = $false }
        
        # Valida Condicional (Desidratacao ainda usa radio)
        if ($rbDehydYes.Checked -and [string]::IsNullOrWhiteSpace($txtDehydVal.Text)) { $isValid = $false }

        if (-not $isValid) { [System.Windows.Forms.MessageBox]::Show("Complete o formulário corretamente.`nVerifique se não há campos vazios ou 'Selecione os dados aqui'.", "Erro", "OK", "Warning"); return }

        $finalDehyd = if ($rbDehydYes.Checked) { $txtDehydVal.Text } else { "/////" }
        # Energia agora salva direto o valor
        $finalEnergy = $txtEnergyVal.Text

        $newItemData = [Ordered]@{
            NomeItem        = $txtName.Text.Trim()
            EfeitoPrincipal = $effectMap[$cmbEffect.SelectedItem]
            Duracao         = $txtDur.Text
            Desidratacao    = $finalDehyd
            ReducaoEnergia  = $finalEnergy
            Delay           = $txtDelay.Text
        }

        $csvPath = Join-Path (Get-DatabasePath) "Stimulants.csv"
        $allItems = @(); if (Test-Path $csvPath) { $allItems = @(Import-Csv $csvPath -Delimiter ";" -Encoding UTF8) }

        if ((-not $EditItem) -or ($EditItem.NomeItem -ne $newItemData.NomeItem)) {
            if ($allItems.NomeItem -contains $newItemData.NomeItem) { [System.Windows.Forms.MessageBox]::Show("Nome já existe!", "Erro", "OK", "Error"); return }
        }

        if ($EditItem) {
            for ($i = 0; $i -lt $allItems.Count; $i++) {
                if ($allItems[$i].NomeItem -eq $EditItem.NomeItem) { $allItems[$i] = [PSCustomObject]$newItemData; break }
            }
        } else { $allItems += [PSCustomObject]$newItemData }

        $allItems | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
        $fEdit.DialogResult = "OK"; $fEdit.Close()
    })

    $fEdit.ShowDialog() | Out-Null

    # --- CORREÇÃO MEMORY LEAK ---
    $fEdit.Dispose()
}

function Start-FoodEditor {
    param (
        $ui,
        $EditItem = $null
    )

    # 1. Janela
    $fEdit = New-Object System.Windows.Forms.Form
    $fEdit.Size = New-Object System.Drawing.Size(950, 750)
    $fEdit.StartPosition = "CenterParent"
    $fEdit.BackColor = $global:theme.PanelBack
    $fEdit.ForeColor = $global:theme.TextMain
    $fEdit.FormBorderStyle = "FixedDialog"
    $fEdit.MaximizeBox = $false
    $fEdit.MinimizeBox = $false
    $fEdit.Text = if ($EditItem) { "Editar Comida: $($EditItem.NomeItem)" } else { "Adicionar Nova Comida" }

    # 2. Paineis
    $pnlContent = New-Object System.Windows.Forms.Panel; $pnlContent.Dock = "Fill"; $pnlContent.AutoScroll = $true; $pnlContent.Padding = New-Object System.Windows.Forms.Padding(0, 0, 0, 80)
    $fEdit.Controls.Add($pnlContent)

    $pnlButtons = New-Object System.Windows.Forms.Panel; $pnlButtons.Dock = "Bottom"; $pnlButtons.Height = 70; $pnlButtons.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $fEdit.Controls.Add($pnlButtons)

    # --- LAYOUT ---
    $layout = @{ RowL = 0; RowR = 0; Col1_X = 30; Col2_X = 480; FieldWidth = 400; RowHeight = 65 }

    function Add-Field {
        param($LabelText, $Control, [int]$Column)
        $x = if ($Column -eq 1) { $layout.Col1_X } else { $layout.Col2_X }
        $r = if ($Column -eq 1) { $layout.RowL } else { $layout.RowR }
        $y = 20 + ($r * $layout.RowHeight)

        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $LabelText; $lbl.Location = "$x, $y"; $lbl.AutoSize = $true; $lbl.ForeColor = $global:theme.OrangeAccent
        $pnlContent.Controls.Add($lbl)
        
        if ($Control) {
            $Control.Location = "$x, $($y + 25)"; $Control.Size = "$($layout.FieldWidth), 30"
            $Control.BackColor = $global:theme.ButtonBack; $Control.ForeColor = $global:theme.TextMain
            if ($Control -is [System.Windows.Forms.TextBox]) { $Control.BorderStyle = "FixedSingle" }
            if ($Control -is [System.Windows.Forms.ComboBox]) { $Control.FlatStyle = "Flat" }
            $pnlContent.Controls.Add($Control)
        }
        
        if ($Column -eq 1) { $layout.RowL++ } else { $layout.RowR++ }
    }

    # --- VALIDACAO ---
    function Add-Validation {
        param($Control, [string]$Mode)
        $Control.Tag = $Mode 
        $Control.ContextMenu = New-Object System.Windows.Forms.ContextMenu
        $Control.Add_KeyDown({
            if (($_.Control -and $_.KeyCode -eq 'V') -or ($_.Shift -and $_.KeyCode -eq 'Insert')) { $_.SuppressKeyPress = $true }
        })
        $kp = {
            $allowed = Test-KeyRestriction -Control $this -Char $_.KeyChar -Mode $this.Tag
            if (-not $allowed) { $_.Handled = $true } 
        }.GetNewClosure()
        $Control.Add_KeyPress($kp)
    }

    # Helper para input de tamanho
    function Create-SizeInput {
        param([string]$InitialVal)
        $p = New-Object System.Windows.Forms.Panel; $p.Height = 30; $p.Width = 400
        $lblX = New-Object System.Windows.Forms.Label; $lblX.Text = "x"; $lblX.AutoSize = $true; $lblX.ForeColor = $global:theme.TextMain; $lblX.Location = "60, 5"
        
        $txtH = New-Object System.Windows.Forms.TextBox; $txtH.Width = 50; $txtH.MaxLength = 1; $txtH.Location = "0, 3"
        Add-Validation -Control $txtH -Mode "numeric_1_4"
        
        $txtV = New-Object System.Windows.Forms.TextBox; $txtV.Width = 50; $txtV.MaxLength = 1; $txtV.Location = "80, 3"
        Add-Validation -Control $txtV -Mode "numeric_1_4"

        if ($InitialVal -match '(\d)x(\d)') {
            $txtH.Text = $Matches[1]; $txtV.Text = $Matches[2]
        }

        $p.Controls.AddRange(@($txtH, $lblX, $txtV))
        return @{ Panel=$p; TxtH=$txtH; TxtV=$txtV }
    }
    
    # --- MAPAS ---
    $staminaMap = [Ordered]@{ "Não recupera"="/////"; "Ligeiro"="Low"; "Normal"="Medium"; "Forte"="High" }
    $placeholderText = "Selecione os dados aqui"

    # ==========================
    # COLUNA 1
    # ==========================

    # 1. Nome
    $txtName = New-Object System.Windows.Forms.TextBox; $txtName.MaxLength = 34
    if ($EditItem) { $txtName.Text = $EditItem.NomeItem }
    Add-Field -LabelText "Qual é o nome da comida?" -Control $txtName -Column 1

    # 2. Hidratacao (Simplificado)
    $txtHydra = New-Object System.Windows.Forms.TextBox; $txtHydra.MaxLength = 4
    Add-Validation -Control $txtHydra -Mode "hydration_strict" # Aceita +50, -10, 0
    if ($EditItem) { $txtHydra.Text = $EditItem.Hidratacao }
    Add-Field -LabelText "Qual é a hidratação? (Ex: 0, +50, -100)" -Control $txtHydra -Column 1

    # 3. Energia (Simplificado)
    $txtEnergy = New-Object System.Windows.Forms.TextBox; $txtEnergy.MaxLength = 4
    Add-Validation -Control $txtEnergy -Mode "hydration_strict" 
    if ($EditItem) { $txtEnergy.Text = $EditItem.Energia }
    Add-Field -LabelText "Qual é a energia? (Ex: 0, +50, -100)" -Control $txtEnergy -Column 1

    # ==========================
    # COLUNA 2
    # ==========================

    # 4. Delay
    $txtDelay = New-Object System.Windows.Forms.TextBox; $txtDelay.MaxLength = 4
    Add-Validation -Control $txtDelay -Mode "decimal_fixed"
    if ($EditItem) { $txtDelay.Text = $EditItem.Delay }
    Add-Field -LabelText "Qual é o tempo de atraso? (ex: 1.2)" -Control $txtDelay -Column 2

    # 5. Recuperacao Stamina (Dropdown)
    $cmbStamina = New-Object System.Windows.Forms.ComboBox; $cmbStamina.DropDownStyle = "DropDownList"
    $cmbStamina.Items.Add($placeholderText) | Out-Null
    foreach ($k in $staminaMap.Keys) { $cmbStamina.Items.Add($k)|Out-Null }
    
    if ($EditItem) { 
        $k=$staminaMap.Keys|Where{$staminaMap[$_] -eq $EditItem.RecuperacaoStamina}
        if($k){$cmbStamina.SelectedItem=$k} else {$cmbStamina.SelectedIndex=0}
    } else { $cmbStamina.SelectedIndex=0 }

    $cmbStamina.Add_DropDown({
        if ($this.Items.Count -gt 0 -and $this.Items[0] -eq "Selecione os dados aqui") {
            $this.Items.RemoveAt(0)
        }
    })
    
    Add-Field -LabelText "Recupera Stamina?" -Control $cmbStamina -Column 2

    # 6. Tamanho (Horizontal x Vertical)
    $sizeObj = Create-SizeInput -InitialVal $EditItem.EspacoOcupado
    Add-Field -LabelText "Qual o tamanho ocupado? (Horiz x Vert)" -Control $sizeObj.Panel -Column 2

    # --- BOTOES ---
    $btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = "Salvar"; $btnSave.Location = "330, 15"; $btnSave.Size = "120, 40"; $btnSave.FlatStyle = "Flat"; $btnSave.BackColor = $global:theme.GreenSuccess; $btnSave.ForeColor = $global:theme.Background
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Cancelar"; $btnCancel.Location = "500, 15"; $btnCancel.Size = "120, 40"; $btnCancel.FlatStyle = "Flat"; $btnCancel.BackColor = $global:theme.ButtonBack; $btnCancel.ForeColor = $global:theme.TextMain
    $pnlButtons.Controls.AddRange(@($btnSave, $btnCancel)); $fEdit.AcceptButton = $btnSave; $fEdit.CancelButton = $btnCancel

    # --- SALVAR ---
    $btnSave.Add_Click({
        $isValid = $true
        
        if ([string]::IsNullOrWhiteSpace($txtName.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtDelay.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($sizeObj.TxtH.Text) -or [string]::IsNullOrWhiteSpace($sizeObj.TxtV.Text)) { $isValid = $false }
        
        # Novos campos obrigatorios
        if ([string]::IsNullOrWhiteSpace($txtHydra.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtEnergy.Text)) { $isValid = $false }

        # Valida Combo
        if (-not $cmbStamina.SelectedItem -or $cmbStamina.SelectedItem -eq $placeholderText) { $isValid = $false }
        
        if (-not $isValid) { [System.Windows.Forms.MessageBox]::Show("Complete o formulário corretamente.`nVerifique se não há campos vazios ou 'Selecione os dados aqui'.", "Erro", "OK", "Warning"); return }

        $finalSize = "$($sizeObj.TxtH.Text)x$($sizeObj.TxtV.Text)"

        $newItemData = [Ordered]@{
            NomeItem           = $txtName.Text.Trim()
            Hidratacao         = $txtHydra.Text
            Energia            = $txtEnergy.Text
            Delay              = $txtDelay.Text
            RecuperacaoStamina = $staminaMap[$cmbStamina.SelectedItem]
            EspacoOcupado      = $finalSize
        }

        $csvPath = Join-Path (Get-DatabasePath) "Food.csv"
        $allItems = @(); if (Test-Path $csvPath) { $allItems = @(Import-Csv $csvPath -Delimiter ";" -Encoding UTF8) }

        if ((-not $EditItem) -or ($EditItem.NomeItem -ne $newItemData.NomeItem)) {
            if ($allItems.NomeItem -contains $newItemData.NomeItem) { [System.Windows.Forms.MessageBox]::Show("Nome já existe!", "Erro", "OK", "Error"); return }
        }

        if ($EditItem) {
            for ($i = 0; $i -lt $allItems.Count; $i++) {
                if ($allItems[$i].NomeItem -eq $EditItem.NomeItem) { $allItems[$i] = [PSCustomObject]$newItemData; break }
            }
        } else { $allItems += [PSCustomObject]$newItemData }

        $allItems | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
        $fEdit.DialogResult = "OK"; $fEdit.Close()
    })

    $fEdit.ShowDialog() | Out-Null
    
    # --- CORREÇÃO MEMORY LEAK ---
    $fEdit.Dispose()
}

function Start-BeverageEditor {
    param (
        $ui,
        $EditItem = $null
    )

    # 1. Janela
    $fEdit = New-Object System.Windows.Forms.Form
    $fEdit.Size = New-Object System.Drawing.Size(950, 750)
    $fEdit.StartPosition = "CenterParent"
    $fEdit.BackColor = $global:theme.PanelBack
    $fEdit.ForeColor = $global:theme.TextMain
    $fEdit.FormBorderStyle = "FixedDialog"
    $fEdit.MaximizeBox = $false
    $fEdit.MinimizeBox = $false
    $fEdit.Text = if ($EditItem) { "Editar Bebida: $($EditItem.NomeItem)" } else { "Adicionar Nova Bebida" }

    # 2. Paineis
    $pnlContent = New-Object System.Windows.Forms.Panel; $pnlContent.Dock = "Fill"; $pnlContent.AutoScroll = $true; $pnlContent.Padding = New-Object System.Windows.Forms.Padding(0, 0, 0, 80)
    $fEdit.Controls.Add($pnlContent)

    $pnlButtons = New-Object System.Windows.Forms.Panel; $pnlButtons.Dock = "Bottom"; $pnlButtons.Height = 70; $pnlButtons.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $fEdit.Controls.Add($pnlButtons)

    # --- LAYOUT ---
    $layout = @{ RowL = 0; RowR = 0; Col1_X = 30; Col2_X = 480; FieldWidth = 400; RowHeight = 65 }

    function Add-Field {
        param($LabelText, $Control, [int]$Column)
        $x = if ($Column -eq 1) { $layout.Col1_X } else { $layout.Col2_X }
        $r = if ($Column -eq 1) { $layout.RowL } else { $layout.RowR }
        $y = 20 + ($r * $layout.RowHeight)

        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $LabelText; $lbl.Location = "$x, $y"; $lbl.AutoSize = $true; $lbl.ForeColor = $global:theme.OrangeAccent
        $pnlContent.Controls.Add($lbl)
        
        if ($Control) {
            $Control.Location = "$x, $($y + 25)"; $Control.Size = "$($layout.FieldWidth), 30"
            $Control.BackColor = $global:theme.ButtonBack; $Control.ForeColor = $global:theme.TextMain
            if ($Control -is [System.Windows.Forms.TextBox]) { $Control.BorderStyle = "FixedSingle" }
            if ($Control -is [System.Windows.Forms.ComboBox]) { $Control.FlatStyle = "Flat" }
            $pnlContent.Controls.Add($Control)
        }
        
        if ($Column -eq 1) { $layout.RowL++ } else { $layout.RowR++ }
    }

    # --- VALIDACAO ---
    function Add-Validation {
        param($Control, [string]$Mode)
        $Control.Tag = $Mode 
        $Control.ContextMenu = New-Object System.Windows.Forms.ContextMenu
        $Control.Add_KeyDown({
            if (($_.Control -and $_.KeyCode -eq 'V') -or ($_.Shift -and $_.KeyCode -eq 'Insert')) { $_.SuppressKeyPress = $true }
        })
        $kp = {
            $allowed = Test-KeyRestriction -Control $this -Char $_.KeyChar -Mode $this.Tag
            if (-not $allowed) { $_.Handled = $true } 
        }.GetNewClosure()
        $Control.Add_KeyPress($kp)
    }

    # Helper para input de tamanho
    function Create-SizeInput {
        param([string]$InitialVal)
        $p = New-Object System.Windows.Forms.Panel; $p.Height = 30; $p.Width = 400
        $lblX = New-Object System.Windows.Forms.Label; $lblX.Text = "x"; $lblX.AutoSize = $true; $lblX.ForeColor = $global:theme.TextMain; $lblX.Location = "60, 5"
        
        $txtH = New-Object System.Windows.Forms.TextBox; $txtH.Width = 50; $txtH.MaxLength = 1; $txtH.Location = "0, 3"
        Add-Validation -Control $txtH -Mode "numeric_1_4"
        
        $txtV = New-Object System.Windows.Forms.TextBox; $txtV.Width = 50; $txtV.MaxLength = 1; $txtV.Location = "80, 3"
        Add-Validation -Control $txtV -Mode "numeric_1_4"

        if ($InitialVal -match '(\d)x(\d)') {
            $txtH.Text = $Matches[1]; $txtV.Text = $Matches[2]
        }

        $p.Controls.AddRange(@($txtH, $lblX, $txtV))
        return @{ Panel=$p; TxtH=$txtH; TxtV=$txtV }
    }

    # --- MAPAS ---
    $staminaMap = [Ordered]@{ "Não recupera"="/////"; "Ligeiro"="Low"; "Normal"="Medium"; "Forte"="High" }
    $placeholderText = "Selecione os dados aqui"

    # ==========================
    # COLUNA 1
    # ==========================

    # 1. Nome
    $txtName = New-Object System.Windows.Forms.TextBox; $txtName.MaxLength = 34
    if ($EditItem) { $txtName.Text = $EditItem.NomeItem }
    Add-Field -LabelText "Qual é o nome da bebida?" -Control $txtName -Column 1

    # 2. Hidratacao (Simplificado)
    $txtHydra = New-Object System.Windows.Forms.TextBox; $txtHydra.MaxLength = 4
    Add-Validation -Control $txtHydra -Mode "hydration_strict"
    if ($EditItem) { $txtHydra.Text = $EditItem.Hidratacao }
    Add-Field -LabelText "Qual é a hidratação? (Ex: 0, +50, -100)" -Control $txtHydra -Column 1

    # 3. Energia (Simplificado)
    $txtEnergy = New-Object System.Windows.Forms.TextBox; $txtEnergy.MaxLength = 4
    Add-Validation -Control $txtEnergy -Mode "hydration_strict"
    if ($EditItem) { $txtEnergy.Text = $EditItem.Energia }
    Add-Field -LabelText "Qual é a energia? (Ex: 0, +50, -100)" -Control $txtEnergy -Column 1

    # ==========================
    # COLUNA 2
    # ==========================

    # 4. Delay
    $txtDelay = New-Object System.Windows.Forms.TextBox; $txtDelay.MaxLength = 4
    Add-Validation -Control $txtDelay -Mode "decimal_fixed"
    if ($EditItem) { $txtDelay.Text = $EditItem.Delay }
    Add-Field -LabelText "Qual é o tempo de atraso? (ex: 1.2)" -Control $txtDelay -Column 2

    # 5. Recuperacao Stamina (Dropdown com Placeholder)
    $cmbStamina = New-Object System.Windows.Forms.ComboBox; $cmbStamina.DropDownStyle = "DropDownList"
    $cmbStamina.Items.Add($placeholderText) | Out-Null
    foreach ($k in $staminaMap.Keys) { $cmbStamina.Items.Add($k)|Out-Null }
    
    if ($EditItem) { 
        $k=$staminaMap.Keys|Where{$staminaMap[$_] -eq $EditItem.RecuperacaoStamina}
        if($k){$cmbStamina.SelectedItem=$k} else {$cmbStamina.SelectedIndex=0}
    } else { $cmbStamina.SelectedIndex=0 }

    # Evento para remover placeholder
    $cmbStamina.Add_DropDown({
        if ($this.Items.Count -gt 0 -and $this.Items[0] -eq "Selecione os dados aqui") {
            $this.Items.RemoveAt(0)
        }
    })
    
    Add-Field -LabelText "Recupera Stamina?" -Control $cmbStamina -Column 2

    # 6. Tamanho (Horizontal x Vertical)
    $sizeObj = Create-SizeInput -InitialVal $EditItem.EspacoOcupado
    Add-Field -LabelText "Qual o tamanho ocupado? (Horiz x Vert)" -Control $sizeObj.Panel -Column 2

    # --- BOTOES ---
    $btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = "Salvar"; $btnSave.Location = "330, 15"; $btnSave.Size = "120, 40"; $btnSave.FlatStyle = "Flat"; $btnSave.BackColor = $global:theme.GreenSuccess; $btnSave.ForeColor = $global:theme.Background
    $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Cancelar"; $btnCancel.Location = "500, 15"; $btnCancel.Size = "120, 40"; $btnCancel.FlatStyle = "Flat"; $btnCancel.BackColor = $global:theme.ButtonBack; $btnCancel.ForeColor = $global:theme.TextMain
    $pnlButtons.Controls.AddRange(@($btnSave, $btnCancel)); $fEdit.AcceptButton = $btnSave; $fEdit.CancelButton = $btnCancel

    # --- SALVAR ---
    $btnSave.Add_Click({
        $isValid = $true
        
        if ([string]::IsNullOrWhiteSpace($txtName.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtDelay.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($sizeObj.TxtH.Text) -or [string]::IsNullOrWhiteSpace($sizeObj.TxtV.Text)) { $isValid = $false }
        
        # Novos campos obrigatorios
        if ([string]::IsNullOrWhiteSpace($txtHydra.Text)) { $isValid = $false }
        if ([string]::IsNullOrWhiteSpace($txtEnergy.Text)) { $isValid = $false }

        # Valida Combo (Placeholder)
        if (-not $cmbStamina.SelectedItem -or $cmbStamina.SelectedItem -eq $placeholderText) { $isValid = $false }
        
        if (-not $isValid) { [System.Windows.Forms.MessageBox]::Show("Complete o formulário corretamente.`nVerifique se não há campos vazios ou 'Selecione os dados aqui'.", "Erro", "OK", "Warning"); return }

        $finalSize = "$($sizeObj.TxtH.Text)x$($sizeObj.TxtV.Text)"

        $newItemData = [Ordered]@{
            NomeItem           = $txtName.Text.Trim()
            Hidratacao         = $txtHydra.Text
            Energia            = $txtEnergy.Text
            Delay              = $txtDelay.Text
            RecuperacaoStamina = $staminaMap[$cmbStamina.SelectedItem]
            EspacoOcupado      = $finalSize
        }

        $csvPath = Join-Path (Get-DatabasePath) "Beverages.csv"
        $allItems = @(); if (Test-Path $csvPath) { $allItems = @(Import-Csv $csvPath -Delimiter ";" -Encoding UTF8) }

        if ((-not $EditItem) -or ($EditItem.NomeItem -ne $newItemData.NomeItem)) {
            if ($allItems.NomeItem -contains $newItemData.NomeItem) { [System.Windows.Forms.MessageBox]::Show("Nome já existe!", "Erro", "OK", "Error"); return }
        }

        if ($EditItem) {
            for ($i = 0; $i -lt $allItems.Count; $i++) {
                if ($allItems[$i].NomeItem -eq $EditItem.NomeItem) { $allItems[$i] = [PSCustomObject]$newItemData; break }
            }
        } else { $allItems += [PSCustomObject]$newItemData }

        $allItems | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
        $fEdit.DialogResult = "OK"; $fEdit.Close()
    })

    $fEdit.ShowDialog() | Out-Null
    
    # --- CORREÇÃO MEMORY LEAK ---
    $fEdit.Dispose()
}

function Add-Field {
        param($LabelText, $Control, [int]$Column)
        $x = if ($Column -eq 1) { $layout.Col1_X } else { $layout.Col2_X }
        $r = if ($Column -eq 1) { $layout.RowL } else { $layout.RowR }
        $y = 20 + ($r * $layout.RowHeight)

        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $LabelText; $lbl.Location = "$x, $y"; $lbl.AutoSize = $true; $lbl.ForeColor = $global:theme.OrangeAccent
        $pnlContent.Controls.Add($lbl)
        
        if ($Control) {
            $Control.Location = "$x, $($y + 25)"; $Control.Size = "$($layout.FieldWidth), 30"
            $Control.BackColor = $global:theme.ButtonBack; $Control.ForeColor = $global:theme.TextMain
            if ($Control -is [System.Windows.Forms.TextBox]) { $Control.BorderStyle = "FixedSingle" }
            if ($Control -is [System.Windows.Forms.ComboBox]) { $Control.FlatStyle = "Flat" }
            $pnlContent.Controls.Add($Control)
        }
        
        $currentY = $y + 25
        if ($Column -eq 1) { $layout.RowL++ } else { $layout.RowR++ }
        return $currentY
    }

function Create-SizeInput {
        param($GroupLabel, [ref]$H_Ref, [ref]$V_Ref, $InitialValue)
        
        $pnl = New-Object System.Windows.Forms.Panel; $pnl.Height = 35; $pnl.Width = 400
        
        $lblX = New-Object System.Windows.Forms.Label; $lblX.Text = "Horiz:"; $lblX.Location = "0,8"; $lblX.AutoSize = $true; $lblX.ForeColor = $global:theme.TextDim
        $txtH = New-Object System.Windows.Forms.TextBox; $txtH.Location = "45,5"; $txtH.Width = 30; $txtH.MaxLength = 1; $txtH.BackColor=$global:theme.ButtonBack; $txtH.ForeColor=$global:theme.TextMain; $txtH.BorderStyle="FixedSingle"
        Add-Validation -Control $txtH -Mode "numeric_1_9"
        
        $lblY = New-Object System.Windows.Forms.Label; $lblY.Text = "Vert:"; $lblY.Location = "90,8"; $lblY.AutoSize = $true; $lblY.ForeColor = $global:theme.TextDim
        $txtV = New-Object System.Windows.Forms.TextBox; $txtV.Location = "130,5"; $txtV.Width = 30; $txtV.MaxLength = 1; $txtV.BackColor=$global:theme.ButtonBack; $txtV.ForeColor=$global:theme.TextMain; $txtV.BorderStyle="FixedSingle"
        Add-Validation -Control $txtV -Mode "numeric_1_9"

        $pnl.Controls.AddRange(@($lblX, $txtH, $lblY, $txtV))
        Add-Field -LabelText $GroupLabel -Control $pnl -Column 1
        
        if ($InitialValue -match '(\d)x(\d)') {
            $txtH.Text = $Matches[1]; $txtV.Text = $Matches[2]
        }
        
        $H_Ref.Value = $txtH; $V_Ref.Value = $txtV
        return $pnl
    }

function Setup-Combo {
        param($Combo, $Items, $IsMap=$false)
        $Combo.Items.Clear()
        $Combo.Items.Add($placeholderText) | Out-Null
        
        if ($IsMap) { foreach ($k in $Items.Keys) { $Combo.Items.Add($k)|Out-Null } }
        else { foreach ($i in $Items) { $Combo.Items.Add($i)|Out-Null } }
        
        $Combo.SelectedIndex = 0 
        
        $Combo.Add_DropDown({
            if ($this.Items.Count -gt 0 -and $this.Items[0] -eq "Selecione os dados aqui") {
                $this.Items.RemoveAt(0)
            }
        })
    }
	
# ===================================================================================
# MÓDULO: MENUS E NAVEGAÇÃO DO GERENCIADOR
# ===================================================================================

function Update-CaliberList {
    param ($ui)
    $ui.LstCalibers.Items.Clear()
    $csvPath = Join-Path (Get-DatabasePath) "Caliber.csv"
    if (Test-Path $csvPath) {
        $data = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8 | Sort-Object CalibreName
        foreach ($item in $data) { $ui.LstCalibers.Items.Add($item.CalibreName) | Out-Null }
    }
    
    # CORREÇÃO: Alterado de $ui.ThemeRef para $global:theme
    $ui.BtnCalEdit.Enabled = $false; $ui.BtnCalEdit.ForeColor = $global:theme.TextDim
    $ui.BtnCalDel.Enabled = $false; $ui.BtnCalDel.ForeColor = $global:theme.TextDim
    $ui.LblCalInfo.Text = "Nota: Selecione um calibre para ver as opções."; $ui.LblCalInfo.ForeColor = $global:theme.TextDim
}

function Initialize-ManagerVisuals {
    param ($targetForm) 

    $ui = @{}
    $ui.Form = $targetForm 

    # --- CORREÇÃO MEMORY LEAK GDI: Criação e Cache de Fontes ---
    if (-not $script:fontMngTitle)     { $script:fontMngTitle     = New-Object System.Drawing.Font("Segoe UI", 24, [System.Drawing.FontStyle]::Bold) }
    if (-not $script:fontMngSubTitle)  { $script:fontMngSubTitle  = New-Object System.Drawing.Font("Segoe UI", 18) }
    if (-not $script:fontMngListLarge) { $script:fontMngListLarge = New-Object System.Drawing.Font("Segoe UI", 12) }
    if (-not $script:fontMngListMed)   { $script:fontMngListMed   = New-Object System.Drawing.Font("Segoe UI", 11) }
    if (-not $script:fontMngInfo)      { $script:fontMngInfo      = New-Object System.Drawing.Font("Segoe UI", 10) }

    # --- 1. PAINEL MESTRE ---
    $pnlManagerRoot = New-Object System.Windows.Forms.Panel
    $pnlManagerRoot.Dock = "Fill"
    $pnlManagerRoot.BackColor = $global:theme.Background
    $pnlManagerRoot.Name = "PnlManagerRoot"
    
    $targetForm.Controls.Add($pnlManagerRoot)
    $pnlManagerRoot.BringToFront()
    
    $ui.PnlManagerRoot = $pnlManagerRoot 

    # --- 2. SUB-PAINÉIS ---
    $pnlMenu = New-Object System.Windows.Forms.Panel; $pnlMenu.Dock = "Fill"; $pnlMenu.Visible = $true
    $pnlCaliber = New-Object System.Windows.Forms.Panel; $pnlCaliber.Dock = "Fill"; $pnlCaliber.Visible = $false
    $pnlCompat = New-Object System.Windows.Forms.Panel; $pnlCompat.Dock = "Fill"; $pnlCompat.Visible = $false
    $pnlItems = New-Object System.Windows.Forms.Panel; $pnlItems.Dock = "Fill"; $pnlItems.Visible = $false
    
    $pnlManagerRoot.Controls.AddRange(@($pnlMenu, $pnlCaliber, $pnlCompat, $pnlItems))
    
    $ui.PnlMenu = $pnlMenu
    $ui.PnlCaliber = $pnlCaliber
    $ui.PnlCompat = $pnlCompat
    $ui.PnlItems = $pnlItems

    # --- 3. MENU PRINCIPAL ---
    $lblTitle = New-Object System.Windows.Forms.Label; $lblTitle.Text = "Gerenciar Banco de Dados"; $lblTitle.Font = $script:fontMngTitle; $lblTitle.ForeColor = $global:theme.OrangeAccent; $lblTitle.AutoSize = $true; $lblTitle.Location = "50, 50"
    $pnlMenu.Controls.Add($lblTitle)
    
    $btnStyle = @{ Size="350, 50"; FlatStyle="Flat"; BackColor=$global:theme.ButtonBack; ForeColor=$global:theme.TextMain }
    
    $btnManageItems = New-Object System.Windows.Forms.Button; $btnManageItems.Text = "Gerenciar Itens"; $btnManageItems.Location = "390, 200"; $btnManageItems.Size = $btnStyle.Size
    $btnManageItems.FlatStyle = "Flat"; $btnManageItems.BackColor = $global:theme.ButtonBack; $btnManageItems.ForeColor = $global:theme.TextMain; $btnManageItems.FlatAppearance.BorderColor = $global:theme.OrangeAccent
    
    $btnCaliber = New-Object System.Windows.Forms.Button; $btnCaliber.Text = "Gerenciar Calibres"; $btnCaliber.Location = "390, 270"; $btnCaliber.Size = $btnStyle.Size; $btnCaliber.FlatStyle = "Flat"; $btnCaliber.BackColor = $global:theme.ButtonBack; $btnCaliber.ForeColor = $global:theme.TextMain; $btnCaliber.FlatAppearance.BorderColor = $global:theme.OrangeAccent
    
    $btnCompat = New-Object System.Windows.Forms.Button; $btnCompat.Text = "Gerenciar Compatibilidade"; $btnCompat.Location = "390, 340"; $btnCompat.Size = $btnStyle.Size; $btnCompat.FlatStyle = "Flat"; $btnCompat.BackColor = $global:theme.ButtonBack; $btnCompat.ForeColor = $global:theme.TextMain; $btnCompat.FlatAppearance.BorderColor = $global:theme.OrangeAccent
    
    $btnBackMain = New-Object System.Windows.Forms.Button; $btnBackMain.Text = "Voltar"; $btnBackMain.Location = "950, 30"; $btnBackMain.Size = "100, 30"; $btnBackMain.FlatStyle = "Flat"; $btnBackMain.BackColor = $global:theme.ButtonBack; $btnBackMain.ForeColor = $global:theme.TextDim; $btnBackMain.FlatAppearance.BorderColor = $global:theme.TextDim; $btnBackMain.Enabled = $true
    
    $pnlMenu.Controls.AddRange(@($btnManageItems, $btnCaliber, $btnCompat, $btnBackMain))
    $ui.BtnManageItems = $btnManageItems; $ui.BtnCaliber = $btnCaliber; $ui.BtnCompat = $btnCompat; $ui.BtnBackMain = $btnBackMain

    # --- 4. TELA CALIBRES ---
    $lblCalTitle = New-Object System.Windows.Forms.Label; $lblCalTitle.Text = "Gerenciamento de Calibres"; $lblCalTitle.Font = $script:fontMngSubTitle; $lblCalTitle.ForeColor = $global:theme.OrangeAccent; $lblCalTitle.AutoSize = $true; $lblCalTitle.Location = "50, 30"
    $lstCalibers = New-Object System.Windows.Forms.ListBox; $lstCalibers.Location = "50, 80"; $lstCalibers.Size = "400, 600"; $lstCalibers.BackColor = $global:theme.PanelBack; $lstCalibers.ForeColor = $global:theme.TextMain; $lstCalibers.BorderStyle = "FixedSingle"; $lstCalibers.Font = $script:fontMngListLarge
    $btnCalAdd = New-Object System.Windows.Forms.Button; $btnCalAdd.Text = "Adicionar Novo"; $btnCalAdd.Location = "480, 80"; $btnCalAdd.Size = "200, 40"; $btnCalAdd.FlatStyle="Flat"; $btnCalAdd.BackColor=$global:theme.ButtonBack; $btnCalAdd.ForeColor=$global:theme.GreenSuccess
    $btnCalEdit = New-Object System.Windows.Forms.Button; $btnCalEdit.Text = "Editar Selecionado"; $btnCalEdit.Location = "480, 130"; $btnCalEdit.Size = "200, 40"; $btnCalEdit.FlatStyle="Flat"; $btnCalEdit.BackColor=$global:theme.ButtonBack; $btnCalEdit.ForeColor=$global:theme.TextDim; $btnCalEdit.Enabled=$false
    $btnCalDel = New-Object System.Windows.Forms.Button; $btnCalDel.Text = "Apagar Selecionado"; $btnCalDel.Location = "480, 180"; $btnCalDel.Size = "200, 40"; $btnCalDel.FlatStyle="Flat"; $btnCalDel.BackColor=$global:theme.ButtonBack; $btnCalDel.ForeColor=$global:theme.TextDim; $btnCalDel.Enabled=$false
    $lblCalInfo = New-Object System.Windows.Forms.Label; $lblCalInfo.Location = "480, 240"; $lblCalInfo.Size = "400, 100"; $lblCalInfo.ForeColor = $global:theme.TextDim; $lblCalInfo.Text = "Nota: Selecione um calibre."; $lblCalInfo.Font = $script:fontMngInfo
    $btnBackCal = New-Object System.Windows.Forms.Button; $btnBackCal.Text = "Voltar"; $btnBackCal.Location = "1050, 30"; $btnBackCal.Size = "100, 35"; $btnBackCal.FlatStyle="Flat"; $btnBackCal.BackColor=$global:theme.ButtonBack; $btnBackCal.ForeColor=$global:theme.TextMain
    $pnlCaliber.Controls.AddRange(@($lblCalTitle, $lstCalibers, $btnCalAdd, $btnCalEdit, $btnCalDel, $lblCalInfo, $btnBackCal))
    $ui.LstCalibers = $lstCalibers; $ui.BtnCalAdd = $btnCalAdd; $ui.BtnCalEdit = $btnCalEdit; $ui.BtnCalDel = $btnCalDel; $ui.LblCalInfo = $lblCalInfo; $ui.BtnBackCal = $btnBackCal

    # --- 5. TELA COMPATIBILIDADE ---
    $lblCompTitle = New-Object System.Windows.Forms.Label; $lblCompTitle.Text = "Compatibilidade de Máscaras"; $lblCompTitle.Font = $script:fontMngSubTitle; $lblCompTitle.ForeColor = $global:theme.OrangeAccent; $lblCompTitle.AutoSize = $true; $lblCompTitle.Location = "50, 30"
    $lblMaskList = New-Object System.Windows.Forms.Label; $lblMaskList.Text = "1. Selecione a Máscara"; $lblMaskList.Location = "50, 80"; $lblMaskList.AutoSize = $true; $lblMaskList.ForeColor = $global:theme.TextDim
    $lstMasks = New-Object System.Windows.Forms.ListBox; $lstMasks.Location = "50, 100"; $lstMasks.Size = "350, 580"; $lstMasks.BackColor = $global:theme.PanelBack; $lstMasks.ForeColor = $global:theme.TextMain; $lstMasks.BorderStyle = "FixedSingle"; $lstMasks.Font = $script:fontMngListMed
    $lblCompList = New-Object System.Windows.Forms.Label; $lblCompList.Text = "2. Capacetes Compatíveis (Atuais)"; $lblCompList.Location = "450, 80"; $lblCompList.AutoSize = $true; $lblCompList.ForeColor = $global:theme.TextDim
    $lstCompHelmets = New-Object System.Windows.Forms.ListBox; $lstCompHelmets.Location = "450, 100"; $lstCompHelmets.Size = "350, 580"; $lstCompHelmets.BackColor = $global:theme.PanelBack; $lstCompHelmets.ForeColor = $global:theme.GreenSuccess; $lstCompHelmets.BorderStyle = "FixedSingle"; $lstCompHelmets.Font = $script:fontMngListMed
    $btnAddCompat = New-Object System.Windows.Forms.Button; $btnAddCompat.Text = "Adicionar Compatibilidade"; $btnAddCompat.Location = "840, 100"; $btnAddCompat.Size = "250, 45"; $btnAddCompat.FlatStyle="Flat"; $btnAddCompat.BackColor=$global:theme.ButtonBack; $btnAddCompat.ForeColor=$global:theme.TextDim; $btnAddCompat.Enabled=$false
    $btnRemCompat = New-Object System.Windows.Forms.Button; $btnRemCompat.Text = "Remover Compatibilidade"; $btnRemCompat.Location = "840, 160"; $btnRemCompat.Size = "250, 45"; $btnAddCompat.FlatStyle="Flat"; $btnRemCompat.BackColor=$global:theme.ButtonBack; $btnRemCompat.ForeColor=$global:theme.TextDim; $btnRemCompat.Enabled=$false
    $lblCompInfo = New-Object System.Windows.Forms.Label; $lblCompInfo.Location = "840, 230"; $lblCompInfo.Size = "250, 300"; $lblCompInfo.ForeColor = $global:theme.TextDim; $lblCompInfo.Text = "Selecione uma máscara à esquerda para começar."; $lblCompInfo.Font = $script:fontMngInfo
    $btnBackCompat = New-Object System.Windows.Forms.Button; $btnBackCompat.Text = "Voltar"; $btnBackCompat.Location = "1050, 30"; $btnBackCompat.Size = "100, 35"; $btnBackCompat.FlatStyle="Flat"; $btnBackCompat.BackColor=$global:theme.ButtonBack; $btnBackCompat.ForeColor=$global:theme.TextMain
    $pnlCompat.Controls.AddRange(@($lblCompTitle, $lblMaskList, $lstMasks, $lblCompList, $lstCompHelmets, $btnAddCompat, $btnRemCompat, $lblCompInfo, $btnBackCompat))
    $ui.LstMasks = $lstMasks; $ui.LstCompHelmets = $lstCompHelmets; $ui.BtnAddCompat = $btnAddCompat; $ui.BtnRemCompat = $btnRemCompat; $ui.BtnBackCompat = $btnBackCompat; $ui.LblCompInfo = $lblCompInfo

    # --- 6. TELA ITENS ---
    $lblItemsTitle = New-Object System.Windows.Forms.Label; $lblItemsTitle.Text = "Gerenciamento de Itens"; $lblItemsTitle.Font = $script:fontMngSubTitle; $lblItemsTitle.ForeColor = $global:theme.OrangeAccent; $lblItemsTitle.AutoSize = $true; $lblItemsTitle.Location = "50, 30"
    $btnBackItems = New-Object System.Windows.Forms.Button; $btnBackItems.Text = "Voltar"; $btnBackItems.Location = "1050, 30"; $btnBackItems.Size = "100, 35"; $btnBackItems.FlatStyle="Flat"; $btnBackItems.BackColor=$global:theme.ButtonBack; $btnBackItems.ForeColor=$global:theme.TextMain
    
    $pnlListContainer = New-Object System.Windows.Forms.Panel; $pnlListContainer.Location = "50, 80"; $pnlListContainer.Size = "1100, 700"; $pnlListContainer.AutoScroll = $true
    
    $tblItems = New-Object System.Windows.Forms.TableLayoutPanel; $tblItems.Dock = "Top"; $tblItems.AutoSize = $true; $tblItems.ColumnCount = 4
    $tblItems.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100))); $tblItems.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 120))); $tblItems.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 120))); $tblItems.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 120)))
    $prop = [System.Windows.Forms.Control].GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]"NonPublic, Instance"); $prop.SetValue($tblItems, $true, $null)
    
    $pnlListContainer.Controls.Add($tblItems)
    $pnlItems.Controls.AddRange(@($lblItemsTitle, $btnBackItems, $pnlListContainer))
    $ui.BtnBackItems = $btnBackItems; $ui.TblItems = $tblItems; $ui.PnlListContainer = $pnlListContainer 

    return $ui
}

function Start-ItemManager {
    param ($ui)

    # [CORREÇÃO CRÍTICA] Verifica se os controles existem antes de tentar usar
    if (-not $ui.PnlListContainer -or -not $ui.TblItems) { 
        # Se os controles não existirem, não faz nada (evita o crash)
        return 
    }

    # [ALTERACAO] 1. Congela a pintura da tela para evitar o "piscar"
    $ui.PnlListContainer.SuspendLayout()
    $ui.TblItems.SuspendLayout()
    
    # [ALTERACAO] 2. Salva a posição atual do Scroll (se estiver visível e existir)
    $savedScroll = 0
    if ($ui.PnlListContainer.VerticalScroll) {
        $savedScroll = $ui.PnlListContainer.VerticalScroll.Value
    }

    # Troca de Paineis (com verificação de nulo)
    if ($ui.PnlMenu) { $ui.PnlMenu.Visible = $false }
    if ($ui.PnlItems) { $ui.PnlItems.Visible = $true }

    # Limpa a tabela anterior para evitar duplicatas visuais
    $ui.TblItems.Controls.Clear()
    $ui.TblItems.RowCount = 0

    # Mapa de Categorias e Arquivos
    $categories = @(
        @{ Name="Armas"; File="Weapons.csv" },
        @{ Name="Munições"; File="Ammo.csv" },
        @{ Name="Arremessáveis"; File="Throwables.csv" },
        @{ Name="Capacetes"; File="Helmets.csv" },
        @{ Name="Máscaras"; File="Masks.csv" },
        @{ Name="Máscaras de Gás"; File="Gasmasks.csv" },
        @{ Name="Fones de Ouvido"; File="Headsets.csv" },
        @{ Name="Coletes Balísticos"; File="Bodyarmors.csv" },
        @{ Name="Coletes Blindados (Armored Rigs)"; File="Armoredrigs.csv" },
        @{ Name="Coletes Não Blindados (Rigs)"; File="Unarmoredrigs.csv" },
        @{ Name="Mochilas"; File="Backpacks.csv" },
        @{ Name="Analgésicos"; File="Painkillers.csv" },
        @{ Name="Kits Médicos"; File="Medicalkit.csv" },
        @{ Name="Kits Cirúrgicos"; File="Surgicalkit.csv" },
        @{ Name="Bandages"; File="Bandages.csv" },
        @{ Name="Estimulantes"; File="Stimulants.csv" },
        @{ Name="Nebulizadores"; File="Nebulizers.csv" },
        @{ Name="Bebidas"; File="Beverages.csv" },
        @{ Name="Comidas"; File="Food.csv" }
    )

    $dbPath = Get-DatabasePath

    # Cores do Tema
    $normalLabelColor  = $global:theme.Background
    $hoverRowColor     = [System.Drawing.Color]::FromArgb(55, 55, 60) # Cinza destaque para hover

    foreach ($cat in $categories) {
        $csvPath = Join-Path $dbPath $cat.File
        $hasItems = $false
        if (Test-Path $csvPath) { 
            # [CORREÇÃO APLICADA] O uso de @() força o resultado a ser um Array.
            # Isso garante que a propriedade .Count funcione corretamente mesmo se houver apenas 1 item.
            $data = @(Import-Csv $csvPath -Delimiter ";" -Encoding UTF8)
            if ($data.Count -gt 0) { $hasItems = $true } 
        }

        # Criação dos Controles Visuais da Linha
        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $cat.Name; $lbl.ForeColor = $global:theme.OrangeAccent; $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold); $lbl.TextAlign = "MiddleLeft"; $lbl.Dock = "Fill"; $lbl.Height = 40; $lbl.BackColor = $normalLabelColor; $lbl.Margin = New-Object System.Windows.Forms.Padding(0)
        
        $btnAdd = New-Object System.Windows.Forms.Button; $btnAdd.Text = "Adicionar"; $btnAdd.Size = "100, 30"; $btnAdd.FlatStyle = "Flat"; $btnAdd.BackColor = $global:theme.ButtonBack; $btnAdd.Margin = New-Object System.Windows.Forms.Padding(5)
        $btnEdit = New-Object System.Windows.Forms.Button; $btnEdit.Text = "Editar"; $btnEdit.Size = "100, 30"; $btnEdit.FlatStyle = "Flat"; $btnEdit.BackColor = $global:theme.ButtonBack; $btnEdit.Margin = New-Object System.Windows.Forms.Padding(5)
        $btnDel = New-Object System.Windows.Forms.Button; $btnDel.Text = "Apagar"; $btnDel.Size = "100, 30"; $btnDel.FlatStyle = "Flat"; $btnDel.BackColor = $global:theme.ButtonBack; $btnDel.Margin = New-Object System.Windows.Forms.Padding(5)

        # --- LOGICA DE ATIVACAO (Quais categorias funcionam) ---
        # [ATUALIZADO] Inclui todas as 19 categorias implementadas com os novos nomes
        $isImplemented = ($cat.Name -eq "Armas" -or 
                          $cat.Name -eq "Munições" -or 
                          $cat.Name -eq "Arremessáveis" -or 
                          $cat.Name -eq "Capacetes" -or 
                          $cat.Name -eq "Coletes Balísticos" -or 
                          $cat.Name -eq "Coletes Blindados (Armored Rigs)" -or
                          $cat.Name -eq "Coletes Não Blindados (Rigs)" -or
                          $cat.Name -eq "Mochilas" -or
                          $cat.Name -eq "Máscaras" -or
                          $cat.Name -eq "Máscaras de Gás" -or
                          $cat.Name -eq "Fones de Ouvido" -or
                          $cat.Name -eq "Analgésicos" -or
                          $cat.Name -eq "Bandages" -or
                          $cat.Name -eq "Kits Cirúrgicos" -or
                          $cat.Name -eq "Kits Médicos" -or
                          $cat.Name -eq "Nebulizadores" -or
                          $cat.Name -eq "Estimulantes" -or
                          $cat.Name -eq "Comidas" -or
                          $cat.Name -eq "Bebidas")

        if ($isImplemented) {
            $btnAdd.Enabled = $true; $btnAdd.ForeColor = $global:theme.GreenSuccess
            if ($hasItems) {
                $btnEdit.Enabled = $true; $btnEdit.ForeColor = $global:theme.TextMain
                $btnDel.Enabled = $true; $btnDel.ForeColor = $global:theme.RedAlert
            } else {
                $btnEdit.Enabled = $false; $btnEdit.ForeColor = $global:theme.TextDim
                $btnDel.Enabled = $false; $btnDel.ForeColor = $global:theme.TextDim
            }
        } else {
            $btnAdd.Enabled = $false; $btnAdd.ForeColor = $global:theme.TextDim
            $btnEdit.Enabled = $false; $btnEdit.ForeColor = $global:theme.TextDim
            $btnDel.Enabled = $false; $btnDel.ForeColor = $global:theme.TextDim
        }

        # --- EVENTOS ESPECIFICOS POR CATEGORIA ---
        
        # 1. ARMAS
        if ($cat.Name -eq "Armas") {
            $clickAdd = { 
                Start-WeaponEditor -ui $ui 
                Start-ItemManager -ui $ui 
            }.GetNewClosure()
            $btnAdd.Add_Click($clickAdd)

            $clickEdit = {
                $allWeps = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $wepNames = $allWeps | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Editar Arma" -Prompt "Selecione a arma:" -Options $wepNames
                
                if ($sel) {
                    $itemData = $allWeps | Where-Object { $_.NomeItem -eq $sel } | Select-Object -First 1
                    Start-WeaponEditor -ui $ui -EditItem $itemData
                    Start-ItemManager -ui $ui
                }
            }.GetNewClosure()
            $btnEdit.Add_Click($clickEdit)

            $clickDel = {
                $allWeps = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $wepNames = $allWeps | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Apagar Arma" -Prompt "Selecione a arma para APAGAR:" -Options $wepNames
                
                if ($sel) {
                    if ([System.Windows.Forms.MessageBox]::Show("Tem certeza absoluta que deseja APAGAR '$sel'?`nEssa ação é irreversível.", "Confirmar Exclusão", "YesNo", "Warning") -eq "Yes") {
                        $newList = $allWeps | Where-Object { $_.NomeItem -ne $sel }
                        $newList | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
                        Start-ItemManager -ui $ui
                    }
                }
            }.GetNewClosure()
            $btnDel.Add_Click($clickDel)
        }

        # 2. MUNIÇÕES
        if ($cat.Name -eq "Munições") {
            $clickAdd = { 
                Start-AmmoEditor -ui $ui 
                Start-ItemManager -ui $ui 
            }.GetNewClosure()
            $btnAdd.Add_Click($clickAdd)

            $clickEdit = {
                $allAmmo = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $ammoDisplay = $allAmmo | ForEach-Object { "$($_.NomeItem) [$($_.Calibre)]" } | Sort-Object
                
                $selString = Show-SelectionDialog -Title "Editar Munição" -Prompt "Selecione a munição:" -Options $ammoDisplay
                
                if ($selString) {
                    if ($selString -match '^(.*) \[(.*)\]$') {
                        $selName = $Matches[1]
                        $selCal  = $Matches[2]
                        $itemData = $allAmmo | Where-Object { $_.NomeItem -eq $selName -and $_.Calibre -eq $selCal } | Select-Object -First 1
                        Start-AmmoEditor -ui $ui -EditItem $itemData
                        Start-ItemManager -ui $ui
                    }
                }
            }.GetNewClosure()
            $btnEdit.Add_Click($clickEdit)

            $clickDel = {
                $allAmmo = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $ammoDisplay = $allAmmo | ForEach-Object { "$($_.NomeItem) [$($_.Calibre)]" } | Sort-Object
                
                $selString = Show-SelectionDialog -Title "Apagar Munição" -Prompt "Selecione a munição para APAGAR:" -Options $ammoDisplay
                
                if ($selString) {
                    if ($selString -match '^(.*) \[(.*)\]$') {
                        $selName = $Matches[1]
                        $selCal  = $Matches[2]
                        if ([System.Windows.Forms.MessageBox]::Show("Tem certeza absoluta que deseja APAGAR '$selName'?`nEssa ação é irreversível.", "Confirmar Exclusão", "YesNo", "Warning") -eq "Yes") {
                            $newList = $allAmmo | Where-Object { -not ($_.NomeItem -eq $selName -and $_.Calibre -eq $selCal) }
                            $newList | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
                            Start-ItemManager -ui $ui
                        }
                    }
                }
            }.GetNewClosure()
            $btnDel.Add_Click($clickDel)
        }

        # 3. ARREMESSÁVEIS
        if ($cat.Name -eq "Arremessáveis") {
            $clickAdd = { 
                Start-ThrowableEditor -ui $ui 
                Start-ItemManager -ui $ui 
            }.GetNewClosure()
            $btnAdd.Add_Click($clickAdd)

            $clickEdit = {
                $allThrow = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allThrow | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Editar Arremessável" -Prompt "Selecione o item:" -Options $names
                
                if ($sel) {
                    $itemData = $allThrow | Where-Object { $_.NomeItem -eq $sel } | Select-Object -First 1
                    Start-ThrowableEditor -ui $ui -EditItem $itemData
                    Start-ItemManager -ui $ui
                }
            }.GetNewClosure()
            $btnEdit.Add_Click($clickEdit)

            $clickDel = {
                $allThrow = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allThrow | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Apagar Arremessável" -Prompt "Selecione o item para APAGAR:" -Options $names
                
                if ($sel) {
                    if ([System.Windows.Forms.MessageBox]::Show("Tem certeza absoluta que deseja APAGAR '$sel'?`nEssa ação é irreversível.", "Confirmar Exclusão", "YesNo", "Warning") -eq "Yes") {
                        $newList = $allThrow | Where-Object { $_.NomeItem -ne $sel }
                        $newList | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
                        Start-ItemManager -ui $ui
                    }
                }
            }.GetNewClosure()
            $btnDel.Add_Click($clickDel)
        }

        # 4. CAPACETES
        if ($cat.Name -eq "Capacetes") {
            $clickAdd = { 
                Start-HelmetEditor -ui $ui 
                Start-ItemManager -ui $ui 
            }.GetNewClosure()
            $btnAdd.Add_Click($clickAdd)

            $clickEdit = {
                $allHelm = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allHelm | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Editar Capacete" -Prompt "Selecione o item:" -Options $names
                if ($sel) {
                    $itemData = $allHelm | Where-Object { $_.NomeItem -eq $sel } | Select-Object -First 1
                    Start-HelmetEditor -ui $ui -EditItem $itemData
                    Start-ItemManager -ui $ui
                }
            }.GetNewClosure()
            $btnEdit.Add_Click($clickEdit)

            $clickDel = {
                $allHelm = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allHelm | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Apagar Capacete" -Prompt "Selecione o item para APAGAR:" -Options $names
                if ($sel) {
                    if ([System.Windows.Forms.MessageBox]::Show("Tem certeza absoluta que deseja APAGAR '$sel'?`nEssa ação é irreversível.", "Confirmar Exclusão", "YesNo", "Warning") -eq "Yes") {
                        $newList = $allHelm | Where-Object { $_.NomeItem -ne $sel }
                        $newList | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
                        Start-ItemManager -ui $ui
                    }
                }
            }.GetNewClosure()
            $btnDel.Add_Click($clickDel)
        }

        # 5. COLETES BALÍSTICOS
        if ($cat.Name -eq "Coletes Balísticos") {
            $clickAdd = { 
                Start-BodyArmorEditor -ui $ui 
                Start-ItemManager -ui $ui 
            }.GetNewClosure()
            $btnAdd.Add_Click($clickAdd)

            $clickEdit = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Editar Colete Balístico" -Prompt "Selecione o item:" -Options $names
                if ($sel) {
                    $itemData = $allItems | Where-Object { $_.NomeItem -eq $sel } | Select-Object -First 1
                    Start-BodyArmorEditor -ui $ui -EditItem $itemData
                    Start-ItemManager -ui $ui
                }
            }.GetNewClosure()
            $btnEdit.Add_Click($clickEdit)

            $clickDel = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Apagar Colete Balístico" -Prompt "Selecione o item para APAGAR:" -Options $names
                if ($sel) {
                    if ([System.Windows.Forms.MessageBox]::Show("Tem certeza absoluta que deseja APAGAR '$sel'?`nEssa ação é irreversível.", "Confirmar Exclusão", "YesNo", "Warning") -eq "Yes") {
                        $newList = $allItems | Where-Object { $_.NomeItem -ne $sel }
                        $newList | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
                        Start-ItemManager -ui $ui
                    }
                }
            }.GetNewClosure()
            $btnDel.Add_Click($clickDel)
        }

        # 6. COLETES BLINDADOS (Armored Rigs)
        if ($cat.Name -eq "Coletes Blindados (Armored Rigs)") {
            $clickAdd = { 
                Start-ArmoredRigEditor -ui $ui 
                Start-ItemManager -ui $ui 
            }.GetNewClosure()
            $btnAdd.Add_Click($clickAdd)

            $clickEdit = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Editar Colete Blindado" -Prompt "Selecione o item:" -Options $names
                if ($sel) {
                    $itemData = $allItems | Where-Object { $_.NomeItem -eq $sel } | Select-Object -First 1
                    Start-ArmoredRigEditor -ui $ui -EditItem $itemData
                    Start-ItemManager -ui $ui
                }
            }.GetNewClosure()
            $btnEdit.Add_Click($clickEdit)

            $clickDel = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Apagar Colete Blindado" -Prompt "Selecione o item para APAGAR:" -Options $names
                if ($sel) {
                    if ([System.Windows.Forms.MessageBox]::Show("Tem certeza absoluta que deseja APAGAR '$sel'?`nEssa ação é irreversível.", "Confirmar Exclusão", "YesNo", "Warning") -eq "Yes") {
                        $newList = $allItems | Where-Object { $_.NomeItem -ne $sel }
                        $newList | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
                        Start-ItemManager -ui $ui
                    }
                }
            }.GetNewClosure()
            $btnDel.Add_Click($clickDel)
        }

        # 7. COLETES NÃO BLINDADOS (Rigs)
        if ($cat.Name -eq "Coletes Não Blindados (Rigs)") {
            $clickAdd = { 
                Start-UnarmoredRigEditor -ui $ui 
                Start-ItemManager -ui $ui 
            }.GetNewClosure()
            $btnAdd.Add_Click($clickAdd)

            $clickEdit = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Editar Colete Não Blindado" -Prompt "Selecione o item:" -Options $names
                if ($sel) {
                    $itemData = $allItems | Where-Object { $_.NomeItem -eq $sel } | Select-Object -First 1
                    Start-UnarmoredRigEditor -ui $ui -EditItem $itemData
                    Start-ItemManager -ui $ui
                }
            }.GetNewClosure()
            $btnEdit.Add_Click($clickEdit)

            $clickDel = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Apagar Colete Não Blindado" -Prompt "Selecione o item para APAGAR:" -Options $names
                if ($sel) {
                    if ([System.Windows.Forms.MessageBox]::Show("Tem certeza absoluta que deseja APAGAR '$sel'?`nEssa ação é irreversível.", "Confirmar Exclusão", "YesNo", "Warning") -eq "Yes") {
                        $newList = $allItems | Where-Object { $_.NomeItem -ne $sel }
                        $newList | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
                        Start-ItemManager -ui $ui
                    }
                }
            }.GetNewClosure()
            $btnDel.Add_Click($clickDel)
        }

        # 8. MOCHILAS
        if ($cat.Name -eq "Mochilas") {
            $clickAdd = { 
                Start-BackpackEditor -ui $ui 
                Start-ItemManager -ui $ui 
            }.GetNewClosure()
            $btnAdd.Add_Click($clickAdd)

            $clickEdit = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Editar Mochila" -Prompt "Selecione o item:" -Options $names
                if ($sel) {
                    $itemData = $allItems | Where-Object { $_.NomeItem -eq $sel } | Select-Object -First 1
                    Start-BackpackEditor -ui $ui -EditItem $itemData
                    Start-ItemManager -ui $ui
                }
            }.GetNewClosure()
            $btnEdit.Add_Click($clickEdit)

            $clickDel = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Apagar Mochila" -Prompt "Selecione o item para APAGAR:" -Options $names
                if ($sel) {
                    if ([System.Windows.Forms.MessageBox]::Show("Tem certeza absoluta que deseja APAGAR '$sel'?`nEssa ação é irreversível.", "Confirmar Exclusão", "YesNo", "Warning") -eq "Yes") {
                        $newList = $allItems | Where-Object { $_.NomeItem -ne $sel }
                        $newList | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
                        Start-ItemManager -ui $ui
                    }
                }
            }.GetNewClosure()
            $btnDel.Add_Click($clickDel)
        }

        # 9. MÁSCARAS
        if ($cat.Name -eq "Máscaras") {
            $clickAdd = { 
                Start-MaskEditor -ui $ui 
                Start-ItemManager -ui $ui 
            }.GetNewClosure()
            $btnAdd.Add_Click($clickAdd)

            $clickEdit = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Editar Máscara" -Prompt "Selecione o item:" -Options $names
                if ($sel) {
                    $itemData = $allItems | Where-Object { $_.NomeItem -eq $sel } | Select-Object -First 1
                    Start-MaskEditor -ui $ui -EditItem $itemData
                    Start-ItemManager -ui $ui
                }
            }.GetNewClosure()
            $btnEdit.Add_Click($clickEdit)

            $clickDel = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Apagar Máscara" -Prompt "Selecione o item para APAGAR:" -Options $names
                if ($sel) {
                    if ([System.Windows.Forms.MessageBox]::Show("Tem certeza absoluta que deseja APAGAR '$sel'?`nEssa ação é irreversível.", "Confirmar Exclusão", "YesNo", "Warning") -eq "Yes") {
                        $newList = $allItems | Where-Object { $_.NomeItem -ne $sel }
                        $newList | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
                        Start-ItemManager -ui $ui
                    }
                }
            }.GetNewClosure()
            $btnDel.Add_Click($clickDel)
        }

        # 10. MÁSCARAS DE GÁS
        if ($cat.Name -eq "Máscaras de Gás") {
            $clickAdd = { 
                Start-GasMaskEditor -ui $ui 
                Start-ItemManager -ui $ui 
            }.GetNewClosure()
            $btnAdd.Add_Click($clickAdd)

            $clickEdit = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Editar Máscara de Gás" -Prompt "Selecione o item:" -Options $names
                if ($sel) {
                    $itemData = $allItems | Where-Object { $_.NomeItem -eq $sel } | Select-Object -First 1
                    # [CORREÇÃO FEITA AQUI: Adicionado o $ui que faltava]
                    Start-GasMaskEditor -ui $ui -EditItem $itemData
                    Start-ItemManager -ui $ui
                }
            }.GetNewClosure()
            $btnEdit.Add_Click($clickEdit)

            $clickDel = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Apagar Máscara de Gás" -Prompt "Selecione o item para APAGAR:" -Options $names
                if ($sel) {
                    if ([System.Windows.Forms.MessageBox]::Show("Tem certeza absoluta que deseja APAGAR '$sel'?`nEssa ação é irreversível.", "Confirmar Exclusão", "YesNo", "Warning") -eq "Yes") {
                        $newList = $allItems | Where-Object { $_.NomeItem -ne $sel }
                        $newList | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
                        Start-ItemManager -ui $ui
                    }
                }
            }.GetNewClosure()
            $btnDel.Add_Click($clickDel)
        }

        # 11. FONES DE OUVIDO
        if ($cat.Name -eq "Fones de Ouvido") {
            $clickAdd = { 
                Start-HeadsetEditor -ui $ui 
                Start-ItemManager -ui $ui 
            }.GetNewClosure()
            $btnAdd.Add_Click($clickAdd)

            $clickEdit = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Editar Fone de Ouvido" -Prompt "Selecione o item:" -Options $names
                if ($sel) {
                    $itemData = $allItems | Where-Object { $_.NomeItem -eq $sel } | Select-Object -First 1
                    Start-HeadsetEditor -ui $ui -EditItem $itemData
                    Start-ItemManager -ui $ui
                }
            }.GetNewClosure()
            $btnEdit.Add_Click($clickEdit)

            $clickDel = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Apagar Fone de Ouvido" -Prompt "Selecione o item para APAGAR:" -Options $names
                if ($sel) {
                    if ([System.Windows.Forms.MessageBox]::Show("Tem certeza absoluta que deseja APAGAR '$sel'?`nEssa ação é irreversível.", "Confirmar Exclusão", "YesNo", "Warning") -eq "Yes") {
                        $newList = $allItems | Where-Object { $_.NomeItem -ne $sel }
                        $newList | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
                        Start-ItemManager -ui $ui
                    }
                }
            }.GetNewClosure()
            $btnDel.Add_Click($clickDel)
        }

        # 12. ANALGÉSICOS
        if ($cat.Name -eq "Analgésicos") {
            $clickAdd = { 
                Start-PainkillerEditor -ui $ui 
                Start-ItemManager -ui $ui 
            }.GetNewClosure()
            $btnAdd.Add_Click($clickAdd)

            $clickEdit = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Editar Analgésico" -Prompt "Selecione o item:" -Options $names
                if ($sel) {
                    $itemData = $allItems | Where-Object { $_.NomeItem -eq $sel } | Select-Object -First 1
                    Start-PainkillerEditor -ui $ui -EditItem $itemData
                    Start-ItemManager -ui $ui
                }
            }.GetNewClosure()
            $btnEdit.Add_Click($clickEdit)

            $clickDel = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Apagar Analgésico" -Prompt "Selecione o item para APAGAR:" -Options $names
                if ($sel) {
                    if ([System.Windows.Forms.MessageBox]::Show("Tem certeza absoluta que deseja APAGAR '$sel'?`nEssa ação é irreversível.", "Confirmar Exclusão", "YesNo", "Warning") -eq "Yes") {
                        $newList = $allItems | Where-Object { $_.NomeItem -ne $sel }
                        $newList | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
                        Start-ItemManager -ui $ui
                    }
                }
            }.GetNewClosure()
            $btnDel.Add_Click($clickDel)
        }

        # 13. BANDAGES
        if ($cat.Name -eq "Bandages") {
            $clickAdd = { 
                Start-BandageEditor -ui $ui 
                Start-ItemManager -ui $ui 
            }.GetNewClosure()
            $btnAdd.Add_Click($clickAdd)

            $clickEdit = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Editar Bandagem" -Prompt "Selecione o item:" -Options $names
                if ($sel) {
                    $itemData = $allItems | Where-Object { $_.NomeItem -eq $sel } | Select-Object -First 1
                    Start-BandageEditor -ui $ui -EditItem $itemData
                    Start-ItemManager -ui $ui
                }
            }.GetNewClosure()
            $btnEdit.Add_Click($clickEdit)

            $clickDel = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Apagar Bandagem" -Prompt "Selecione o item para APAGAR:" -Options $names
                if ($sel) {
                    if ([System.Windows.Forms.MessageBox]::Show("Tem certeza absoluta que deseja APAGAR '$sel'?`nEssa ação é irreversível.", "Confirmar Exclusão", "YesNo", "Warning") -eq "Yes") {
                        $newList = $allItems | Where-Object { $_.NomeItem -ne $sel }
                        $newList | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
                        Start-ItemManager -ui $ui
                    }
                }
            }.GetNewClosure()
            $btnDel.Add_Click($clickDel)
        }

        # 14. KITS CIRÚRGICOS
        if ($cat.Name -eq "Kits Cirúrgicos") {
            $clickAdd = { 
                Start-SurgicalKitEditor -ui $ui 
                Start-ItemManager -ui $ui 
            }.GetNewClosure()
            $btnAdd.Add_Click($clickAdd)

            $clickEdit = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Editar Kit Cirúrgico" -Prompt "Selecione o item:" -Options $names
                if ($sel) {
                    $itemData = $allItems | Where-Object { $_.NomeItem -eq $sel } | Select-Object -First 1
                    Start-SurgicalKitEditor -ui $ui -EditItem $itemData
                    Start-ItemManager -ui $ui
                }
            }.GetNewClosure()
            $btnEdit.Add_Click($clickEdit)

            $clickDel = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Apagar Kit Cirúrgico" -Prompt "Selecione o item para APAGAR:" -Options $names
                if ($sel) {
                    if ([System.Windows.Forms.MessageBox]::Show("Tem certeza absoluta que deseja APAGAR '$sel'?`nEssa ação é irreversível.", "Confirmar Exclusão", "YesNo", "Warning") -eq "Yes") {
                        $newList = $allItems | Where-Object { $_.NomeItem -ne $sel }
                        $newList | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
                        Start-ItemManager -ui $ui
                    }
                }
            }.GetNewClosure()
            $btnDel.Add_Click($clickDel)
        }

        # 15. KITS MÉDICOS
        if ($cat.Name -eq "Kits Médicos") {
            $clickAdd = { 
                Start-MedicalKitEditor -ui $ui 
                Start-ItemManager -ui $ui 
            }.GetNewClosure()
            $btnAdd.Add_Click($clickAdd)

            $clickEdit = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Editar Kit Médico" -Prompt "Selecione o item:" -Options $names
                if ($sel) {
                    $itemData = $allItems | Where-Object { $_.NomeItem -eq $sel } | Select-Object -First 1
                    Start-MedicalKitEditor -ui $ui -EditItem $itemData
                    Start-ItemManager -ui $ui
                }
            }.GetNewClosure()
            $btnEdit.Add_Click($clickEdit)

            $clickDel = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Apagar Kit Médico" -Prompt "Selecione o item para APAGAR:" -Options $names
                if ($sel) {
                    if ([System.Windows.Forms.MessageBox]::Show("Tem certeza absoluta que deseja APAGAR '$sel'?`nEssa ação é irreversível.", "Confirmar Exclusão", "YesNo", "Warning") -eq "Yes") {
                        $newList = $allItems | Where-Object { $_.NomeItem -ne $sel }
                        $newList | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
                        Start-ItemManager -ui $ui
                    }
                }
            }.GetNewClosure()
            $btnDel.Add_Click($clickDel)
        }

        # 16. NEBULIZADORES
        if ($cat.Name -eq "Nebulizadores") {
            $clickAdd = { 
                Start-NebulizerEditor -ui $ui 
                Start-ItemManager -ui $ui 
            }.GetNewClosure()
            $btnAdd.Add_Click($clickAdd)

            $clickEdit = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Editar Nebulizador" -Prompt "Selecione o item:" -Options $names
                if ($sel) {
                    $itemData = $allItems | Where-Object { $_.NomeItem -eq $sel } | Select-Object -First 1
                    Start-NebulizerEditor -ui $ui -EditItem $itemData
                    Start-ItemManager -ui $ui
                }
            }.GetNewClosure()
            $btnEdit.Add_Click($clickEdit)

            $clickDel = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Apagar Nebulizador" -Prompt "Selecione o item para APAGAR:" -Options $names
                if ($sel) {
                    if ([System.Windows.Forms.MessageBox]::Show("Tem certeza absoluta que deseja APAGAR '$sel'?`nEssa ação é irreversível.", "Confirmar Exclusão", "YesNo", "Warning") -eq "Yes") {
                        $newList = $allItems | Where-Object { $_.NomeItem -ne $sel }
                        $newList | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
                        Start-ItemManager -ui $ui
                    }
                }
            }.GetNewClosure()
            $btnDel.Add_Click($clickDel)
        }

        # 17. ESTIMULANTES
        if ($cat.Name -eq "Estimulantes") {
            $clickAdd = { 
                Start-StimulantEditor -ui $ui 
                Start-ItemManager -ui $ui 
            }.GetNewClosure()
            $btnAdd.Add_Click($clickAdd)

            $clickEdit = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Editar Estimulante" -Prompt "Selecione o item:" -Options $names
                if ($sel) {
                    $itemData = $allItems | Where-Object { $_.NomeItem -eq $sel } | Select-Object -First 1
                    Start-StimulantEditor -ui $ui -EditItem $itemData
                    Start-ItemManager -ui $ui
                }
            }.GetNewClosure()
            $btnEdit.Add_Click($clickEdit)

            $clickDel = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Apagar Estimulante" -Prompt "Selecione o item para APAGAR:" -Options $names
                if ($sel) {
                    if ([System.Windows.Forms.MessageBox]::Show("Tem certeza absoluta que deseja APAGAR '$sel'?`nEssa ação é irreversível.", "Confirmar Exclusão", "YesNo", "Warning") -eq "Yes") {
                        $newList = $allItems | Where-Object { $_.NomeItem -ne $sel }
                        $newList | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
                        Start-ItemManager -ui $ui
                    }
                }
            }.GetNewClosure()
            $btnDel.Add_Click($clickDel)
        }

        # 18. COMIDAS
        if ($cat.Name -eq "Comidas") {
            $clickAdd = { 
                Start-FoodEditor -ui $ui 
                Start-ItemManager -ui $ui 
            }.GetNewClosure()
            $btnAdd.Add_Click($clickAdd)

            $clickEdit = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Editar Comida" -Prompt "Selecione o item:" -Options $names
                if ($sel) {
                    $itemData = $allItems | Where-Object { $_.NomeItem -eq $sel } | Select-Object -First 1
                    Start-FoodEditor -ui $ui -EditItem $itemData
                    Start-ItemManager -ui $ui
                }
            }.GetNewClosure()
            $btnEdit.Add_Click($clickEdit)

            $clickDel = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Apagar Comida" -Prompt "Selecione o item para APAGAR:" -Options $names
                if ($sel) {
                    if ([System.Windows.Forms.MessageBox]::Show("Tem certeza absoluta que deseja APAGAR '$sel'?`nEssa ação é irreversível.", "Confirmar Exclusão", "YesNo", "Warning") -eq "Yes") {
                        $newList = $allItems | Where-Object { $_.NomeItem -ne $sel }
                        $newList | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
                        Start-ItemManager -ui $ui
                    }
                }
            }.GetNewClosure()
            $btnDel.Add_Click($clickDel)
        }
        
        # 19. BEBIDAS
        if ($cat.Name -eq "Bebidas") {
            $clickAdd = { 
                Start-BeverageEditor -ui $ui 
                Start-ItemManager -ui $ui 
            }.GetNewClosure()
            $btnAdd.Add_Click($clickAdd)

            $clickEdit = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Editar Bebida" -Prompt "Selecione o item:" -Options $names
                if ($sel) {
                    $itemData = $allItems | Where-Object { $_.NomeItem -eq $sel } | Select-Object -First 1
                    Start-BeverageEditor -ui $ui -EditItem $itemData
                    Start-ItemManager -ui $ui
                }
            }.GetNewClosure()
            $btnEdit.Add_Click($clickEdit)

            $clickDel = {
                $allItems = Import-Csv $csvPath -Delimiter ";" -Encoding UTF8
                $names = $allItems | Select-Object -ExpandProperty NomeItem | Sort-Object
                $sel = Show-SelectionDialog -Title "Apagar Bebida" -Prompt "Selecione o item para APAGAR:" -Options $names
                if ($sel) {
                    if ([System.Windows.Forms.MessageBox]::Show("Tem certeza absoluta que deseja APAGAR '$sel'?`nEssa ação é irreversível.", "Confirmar Exclusão", "YesNo", "Warning") -eq "Yes") {
                        $newList = $allItems | Where-Object { $_.NomeItem -ne $sel }
                        $newList | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
                        Start-ItemManager -ui $ui
                    }
                }
            }.GetNewClosure()
            $btnDel.Add_Click($clickDel)
        }

        # --- EFEITOS VISUAIS (Highlight) ---
        $onEnter = { $lbl.BackColor = $hoverRowColor }.GetNewClosure()
        $onLeave = { $lbl.BackColor = $normalLabelColor }.GetNewClosure()
        
        $rowControls = @($lbl, $btnAdd, $btnEdit, $btnDel)
        foreach ($c in $rowControls) { 
            $c.Add_MouseEnter($onEnter)
            $c.Add_MouseLeave($onLeave) 
        }

        # Adiciona na Tabela
        $ui.TblItems.RowCount++
        $ui.TblItems.Controls.Add($lbl, 0, ($ui.TblItems.RowCount - 1))
        $ui.TblItems.Controls.Add($btnAdd, 1, ($ui.TblItems.RowCount - 1))
        $ui.TblItems.Controls.Add($btnEdit, 2, ($ui.TblItems.RowCount - 1))
        $ui.TblItems.Controls.Add($btnDel, 3, ($ui.TblItems.RowCount - 1))
    }

    # [ALTERACAO] 3. Restaura o layout
    $ui.TblItems.ResumeLayout()
    $ui.PnlListContainer.ResumeLayout($true) # O $true forca o layout a recalcular

    # [ALTERACAO] 4. Restaura a posição do Scroll para onde estava
    if ($savedScroll -gt 0) {
        $ui.PnlListContainer.AutoScrollPosition = New-Object System.Drawing.Point(0, $savedScroll)
    }
}

function Start-CaliberManager {
    param ($ui)

    # Verifica se os controles existem
    if (-not $ui.PnlCaliber -or -not $ui.LstCalibers) { return }

    # Troca de Tela
    $ui.PnlMenu.Visible = $false
    $ui.PnlCaliber.Visible = $true
    
    # Chama a função GLOBAL de atualização (que já corrigimos as cores anteriormente)
    Update-CaliberList -ui $ui

    # --- EVENTO: Seleção na Lista ---
    if ($ui.EventSelChange) { $ui.LstCalibers.Remove_SelectedIndexChanged($ui.EventSelChange) }
    
    $eventSelChange = {
        $sel = $ui.LstCalibers.SelectedItem; if (-not $sel) { return }
        
        $inUse = Test-CaliberUsage $sel 
        
        if ($inUse) {
            $ui.BtnCalEdit.Enabled = $false; $ui.BtnCalEdit.ForeColor = $global:theme.TextDim
            $ui.BtnCalDel.Enabled = $false; $ui.BtnCalDel.ForeColor = $global:theme.TextDim
            $ui.LblCalInfo.Text = "Nota: O calibre '$sel' está em uso e NÃO pode ser editado/apagado."; $ui.LblCalInfo.ForeColor = $global:theme.RedAlert
        } else {
            $ui.BtnCalEdit.Enabled = $true; $ui.BtnCalEdit.ForeColor = $global:theme.TextMain
            $ui.BtnCalDel.Enabled = $true; $ui.BtnCalDel.ForeColor = $global:theme.RedAlert
            $ui.LblCalInfo.Text = "Nota: Calibre disponível para edição ou exclusão."; $ui.LblCalInfo.ForeColor = $global:theme.GreenSuccess
        }
    }.GetNewClosure()
    
    $ui.LstCalibers.Add_SelectedIndexChanged($eventSelChange)
    Add-Member -InputObject $ui -MemberType NoteProperty -Name "EventSelChange" -Value $eventSelChange -Force

    # --- EVENTO: Adicionar ---
    if ($ui.EventCalAdd) { $ui.BtnCalAdd.Remove_Click($ui.EventCalAdd) }
    $eventCalAdd = {
        $existingItems = [object[]]$ui.LstCalibers.Items
        $newCal = Show-InputDialog -Title "Adicionar Calibre" -Prompt "Digite o nome:" -ForbiddenList $existingItems
        if (-not [string]::IsNullOrWhiteSpace($newCal)) {
            $csvPath = Join-Path (Get-DatabasePath) "Caliber.csv"
            $currentList = @(); if (Test-Path $csvPath) { $currentList = @(Import-Csv $csvPath -Delimiter ";" -Encoding UTF8) }
            $obj = [PSCustomObject]@{ CalibreName = $newCal }; $currentList += $obj
            $currentList | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
            
            # [CORREÇÃO] Usa a função global Update-CaliberList
            Update-CaliberList -ui $ui
            $ui.LblCalInfo.Text = "Sucesso: Calibre adicionado!"; $ui.LblCalInfo.ForeColor = $global:theme.GreenSuccess
        }
    }.GetNewClosure()
    $ui.BtnCalAdd.Add_Click($eventCalAdd)
    Add-Member -InputObject $ui -MemberType NoteProperty -Name "EventCalAdd" -Value $eventCalAdd -Force

    # --- EVENTO: Editar ---
    if ($ui.EventCalEdit) { $ui.BtnCalEdit.Remove_Click($ui.EventCalEdit) }
    $eventCalEdit = {
        $sel = $ui.LstCalibers.SelectedItem; if (-not $sel) { return }
        $existingItems = [object[]]$ui.LstCalibers.Items
        $newName = Show-InputDialog -Title "Renomear" -Prompt "Digite o novo nome:" -DefaultText $sel -ForbiddenList $existingItems
        if (-not [string]::IsNullOrWhiteSpace($newName) -and $newName -ne $sel) {
            $csvPath = Join-Path (Get-DatabasePath) "Caliber.csv"
            $currentList = @(Import-Csv $csvPath -Delimiter ";" -Encoding UTF8)
            foreach ($item in $currentList) { if ($item.CalibreName -eq $sel) { $item.CalibreName = $newName } }
            $currentList | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
            
            # [CORREÇÃO] Usa a função global Update-CaliberList
            Update-CaliberList -ui $ui
            $ui.LblCalInfo.Text = "Sucesso: Renomeado."; $ui.LblCalInfo.ForeColor = $global:theme.GreenSuccess
        }
    }.GetNewClosure()
    $ui.BtnCalEdit.Add_Click($eventCalEdit)
    Add-Member -InputObject $ui -MemberType NoteProperty -Name "EventCalEdit" -Value $eventCalEdit -Force

    # --- EVENTO: Apagar ---
    if ($ui.EventCalDel) { $ui.BtnCalDel.Remove_Click($ui.EventCalDel) }
    $eventCalDel = {
        $sel = $ui.LstCalibers.SelectedItem; if (-not $sel) { return }
        if ([System.Windows.Forms.MessageBox]::Show("Apagar '$sel'?", "Confirmar", "YesNo", "Warning") -eq "Yes") {
            $csvPath = Join-Path (Get-DatabasePath) "Caliber.csv"
            $currentList = @(Import-Csv $csvPath -Delimiter ";" -Encoding UTF8)
            $newList = $currentList | Where-Object { $_.CalibreName -ne $sel }
            $newList | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
            
            # [CORREÇÃO] Usa a função global Update-CaliberList
            Update-CaliberList -ui $ui
            $ui.LblCalInfo.Text = "Sucesso: Apagado."; $ui.LblCalInfo.ForeColor = $global:theme.GreenSuccess
        }
    }.GetNewClosure()
    $ui.BtnCalDel.Add_Click($eventCalDel)
    Add-Member -InputObject $ui -MemberType NoteProperty -Name "EventCalDel" -Value $eventCalDel -Force
}

function Start-CompatManager {
    param ($ui)
    
    # Verifica controles
    if (-not $ui.PnlCompat -or -not $ui.LstMasks) { return }

    # Troca Tela
    $ui.PnlMenu.Visible = $false
    $ui.PnlCompat.Visible = $true
    
    $dbPath = Get-DatabasePath
    $maskPath = Join-Path $dbPath "Masks.csv"
    $helmPath = Join-Path $dbPath "Helmets.csv"
    $compPath = Join-Path $dbPath "MaskCompatibility.csv"

    # Verificação de Segurança
    if (-not (Test-Path $maskPath) -or -not (Test-Path $helmPath)) {
        [System.Windows.Forms.MessageBox]::Show("Erro Crítico: Arquivos 'Masks.csv' ou 'Helmets.csv' não encontrados.", "Erro", "OK", "Error")
        if ($ui.BtnBackCompat) { $ui.BtnBackCompat.PerformClick() }
        return
    }

    # Carrega Lista de Máscaras
    $ui.LstMasks.Items.Clear()
    $masks = Import-Csv $maskPath -Delimiter ";" -Encoding UTF8 | Sort-Object NomeItem
    foreach ($m in $masks) { $ui.LstMasks.Items.Add($m.NomeItem) | Out-Null }
    
    # Limpa UI direita e Define Cores Iniciais
    $ui.LstCompHelmets.Items.Clear()
    $ui.BtnAddCompat.Enabled = $false; $ui.BtnAddCompat.ForeColor = $global:theme.TextDim
    $ui.BtnRemCompat.Enabled = $false; $ui.BtnRemCompat.ForeColor = $global:theme.TextDim
    $ui.LblCompInfo.Text = "Selecione uma máscara à esquerda para gerenciar."

    # --- EVENTO: Seleção de Máscara ---
    if ($ui.EventMaskSel) { $ui.LstMasks.Remove_SelectedIndexChanged($ui.EventMaskSel) }
    $eventMaskSel = {
        $selMask = $ui.LstMasks.SelectedItem
        if (-not $selMask) { return }

        $localCompPath = Join-Path (Get-DatabasePath) "MaskCompatibility.csv"
        
        $ui.LstCompHelmets.Items.Clear()
        $ui.BtnAddCompat.Enabled = $true; $ui.BtnAddCompat.ForeColor = $global:theme.GreenSuccess
        $ui.BtnRemCompat.Enabled = $false; $ui.BtnRemCompat.ForeColor = $global:theme.TextDim

        $currentCompatibleHelmets = @()
        
        if (Test-Path $localCompPath) {
            $compData = Import-Csv $localCompPath -Delimiter ";" -Encoding UTF8
            $currentCompRow = $compData | Where-Object { $_.MaskName -eq $selMask } | Select-Object -First 1
            
            if ($currentCompRow -and -not [string]::IsNullOrWhiteSpace($currentCompRow.CompatibleHelmets)) {
                $currentCompatibleHelmets = @($currentCompRow.CompatibleHelmets -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
            }
        }

        foreach ($h in $currentCompatibleHelmets) { 
            $ui.LstCompHelmets.Items.Add($h) | Out-Null 
        }
        
        if ($ui.LstCompHelmets.Items.Count -gt 0) { 
            $ui.LblCompInfo.Text = "Máscara: $selMask`nCapacetes Compatíveis: $($ui.LstCompHelmets.Items.Count)" 
        } else { 
            $ui.LblCompInfo.Text = "Máscara: $selMask`nNenhum capacete compatível registrado." 
        }
    }.GetNewClosure() # Closure Vital
    
    $ui.LstMasks.Add_SelectedIndexChanged($eventMaskSel)
    Add-Member -InputObject $ui -MemberType NoteProperty -Name "EventMaskSel" -Value $eventMaskSel -Force

    # --- EVENTO: Seleção de Capacete (para remover) ---
    if ($ui.EventHelmSel) { $ui.LstCompHelmets.Remove_SelectedIndexChanged($ui.EventHelmSel) }
    $eventHelmSel = {
        if ($ui.LstCompHelmets.SelectedItem) {
            $ui.BtnRemCompat.Enabled = $true; $ui.BtnRemCompat.ForeColor = $global:theme.RedAlert
        }
    }.GetNewClosure()
    
    $ui.LstCompHelmets.Add_SelectedIndexChanged($eventHelmSel)
    Add-Member -InputObject $ui -MemberType NoteProperty -Name "EventHelmSel" -Value $eventHelmSel -Force

    # --- EVENTO: Adicionar Compatibilidade ---
    if ($ui.EventAddComp) { $ui.BtnAddCompat.Remove_Click($ui.EventAddComp) }
    $eventAddComp = {
        $selMask = $ui.LstMasks.SelectedItem
        if (-not $selMask) { return }

        $localDb = Get-DatabasePath
        $localHelm = Join-Path $localDb "Helmets.csv"
        $localComp = Join-Path $localDb "MaskCompatibility.csv"

        $allHelmets = Import-Csv $localHelm -Delimiter ";" -Encoding UTF8
        $currentCompList = [object[]]$ui.LstCompHelmets.Items

        $available = $allHelmets | Where-Object { 
            $_.NomeItem -notin $currentCompList -and 
            $_.AreaProtegida -ne "Head, Ears, Face" -and 
            $_.Acessorio -ne "/////" -and 
            $_.Acessorio -ne "TE" 
        } | Select-Object -ExpandProperty NomeItem | Sort-Object

        if ($available.Count -eq 0) { 
            [System.Windows.Forms.MessageBox]::Show("Não há mais capacetes válidos para adicionar a esta máscara.", "Aviso", "OK", "Information")
            return 
        }

        # Usa o Show-SelectionDialog
        $helmetToAdd = Show-SelectionDialog -Title "Adicionar Compatibilidade" -Prompt "Selecione o capacete para vincular:" -Options $available
        
        if ($helmetToAdd) {
            $compData = @()
            if (Test-Path $localComp) { $compData = @(Import-Csv $localComp -Delimiter ";" -Encoding UTF8) }
            
            $targetRow = $compData | Where-Object { $_.MaskName -eq $selMask }
            
            if ($targetRow) {
                $currentList = @()
                if (-not [string]::IsNullOrWhiteSpace($targetRow.CompatibleHelmets)) {
                    $currentList = @($targetRow.CompatibleHelmets -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
                }
                $currentList += $helmetToAdd.ToString().Trim()
                $targetRow.CompatibleHelmets = $currentList -join ","
            } else {
                $compData += [PSCustomObject]@{ MaskName = $selMask; CompatibleHelmets = $helmetToAdd.ToString().Trim() }
            }
            
            $compData | Export-Csv $localComp -NoTypeInformation -Delimiter ";" -Encoding UTF8
            
            # Recarrega a seleção para atualizar a lista visual
            $ui.LstMasks.SetSelected($ui.LstMasks.SelectedIndex, $true)
        }
    }.GetNewClosure()
    
    $ui.BtnAddCompat.Add_Click($eventAddComp)
    Add-Member -InputObject $ui -MemberType NoteProperty -Name "EventAddComp" -Value $eventAddComp -Force

    # --- EVENTO: Remover Compatibilidade ---
    if ($ui.EventRemComp) { $ui.BtnRemCompat.Remove_Click($ui.EventRemComp) }
    $eventRemComp = {
        $selMask = $ui.LstMasks.SelectedItem
        $selHelm = $ui.LstCompHelmets.SelectedItem
        
        if (-not $selMask -or -not $selHelm) { return }

        $res = [System.Windows.Forms.MessageBox]::Show("Remover compatibilidade com '$selHelm'?", "Confirmar", "YesNo", "Question")
        
        if ($res -eq "Yes") {
            $localComp = Join-Path (Get-DatabasePath) "MaskCompatibility.csv"
            $compData = @(Import-Csv $localComp -Delimiter ";" -Encoding UTF8)
            
            $targetRow = $compData | Where-Object { $_.MaskName -eq $selMask }
            
            if ($targetRow) {
                $currentArr = @($targetRow.CompatibleHelmets -split ',' | ForEach-Object { $_.Trim() })
                $newArr = $currentArr | Where-Object { $_ -ne $selHelm -and $_ -ne "" }
                $targetRow.CompatibleHelmets = $newArr -join ","
                
                $compData | Export-Csv $localComp -NoTypeInformation -Delimiter ";" -Encoding UTF8
                
                # Recarrega a lista
                $ui.LstMasks.SetSelected($ui.LstMasks.SelectedIndex, $true)
            }
        }
    }.GetNewClosure()
    
    $ui.BtnRemCompat.Add_Click($eventRemComp)
    Add-Member -InputObject $ui -MemberType NoteProperty -Name "EventRemComp" -Value $eventRemComp -Force
}

function Register-ManagerEvents {
    param ($ui)

    # Verifica se o objeto UI existe
    if (-not $ui) { return }

    # --- NAVEGAÇÃO DO MENU PRINCIPAL ---
    # Usamos .GetNewClosure() para garantir que o botão "lembre" quem é $ui
    
    if ($ui.BtnCaliber) { 
        $ui.BtnCaliber.Add_Click({ 
            Start-CaliberManager -ui $ui 
        }.GetNewClosure()) 
    }

    if ($ui.BtnCompat) { 
        $ui.BtnCompat.Add_Click({ 
            Start-CompatManager -ui $ui 
        }.GetNewClosure()) 
    }

    if ($ui.BtnManageItems) { 
        $ui.BtnManageItems.Add_Click({ 
            Start-ItemManager -ui $ui 
        }.GetNewClosure()) 
    }

    # --- BOTÕES DE VOLTAR (Sub-telas) ---
    if ($ui.BtnBackCal) { 
        $ui.BtnBackCal.Add_Click({ 
            if($ui.PnlCaliber){$ui.PnlCaliber.Visible=$false}
            if($ui.PnlMenu){$ui.PnlMenu.Visible=$true} 
        }.GetNewClosure()) 
    }

    if ($ui.BtnBackCompat) { 
        $ui.BtnBackCompat.Add_Click({ 
            if($ui.PnlCompat){$ui.PnlCompat.Visible=$false}
            if($ui.PnlMenu){$ui.PnlMenu.Visible=$true} 
        }.GetNewClosure()) 
    }

    if ($ui.BtnBackItems) { 
        $ui.BtnBackItems.Add_Click({ 
            if($ui.PnlItems){$ui.PnlItems.Visible=$false}
            if($ui.PnlMenu){$ui.PnlMenu.Visible=$true} 
        }.GetNewClosure()) 
    }

    # --- BOTÃO VOLTAR PRINCIPAL (Fecha o Painel) ---
    if ($ui.BtnBackMain) {
        $ui.BtnBackMain.Add_Click({ 
            if ($ui.PnlManagerRoot) { $ui.PnlManagerRoot.Dispose() }
        }.GetNewClosure())
    }

    # --- TECLA ESC INTEGRADA ---
    if ($ui.Form) {
        $ui.Form.KeyPreview = $true
        
        # Salvamos o scriptblock em variável para poder remover depois
        $escEvent = { 
            if ($_.KeyCode -eq "Escape") {
                # Verifica se o painel ainda existe e está visivel
                if ($ui.PnlManagerRoot -and -not $ui.PnlManagerRoot.IsDisposed -and $ui.PnlManagerRoot.Visible) {
                    
                    if ($ui.PnlCaliber.Visible) { 
                        $_.SuppressKeyPress = $true; $ui.BtnBackCal.PerformClick() 
                    }
                    elseif ($ui.PnlCompat.Visible) { 
                        $_.SuppressKeyPress = $true; $ui.BtnBackCompat.PerformClick() 
                    }
                    elseif ($ui.PnlItems.Visible) { 
                        $_.SuppressKeyPress = $true; $ui.BtnBackItems.PerformClick() 
                    } 
                    elseif ($ui.PnlMenu.Visible) { 
                        $_.SuppressKeyPress = $true
                        # Fecha o painel mestre
                        $ui.PnlManagerRoot.Dispose() 
                    }
                }
            }
        }.GetNewClosure()
        
        # Remove anterior para não duplicar e adiciona o novo
        $ui.Form.remove_KeyDown($escEvent)
        $ui.Form.Add_KeyDown($escEvent)
        
        # Limpeza automática ao fechar o painel
        if ($ui.PnlManagerRoot) {
            $ui.PnlManagerRoot.Add_Disposed({
                $ui.Form.Remove_KeyDown($escEvent)
            }.GetNewClosure())
        }
    }
}

function Start-DatabaseManager {
    param ($MainForm) # Recebe a Janela Principal

    # 1. Inicializa os visuais dentro do MainForm
    $ui = Initialize-ManagerVisuals -targetForm $MainForm

    # 2. Conecta os botões
    Register-ManagerEvents -ui $ui

    # 3. Exibe o painel mestre
    if ($ui.PnlManagerRoot) {
        $ui.PnlManagerRoot.Visible = $true
        $ui.PnlManagerRoot.BringToFront()
        $ui.PnlManagerRoot.Focus()
    }
}

# ===================================================================================
# 6. O PORTEIRO (EVENTOS)
# ===================================================================================
function Register-MainEvents {
    param ($ui)
    $events = @{}

    $events["OpenDatabase"] = {
        Show-MainForm -MainForm $ui.Form
    }

    $events["OpenCompare"] = { 
        Show-ComparisonForm -MainForm $ui.Form
    }

    $events["OpenManage"] = { 
        Start-DatabaseManager -MainForm $ui.Form
    }

    $events["CheckUpdates"] = {
        # [CORREÇÃO] Passamos -MainForm em vez de -OwnerForm
        Start-UpdateModule -CurrentVersion $AppVersion -MainForm $ui.Form
    }

    $events["ExitApp"] = { $ui.Form.Close() }
    return $events
}

# ===================================================================================
# 7. EXECUCAO
# ===================================================================================
function Start-ABIDB {
    $ui = Initialize-MainVisuals
    $actions = Register-MainEvents -ui $ui
    Build-MainMenu -ui $ui -events $actions
    $ui.Form.ShowDialog() | Out-Null
    
    # --- LIMPEZA FINAL DE MEMÓRIA (Encerramento Limpo) ---
    $ui.Form.Dispose()
}

Start-ABIDB