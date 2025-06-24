# fpga-market-parser
This is a personal project. I have always been interested in Finance, and even almost switched to Finance my first year of university. I decided not to, but my interest still lingered. When I found out there are FPGA engineers in quant firms, I knew I had to make an attempt to work for one out of college.

The project is a market parser that uses a Basys 3 board. This project includes the use of Git, C++, Python, Verilog, and Vivado

June 23, 2025:
The C++ model is finished, and I am ready to move towards planning and programming the version in Vivado using Verilog. The producer takes in the sample data, where I simulate a delay-buffer with a depth of 5 messages. The feed rate is 1 message per 100 ms (or 10 messages a second). The stats and parsing are written to an output files which contains each trade with the parsed information below. The latency statistics are printed at the very bottom after the 4 trades that are flushed until the end due to the buffer.

To run this, type the following in this order: 
g++ -std=c++17 -o parser main.cpp
./parser
