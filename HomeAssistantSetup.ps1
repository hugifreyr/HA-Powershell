#Setting up Home Assistant using Docker and Certify


###********Before running this function************
#Docker need to be installed and if running on Windows, you need to switch the Docker environment to Linux containers.
#The folder need to be manual created on local machine 
#The folder or root of the folder need to be added to Docker->Setting->Resources->File Sharing 
function New-HADockerEnv($name = "home-assistant", $volume = "C:\Docker\homeassistant", $port = "8123")
{
    $portforward = $port + ":8123"
    $volume = $volume + ":/config"
    Write-Output $port
    Write-Output $volume

    #Create docker container
    docker run --init -d --name="$name" -e "TZ=Iceland" -v $volume -p $portforward homeassistant/home-assistant:stable
    
    #Need to sleep for 5 sec, because HA is still starting
    Start-Sleep -s 5
    Start-Process "http://localhost:$port"
}


function Get-HAConvertPFX2PEM ( $PFXfolder = "C:\ProgramData\Certify\certes\assets\pfx\", $HAfolder = "C:\Docker\homeassistant\ssl\", $OpenSSLfolder = "C:\Program Files\Git\mingw64\bin\" , $Domain  )
{
    $temp = Get-ChildItem -Path $PFXfolder -Recurse -include *.pfx | Select-Object -first 100 | Sort-Object LastWriteTime -Descending

    foreach ( $tmp in $temp )
    {
        $name = $tmp.Name
        $file = "$PFXfolder\$name"""
        $Domain = "CN=" + $Domain
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