#!/bin/sh -u
# summary: Uses Pyinstaller and Wine to package Python scripts into standalone
# Windows executables
#
# usage: pywinmk [options] <project>
#
# sudo port install wine

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
DEFINE_boolean 'spec' 'false' 'use project pyinstaller spec file' 'S' || return $?

# parse the command-line
FLAGS "$@" || exit 1
[ ${FLAGS_help} -eq ${FLAGS_FALSE} ] || exit
eval set -- "${FLAGS_ARGV}"

# main
BUILD_DIR='win-build'
DIST_DIR='win-dist'
export "WINEPREFIX=${FLAGS_prefix}"
INSTALLERS_DIR="$(dirname $0)/win-installers"

WINE_TARBALL="${FLAGS_dir}/wine.tar.gz"
C="${FLAGS_prefix}/drive_c"
WINE_SCRIPTS=`echo $C/Python*/scripts`
EASY_INSTALL=$(winepath -w $WINE_SCRIPTS/easy_install.exe)
PIP=$(winepath -w $WINE_SCRIPTS/pip.exe)
PYINSTALLER=$(winepath -w $WINE_SCRIPTS/pyinstaller.exe)

cd ${FLAGS_dir}

if [ ${FLAGS_thaw} ]; then
	rm -fr ${FLAGS_prefix}
	mkdir ${FLAGS_prefix}
	cd ${FLAGS_prefix}
	tar -xzf ${FLAGS_thaw}
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
ln -s ${FLAGS_dir} $C/${FLAGS_project}
SOURCE_DIR="$C/${FLAGS_project}"

# Create hard link for missing msvcp90.dll
ln $C/windows/system32/msvcp90.dll $C/Python*/msvcp90.dll

if [ ${FLAGS_spec} -eq ${FLAGS_TRUE} ]; then
	wine $PYINSTALLER -Fn ${FLAGS_project} --distpath=$DIST_DIR \
		--workpath=$BUILD_DIR $(winepath -w ${SOURCE_DIR}/${FLAGS_project}.spec)
else
	wine $PYINSTALLER -Fn ${FLAGS_project} --distpath=$DIST_DIR  \
		--workpath=$BUILD_DIR $(winepath -w $SOURCE_DIR/${FLAGS_script})
fi

exit 0

