#Setting up Home Assistant using Docker and Certify


function Get-HAConvertPFX2PEM ( $PFXfolder = "C:\ProgramData\Certify\certes\assets\pfx\", $HAfolder = "C:\Docker\homeassistant\ssl\", $OpenSSLfolder = "C:\Program Files\Git\mingw64\bin\" , $Domain = "CN=hugifreyr.com" )
{
    $temp = Get-ChildItem -Path $PFXfolder -Recurse -include *.pfx | Select-Object -first 100 | Sort-Object LastWriteTime -Descending

    foreach ( $tmp in $temp )
    {
        $name = $tmp.Name
        $file = "$PFXfolder\$name"
        try
        {
            $tempPFX = Get-PfxCertificate -FilePath $file

            if( $tempPFX.Subject -ieq $Domain)
            {
                Write-Output $name
                Set-Location $OpenSSLfolder

                $temp = "openssl pkcs12 -in `"$file`" -passin pass: -out `"$HAfolder\`"key.pem -nocerts -nodes"
                Write-Output $temp
                cmd.exe /c $temp
                $temp = "openssl pkcs12 -in `"$file`" -out `"$HAfolder\`"cert.pem -nokeys -passin pass:"
                Write-Output $temp
                cmd.exe /c $temp

                return
            }
        }
        finally {
        }
    }
}