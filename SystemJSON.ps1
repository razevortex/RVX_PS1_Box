function SystemJSON(){
  param(
    [parameter(Mandatory=$true)]
    [string]$path
  )
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
    foreach ($obj in Get-CimInstance -ClassName Win32_$prop) {
        $temp = @{}
        foreach ($value in $classes.$prop){
            $temp[$value] = $obj | Select -expand $value
        }
        if ($prop -eq "NetworkAdapter"){
            if ($temp.PhysicalAdapter){ $item += $temp }
        }
        else { $item += $temp }
    }
    $SystemObject[$prop] = $item
  }


  $json = $SystemObject | ConvertTo-Json
  $json | Out-File -FilePath "$path$(Get-Date -Format 'dd_MM_yyyy_HH_mm_ss').json"
}
