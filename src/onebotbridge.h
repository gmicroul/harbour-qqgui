#ifndef ONEBOTBRIDGE_H
#define ONEBOTBRIDGE_H

#include <QObject>
#include <QWebSocket>
#include <QNetworkAccessManager>
#include <QString>

class QJsonObject;

// OneBot11 client: chat events stream in over websocket (:3001), while
// all actions (login info, contact lists, sending) go over plain http
// (:3000) - NapCat's ws endpoint does not answer action frames reliably.
class OneBotBridge : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
    Q_PROPERTY(QString url READ url WRITE setUrl NOTIFY urlChanged)

public:
    explicit OneBotBridge(QObject *parent = nullptr);
    ~OneBotBridge() override { m_ws.close(); }

    bool connected() const;
    QString url() const { return m_url; }
    void setUrl(const QString &url);

    Q_INVOKABLE void open();
    Q_INVOKABLE void close();
    // returns the echo id, or empty string when not connected
    Q_INVOKABLE QString sendAction(const QString &action,
                                   const QString &paramsJson);

    // login helpers: sha256 for the WebUI auth handshake and a
    // rendered QR code returned as a "data:image/png;base64," url
    Q_INVOKABLE QString sha256Hex(const QString &s);
    Q_INVOKABLE QString qrDataUrl(const QString &text);

    // persistent settings (~/.config/harbour-qqcat/harbour-qqcat.conf)
    Q_INVOKABLE QVariant getSetting(const QString &key,
                                    const QVariant &defaultValue);
    Q_INVOKABLE void setSetting(const QString &key, const QVariant &value);

    // file helpers for attachments
    Q_INVOKABLE QString fileToBase64(const QString &path);
    Q_INVOKABLE qint64 fileSize(const QString &path);
    Q_INVOKABLE bool copyFile(const QString &src, const QString &dst);
    Q_INVOKABLE bool writeFile(const QString &path, const QString &content);
    Q_INVOKABLE void copyText(const QString &text);
    // download a remote url to a local file (async); emits fileDownloadDone
    Q_INVOKABLE QString downloadFile(const QString &url,
                                     const QString &destPath);

signals:
    void connectedChanged();
    void urlChanged();
    // single JSON packet: {where,who,text,imagesJson,uid}
    // (name-independent: QML parses the packet, no param-name coupling)
    void eventReceived(const QString &packet);
    void actionReply(const QString &echo, bool ok, const QString &dataJson);
    void fileDownloadDone(const QString &token, bool ok,
                          const QString &path);

private slots:
    void onTextMessage(const QString &message);

private:
    void handleGroupUpload(const QJsonObject &m);

    QString m_httpBase;
    QString m_token;
    QWebSocket m_ws;
    QNetworkAccessManager m_nam;
    QString m_url;
    int m_echoSeq = 0;
};

#endif
