python3 --version
cocotb-config --version

if [ "$EDATOOL" == "questa" ]; then
  echo "Simulating with Questa"
  make SIM=questa-compat
else
  echo "Simulating with Riviera-PRO"
  make SIM=riviera
fi