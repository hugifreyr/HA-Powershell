#Setting up Home Assistant using Docker and Certify


###********Before running this function************
#Docker need to be installed and if running on Windows, you need to switch the Docker environment to Linux containers.
#The folder need to be manual created on local machine 
#The folder or root of the folder need to be added to Docker->Setting->Resources->File Sharing 
function New-HADockerEnv($name = "home-assistant", $volume = "X:\HomeAssistant", $port = "8123", $SSLenabled = $false) {
    $portforward = $port + ":8123"
    $volume = $volume + ":/config"
    Write-Output $port
    Write-Output $volume

    #Create docker container
    # Version 2022.6 does not work with --init command
    #docker run --init -d --restart unless-stopped --name="$name" -e "TZ=Iceland" -v $volume -p $portforward homeassistant/home-assistant:stable #-v "/var/run/docker.sock:/var/run/docker.sock"
    docker run -d --restart unless-stopped --name="$name" -e "TZ=Iceland" -v $volume -p $portforward homeassistant/home-assistant:stable
    
    #Need to sleep for 5 sec, because HA is still starting
    Start-Sleep -s 5
    if ($SSLenabled -eq $true) {
        Start-Process "https://localhost:$port"
    }
    else {
        Start-Process "http://localhost:$port"      
    }

}

function Get-UpgradeHADockerEnv( $path = "X:\HomeAssistant", $SSLenabled = $true) {
    $starttimer = (Get-Date)
    docker stop "home-assistant"
    docker rm "home-assistant"
    docker rmi "homeassistant/home-assistant:stable"
    docker pull homeassistant/home-assistant:stable

    $path = "X:\HomeAssistant"
    $destinationPath = "$path-backup\" + (Get-Date).tostring("dd.MM.yyyy")
    Copy-Item -Force -Recurse -Verbose -Path $path\ -Destination $destinationPath -PassThru 

    New-HADockerEnv -SSLenabled $SSLenabled
    $endtimer = (Get-Date)
    $timer = $($endtimer - $starttimer).Seconds
    Write-Output "Upgrading HA environment took $timer secounds"
}

#Old PFXfolder path was C:\ProgramData\Certify\certes\assets\pfx\
#New PFXfolder parh is "C:\ProgramData\Certify\assets\domainname\"
function Get-HAConvertPFX2PEM {
    Param(
        $PFXfolder = "C:\ProgramData\Certify\assets\",
        $HAfolder = "X:\HomeAssistant\",
        $OpenSSLfolder = "C:\Program Files\Git\mingw64\bin\",
        [parameter(Mandatory = $true)]
        $Domain,
        $Wildcard = $false 
    )

    if ($Wildcard -eq $true) {
        $PFXfolder = $PFXfolder + "_."
    }

    $PFXfolder = $PFXfolder + $Domain + "" 
    Write-Output $PFXfolder
    $temp = Get-ChildItem -Path $PFXfolder -Recurse -include *.pfx | Select-Object -first 100 | Sort-Object LastWriteTime -Descending
    Write-Output $temp

    foreach ( $tmp in $temp ) {
        $name = $tmp.Name
        $file = "$PFXfolder\$name"
        Write-Output $file

        try {
            $tempPFX = Get-PfxCertificate -FilePath $file
            Write-Output $tempPFX.Subject

            if ( $tempPFX.Subject -ieq ( "CN=" + $Domain ) -or $tempPFX.Subject -ieq ("CN=*." + $Domain) ) {
                Write-Output $name
                Set-Location $OpenSSLfolder

                $temp = "openssl pkcs12 -legacy -in `"$file`" -passin pass: -out `"$HAfolder\`"key.pem -nocerts -nodes"
                Write-Output $temp
                cmd.exe /c $temp
                $temp = "openssl pkcs12 -legacy -in `"$file`" -out `"$HAfolder\`"cert.pem -nokeys -passin pass:"
                Write-Output $temp
                cmd.exe /c $temp

                return
            }
        }
        finally {
        }
    }
}