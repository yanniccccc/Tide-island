#include "WallpaperContrastBackend.h"

#include <QImage>
#include <QTemporaryDir>
#include <QTest>

class WallpaperContrastTests : public QObject {
    Q_OBJECT

private slots:
    void choosesLightForegroundOnDarkWallpaper();
    void choosesDarkForegroundOnBrightWallpaper();
    void samplesTheRequestedRegion();
};

void WallpaperContrastTests::choosesLightForegroundOnDarkWallpaper()
{
    QTemporaryDir directory;
    QVERIFY(directory.isValid());
    const QString path = directory.filePath(QStringLiteral("dark.png"));
    QImage image(160, 90, QImage::Format_RGB32);
    image.fill(QColor(QStringLiteral("#102d4f")));
    QVERIFY(image.save(path));

    WallpaperContrastBackend backend;
    QCOMPARE(backend.foregroundForRegion(path, 160, 90, 100, 0, 60, 20).name(),
             QStringLiteral("#f7f8fb"));
}

void WallpaperContrastTests::choosesDarkForegroundOnBrightWallpaper()
{
    QTemporaryDir directory;
    QVERIFY(directory.isValid());
    const QString path = directory.filePath(QStringLiteral("bright.png"));
    QImage image(160, 90, QImage::Format_RGB32);
    image.fill(QColor(QStringLiteral("#f2e8cf")));
    QVERIFY(image.save(path));

    WallpaperContrastBackend backend;
    QCOMPARE(backend.foregroundForRegion(path, 160, 90, 100, 0, 60, 20).name(),
             QStringLiteral("#15171a"));
}

void WallpaperContrastTests::samplesTheRequestedRegion()
{
    QTemporaryDir directory;
    QVERIFY(directory.isValid());
    const QString path = directory.filePath(QStringLiteral("split.png"));
    QImage image(200, 100, QImage::Format_RGB32);
    image.fill(Qt::black);
    for (int y = 0; y < image.height(); ++y) {
        for (int x = image.width() / 2; x < image.width(); ++x)
            image.setPixelColor(x, y, Qt::white);
    }
    QVERIFY(image.save(path));

    WallpaperContrastBackend backend;
    QCOMPARE(backend.foregroundForRegion(path, 200, 100, 0, 0, 80, 20).name(),
             QStringLiteral("#f7f8fb"));
    QCOMPARE(backend.foregroundForRegion(path, 200, 100, 120, 0, 80, 20).name(),
             QStringLiteral("#15171a"));
}

QTEST_GUILESS_MAIN(WallpaperContrastTests)

#include "wallpaper_contrast_tests.moc"
