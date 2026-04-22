#!/bin/bash
cd /home/z/my-project/hermes-home
exec python3 -u test_100_v2.py >> /home/z/my-project/hermes-home/test_100_output.txt 2>&1
