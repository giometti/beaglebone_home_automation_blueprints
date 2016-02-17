#!/bin/bash

BIN="../bin"

set -e

$BIN/load_firmware.sh UART1
$BIN/load_firmware.sh UART2

echo "done!"

exit 0
