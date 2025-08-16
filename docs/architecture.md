# VirtuSoC-DSP: Архитектура SoC

## 1. Обзор
**VirtuSoC-DSP** — учебно-исследовательский SoC на базе **RISC-V** с аппаратным **DSP-ускорителем FIR**. Проект предназначен для полностью программной верификации без FPGA: RTL-симуляция (Verilator), системная эмуляция (Renode/QEMU), ко-симуляция с Matlab/Simulink.

Цели:
- показать типовой паттерн интеграции аппаратного DSP в SoC (управление по AXI4-Lite, поток данных по AXI4-Stream, перенос через DMA);
- дать воспроизводимую среду для функциональной верификации и оценки пропускной способности.

## 2. Блок-схема (высокий уровень)

```mermaid
flowchart LR
  subgraph SW["ПО (C/RTOS/Linux)"]
    APP["DSP App"] -->|MMIO| DIF["DIF/Driver"]
  end

  subgraph SoC["VirtuSoC-DSP (RISC-V SoC)"]
    CPU["RISC-V CPU (RV32IMC)"]
    IC["AXI Interconnect"]
    SRAM["SRAM"]
    UART["UART"]
    TIMER["CLINT/Timer"]
    PLIC["PLIC"]
    DMA["DMA (AXI4-Lite ctl, AXI4 data)"]
    DSP["FIR Accelerator (AXI4-Lite ctl, AXI4-Stream data)"]
  end

  APP --> DIF
  DIF -->|AXI4-Lite| IC
  CPU -->|I/D AXI| IC
  IC --> SRAM
  IC --> UART
  IC --> TIMER
  IC --> PLIC
  IC --> DMA
  IC -->|Ctl| DSP
  DMA <-->|AXI4 Mem| IC
  DMA -->|AXI4-Stream| DSP
  DSP -->|IRQ| PLIC
  ```

## 3  Состав и интерфейсы

CPU: RISC-V RV32IMC, 3–5 стадий, little-endian.

Память: on-chip SRAM + «переферийное» окно MMIO.

Интерконнект: AXI4 для памяти, AXI4-Lite для регистров.

DMA: memory-to-stream / stream-to-memory, управляется CPU по AXI4-Lite, данные по AXI4 или AXI4-Stream.

DSP-ускоритель (FIR): управление по AXI4-Lite, вход/выход — AXI4-Stream.

Прерывания: от DSP и DMA на PLIC (Platform-Level Interrupt Controller). 
Five EmbedDev
courses.grainger.illinois.edu

Таймер/системные таймауты: CLINT/Timer.

UART: консоль и логирование.

