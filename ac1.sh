#!/bin/bash

# See https://github.com/sftcd/anonymise-column1 for updates.
# There is a README.md there for usage.
#
# MIT License
#
# Copyright(c) 2024 Stephen Farrell
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# set -x

OSSL=`which openssl`
if [[ "$OSSL" == "" ]]
then
    echo "You need to install openssl first."
    exit 1
fi
XXD=`which xxd`
if [[ "$XXD" == "" ]]
then
    echo "You need to install xxd first"
    exit 2
fi

# you can set this in the environment
: ${AC1_SECRET:=""}

# or if not, we'll prompt you for it
if [[ "$AC1_SECRET" == "" ]]
then
    # ask for secret
    echo "Please provide a secret:"
    read -s AC1_SECRET </dev/tty
fi
if [[ "$AC1_SECRET" == "" ]]
then
    echo "Can't run without a non-blank secret"
    exit 3
fi

# In any case, we'll use the ascii-hex of the secret to
# keep openssl happy
hexsecret=`echo -n $AC1_SECRET | $XXD -ps -c200`

# keyed-hash function
kh(){
    line=$1
    rest=`echo $line | cut -d',' -f2-`
    oval=`echo $line | cut -d',' -f1 \
          | $OSSL dgst -sha256 -mac hmac -macopt hexkey:$hexsecret \
          | awk '{print substr($2,1,8)}'`
    echo $oval","$rest
}

# read input CSV, output 1st line as header
# then rest as keyed-hashed of col1 followed
# by other cols
firstline=1
while read line
do
    if [[ $firstline == 1 ]]
    then
        echo $line
        firstline=0
    else
        kh "$line"
    fi
done < "${1:-/dev/stdin}" # read from stdin or a supplied filename

