#include "headeronly.hpp"
#include "shared.hpp"
#include "static.hpp"

int main(int argc, char* argv[]) {
    headeronly();
    shared();
    static_();
    return 0;
}
