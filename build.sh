#!/bin/sh -ex
docker build -t 9pkernel-done .
docker cp $(docker create 9pkernel-done):/root/9pboot.iso .
