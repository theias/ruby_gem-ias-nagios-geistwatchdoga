#!/bin/bash

rm -rf build

rm -r \
ias-*.tar.gz \
ruby-*.debian.tar.xz \
ruby-*.dsc \
ruby-*.deb \
ruby-*amd64.changes \
ruby-*.orig.tar.gz \
ruby-*-0.1.0

rm Gemfile.lock
