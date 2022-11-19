#include <fstream>

#ifdef QT_VERSION
#   include <QCoreApplication>
#endif

#include "headeronly.hpp"
#include "shared.hpp"
#include "static.hpp"

int32_t main(int32_t argc, char* argv[]) {
# ifdef QT_VERSION
    QCoreApplication app(argc, argv);
# endif

    headeronly();
    shared();
    static_();

    std::ofstream test("test.txt");
    for (int32_t i = 0; i < argc; ++i) {
        test << argv[i] << std::endl;
    }

# ifdef QT_VERSION
    QObject::tr("Some string");
# endif
    return 0;
}
