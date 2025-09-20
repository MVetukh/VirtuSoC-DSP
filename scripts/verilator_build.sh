#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"/.. || exit 1

echo "==> Running Verilator build script"

# Проверить наличие папки sim
if [ ! -d sim ]; then
  echo "No sim/ directory found. Create sim/ and add your top.sv and sim_main.cpp"
  exit 2
fi

# Проверим, установлен ли verilator
if ! command -v verilator >/dev/null 2>&1; then
  echo "Verilator not found in PATH. Install Verilator or run this script inside WSL where it's installed."
  exit 3
fi

# Указать имя top-модуля и файлы (при необходимости измените)
TOP_SV="sim/top.sv"
TB_CPP="sim/sim_main.cpp"

if [ ! -f "$TOP_SV" ]; then
  echo "Top SystemVerilog file not found: $TOP_SV"
  exit 4
fi
if [ ! -f "$TB_CPP" ]; then
  echo "Testbench C++ file not found: $TB_CPP"
  exit 5
fi

# Очистка старых артефактов
rm -rf obj_dir build_verilator || true
mkdir -p build_verilator

# Запуск Verilator
echo "Invoking verilator..."
verilator -Wall --cc "$TOP_SV" --exe "$TB_CPP" -Mdir build_verilator

# Собрать C++ сгенерированный проект (Makefile создаётся в build_verilator)
echo "Building simulation binary..."
make -C build_verilator -f Vtop.mk -j$(nproc) || { echo "Build failed"; exit 6; }

# Запустить бинарник (если он создан)
SIM_BIN="build_verilator/Vtop"
if [ -x "$SIM_BIN" ]; then
  echo "Running simulation binary..."
  ./"$SIM_BIN" || { echo "Simulation returned non-zero"; exit 7; }
else
  echo "Simulation binary not found at $SIM_BIN"
  exit 8
fi

echo "Simulation finished successfully."
