/*
 * Copyright 2013-2015 Canonical Ltd.
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License version 3 as published by the
 * Free Software Foundation. See http://www.gnu.org/copyleft/gpl.html the full
 * text of the license.
 */

import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3

GridLayout {
    id: entry
    columns: 1

    property var date: ""
    property var score: ""
    property var color: ""
    property var size: units.gu (8)

    Rectangle {
        id: circle
        width: entry.size
        height: width
        radius: width / 2
        color: entry.color
        Layout.alignment: Qt.AlignHCenter
        Label {
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: height * 0.4
            color: "white"
            text: entry.score
        }
    }

    Label {
        Layout.alignment: Qt.AlignHCenter
        text: entry.date
    }
}