#pragma once

#include <iostream>
#include <fstream>
#include <string>
#include <cstdint>
#include <vector>
#include <sstream>
#include <limits>
#include <queue>

struct TradeObjects_t{
    int id;
    std::string timestamp;
    std::string side;
    double quantity;
    double price;
};

std::vector<std::string> split(const std::string& s, char delim);
std::vector<TradeObjects_t> trades;



    