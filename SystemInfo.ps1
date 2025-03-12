function SystemJSON(){
  param(
    [parameter(Mandatory=$true)]
    [string]$path
    )

  #  Adjust classes to Select the set of Propertys that are collected
  $classes = @{
            Bios = @('Manufacturer', 'Version')
            BaseBoard = @('Manufacturer', 'Product')
            Processor = @('Manufacturer', 'Name', 'MaxClockSpeed', 'SocketDesignation', 'NumberOfCores', 'ProcessorId')
            PhysicalMemory = @('Manufacturer', 'PartNumber', 'Capacity', 'Speed', 'DeviceLocator')
            OperatingSystem = @('Manufacturer', 'Caption', 'OSArchitecture', 'InstallDate', 'CSName')
            DiskDrive = @('Model', 'Size', 'InterfaceType', 'SerialNumber')
            VideoController = @('Name', 'AdapterRAM')
            NetworkAdapter = @('Name', 'Description', 'PhysicalAdapter', 'MACAddress', 'NetConnectionID')
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
  
  $json | Out-File -FilePath $path 
}
