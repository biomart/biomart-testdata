#!/bin/bash -xe

INPUT_DIR=${1?}
SUFFIX="_test"

for FILE in $(find ${INPUT_DIR?} -maxdepth 1 -type f -name '*'"${SUFFIX?}"'.xml'); do
  NEW_FILE=$(echo ${FILE?} | awk '{gsub(/'"${SUFFIX?}"'\.xml$/,".xml")}1')
  cp ${FILE?} ${NEW_FILE?}
done

