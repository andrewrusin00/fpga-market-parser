#include "main.hpp"

int main()
{
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
    }

    return 0;
}