#include "appcontroller.h"

AppController::AppController(QObject *parent) :
    QObject(parent)
{
    m_api = new NeteaseAPI(this);
    connect(m_api, &NeteaseAPI::topPlaylistGot, this, &AppController::topPlaylistsGot);
    connect(m_api, &NeteaseAPI::playlistDetailGot, this, &AppController::playlistDetailGot);
}

void AppController::getTopPlaylists()
{
    m_api->topPlaylist();
}

void AppController::getPlaylistDetail(QString playlistId)
{
    m_api->playlistDetail(playlistId);
}
