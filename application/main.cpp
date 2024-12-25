#include "pch.hpp"
#include "application.metainfo.h"

#include "headeronly.hpp"
#include "shared.hpp"
#include "static.hpp"


int32_t main(int32_t argc, char* argv[]) {
# ifdef QT_VERSION
    QCoreApplication app(argc, argv);
# endif
    std::cout << "Application: v" << application_Version() << std::endl;

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
