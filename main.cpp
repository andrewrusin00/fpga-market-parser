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


std::deque<TradeObjects_t> fifo;
std::mutex fifoMutex;
std::condition_variable fifoCondition;
constexpr int BUFFER_DELAY = 5;

void producer()
{

    // Put these into classes later
    double totalBuyQty = 0.0;
    double totalSellQty = 0.0;

    double bestBid = 0.0;
    double bestAsk = std::numeric_limits<double>::max();

    int id_counter = 1;
    std::deque<TradeObjects_t> tradeBuffer;
    char delim = ',';
    std::ifstream file("data/sample_feed.txt");
    std::string line;

    if(!file) return;

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

        // Simulate a trade buffer using queue/dequeue
        if (tradeBuffer.size() > BUFFER_DELAY)
        {
            auto delayedTrade = tradeBuffer.front();
            tradeBuffer.pop_front();

            // Measure and log latency
            delayedTrade.latency_us = std::chrono::duration_cast<
                                        std::chrono::microseconds>(
                                            std::chrono::high_resolution_clock::now() 
                                            - delayedTrade.arrivalTime
                                        ).count();
            
            {
                std::lock_guard<std::mutex> lock(fifoMutex);
                fifo.push_back(delayedTrade);
            }
            fifoCondition.notify_one();
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(100));         
    }

    while (!tradeBuffer.empty()) 
    {
    auto dt = tradeBuffer.front();
    tradeBuffer.pop_front();
    dt.latency_us = 0; 
        {
            std::lock_guard<std::mutex> lock(fifoMutex);
            fifo.push_back(dt);
        }
        fifoCondition.notify_one();
    }    

    {
        TradeObjects_t sentinel{};
        sentinel.id = 0;
        std::lock_guard<std::mutex> lock(fifoMutex);
        fifo.push_back(sentinel);
    }

    fifoCondition.notify_one();
}

void consumer()
{
    std::ofstream out("parsed_output.txt");

    while(true)
    {
        std::unique_lock<std::mutex> lock(fifoMutex);
        fifoCondition.wait(lock, []{return !fifo.empty();});
        auto t = fifo.front();
        fifo.pop_front();
        lock.unlock();

        if (t.id == 0) break;

        out << "Trade ID: " << t.id << "\n"
            << "Latency: " << t.latency_us << "\n"
            << "Timestamp: " << t.timestamp << "\n"
            << "Side:      " << t.side      << "\n"
            << "Quantity:  " << t.quantity  << "\n"
            << "Price:     " << t.price     << "\n";
    }
}


int main()
{
    
    std::thread prod(producer);
    std::thread cons(consumer);
    prod.join();
    cons.join();
    return 0;
}