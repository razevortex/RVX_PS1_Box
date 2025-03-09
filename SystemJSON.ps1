function SystemJSON(){
  param(
    [parameter(Mandatory=$true)]
    [string]$path,
    [parameter(Mandatory=$false)]
    [string]$computername
    )
  # The CimSession part that should allow a remote collection of the data is still WIP and will likely not work without some further information 
  if (-not $computername) { $session = New-CimSession }
  else { $session = New-CimSession -ComputerName $computername}
  
  #  Adjust classes to Select the set of Propertys that are collected
  $classes = @{
            Bios = @('Manufacturer', 'Version')
            BaseBoard = @('Manufacturer', 'Product')
            Processor = @('Manufacturer', 'Name', 'MaxClockSpeed', 'SocketDesignation', 'NumberOfCores', 'ProcessorId')
            PhysicalMemory = @('Manufacturer', 'PartNumber', 'Capacity', 'Speed', 'DeviceLocator')
            OperatingSystem = @('Manufacturer', 'Caption', 'OSArchitecture', 'InstallDate', 'CSName')
            DiskDrive = @('Model', 'Size', 'InterfaceType', 'SerialNumber')
            VideoController = @('Name', 'AdapterRAM')
            NetworkAdapter = @('Name', 'Description', 'PhysicalAdapter', 'MACAddress')
            }

  $SystemObject = @{}

  foreach ($prop in $classes.Keys){
    $item  = @()
    foreach ($obj in Get-CimInstance -ClassName Win32_$prop -CimSession $session) {
        $temp = @{}
        foreach ($value in $classes.$prop){
            $temp[$value] = $obj | Select -expand $value
        }
        # The next for lines 28:31 are a filter to not include not physical NetworkAdapter and can be removed if unwanted
        if ($prop -eq "NetworkAdapter"){
            if ($temp.PhysicalAdapter){ $item += $temp }
        }
        else { $item += $temp }
    }
    $SystemObject[$prop] = $item
  }


  $json = $SystemObject | ConvertTo-Json
  # note that the file is without encoding (bytes) if encoding is needed uncomment the arg
  $json | Out-File -FilePath "$path$(Get-Date -Format 'dd_MM_yyyy_HH_mm_ss').json" #-Encoding utf-8
}

