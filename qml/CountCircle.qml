/*
 * Copyright 2013-2015 Canonical Ltd.
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License version 3 as published by the
 * Free Software Foundation. See http://www.gnu.org/copyleft/gpl.html the full
 * text of the license.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3

Item {
    property double radius
    property string color
    property string textColor
    property string count
    property string text
    width: circle.width > label.width ? circle.width : label.width
    height: circle.height + units.gu (2) + label.height

    Rectangle {
        id: circle
        width: parent.radius * 2
        height: width
        radius: parent.radius
        color: parent.color
        Label {
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: height * 0.5
            color: textColor
            text: count
        }
    }
    Label {
        id: label
        anchors.top: circle.bottom
        anchors.topMargin: units.gu (1)
        anchors.horizontalCenter: circle.horizontalCenter
        horizontalAlignment: Text.AlignHCenter
        text: parent.text
    }
}
