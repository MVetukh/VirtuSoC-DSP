#include "Vtop.h"
#include "verilated.h"
#include <iostream>

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtop* top = new Vtop;

    // Инициализируем такт
    top->clk = 0;
    const int cycles = 10;

    for (int i = 0; i < cycles; ++i) {
        // Поднимаем фронт
        top->clk = 1;
        top->eval();

        // Сброс фронта
        top->clk = 0;
        top->eval();
    }

    std::cout << "Sim done\n";
    delete top;
    return 0;
}
