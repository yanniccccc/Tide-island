#pragma once

#include <QColor>
#include <QObject>
#include <QtQml/qqml.h>

class WallpaperContrastBackend final : public QObject {
    Q_OBJECT
    QML_NAMED_ELEMENT(WallpaperContrast)
    QML_SINGLETON

public:
    explicit WallpaperContrastBackend(QObject *parent = nullptr);

    Q_INVOKABLE QColor foregroundForRegion(const QString &wallpaperPath,
                                           qreal viewportWidth,
                                           qreal viewportHeight,
                                           qreal regionX,
                                           qreal regionY,
                                           qreal regionWidth,
                                           qreal regionHeight) const;
};
