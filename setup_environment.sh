#!/bin/bash
#
# Setup script. Downloads dependencies if they are not already present
# in the current installation.
# Thu Oct 23 22:02:08 CEST 2014

BLUE="[34m"
RED="[31m"
BLACK="(B[m"

QPACKAGE_ROOT=${PWD}

if [[ -z ${IRPF90} ]] ;
then
    make irpf90
    IRPF90=${QPACKAGE_ROOT}/bin/irpf90
    if [[ ! -x ${IRPF90} ]]
    then
      echo $RED "Error in IRPF90 installation" $BLACK
      exit 1
    fi
fi


cat << EOF > quantum_package.rc
export IRPF90=${IRPF90}
export QPACKAGE_ROOT=${QPACKAGE_ROOT}
export PYTHONPATH=\${PYTHONPATH}:\${QPACKAGE_ROOT}/scripts
export PATH=\${PATH}:\${QPACKAGE_ROOT}/scripts
export PATH=\${PATH}:\${QPACKAGE_ROOT}/bin
export QPACKAGE_CACHE_URL="http://qmcchem.ups-tlse.fr/files/scemama/quantum_package/cache"
source \${QPACKAGE_ROOT}/bin/irpman > /dev/null
EOF

source quantum_package.rc
make EZFIO
if [[ ! -d ${QPACKAGE_ROOT}/EZFIO ]]
then
  echo $RED "Error in IRPF90 installation" $BLACK
  exit 1
fi

make ocaml
if [[ ! -f ${QPACKAGE_ROOT}/ocaml/Qptypes.ml ]]
then
  echo $RED "Error in ocaml installation" $BLACK
  exit 1
fi

echo $RED "
=======================================================
To complete the installation, add the following line to
your ~/.bashrc:

source quantum_package.rc

=======================================================
" $BLACK

