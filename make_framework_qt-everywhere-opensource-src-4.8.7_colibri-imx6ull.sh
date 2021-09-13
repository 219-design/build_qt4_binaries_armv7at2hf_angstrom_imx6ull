#!/bin/bash

#
# Copyright (c) 2021, 219 Design, LLC
# See LICENSE.txt
#
# https://www.219design.com
# Software | Electrical | Mechanical | Product Design
#

set -Eeuxo pipefail # https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/

# Tested on Ubuntu 18.04 as of Sept 2021.

echo "Reading first argument. Directory into which to download the Qt framework."
WORK_DIR=$1
shift 1

echo "Reading second argument. Installation directory."
INSTALL_PREFIX_DIR=$1
shift 1

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

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

if [ -f ${WORK_DIR}/qt-everywhere-opensource-src-4.8.7.tar.gz ]; then
  echo "Qt sources were already downloaded. Will NOT download again."
else
  wget https://download.qt.io/archive/qt/4.8/4.8.7/qt-everywhere-opensource-src-4.8.7.tar.gz
fi

if [ -d ${WORK_DIR}/qt-everywhere-opensource-src-4.8.7/ ]; then
  echo "Qt sources were already extracted. Will NOT extract again."
else
  tar xvfz qt-everywhere-opensource-src-4.8.7.tar.gz

  echo "QMAKE_INCDIR += ${LEGACY_TSLIB_DIR}/include" >> qt-everywhere-opensource-src-4.8.7/mkspecs/qws/linux-arm-g++/qmake.conf
  echo "QMAKE_LIBDIR += ${LEGACY_TSLIB_DIR}/lib" >> qt-everywhere-opensource-src-4.8.7/mkspecs/qws/linux-arm-g++/qmake.conf

  # This patch was needed for the armv5tejl_sbc6000x legacy platform,
  # so we use it on the desktop just to foster consistency:
  patch ${WORK_DIR}/qt-everywhere-opensource-src-4.8.7/src/corelib/thread/qthread_unix.cpp "${THISDIR}"/no_thread_tls.patch
fi

mkdir -p ${WORK_DIR}/build
pushd build/

  export CFLAGS=-std=c99 CXXFLAGS=-std=gnu++98

  # print 'o' to accept open source license agreement
  # (Note: the -v flag can be supplied more than once, like: -v -v -v)
  printf 'o\nyes\n' | ../qt-everywhere-opensource-src-4.8.7/configure \
      -v \
      -prefix ${INSTALL_PREFIX_DIR} \
      -embedded arm \
      -xplatform qws/linux-arm-g++ \
      -little-endian \
      -qt-gfx-transformed \
      -qt-gfx-linuxfb \
      -lrt \
      -no-feature-CURSOR \
      -qt-libjpeg \
      -qt-libpng \
      -qt-libtiff \
      -qt-mouse-tslib \
      -qt-zlib \
      -no-cups \
      -no-icu \
      -no-pch \
      -no-declarative \
      -no-declarative-debug \
      -no-freetype \
      -no-javascript-jit \
      -no-openssl \
      -no-script \
      -no-scripttools \
      -no-sql-ibase \
      -no-sql-mysql \
      -no-sql-odbc \
      -no-sql-psql \
      -no-sql-sqlite \
      -no-sql-sqlite2 \
      -no-qt3support \
      -no-webkit \
      -nomake tools \
      -nomake examples \
      -nomake demos \
      -nomake docs \
      -nomake translations

  make -j6
  make install

popd # corresponds to: pushd build/

popd # corresponds to: pushd ${WORK_DIR}/
