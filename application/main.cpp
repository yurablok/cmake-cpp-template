#include <fstream>

#include <QCoreApplication>

#include "headeronly.hpp"
#include "shared.hpp"
#include "static.hpp"

int32_t main(int32_t argc, char* argv[]) {
    QCoreApplication app(argc, argv);

    headeronly();
    shared();
    static_();

    std::ofstream test("test.txt");
    for (int32_t i = 0; i < argc; ++i) {
        test << argv[i] << std::endl;
    }

    QObject::tr("Some string");
    return 0;
}
