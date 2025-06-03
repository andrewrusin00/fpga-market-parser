#include <iostream>
#include <fstream>
#include <string>
#include <cstdint>
#include <vector>
#include <sstream>

std::vector<std::string> split(const std::string& s, char delim)
{
    std::vector<std::string> elems;
    std::istringstream iss(s);
    std::string item;
    while(std::getline(iss, item, delim))
    {
        elems.push_back(item);
    }

    return elems;
}

struct TradeObjects_t{
    std::string timestamp;
    std::string side;
    std::string quantity;
    std::string price;
};

TradeObjects_t catagories = {"None", "None", "0.0","0.0"};
    