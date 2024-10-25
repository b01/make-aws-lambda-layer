#!/bin/sh

# Copyright 2024 Khalifah K. Shabazz
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the “Software”),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

set -e

usage="
Build and upload a AWS Lambda Layer. Defaults to NodeJS because that is what I used when I first wrote this.

make-lambda-layer.sh [OPTIONS] <LAYER_NAME> <PACKAGE> [PACKAGE]...

Example:
  make-lambda-layer.sh --runtime \"python\" \"python312_aws_cdk\" \"boto3 aws-cdk-lib\"

Options

-d|--description
    Short description for the layer. (default: Auto generated lambda layer).

--license
    License for the code bundled in the layer. (default: MIT).

-p,--prefix
    Working directory to build the package up (default: ./lambda-layer).
    Will be made if it does not exist.

-r,--runtime
    Lamda runtime to use to download dependencies. Only (node|python) are
    supported (default: nodejs).

-h, --help
    Print this usage info.
"

# For details see:
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
getopt --test > /dev/null && true
if [ $? -ne 4 ]; then
    echo 'sorry, getopts --test` failed in this environment'
    exit 1
fi


# Set defaults
export prefix="./lambda-layer"
export description="Auto generated lambda layer"
export license="MIT"
export runtime="nodejs"

# Options with a colon must provide a value
LONG_OPTS=dir:description:,help,license:, prefix:,runtime:
OPTIONS=d:,h,-p:,r:

# Standardize options and arguments
PARSED=$(getopt --options=${OPTIONS} --longoptions=${LONG_OPTS} --name "$0" -- "${@}") || exit 1
eval set -- "${PARSED}"

# Process options
while true; do
    case "${1}" in
        -p|--prefix)
            prefix="${2}"
            shift 2
            ;;
        -d|--description)
            description="${2}"
            shift 2
            ;;
        --license)
            license="${2}"
            shift 2
            ;;
        -r|--runtime)
            runtime="${2}"
            shift 2
            ;;
        -h|--help)
            echo "${usage}"
            exit 0
            ;;
        --) shift; break;;
        *) echo "unknown option \"${1}\""; exit 1;;
    esac
done

# Process arguments
export layer_name="${1}"
export modules="${2}"

if [ "${layer_name}" = "" ]; then
  echo "please enter the name to call your layer"
  exit 1
elif [ "${modules}" = "" ]; then
  echo "please enter the name or names of a module or modules (separated by a space)."
  exit 1
fi

# Begin building the layer

dir_name="${prefix}/${runtime}"

mkdir -p "${dir_name}"

cd "${dir_name}"

echo "working dir $(pwd)"

# Download dependencies
if [ "${runtime}" = "nodejs" ]; then
    if ! which npm; then
        echo "npm is not installed, exiting with 1"
        exit 1
    fi
    run_cmd="npm install ${modules}"
    ${run_cmd}
fi

if [ "${runtime}" = "python" ]; then
    run_cmd="pip install ${modules}"
    ${run_cmd}
fi

# Move a level up from where the deps
cd ..

echo "basename dir = ${runtime}"

# Upload Lambda layer
zip -rq ../package.zip "${runtime}"

aws lambda publish-layer-version \
    --layer-name "${layer_name}" \
    --description "${description}" \
    --license-info "${license}" \
    --compatible-runtimes \
    --zip-file fileb://../package.zip

exit 0