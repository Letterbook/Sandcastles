#! /bin/bash

CA_FINGERPRINT=$(docker --log-level ERROR compose --progress quiet run --rm --quiet-pull fingerprint)
step ca bootstrap --ca-url https://root-ca.castle:9000 --fingerprint $CA_FINGERPRINT --install