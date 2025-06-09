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

    while (std::getline(file, line))
    {
        std::cout << "Read line: " <<  line << '\n';
        auto parts = split(line, delim);
        if(parts.size() < 4) 
        {
            std::cerr << "Bad line: " << line << "\n";
            continue;
        }
        TradeObjects_t trade;
        trade.timestamp = parts[0];
        trade.side = parts[1];
        trade.quantity = std::stod(parts[2]);
        trade.price = std::stod(parts[3]);

        static int currentID = 1;
        trade.id = currentID++;

        if (trade.side == "BUY")
        {
            totalBuyQty += trade.quantity;
            if (trade.price > bestBid)
            {
                bestBid = trade.price;
            }
        }
        else if (trade.side == "SELL")
        {
            totalSellQty += trade.quantity;
            if(trade.price < bestAsk)
            {
                bestAsk = trade.price;
            }
        }

        trades.push_back(trade);
    
        std::ofstream out("parsed_output.txt");
        for (const auto& trade : trades)
        {
            out << "Trade ID: " << trade.id << "\n"
                << "Timestamp: " << trade.timestamp << "\n"
                << "Side:      " << trade.side      << "\n"
                << "Quantity:  " << trade.quantity  << "\n"
                << "Price:     " << trade.price     << "\n";
        }

    }

    std::cout << "Total BUY Quantity: " << totalBuyQty << "\n";
    std::cout << "Total SELL Quantity: " << totalSellQty << "\n";
    std::cout << "Best BID: " << bestBid << "\n";
    std::cout << "Best ASK: " << bestAsk << "\n";

    return 0;
}