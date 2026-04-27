#include <iostream>
#include <iomanip>
#include <cmath>

int main()
{
    float x = 88.722f;
    float d_exp_x = float(std::exp(double(x)));
    float f_exp_x = std::exp(x);
    std::cout << std::setprecision(60);
    std::cout << " x is " << x << std::endl;
    std::cout << "  expf(x) is " << f_exp_x << std::endl;
    std::cout << "  exp(x)  is " << d_exp_x << std::endl;
    return (( f_exp_x == d_exp_x ) ? 0 : 1);
}
