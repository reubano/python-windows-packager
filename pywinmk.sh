#!/bin/sh -u
# summary: Uses Pyinstaller and Wine to package Python scripts into standalone
# Windows executables
#
# usage: pywinmk [options] <project>

# source shflags
. /usr/lib/shflags || return $?

PROJECT=${PWD##*/}

# configure shflags
DEFINE_string 'dir' `echo ~/Documents/Projects/$PROJECT` 'the project directory' 'd' || return $?
DEFINE_string 'project' `echo $PROJECT` 'the project name' 'p' || return $?
DEFINE_string 'script' `echo $PROJECT.py` 'the python script to package' 's' || return $?
DEFINE_string 'prefix' `echo ~/.local/share/wineprefixes/pyinstaller` 'the wine prefix to use' 'w' || return $?
DEFINE_string 'thaw' '' "restore from a previously frozen wine environment (by supplying the path to the tar.gz file) and exit. Use the -f option to freeze a wine environment" 't' || return $?
DEFINE_boolean 'freeze' 'false' 'freeze the wine environment (creates wine environment if necessary) and exit' 'f' || return $?
DEFINE_boolean 'onefile' 'false' 'use pyinstaller in one-file mode' 'F' || return $?
DEFINE_boolean 'windowed' 'false' 'use pyinstaller in windowed/no-console mode' 'W' || return $?
DEFINE_boolean 'spec' 'false' "run pyinstaller with spec file ($PROJECT.spec)" 'S' || return $?

# parse the command-line
FLAGS "$@" || exit 1
[ ${FLAGS_help} -eq ${FLAGS_FALSE} ] || exit
eval set -- "${FLAGS_ARGV}"

# main
BUILD_DIR='win-build'
DIST_DIR='win-dist'
INSTALLERS_DIR="$(dirname $0)/win-installers"
ENV_REG='path.reg'
PIP_CONFIG='distutils.cfg'

WINE_TARBALL="${FLAGS_dir}/wine.tar.gz"
C="${FLAGS_prefix}/drive_c"
SOURCE_DIR="$C/${FLAGS_project}"
PYTHON_DIR=`echo $C/Python*`
SYS32="$C/windows/system32"
WINE_SCRIPTS=`echo $PYTHON_DIR/Scripts`
DISTUTILS="$PYTHON_DIR/distutils"

EASY_INSTALL=$(winepath -w $WINE_SCRIPTS/easy_install.exe)
PIP=$(winepath -w $WINE_SCRIPTS/pip.exe)
PYINSTALLER=$(winepath -w $WINE_SCRIPTS/pyinstaller.exe)

if [ ${FLAGS_thaw} ]; then
	echo 'Removing old prefix'
	rm -fr ${FLAGS_prefix}
	echo "Restoring wine environment..."
	tar -C ${FLAGS_prefix} -xzf ${FLAGS_thaw}
	exit 0
elif [ ! -d ${FLAGS_prefix} ]; then
	echo "Creating new wine environment"
	export "WINEPREFIX=${FLAGS_prefix}"
	cd $INSTALLERS_DIR
	wine start python*.msi
	wine pywin32*.exe
	wine setup*.exe
	wine $EASY_INSTALL pip
	wine $PIP install PyInstaller
fi

if [ ${FLAGS_freeze} -eq ${FLAGS_TRUE} ]; then
	echo "Freezing ${FLAGS_prefix} to $WINE_TARBALL"
	cd ${FLAGS_prefix}
	tar -czf $WINE_TARBALL .
	exit 0
fi

# Create symbolic link to source directory so Wine can access it
if [ ! -d $C/${FLAGS_project} ]; then
	echo "Symlinking ${FLAGS_dir} to $C/${FLAGS_project}/"
	ln -s ${FLAGS_dir} $C/${FLAGS_project}/
fi

# Create hard link for missing msvcp90.dll
if [ ! -f $PYTHON_DIR/msvcp90.dll ]; then
	echo "Linking $SYS32/msvcp90.dll to $PYTHON_DIR/"
	ln $SYS32/msvcp90.dll $PYTHON_DIR/
fi

if [ ${FLAGS_spec} -eq ${FLAGS_TRUE} ]; then
	SOURCE_FILE=${FLAGS_project}.spec
else
	SOURCE_FILE=${FLAGS_script}
fi

if [ ${FLAGS_onefile} -eq ${FLAGS_TRUE} ]; then
	O='-F'
else
	O=''
fi

if [ ${FLAGS_windowed} -eq ${FLAGS_TRUE} ]; then
	O="$O -W"
else
	O=$O
fi

if [ ! -f $DISTUTILS/$PIP_CONFIG ]; then
	echo "Copying $PIP_CONFIG to $DISTUTILS/"
	cd $INSTALLERS_DIR
	cp $PIP_CONFIG $DISTUTILS/
fi

export "WINEPREFIX=${FLAGS_prefix}"
wine regedit $ENV_REG

if [ -f $SOURCE_DIR/requirements.txt ]; then
	if cat $SOURCE_DIR/requirements.txt | grep lxml; then
		cd $INSTALLERS_DIR
		wine $EASY_INSTALL lxml‑3.3.3.win32‑py2.7.exe
	fi

	cd $SOURCE_DIR
	cat requirements.txt | grep -v lxml > requirements_nolxml.txt
	wine $PIP install -r requirements_nolxml.txt
	rm requirements_nolxml.txt
fi

wine $PYINSTALLER $O -n ${FLAGS_project} --distpath=$DIST_DIR  \
	--workpath=$BUILD_DIR $(winepath -w $SOURCE_DIR/${SOURCE_FILE})

exit 0

