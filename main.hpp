#include <iostream>
#include <fstream>
#include <string>
#include <cstdint>

typedef struct {
    uint16_t timestamp,
    side,
    quantity,
    price;
}TradeObjects_t;

volatile TradeObjects_t tradeobjects = {0,0,0,0};
    