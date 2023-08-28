#!/bin/sh

KALDI_REPO="https://github.com/kaldi-asr/kaldi"
KALDI_BRANCH="master"
KALDI_NL=1
KALDI_NL_REPO="https://github.com/opensource-spraakherkenning-nl/Kaldi_NL"
KALDI_NL_BRANCH="master"
MODELS="utwente radboud_OH radboud_PR radboud_GN"
INSTALL_GLOBAL_DEPS=0

usage() {
    echo "Usage: install.sh [options] -p [path]">&2
    echo "Description: Script to install kaldi (and optionally kaldi_nl), geared towards ponyland servers at Radboud University Nijmegen">&2
    echo "Parameters:">&2
    echo "-p DIR    - Path where everything will be installed, this will be the KALDI_ROOT (mandatory)">&2
    echo "-g        - Attempt to install global dependencies on debian/ubuntu systems (requires root)">&2
    echo "-n        - Do NOT install Kaldi NL (is installed by default)">&2
    echo "-m MODELS - Space separated list of Kaldi NL models to install (default: $MODELS)">&2
    echo "-r REPO   - URL to the kaldi-asr git repo (default: $KALDI_REPO)">&2
    echo "-b BRANCH - kaldi git branch (default: $KALDI_BRANCH)">&2
    echo "-R REPO   - URL to the kaldi-nl git repo (default: $KALDI_NL_REPO)">&2
    echo "-B BRANCH - kaldi-nl git branch (default: $KALDI_NL_BRANCH)">&2
}

die() {
    echo "ERROR: $*" >&2
    exit 2
}

info() {
    echo
    echo "-------------------------------------------------------------------">&2
    echo "$*">&2
    echo "-------------------------------------------------------------------">&2
    echo
}

while getopts "h?p:gr:b:R:B:nm:" opt; do
    # shellcheck disable=SC2154
    case "$opt" in
        h|\?)
            usage
            exit 0
            ;;
        p)
            KALDI_ROOT=$OPTARG
            ;;
        g)
            INSTALL_GLOBAL_DEPS=1
            ;;
        r)
            KALDI_REPO=$OPTARG
            ;;
        b)
            KALDI_BRANCH=$OPTARG
            ;;
        n)
            KALDI_NL=0
            ;;
        R)
            KALDI_NL_REPO=$OPTARG
            ;;
        B)
            KALDI_NL_BRANCH=$OPTARG
            ;;
        m)
            MODELS="$OPTARG"
            ;;
    esac
done

if [ -z "$KALDI_ROOT" ]; then
    usage
    exit 1
fi

if [ -d "$KALDI_ROOT" ]; then
    die "Kaldi root $KALDI_ROOT already exists, refusing to overwrite, delete it first...">&2
fi

if [ "$INSTALL_GLOBAL_DEPS" -eq 1 ]; then
    sudo apt-get install -y --no-install-recommends sox subversion python2.7 libatlas-base-dev liblapack3 liblapacke-dev gfortran time make gcc g++ autoconf automake autoconf-archive || die "global installation failed"
    if [ "$KALDI_NL" -eq 1 ]; then
        sudo apt-get install -y --no-install-recommends python3-numpy default-jre-headless time procps dialog || die "global installation failed"
    fi
fi

info "Downloading kaldi"
git clone --branch "$KALDI_BRANCH" "$KALDI_REPO" "$KALDI_ROOT" || die "git clone failed"
cd "$KALDI_ROOT" || die "expected target directory not created"

info "Compiling and installing kaldi/tools"
cd tools || die "kaldi/tools directory not found"
make -j "$(nproc || echo 1)" || die "kaldi/tools compilation failed"

info "Compiling and installing kaldi/src"
cd ../src || die "kaldi/src directory not found"
./configure --shared --mathlib=ATLAS || die "configure failed"
make -j "$(nproc || echo 1)" || die "kaldi/src compilation failed"
cd .. || die "unable to go back"

if [ "$KALDI_NL" -eq 1 ]; then
    info "Downloading Kaldi_NL"
    git clone --branch "$KALDI_NL_BRANCH" "$KALDI_NL_REPO" "$KALDI_ROOT/Kaldi_NL" || die "git clone failed"
    cd "$KALDI_ROOT/Kaldi_NL" || die "expected target directory not created"

    info "Installing Kaldi_NL"
    export modelpack="$KALDI_ROOT/Kaldi_NL/models"
    # shellcheck disable=SC2086
    ./configure.sh $MODELS || die "Kaldi_NL installation failed"
    cd .. || die "unable to go back"
fi

info "Installation complete"
echo "You may want to add the following to your ~/.bashrc and/or ~/.bash_profile:"
echo "   export KALDI_ROOT=\"$KALDI_ROOT\"" >&2
if [ "$KALDI_NL" -eq 1 ]; then
    echo "Kaldi_NL is in $KALDI_ROOT/Kaldi_NL">&2
    echo "All Kaldi_NL models are under $KALDI_ROOT/Kaldi_NL/models , this is also where you should add your own models">&2
fi
echo "Installation completed succesfully! ">&2
