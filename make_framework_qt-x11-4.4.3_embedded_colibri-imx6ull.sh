#!/bin/bash

#
# Copyright (c) 2021, 219 Design, LLC
# See LICENSE.txt
#
# https://www.219design.com
# Software | Electrical | Mechanical | Product Design
#

set -Eeuxo pipefail # https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/

# Tested on Ubuntu 18.04 as of Aug 2021.

echo "Reading first argument. Directory into which to download the Qt framework."
WORK_DIR=$1
shift 1

echo "Reading second argument. Installation directory."
INSTALL_PREFIX_DIR=$1
shift 1

LEGACY_DIR=/opt/legacy_qt
LEGACY_TSLIB_DIR="${LEGACY_DIR}/qtarm_colibri-imx6ull/tslib-1.1/"
CROSSTOOLS="/usr/local/oecore-x86_64/environment-setup-armv7at2hf-neon-angstrom-linux-gnueabi"

if [[ ! -f ${CROSSTOOLS} ]]; then
  echo "Oops. This is bound to fail until you install ${CROSSTOOLS}"
  exit 1
fi

if [[ ! -d ${LEGACY_TSLIB_DIR} ]]; then
  echo "Oops. This is bound to fail until you install ${LEGACY_TSLIB_DIR}"
  exit 1
fi

export PATH="/usr/local/oecore-x86_64/sysroots/x86_64-angstromsdk-linux/usr/bin/arm-angstrom-linux-gnueabi:${PATH}"

pushd ${WORK_DIR}/

if [ -f ${WORK_DIR}/qt-embedded-linux-opensource-src-4.4.3.tar.gz ]; then
  echo "Qt sources were already downloaded. Will NOT download again."
else
  wget https://download.qt.io/archive/qt/4.4/qt-embedded-linux-opensource-src-4.4.3.tar.gz
fi

if [ -d ${WORK_DIR}/qt-embedded-linux-opensource-src-4.4.3/ ]; then
  echo "Qt sources were already extracted. Will NOT extract again."
else
  tar xvfz qt-embedded-linux-opensource-src-4.4.3.tar.gz

  echo "QMAKE_INCDIR += ${LEGACY_TSLIB_DIR}/include" >> qt-embedded-linux-opensource-src-4.4.3/mkspecs/qws/linux-arm-g++/qmake.conf
  echo "QMAKE_LIBDIR += ${LEGACY_TSLIB_DIR}/lib" >> qt-embedded-linux-opensource-src-4.4.3/mkspecs/qws/linux-arm-g++/qmake.conf
fi

# when we run Qt's configure, it ends up looking for 'src/' one dir up, so link it:
ln -sf qt-embedded-linux-opensource-src-4.4.3/src .

mkdir -p ${WORK_DIR}/build
pushd build/

  export CFLAGS=-std=c99 CXXFLAGS=-std=gnu++98

  # echo 'yes' to accept license agreement.
  # (Note: the -v flag can be supplied more than once, like: -v -v -v)
  echo yes | ../qt-embedded-linux-opensource-src-4.4.3/configure \
      -v \
      -prefix ${INSTALL_PREFIX_DIR} \
      -embedded arm \
      -xplatform qws/linux-arm-g++ \
      -little-endian \
      -qt-gfx-transformed \
      -qt-gfx-linuxfb \
      -lrt \
      -no-feature-CURSOR \
      -qt-gif \
      -qt-libjpeg \
      -qt-libpng \
      -qt-libtiff \
      -qt-mouse-tslib \
      -qt-zlib \
      -no-openssl \
      -no-cups \
      -no-sql-odbc \
      -no-sql-mysql \
      -no-sql-sqlite \
      -no-sql-ibase \
      -no-sql-psql \
      -no-sql-sqlite \
      -no-sql-sqlite2 \
      -no-qt3support \
      -no-webkit \
      -no-assistant-webkit \
      -nomake tools \
      -nomake examples \
      -nomake demos \
      -nomake docs \
      -nomake translations

  make -j6
  make install

popd # corresponds to: pushd build/

popd # corresponds to: pushd ${WORK_DIR}/
