#include "onebotbridge.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QUrl>
#include <QCryptographicHash>
#include <QImage>
#include <QBuffer>
#include <QSettings>
#include <QUrlQuery>
#include <QFileInfo>
#include <QDir>
#include <QClipboard>
#include <QGuiApplication>
#include <QDebug>
#include "qrcodegen.hpp"

QVariant OneBotBridge::getSetting(const QString &key,
                                  const QVariant &defaultValue)
{
    return QSettings().value(key, defaultValue);
}

void OneBotBridge::setSetting(const QString &key, const QVariant &value)
{
    QSettings().setValue(key, value);
}

QString OneBotBridge::fileToBase64(const QString &path)
{
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly))
        return QString();
    return f.readAll().toBase64();
}

qint64 OneBotBridge::fileSize(const QString &path)
{
    QFileInfo info(path);
    return info.size();
}

bool OneBotBridge::writeFile(const QString &path, const QString &content)
{
    QDir().mkpath(QFileInfo(path).absolutePath());
    QFile f(path);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return false;
    return f.write(content.toUtf8()) >= 0;
}

void OneBotBridge::copyText(const QString &text)
{
    QGuiApplication::clipboard()->setText(text);
}

bool OneBotBridge::copyFile(const QString &src, const QString &dst)
{
    QDir().mkpath(QFileInfo(dst).absolutePath());
    QFile::remove(dst);
    return QFile::copy(src, dst);
}

QString OneBotBridge::sha256Hex(const QString &s)
{
    return QString::fromLatin1(QCryptographicHash::hash(
        s.toUtf8(), QCryptographicHash::Sha256).toHex());
}

QString OneBotBridge::qrDataUrl(const QString &text)
{
    try {
        using qrcodegen::QrCode;
        const QrCode qr = QrCode::encodeText(
            text.toUtf8().constData(), QrCode::Ecc::MEDIUM);
        const int quiet = 4, scale = 8, size = qr.getSize();
        const int dim = (size + quiet * 2) * scale;
        QImage img(dim, dim, QImage::Format_RGB32);
        img.fill(0xFFFFFFFF);
        const QColor black(0, 0, 0);
        for (int y = 0; y < size; y++)
            for (int x = 0; x < size; x++)
                if (qr.getModule(x, y))
                    for (int dy = 0; dy < scale; dy++)
                        for (int dx = 0; dx < scale; dx++)
                            img.setPixel(quiet * scale + x * scale + dx,
                                         quiet * scale + y * scale + dy,
                                         black.rgba());
        QByteArray ba;
        QBuffer buf(&ba);
        buf.open(QIODevice::WriteOnly);
        img.save(&buf, "PNG");
        return QStringLiteral("data:image/png;base64,")
               + ba.toBase64();
    } catch (const std::exception &e) {
        qWarning() << "qqcat: qr encode failed:" << e.what();
    }
    return QString();
}

OneBotBridge::OneBotBridge(QObject *parent)
    : QObject(parent)
{
    // connection profile comes from persistent settings so the app
    // can talk to a NapCat running anywhere (generic integration)
    QSettings settings;
    m_url = settings.value(QStringLiteral("connection/wsUrl"),
                           QStringLiteral("ws://127.0.0.1:3001")).toString();
    m_httpBase = settings.value(QStringLiteral("connection/httpBase"),
                                QStringLiteral("http://127.0.0.1:3000")).toString();
    m_token = settings.value(QStringLiteral("connection/token")).toString();

    connect(&m_ws, &QWebSocket::connected, this, [this]() {
        qDebug() << "qqcat: ws open";
        emit connectedChanged();
    });
    connect(&m_ws, &QWebSocket::disconnected, this, [this]() {
        qDebug() << "qqcat: ws closed";
        emit connectedChanged();
    });
    connect(&m_ws,
            static_cast<void (QWebSocket::*)(QAbstractSocket::SocketError)>(
                &QWebSocket::error),
            this, [this](QAbstractSocket::SocketError) {
        qDebug() << "qqcat: ws error:" << m_ws.errorString();
    });
    connect(&m_ws, &QWebSocket::textMessageReceived,
            this, &OneBotBridge::onTextMessage);
}

bool OneBotBridge::connected() const
{
    return m_ws.state() == QAbstractSocket::ConnectedState;
}

void OneBotBridge::setUrl(const QString &url)
{
    if (m_url == url)
        return;
    m_url = url;
    emit urlChanged();
}

void OneBotBridge::open()
{
    if (m_url.isEmpty())
        return;
    QUrl u(m_url);
    if (!m_token.isEmpty()) {
        QUrlQuery q(u);
        if (!q.hasQueryItem(QStringLiteral("access_token")))
            q.addQueryItem(QStringLiteral("access_token"), m_token);
        u.setQuery(q);
    }
    m_ws.open(u);
}

void OneBotBridge::close()
{
    m_ws.close();
}

QString OneBotBridge::sendAction(const QString &action,
                                 const QString &paramsJson)
{
    // actions go over http; the websocket is used for event push only
    const QString echo = QStringLiteral("e%1").arg(++m_echoSeq);
    QNetworkRequest req(QUrl(m_httpBase + QLatin1Char('/') + action));
    req.setHeader(QNetworkRequest::ContentTypeHeader,
                  QStringLiteral("application/json"));
    QNetworkReply *rep = m_nam.post(req, paramsJson.toUtf8());
    qDebug() << "qqcat: ->" << action << "echo" << echo;
    connect(rep, &QNetworkReply::finished, this, [this, rep, echo]() {
        rep->deleteLater();
        if (rep->error() != QNetworkReply::NoError) {
            qWarning() << "qqcat: <- FAIL" << echo << rep->errorString();
            emit actionReply(echo, false,
                             QStringLiteral("{\"error\":%1}")
                                 .arg(rep->errorString()));
            return;
        }
        const QByteArray raw = rep->readAll();
        const QJsonObject o = QJsonDocument::fromJson(raw).object();
        const bool ok =
            o.value(QStringLiteral("status")).toString() == QLatin1String("ok")
            && o.value(QStringLiteral("retcode")).toInt() == 0;
        // data may be an object OR an array (e.g. contact lists)
        const QJsonValue v = o.value(QStringLiteral("data"));
        const QJsonDocument doc = v.isObject()
            ? QJsonDocument(v.toObject())
            : QJsonDocument(v.toArray());
        qDebug() << "qqcat: <-" << echo << "ok" << ok
                 << raw.left(80);
        emit actionReply(echo, ok, QString::fromUtf8(doc.toJson(
                                       QJsonDocument::Compact)));
    });
    return echo;
}

void OneBotBridge::onTextMessage(const QString &message)
{
    QJsonParseError err;
    const QJsonObject m =
        QJsonDocument::fromJson(message.toUtf8(), &err).object();
    if (err.error != QJsonParseError::NoError)
        return;

    // action replies carry an echo field
    if (m.contains(QStringLiteral("echo"))) {
        const QString echo = m.value(QStringLiteral("echo")).toString();
        if (echo.startsWith(QLatin1String("e")) && !m.contains(QStringLiteral("post_type"))) {
            const bool ok = m.value(QStringLiteral("status")).toString()
                                == QLatin1String("ok");
            emit actionReply(echo, ok,
                             QString::fromUtf8(QJsonDocument(
                                 m.value(QStringLiteral("data")).toObject())
                                                   .toJson(QJsonDocument::Compact)));
            return;
        }
    }

    const QString post = m.value(QStringLiteral("post_type")).toString();
    // "message_sent" covers messages sent by ourselves from OTHER
    // clients (phone QQ etc.) when reportSelfMessage is enabled
    if (post != QLatin1String("message")
            && post != QLatin1String("message_sent"))
        return;  // meta/notice/request events are not shown in v1 UI

    const QString kind = m.value(QStringLiteral("message_type")).toString()
                             == QLatin1String("group")
                         ? QStringLiteral("群")
                         : QStringLiteral("私聊");
    QString who = m.value(QStringLiteral("user_id")).toString();
    const QJsonObject sender = m.value(QStringLiteral("sender")).toObject();
    if (sender.contains(QStringLiteral("nickname")))
        who = sender.value(QStringLiteral("nickname")).toString();

    // fold array-format segments: text parts become the message body,
    // image segments are collected for the QML side to render tiles
    QStringList texts;
    QJsonArray images;
    const QJsonValue mv = m.value(QStringLiteral("message"));
    if (mv.isArray()) {
        const QJsonArray segs = mv.toArray();
        for (const QJsonValue &v : segs) {
            const QJsonObject seg = v.toObject();
            const QString st = seg.value(QStringLiteral("type")).toString();
            const QJsonObject sd = seg.value(QStringLiteral("data")).toObject();
            if (st == QLatin1String("text")) {
                texts << sd.value(QStringLiteral("text")).toString();
            } else if (st == QLatin1String("image")) {
                QJsonObject img;
                img.insert(QStringLiteral("url"),
                           sd.value(QStringLiteral("url")).toString());
                img.insert(QStringLiteral("file"),
                           sd.value(QStringLiteral("file")).toString());
                images.append(img);
            } else if (st == QLatin1String("video")) {
                QJsonObject vid;
                vid.insert(QStringLiteral("video"), true);
                vid.insert(QStringLiteral("url"),
                           sd.value(QStringLiteral("url")).toString());
                vid.insert(QStringLiteral("file"),
                           sd.value(QStringLiteral("file")).toString());
                images.append(vid);
            } else if (st == QLatin1String("reply")) {
                QJsonObject rp;
                rp.insert(QStringLiteral("isReply"), true);
                rp.insert(QStringLiteral("rid"),
                          sd.value(QStringLiteral("id")).toString());
                images.append(rp);
            } else if (st == QLatin1String("face")) {
                QJsonObject fc;
                fc.insert(QStringLiteral("faceId"),
                          static_cast<int>(sd.value(
                              QStringLiteral("id")).toDouble()));
                images.append(fc);
            } else if (st == QLatin1String("file")) {
                QJsonObject fil;
                fil.insert(QStringLiteral("filemsg"), true);
                QString nm = sd.contains(QStringLiteral("name"))
                        ? sd.value(QStringLiteral("name")).toString()
                        : sd.value(QStringLiteral("file")).toString();
                fil.insert(QStringLiteral("name"), nm);
                fil.insert(QStringLiteral("fid"),
                           sd.value(QStringLiteral("file_id")).toString());
                images.append(fil);
            }
        }
    }
    QString text = texts.join(QLatin1Char(' '));
    if (text.isEmpty() && images.isEmpty()
            && m.contains(QStringLiteral("raw_message")))
        text = m.value(QStringLiteral("raw_message")).toString();

    QString where = kind;
    const qlonglong peerId = static_cast<qlonglong>(
        kind == QStringLiteral("群")
            ? m.value(QStringLiteral("group_id")).toDouble()
            : m.value(QStringLiteral("user_id")).toDouble());
    where += QString::number(peerId);

    QJsonObject packet;
    packet.insert(QStringLiteral("dbg"),
                  QString("post=%1 mtype=%2 gid=%3 uid=%4")
                      .arg(m.value(QStringLiteral("post_type")).toString(),
                           m.value(QStringLiteral("message_type")).toString())
                      .arg(m.value(QStringLiteral("group_id")).toDouble(), 0, 'f', 0)
                      .arg(m.value(QStringLiteral("user_id")).toDouble(), 0, 'f', 0));
    packet.insert(QStringLiteral("where"), where);
    packet.insert(QStringLiteral("who"), who);
    packet.insert(QStringLiteral("text"), text);
    packet.insert(QStringLiteral("imagesJson"),
                  QString::fromUtf8(QJsonDocument(images).toJson(
                      QJsonDocument::Compact)));
    packet.insert(QStringLiteral("uid"), QString::number(static_cast<qlonglong>(
                  m.value(QStringLiteral("user_id")).toDouble())));
    packet.insert(QStringLiteral("mid"),
                  m.value(QStringLiteral("message_id")).toString());
    emit eventReceived(QString::fromUtf8(
        QJsonDocument(packet).toJson(QJsonDocument::Compact)));
}
