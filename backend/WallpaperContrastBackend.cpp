#include "WallpaperContrastBackend.h"

#include <QDir>
#include <QFileInfo>
#include <QImage>
#include <QImageReader>
#include <QUrl>

#include <algorithm>
#include <cmath>
#include <vector>

namespace {
constexpr int kAnalysisLongEdge = 512;

QString localWallpaperPath(const QString &value)
{
    if (value.startsWith(QLatin1String("file:")))
        return QUrl(value).toLocalFile();
    if (value == QLatin1String("~"))
        return QDir::homePath();
    if (value.startsWith(QLatin1String("~/")))
        return QDir::home().filePath(value.mid(2));
    return value;
}

double linearChannel(double channel)
{
    channel /= 255.0;
    return channel <= 0.04045
        ? channel / 12.92
        : std::pow((channel + 0.055) / 1.055, 2.4);
}

double luminance(QRgb pixel)
{
    return 0.2126 * linearChannel(qRed(pixel))
        + 0.7152 * linearChannel(qGreen(pixel))
        + 0.0722 * linearChannel(qBlue(pixel));
}

double contrast(double first, double second)
{
    const double lighter = std::max(first, second);
    const double darker = std::min(first, second);
    return (lighter + 0.05) / (darker + 0.05);
}
}

WallpaperContrastBackend::WallpaperContrastBackend(QObject *parent)
    : QObject(parent)
{
}

QColor WallpaperContrastBackend::foregroundForRegion(const QString &wallpaperPath,
                                                      qreal viewportWidth,
                                                      qreal viewportHeight,
                                                      qreal regionX,
                                                      qreal regionY,
                                                      qreal regionWidth,
                                                      qreal regionHeight) const
{
    const QColor lightForeground(QStringLiteral("#f7f8fb"));
    const QColor darkForeground(QStringLiteral("#15171a"));
    const QString path = localWallpaperPath(wallpaperPath.trimmed());
    if (path.isEmpty() || !QFileInfo::exists(path)
            || viewportWidth <= 0 || viewportHeight <= 0
            || regionWidth <= 0 || regionHeight <= 0) {
        return lightForeground;
    }

    QImageReader reader(path);
    reader.setAutoTransform(true);
    const QSize sourceSize = reader.size();
    if (!sourceSize.isValid())
        return lightForeground;

    QSize analysisSize = sourceSize;
    if (std::max(sourceSize.width(), sourceSize.height()) > kAnalysisLongEdge)
        analysisSize.scale(kAnalysisLongEdge, kAnalysisLongEdge, Qt::KeepAspectRatio);
    reader.setScaledSize(analysisSize);

    const QImage image = reader.read().convertToFormat(QImage::Format_RGB32);
    if (image.isNull())
        return lightForeground;

    // awww's default presentation and the in-shell previews both behave like
    // PreserveAspectCrop: scale to cover the output, then center-crop.
    const qreal coverScale = std::max(viewportWidth / image.width(),
                                      viewportHeight / image.height());
    const qreal visibleImageWidth = viewportWidth / coverScale;
    const qreal visibleImageHeight = viewportHeight / coverScale;
    const qreal cropX = (image.width() - visibleImageWidth) / 2.0;
    const qreal cropY = (image.height() - visibleImageHeight) / 2.0;

    const int sampleLeft = std::clamp(
        static_cast<int>(std::floor(cropX + regionX / coverScale)),
        0, image.width() - 1);
    const int sampleTop = std::clamp(
        static_cast<int>(std::floor(cropY + regionY / coverScale)),
        0, image.height() - 1);
    const int sampleRight = std::clamp(
        static_cast<int>(std::ceil(cropX + (regionX + regionWidth) / coverScale)),
        sampleLeft + 1, image.width());
    const int sampleBottom = std::clamp(
        static_cast<int>(std::ceil(cropY + (regionY + regionHeight) / coverScale)),
        sampleTop + 1, image.height());

    std::vector<double> lightContrasts;
    std::vector<double> darkContrasts;
    const int stepX = std::max(1, (sampleRight - sampleLeft) / 80);
    const int stepY = std::max(1, (sampleBottom - sampleTop) / 12);
    for (int y = sampleTop; y < sampleBottom; y += stepY) {
        const QRgb *scanLine = reinterpret_cast<const QRgb *>(image.constScanLine(y));
        for (int x = sampleLeft; x < sampleRight; x += stepX) {
            const double background = luminance(scanLine[x]);
            lightContrasts.push_back(contrast(1.0, background));
            darkContrasts.push_back(contrast(0.0086, background));
        }
    }

    if (lightContrasts.empty())
        return lightForeground;

    // Prefer the color whose weak-contrast pixels fare better. The tenth
    // percentile avoids letting a few highlights or shadows flip the bar.
    const auto percentile = [](std::vector<double> values) {
        const size_t index = static_cast<size_t>(std::floor((values.size() - 1) * 0.10));
        std::nth_element(values.begin(), values.begin() + index, values.end());
        return values[index];
    };

    return percentile(darkContrasts) > percentile(lightContrasts)
        ? darkForeground : lightForeground;
}
