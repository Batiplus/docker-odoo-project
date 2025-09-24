#!/bin/bash
set -euxo pipefail

#
# Build the image
#
# Normally run by the Makefile:
#
#   $ make VERSION=$VERSION build
#
# It expects the following variables to be set:
#
# * VERSION (9.0, 10.0, 11.0, ...)
# * BUILD_TAG (tag of the 'latest' image built)
# * DOCKERFILE (name of the file used for the Docker build)
#
if [ -z "$VERSION" ]; then
    echo "VERSION environment variable is missing"
    exit 1
fi

TMP=$(mktemp -d)
echo "Working in $TMP"

on_exit() {
    echo "Cleaning up temporary directory..."
    rm -rf $TMP
    rm -f /tmp/odoo.tar.gz
}

trap on_exit EXIT

cp -r ${VERSION}/. ${TMP}
cp -r bin ${TMP}
cp -r bin-py2 ${TMP}
# Copy "common" into $TMP in a cross-platform way (GNU/BSD cp)
# Try GNU cp first (-T), fall back to BSD cp syntax
cp -rT common ${TMP} 2>/dev/null || cp -R common/. ${TMP}

cp ${TMP}/Dockerfile-onbuild ${TMP}/Dockerfile-batteries-onbuild
# Prepend FROM lines portably (avoid sed -i differences between GNU/BSD)
{
    printf 'FROM %s\n' "${BUILD_TAG}"
    cat "${TMP}/Dockerfile-onbuild"
} > "${TMP}/.Dockerfile-onbuild.tmp" && mv "${TMP}/.Dockerfile-onbuild.tmp" "${TMP}/Dockerfile-onbuild"

{
    printf 'FROM %s\n' "${BUILD_TAG}"
    cat "${TMP}/Dockerfile-batteries"
} > "${TMP}/.Dockerfile-batteries.tmp" && mv "${TMP}/.Dockerfile-batteries.tmp" "${TMP}/Dockerfile-batteries"

{
    printf 'FROM %s-batteries\n' "${BUILD_TAG}"
    cat "${TMP}/Dockerfile-batteries-onbuild"
} > "${TMP}/.Dockerfile-batteries-onbuild.tmp" && mv "${TMP}/.Dockerfile-batteries-onbuild.tmp" "${TMP}/Dockerfile-batteries-onbuild"
cp -r install ${TMP}
cp -r start-entrypoint.d ${TMP}
cp -r before-migrate-entrypoint.d ${TMP}

docker build --no-cache -f ${TMP}/Dockerfile -t ${BUILD_TAG} ${TMP}
docker build --no-cache -f ${TMP}/Dockerfile-onbuild -t ${BUILD_TAG}-onbuild ${TMP}
docker build --no-cache -f ${TMP}/Dockerfile-batteries -t ${BUILD_TAG}-batteries ${TMP}
docker build --no-cache -f ${TMP}/Dockerfile-batteries-onbuild -t ${BUILD_TAG}-batteries-onbuild ${TMP}
