Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead('docs/UniCheck_Software_Design_Document.docx')
$doc = (New-Object System.IO.StreamReader($zip.GetEntry('word/document.xml').Open())).ReadToEnd()
$rels = (New-Object System.IO.StreamReader($zip.GetEntry('word/_rels/document.xml.rels').Open())).ReadToEnd()
$zip.Dispose()

[xml]$relsXml = $rels
$relMap = @{}
foreach ($r in $relsXml.Relationships.Relationship) {
    $relMap[$r.Id] = $r.Target
}

[xml]$dXml = $doc
$ns = New-Object System.Xml.XmlNamespaceManager($dXml.NameTable)
$ns.AddNamespace('w', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main')
$ns.AddNamespace('a', 'http://schemas.openxmlformats.org/drawingml/2006/main')
$ns.AddNamespace('r', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships')

$pars = $dXml.SelectNodes('//w:p', $ns)
for ($i = 0; $i -lt $pars.Count; $i++) {
    $p = $pars[$i]
    $txt = ($p.SelectNodes('.//w:t', $ns) | ForEach-Object { $_.InnerText }) -join ''
    if ($txt -match 'Figure (6|7|14):') {
        # check preceding or following 3 paragraphs for drawing/blip
        $foundImages = @()
        for ($j = [Math]::Max(0, $i - 3); $j -le [Math]::Min($pars.Count - 1, $i + 3); $j++) {
            $blips = $pars[$j].SelectNodes('.//a:blip', $ns)
            foreach ($b in $blips) {
                $rid = $b.GetAttribute('embed', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships')
                if ($relMap.ContainsKey($rid)) {
                    $foundImages += $relMap[$rid]
                }
            }
        }
        Write-Output "[$txt] -> $($foundImages -join ', ')"
    }
}
