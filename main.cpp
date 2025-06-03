#include "main.hpp"


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

    while (std::getline(file, line))
    {
        std::cout << "Read line: " <<  line << '\n';
        auto parts = split(line, delim);
        if(parts.size() < 4) 
        {
            std::cerr << "Bad line: " << line << "\n";
            continue;
        }

        catagories.timestamp = parts[0];
        catagories.side = parts[1];
        catagories.quantity= parts[2];
        catagories.price = parts[3];

    std::cout << "Timestamp: " << catagories.timestamp << "\n"
              << "Side:      " << catagories.side      << "\n"
              << "Quantity:  " << catagories.quantity  << "\n"
              << "Price:     " << catagories.price     << "\n";

    }

    return 0;
}