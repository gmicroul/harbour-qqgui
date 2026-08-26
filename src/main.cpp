#include <QGuiApplication>
#include <QFileInfo>
#include <QQuickView>
#include <QQmlEngine>
#include <QDebug>
#include <QTimer>
#include <QImage>
#include <QDir>
#include <cstdio>

#include "onebotbridge.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("harbour-qqcat"));
    app.setOrganizationName(QStringLiteral("harbour-qqcat"));

    qmlRegisterType<OneBotBridge>("Qqcat", 1, 0, "OneBotBridge");

    qInfo() << "qqcat starting";

    QQuickView view;
    view.setResizeMode(QQuickView::SizeRootObjectToView);

    QString qmlMain = QStringLiteral("/usr/share/%1/qml/%1.qml")
                          .arg(app.applicationName());
    if (!QFileInfo::exists(qmlMain))
        qmlMain = QStringLiteral("qml/harbour-qqcat.qml");
    qDebug() << "loading" << qmlMain;
    view.setSource(QUrl::fromLocalFile(qmlMain));

    if (view.status() == QQuickView::Error)
        return 1;
    view.show();

    // debug helper: QQCAT_SHOT=/some/dir grabs the window every 3s
    const QString shotDir = QString::fromLocal8Bit(qgetenv("QQCAT_SHOT"));
    if (!shotDir.isEmpty()) {
        QDir().mkpath(shotDir);
        QTimer *shotTimer = new QTimer(&view);
        static int n = 0;
        QQuickView *v = &view;
        QObject::connect(shotTimer, &QTimer::timeout, [v, shotDir]() {
            QImage img = v->grabWindow();
            img.save(QString("%1/shot-%2.png")
                         .arg(shotDir).arg(++n, 3, 10, QLatin1Char('0')));
        });
        shotTimer->start(3000);
    }

    return app.exec();
}
