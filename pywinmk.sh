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
DEFINE_string 'wine-prefix' `echo ~/.wine-pyinstaller` 'the wine prefix to use' 'w' || return $?
DEFINE_string 'defrost' '' 'to restore a previously frozen wine environment, supply the path to the tar.gz file (use -f option to freeze a wine environment' 'D' || return $?
DEFINE_boolean 'freeze' 'false' 'freeze the wine environment (creates wine environment if necessary)' 'f' || return $?
DEFINE_boolean 'spec' 'false' 'use project spec file' 'S' || return $?

# parse the command-line
FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"

# main
BUILD_DIR='win-build'
DIST_DIR='win-dist'
INSTALLERS_DIR='win-installers'

WINE_TARBALL="${FLAGS_dir}/wine.tar.gz"
C="${FLAGS_wine_prefix}/drive_c"
WINE_SCRIPTS=`echo $C/Python*/scripts`
EASY_INSTALL=$(winepath -w $WINE_SCRIPTS/easy_install.exe)
PIP=$(winepath -w $WINE_SCRIPTS/pip.exe)
PYINSTALLER=$(winepath -w $WINE_SCRIPTS/pyinstaller.exe)

export "WINEPREFIX=${FLAGS_wine_prefix}"

cd ${FLAGS_dir}

if [ ${FLAGS_defrost} ]; then
	rm -fr ${FLAGS_wine_prefix}
	mkdir ${FLAGS_wine_prefix}
	cd ${FLAGS_wine_prefix}
	tar -xzf ${FLAGS_defrost}
elif [ ! -d ${FLAGS_wine_prefix} ]; then
	echo "Creating new wine environment"
	wine start $INSTALLERS_DIR/python*.msi
	wine start $INSTALLERS_DIR/pywin32*.exe
	wine $INSTALLERS_DIR/setup*.exe
	wine $EASY_INSTALL pip
	wine $PIP install PyInstaller
fi

if [ ${FLAGS_freeze} -eq ${FLAGS_TRUE} ]; then
	echo "Freezing ${FLAGS_wine_prefix} to $WINE_TARBALL"
	cd ${FLAGS_wine_prefix}
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

