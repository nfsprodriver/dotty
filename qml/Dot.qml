/*
 * Copyright 2013-2015 Canonical Ltd.
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License version 3 as published by the
 * Free Software Foundation. See http://www.gnu.org/copyleft/gpl.html the full
 * text of the license.
 */

import QtQuick 2.4

Rectangle {
    width: 60
    property int x_coord
    property int y_coord
    property real cx
    property real cy
    x: cx - width / 2
    y: cy - height / 2
    height: width
    radius: width / 2
    antialiasing: true
    color: "#4e9a06"

    Behavior on y {
        NumberAnimation {
            duration: 400;
            easing.type: Easing.OutBounce;
            easing.amplitude: 0.5;
        }
    }
}
