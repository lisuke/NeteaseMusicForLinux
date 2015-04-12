import QtQuick 2.2
import QtQuick.Window 2.1
import QtQuick.Controls 1.0
import QtMultimedia 5.0

import Org.Hualet.Widgets 1.0

import "../qmls/widgets"
import "qrc:/src/qmls/utils.js" as Utils

Window {
    visible: true
    width: 1000
    height: 640
    color: "transparent"
    title: " "

    Item {
        id: window_content
        focus: true
        anchors.fill: parent

        state: "suggestions"

        property bool stateChangedByUser: true

        states: [
            State {
                name: "suggestions"
                PropertyChanges { target: main_tab_view; currentIndex: 0 }
                PropertyChanges { target: playlist_detail_view; visible: false }
            },
            State {
                name: "ranklists"
                PropertyChanges { target: main_tab_view; currentIndex: 1 }
                PropertyChanges { target: playlist_detail_view; visible: false }
            },
            State {
                name: "playlists"
                PropertyChanges { target: main_tab_view; currentIndex: 2 }
                PropertyChanges { target: playlist_detail_view; visible: false }
            },
            State {
                name: "playlist_detail"
                PropertyChanges { target: playlist_detail_view; visible: true }
            }
        ]

        onStateChanged: {
            if (stateChangedByUser) {
                views_history_manager.append(state)
            } else {
                stateChangedByUser = true
            }
        }

        Keys.onLeftPressed: goBack()
        Keys.onRightPressed: goForward()

        function goBack() {
            var _state = views_history_manager.goBack()
            if (_state) {
                stateChangedByUser = false
                state = _state
            }
        }

        function goForward() {
            var _state = views_history_manager.goForward()
            if (_state) {
                stateChangedByUser = false
                state = _state
            }
        }

        Audio {
            id: player
            autoPlay: true
            volume: 0.8
            source: current_song.mp3Url

            onStatusChanged: {
                if (status == Audio.EndOfMedia) {
                    main_controller.playNext()
                }
            }
        }

        Song { id: current_song }

        MainController { id: main_controller }

        ViewHistoryManager { id: views_history_manager }

        Connections {
            target: _controller
            onLyricGot: {
                current_song.lyric = lyric
            }
        }

        Rectangle {
            id: background
            color: Qt.rgba(1, 1, 1, 0.8)
            anchors.fill: parent
        }

        Column {
            width: parent.width
            height: parent.height

            Header {
                id: header
                width: parent.width
            }

            Row {
                clip: true
                width: parent.width
                height: parent.height - header.height - footer.height

                SideBar {
                    id: side_bar
                    width: 200
                    height: parent.height
                }

                VSep { height: parent.height }

                Rectangle {
                    width: parent.width - side_bar.width - 1
                    height: parent.height

                    HTTabView {
                        id: main_tab_view
                        anchors.fill: parent
                        visible: !playlist_detail_view.visible

                        property var _tabs: ["suggestions", "ranklists", "playlists"]

                        onCurrentIndexChanged: window_content.state = _tabs[currentIndex]

                        Tab {
                            title: "推荐"

                            HTTabContent {
                                width: parent.width
                                height: parent.height

                                HTBannersView {
                                    id: banners_view

                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Connections {
                                        target: _controller
                                        onBannersGot: banners_view.setData(banners)
                                    }

                                    Component.onCompleted: _controller.getBanners()
                                }

                                PlaylistIconView {
                                    id: hotspot_icon_view
                                    width: cellWidth * 4
                                    height: parent.height

                                    anchors.top: banners_view.bottom
                                    anchors.topMargin: 20
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Connections {
                                        target: _controller
                                        onHotspotGot: hotspot_icon_view.setData(hotspot)
                                    }

                                    Component.onCompleted: _controller.getHotspot()

                                    onPlaylistClicked: {
                                        playlist_detail_view.setPlaylist(playlistId)
                                    }
                                }
                            }
                        }
                        Tab {
                            title: "排行榜"

                            HTTabContent {
                                width: parent.width
                                height: parent.height

                                PlaylistIconView {
                                    id: toplist_icon_view
                                    width: cellWidth * 4
                                    height: parent.height

                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Connections {
                                        target: _controller
                                        onRankingListsGot: toplist_icon_view.setData(lists)
                                    }

                                    Component.onCompleted: _controller.getRankingLists()

                                    onPlaylistClicked: {
                                        playlist_detail_view.setPlaylist(playlistId)
                                    }
                                }
                            }
                        }
                        Tab {
                            title: "歌单"

                            PlaylistIconView {
                                id: playlists_icon_view
                                width: cellWidth * 4
                                height: parent.height

                                anchors.horizontalCenter: parent.horizontalCenter

                                Connections {
                                    target: _controller
                                    onTopPlaylistsGot: playlists_icon_view.setData(playlists)
                                }

                                Component.onCompleted: _controller.getTopPlaylists()

                                onPlaylistClicked: {
                                    playlist_detail_view.setPlaylist(playlistId)
                                }
                            }
                        }
//                        Tab {
//                            title: "最新音乐"
//                        }
                    }

                    PlaylistDetialView {
                        id: playlist_detail_view
                        visible: false
                        anchors.fill: parent

                        onSongClicked: main_controller.playSong(song)
                        onPlayAllClicked: {
                            main_controller.playPlaylist(playlistId)
                        }

                        function setPlaylist(playlistId) {
                            _controller.getPlaylistDetail(playlistId)

                            _controller.playlistDetailGot.disconnect(main_controller.playlistDetailGot)
                            _controller.playlistDetailGot.connect(playlistDetailGot)
                        }

                        function playlistDetailGot(detail) {
                            var result = JSON.parse(detail)

                            playlist_detail_view.id = result.id
                            playlist_detail_view.name = result.name
                            playlist_detail_view.coverImgUrl = result.coverImgUrl
                            playlist_detail_view.creator = result.creator.nickname
                            playlist_detail_view.createTime = result.createTime
                            playlist_detail_view.description = result.description
                            playlist_detail_view.setData(result.tracks)

                            playlist_detail_view.visible = true
                            window_content.state = "playlist_detail"
                        }
                    }
                }
            }

            Footer {
                id: footer
                width: parent.width

                playing: player.playbackState == Audio.PlayingState
                progress: player.position / player.duration
                timeInfo: "%1/%2".arg(Utils.formatTime(player.position)).arg(Utils.formatTime(player.duration))
                volume: player.volume
                muted: player.muted

                onMutedSet: player.muted = muted
                onPlay: player.play()
                onPause: player.pause()
                onVolumeSet: player.volume = volume
                onSeek: player.seek(player.duration * progress)
                onPlayPrev: main_controller.playPrev()
                onPlayNext: main_controller.playNext()
            }
        }

        Item {
            id: floats
            y: header.height
            width: parent.width
            height: parent.height - header.height - footer.height

            PlayView {
                width: state == "mini" ? side_bar.width : parent.width
                height: state == "mini" ? 80 : parent.height
                picUrl: current_song.picUrl
                artist: current_song.artist
                song: current_song.name
                album: current_song.album
                lyric: current_song.lyric
                position: player.position
                playing: player.playbackState == Audio.PlayingState

                anchors.left: parent.left
                anchors.bottom: parent.bottom
            }
        }
    }
}
