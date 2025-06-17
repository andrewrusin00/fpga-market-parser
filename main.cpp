#include "main.hpp"

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

// std::deque<TradeObjects_t> fifo;
// std::mutex fifoMutex;
// std::conditional fifoCondition;
// constexpr int BUFFER_DEPTH = 5;


int main()
{
    char delim = ',';
    std::ifstream file("data/sample_feed.txt");
    std::string line;

    if(!file)
    {
        std::cerr << "Failed to open file.\n";
        return 1;
    }

    constexpr int BUFFER_DELAY = 5;
    std::vector<TradeObjects_t> trades;
    std::deque<TradeObjects_t> tradeBuffer;

    // Put these into classes later
    double totalBuyQty = 0.0;
    double totalSellQty = 0.0;

    double bestBid = 0.0;
    double bestAsk = std::numeric_limits<double>::max();

    std::ofstream out("parsed_output.txt");
    int id_counter = 1;

    while (std::getline(file, line))
    {
        auto parts = split(line, delim);
        if(parts.size() < 4) continue;
    
        TradeObjects_t t;
        t.id = id_counter++;
        t.timestamp = parts[0];
        t.side = parts[1];
        t.quantity = std::stod(parts[2]);
        t.price = std::stod(parts[3]);
        // Stamp the arrival time of the trade
        t.arrivalTime = std::chrono::high_resolution_clock::now();

        tradeBuffer.push_back(t);

        // Simulate real time feed arrival
        std::this_thread::sleep_for(std::chrono::milliseconds(100));

        // Simulate a trade buffer using queue/dequeue
        if (tradeBuffer.size() > BUFFER_DELAY)
        {
            TradeObjects_t delayedTrade = tradeBuffer.front();
            tradeBuffer.pop_front();

            // Measure and log latency
            auto emit_time = std::chrono::high_resolution_clock::now();
            auto latency_us = std::chrono::duration_cast<std::chrono::microseconds>(emit_time - delayedTrade.arrivalTime).count();
            

            if (delayedTrade.side == "BUY")
            {
                totalBuyQty += delayedTrade.quantity;
                if (delayedTrade.price > bestBid)
                {
                    bestBid = delayedTrade.price;
                }
            }
            else if (delayedTrade.side == "SELL")
            {
                totalSellQty += delayedTrade.quantity;
                if (delayedTrade.price < bestAsk)
                {
                    bestAsk = delayedTrade.price;
                }
            }
            
            trades.push_back(delayedTrade);
            out << "Trade ID: " << delayedTrade.id << "\n"
                << "Latency: " << latency_us << "\n"
                << "Timestamp: " << delayedTrade.timestamp << "\n"
                << "Side:      " << delayedTrade.side      << "\n"
                << "Quantity:  " << delayedTrade.quantity  << "\n"
                << "Price:     " << delayedTrade.price     << "\n";
        }
    }
    // Flush the remaining trades in the buffer
    while (!tradeBuffer.empty())
    {
        TradeObjects_t delayedTrade = tradeBuffer.front();
        tradeBuffer.pop_front();

        if (delayedTrade.side == "BUY")
        {
            totalBuyQty += delayedTrade.quantity;
            if (delayedTrade.price > bestBid)
            {
                bestBid = delayedTrade.price;
            }
        }
        else if (delayedTrade.side == "SELL")
        {
            totalSellQty += delayedTrade.quantity;
            if (delayedTrade.price < bestAsk)
            {
                bestAsk = delayedTrade.price;
            }
        }

        trades.push_back(delayedTrade);

        out << "FLUSHED TRADES\n"
            << "Trade ID: " << delayedTrade.id << "\n"
            << "Timestamp: " << delayedTrade.timestamp << "\n"
            << "Side:      " << delayedTrade.side      << "\n"
            << "Quantity:  " << delayedTrade.quantity  << "\n"
            << "Price:     " << delayedTrade.price     << "\n\n";        
    }

    out.close();

    std::cout << "Total BUY Quantity: " << totalBuyQty << "\n";
    std::cout << "Total SELL Quantity: " << totalSellQty << "\n";
    std::cout << "Best BID: " << bestBid << "\n";
    std::cout << "Best ASK: " << bestAsk << "\n";

    return 0;
}