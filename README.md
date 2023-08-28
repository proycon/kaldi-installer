# Kaldi installer

This is an installation script for installing
[kaldi](https://github.com/kaldi-asr/kaldi) and
[kaldi_NL](https://github.com/opensource-spraakherkenning-nl/Kaldi_NL/) on
Debian/Ubuntu systems; intended primarily for the ponyland servers at Radboud
University Nijmegen.

Usage of this script is only intended for developers or whom the provides containers are not sufficient.
Most users should just use the OCI/Docker container solution provided by Kaldi_NL and do not need this script!

## Usage

After cloning this repository, you can install Kaldi and Kaldi_NL using:

``./install.sh -p /some/destination/path/``

The destination path will be your `KALDI_ROOT`, see `./install.sh -h` for more usage instructions.
