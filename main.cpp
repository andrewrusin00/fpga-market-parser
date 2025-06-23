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

// The producer takes in the data and parses through and storing
// it for the consumer to use. Also simulates a buffer
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
    dt.latency_us = std::chrono::duration_cast<
                                std::chrono::microseconds>(
                                std::chrono::high_resolution_clock::now() 
                                - dt.arrivalTime
                                ).count(); 
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

// Consumer function which takes in the parsing and writes to an output
// ready for a trading algorithm to use
void consumer()
{
    std::ofstream out("parsed_output.txt");
    std::vector<long long> latencies;

    while(true)
    {
        std::unique_lock<std::mutex> lock(fifoMutex);
        fifoCondition.wait(lock, []{return !fifo.empty();});
        auto t = fifo.front();
        fifo.pop_front();
        lock.unlock();

        if (t.id == 0) break;

        latencies.push_back(t.latency_us);

        out << "Trade ID: " << t.id << "\n"
            << "Latency: " << t.latency_us << "\n"
            << "Timestamp: " << t.timestamp << "\n"
            << "Side:      " << t.side      << "\n"
            << "Quantity:  " << t.quantity  << "\n"
            << "Price:     " << t.price     << "\n";
    }

    auto [minIt, maxIt] = std::minmax_element(latencies.begin(), latencies.end());
    long long sum = std::accumulate(latencies.begin(), latencies.end(), 0LL);
    double avg = static_cast<double>(sum) / latencies.size();

    double totalTime_sec = sum / 1'000'000.0;
    double throughput = latencies.size() / totalTime_sec;

    out
        << "\nMin Latency: " << *minIt  << " µs\n"
        << "Max Latency: " << *maxIt  << " µs\n"
        << "Avg Latency: " << avg     << " µs\n"
        << "Throughput:  " << throughput << " trades/sec\n";
}


int main()
{
    std::thread prod(producer);
    std::thread cons(consumer);
    prod.join();
    cons.join();
    return 0;
}