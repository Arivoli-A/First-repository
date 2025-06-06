#!/bin/bash

set -e

if [ `id -u` == 0 ]; then
    export SUDO=
    export DEBIAN_FRONTEND=noninteractive
    export PIP_ARGS= #--break-system-packages
else
    SUDO="sudo -H"
fi

install_common_dependencies()
{
    # install most dependencies via apt-get
    ${SUDO} apt-get -y update && \
    ${SUDO} apt-get -y install \
        clang \
        cmake \
        libboost-filesystem-dev \
        libboost-program-options-dev \
        libboost-serialization-dev \
        libboost-system-dev \
        libboost-test-dev \
        libeigen3-dev \
        libexpat1 \
        libtriangle-dev \
        ninja-build \
        pkg-config \
        wget
    export CXX=clang++
}

install_python_binding_dependencies()
{
    ${SUDO} apt-get -y install \
        castxml \
        libboost-numpy-dev \
        libboost-python-dev \
        python3-celery \
        python3-dev \
        python3-flask \
        python3-numpy \
        python3-opengl \
        python3-pip \
        python3-pyqt5.qtopengl \
        pypy3 \
        wget && \
        # install additional python dependencies via pip
        ${SUDO} pip3 install ${PIP_ARGS} -vU https://github.com/CastXML/pygccxml/archive/develop.zip pyplusplus
}

install_app_dependencies()
{
    ${SUDO} apt-get -y install \
        freeglut3-dev \
        libassimp-dev \
        libccd-dev \
        libfcl-dev
}

install_ompl()
{
    if [ -z $APP ]; then
        wget -O - https://github.com/ompl/ompl/archive/1.7.0.tar.gz | tar zxf -
        cd ompl-1.7.0
    else
        wget -O - https://github.com/ompl/omplapp/releases/download/1.7.0/omplapp-1.7.0-Source.tar.gz | tar zxf -
        cd omplapp-1.7.0-Source
    fi
    cmake \
        -G Ninja \
        -B build \
        -DPYTHON_EXEC=/usr/bin/python3 \
        -DOMPL_REGISTRATION=OFF \
        -DCMAKE_INSTALL_PREFIX=/usr && \
    cmake --build build -t update_bindings && \
    cmake --build build && \
    ${SUDO} cmake --install build
}

for i in "$@"
do
case $i in
    -a|--app)
        APP=1
        PYTHON=1
        shift
        ;;
    -p|--python)
        PYTHON=1
        shift
        ;;
    *)
        # unknown option -> show help
        echo "Usage: `basename $0` [-p] [-a]"
        echo "  -p: enable Python bindings"
        echo "  -a: enable OMPL.app (implies '-p')"
        echo "  -g: install latest commit from main branch on GitHub"
    ;;
esac
done

install_common_dependencies
if [ ! -z $PYTHON ]; then
    install_python_binding_dependencies
fi
if [ ! -z $APP ]; then
    install_app_dependencies
fi
install_ompl
