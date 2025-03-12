from json import loads, dumps
import subprocess as sp
import socket
from os import remove
from pathlib import Path
import sys
import os


def to_GiB(item):
	if isinstance(item, (int, float)):
			temp = '{:.1f}'.format(round(item * (1 / (1.024 ** 3))) * (1 / (10 ** 9)))
			return temp + ' GiB'
	return item


def to_GHz(item, rounded=True):
	if isinstance(item, (int, float)):
		if rounded:
			temp = '{:.1f}'.format(round(item, -2) / 1000)
		else:
			temp = '{:.3f}'.format(item / 1000)
		return temp + ' GHz'
	return item


class Component:
	__slots__ = ()
	__name__ = 'Component'
	renaming = []
	def __init__(self, **kwargs):
		[setattr(self, key, value) for key, value in kwargs.items() if key in self.__slots__]
		self.post_process()

	def post_process(self):
		pass

	@staticmethod
	def rename(_dict, *args):
		for a, b in args:
			if _dict.get(a, False):
				_dict[b] = _dict.pop(a)
		return _dict

	def __dict__(self):
		temp = {'Object': self.__name__}
		for key in self.__slots__:
            try:
                value = getattr(self, key)
                if isinstance(value, str):
                    value = value.strip()
                temp.update({key: value})
            except:
                pass
		return self.rename(temp, *self.renaming)


class Bios(Component):
	__slots__ = 'Manufacturer', 'Version'
	__name__ = 'Bios'


class Mainboard(Component):
	__slots__ = 'Manufacturer', 'Product'
	__name__ = 'Mainboard'


class Processor(Component):
	__slots__ = 'Manufacturer', 'Name', 'MaxClockSpeed', 'ProcessorId', 'NumberOfCores', 'SocketDesignation'
	__name__ = 'Processor'
	renaming = [('Name', 'Product'),]

	def post_process(self):
		self.MaxClockSpeed = to_GHz(self.MaxClockSpeed)


class PhysicalMemory(Component):
	__slots__ = 'Manufacturer', 'Capacity', 'Speed', 'PartNumber', 'DeviceLocator'
	__name__ = 'PhysicalMemory'
	
	def post_process(self):
		self.Capacity = to_GiB(self.Capacity)
		self.Speed = to_GHz(self.Speed, rounded=False)


class OS(Component):
	__slots__ = 'Manufacturer', 'Caption', 'OSArchitecture', 'InstallDate', 'CSName'
	__name__ = 'OS'
	renaming = [('CSName', 'ComputerName')]
	def post_process(self):
		self.InstallDate = self.InstallDate['DateTime']


class NetworkAdapter(Component):
	__slots__ = 'Name', 'MACAddress', 'NetConnectionID'
	__name__ = 'NetworkAdapter'
	renaming = [('Name', 'Product'), ('NetConnectionID', 'ConnectionType')]

	def __dict__(self):
		if len(self.MACAddress) < 8:
			return {}
		else:
			return super().__dict__()
			
			
class VideoController(Component):
	__slots__ = 'Name', 'AdapterRAM'
	__name__ = 'VideoController'
	renaming = [('Name', 'Product'),]
	def post_process(self):
		self.AdapterRAM = to_GiB(self.AdapterRAM)


class DiskDrive(Component):
	__slots__ = 'Model', 'Size', 'InterfaceType', 'SerialNumber'
	__name__ = 'DiskDrive'
	def post_process(self):
		self.Size = to_GiB(self.Size)


obj_dict = {
			'Bios': Bios,
			'BaseBoard': Mainboard,
			'Processor': Processor,
			'VideoController': VideoController,
			'PhysicalMemory': PhysicalMemory,
			'OperatingSystem': OS,
			'NetworkAdapter': NetworkAdapter,
			'DiskDrive': DiskDrive,
			}


def run():
	hidden = sp.STARTUPINFO()
	hidden.dwFlags |= sp.STARTF_USESHOWWINDOW
	root = Path(os.path.dirname(os.path.abspath(sys.argv[0])))
	os.chdir(root)

	files = ['SystemInfo.ps1', 'temp.temp', f'{socket.gethostname()}.json', 'psexec.exe']

	def paths(select):
		temp = [d for d in root.parts] + [files[select],]
		return Path(*temp)

	
	sp.run(f'powershell.exe -executionpolicy bypass {paths(0)}', startupinfo=hidden)
	
	SysInfo = []
	with open(f'{paths(1)}', 'rb') as f:
		data = loads(f.read())
	for comp, Objs in data.items():
		for obj in Objs:
			assert isinstance(comp, str), "comp must be a string"
			if obj_dict.get(comp, False):
				if obj_dict[comp](**obj).__dict__() != {}:
					SysInfo.append(obj_dict[comp](**obj).__dict__())
	with open(f'{paths(2)}', 'w') as f:
		f.write(dumps(SysInfo, indent=4))
	remove(f'{paths(1)}')


if __name__ == '__main__':
	run()
