#pragma once

#include <iostream>
#include <fstream>
#include <string>
#include <cstdint>
#include <vector>
#include <sstream>
#include <limits>
#include <deque>
#include <queue>
#include <chrono>
#include <thread>
#include <mutex>
#include <condition_variable>

struct TradeObjects_t{
    int id;
    std::string timestamp;
    std::string side;
    double quantity;
    double price;
    std::chrono::high_resolution_clock::time_point arrivalTime;
    uint64_t latency_us;
};

std::vector<std::string> split(const std::string& s, char delim);

void producer();
void consumer();


    