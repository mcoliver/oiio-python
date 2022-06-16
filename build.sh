set -ex
OIIO_VERSION="2.3.16.0"
BOOST_VERSION="1_76_0"
BOOST_VER_DOT="1.7.6"

sudo yum install -y libjpeg-turbo-devel zlib-devel libpng-devel libtiff-devel OpenEXR-devel LibRaw-devel cmake3


# -I/usr/local/include/python3.9m -I/usr/local/include/python3.9m
# -lpython3.9m -lcrypt -lpthread -ldl  -lutil -lm

export CPLUS_INCLUDE_PATH="$CPLUS_INCLUDE_PATH:/usr/local/include/python3.9m"
export CPATH="$CPATH:/usr/include:/usr/local/include"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/lib:/usr/lib64:/usr/local/lib:/usr/local/lib64"
if [ ! -f boost_${BOOST_VERSION}.tar.gz ]; then
    wget https://boostorg.jfrog.io/artifactory/main/release/${BOOST_VER_DOT}/source/boost_${BOOST_VERSION}.tar.gz
fi
if [ ! -d boost_${BOOST_VERSION} ]; then
    tar -xzf boost_${BOOST_VERSION}.tar.gz
fi
if [ ! -d /opt/boost ]; then
   sudo mkdir /opt/boost
    sud o chmod -R 777 /opt/boost
fi
cd boost_${BOOST_VERSION}
sudo ./bootstrap.sh --prefix=/opt/boost
sudo ./b2 install --prefix=/opt/boost --with=all -j4
cd ../

# if [ -d oiio ]; then
#   sudo rm -rf oiio;
# fi
if [ ! -d oiio ]; then
    git clone https://github.com/OpenImageIO/oiio.git
fi
pip3.9 install pybind11[global]
pip3.9 install numpy


cd oiio
git checkout "v${OIIO_VERSION}"
if [ ! -d build ]; then
    mkdir build
fi


bash src/build-scripts/gh-installdeps-centos.bash

cd ../
OPENEXR_CMAKE_FLAGS="-DCMAKE_NO_SYSTEM_FROM_IMPORTED:BOOL=TRUE" oiio/src/build-scripts/build_openexr.bash
export OpenEXR_ROOT="$(pwd)/ext/dist"
echo "OpenEXR_ROOT=${OpenEXR_ROOT}"
cd oiio

sleep 2
echo "Executing cmake"
cd build  && cmake3 .. -DCMAKE_CXX_FLAGS="-Wno-error=unused-variable" -DVERBOSE=1 -DSTOP_ON_WARNING=0 -DBoost_ROOT="/opt/boost" -DOIIO_BUILD_TESTS=0 -DOpenEXR_ROOT="${OpenEXR_ROOT}" -DCMAKE_NO_SYSTEM_FROM_IMPORTED:BOOL="TRUE" -DCMAKE_INSTALL_PREFIX="${OpenEXR_ROOT}"
sleep 2
echo "Make install"
sudo make install

