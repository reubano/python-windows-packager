# Python Packager
## Overview

Develop Python on Linux or Mac, deploy on Windows.

Uses Pyinstaller and Wine to package Python programs to standalone Windows
executables, all from your Linux or Mac box.

## Quick start

### Download required files

	cd win-installers
	wget "https://github.com/reubano/shFlags/blob/master/src/shflags"
	wget "http://www.python.org/ftp/python/2.7.6/python-2.7.3.msi"
	wget "http://downloads.sourceforge.net/project/pywin32/pywin32/Build%20218/pywin32-218.win32-py2.7.exe"
	wget "https://pypi.python.org/packages/2.7/s/setuptools/setuptools-0.6c11.win32-py2.7.exe"
	wget "http://www.lfd.uci.edu/~gohlke/pythonlibs/bmsicnqj/lxml-3.3.3.win32-py2.7.exe"

### Install dependencies

	sudo mv shflags /usr/lib/shflags
	
	# Mac
	sudo port install wine winetricks samba3

	# Linux
	apt-get wine winetricks samba3
	
### Setup Wine environment
	
	export "WINEPREFIX=~/.local/share/wineprefixes/pyinstaller"
	winetricks --no-isolate mingw
	
	# winetricks with display error message so cd to bin and run again
	cd ~/.local/share/wineprefixes/pyinstaller/drive_c/MinGW/bin
	winetricks --no-isolate mingw

### Create your standalone EXE

	cd /path/to/pywinmk/sample-app
	../pywinmk.sh -s main.py -n MySampleProject

## Modifying the Python Windows environment

If you want to use a different Python version or add additional Python
modules, just do the above with different Windows Python installers.

