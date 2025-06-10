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

// Put these into classes later
double totalBuyQty = 0.0;
double totalSellQty = 0.0;

double bestBid = 0.0;
double bestAsk = std::numeric_limits<double>::max();


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
    std::vector<TradeObjects_t> trades;
    constexpr int BUFFER_DELAY = 5;
    std::deque<TradeObjects_t> tradeBuffer;

    std::ofstream out("parsed_output.txt");
    int id_counter = 1;
    while (std::getline(file, line))
    {
        auto parts = split(line, delim);
        if(parts.size() < 4) continue;
    
        TradeObjects_t trade;
        trade.timestamp = parts[0];
        trade.side = parts[1];
        trade.quantity = std::stod(parts[2]);
        trade.price = std::stod(parts[3]);
        trade.id = id_counter++;

        tradeBuffer.push_back(trade);

        // Simulate a trade buffer using queue/dequeue
        if (tradeBuffer.size() >= BUFFER_DELAY)
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
        }


    // out << "Trade ID: " << trade.id << "\n"
    //     << "Timestamp: " << trade.timestamp << "\n"
    //     << "Side:      " << trade.side      << "\n"
    //     << "Quantity:  " << trade.quantity  << "\n"
    //     << "Price:     " << trade.price     << "\n";


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

        out << "Trade ID: " << delayedTrade.id << "\n"
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