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
        
        for (auto& token : parts)
        {    
            std::cout << "[" << token << "]\n";
        
        }
    }

    return 0;
}