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
import Ubuntu.Components.Popups 1.3
import QtQuick.LocalStorage 2.0

MainView {
    applicationName: "com.ubuntu.developer.robert-ancell.dotty"
    // useDeprecatedToolbar: false
    automaticOrientation: true

    width: units.gu (40)
    height: units.gu (71)
    property bool isHorizontal: width > height

    Component {
        id: confirm_new_game_dialog
        Dialog {
            id: d
            // TRANSLATORS: Title for dialog shown when starting a new game while one in progress
            title: i18n.tr ("Game in progress")
            // TRANSLATORS: Content for dialog shown when starting a new game while one in progress
            text: i18n.tr ("Are you sure you want to restart this game?")
            Button {
                // TRANSLATORS: Button in new game dialog that cancels the current game and starts a new one
                text: i18n.tr ("Restart game")
                color: UbuntuColors.red
                onClicked: {
                    table.start_game ()
                    PopupUtils.close (d)
                }
            }
            Button {
                // TRANSLATORS: Button in new game dialog that cancels new game request
                text: i18n.tr ("Continue current game")
                onClicked: PopupUtils.close (d)
            }
        }
    }

    Component {
        id: confirm_clear_scores_dialog
        Dialog {
            id: d
            // TRANSLATORS: Title for dialog confirming if scores should be cleared
            title: i18n.tr ("Clear scores")
            // TRANSLATORS: Content for dialog confirming if scores should be cleared
            text: i18n.tr ("Existing scores will be deleted. This cannot be undone.")
            Button {
                // TRANSLATORS: Button in clear scores dialog that clears scores
                text: i18n.tr ("Clear scores")
                color: UbuntuColors.red
                onClicked: {
                    table.clear_scores ()
                    PopupUtils.close (d)
                }
            }
            Button {
                // TRANSLATORS: Button in clear scores dialog that cancels clear scores request
                text: i18n.tr ("Keep existing scores")
                onClicked: PopupUtils.close (d)
            }
        }
    }

    PageStack {
        id: page_stack
        Component.onCompleted: push (main_page)

        Page {
            id: main_page
            visible: false
            // TRANSLATORS: Title of application
            title: i18n.tr ("Dotty")
            head.actions:
            [
                Action {
                    // TRANSLATORS: Action on main page that shows game instructions
                    text: i18n.tr ("How to Play")
                    iconName: "help"
                    onTriggered: page_stack.push (how_to_play_page)
                },
                Action {
                    // TRANSLATORS: Action on main page that shows high score dialog
                    text: i18n.tr ("High Scores")
                    iconSource: "high-scores.svg"
                    onTriggered: {
                        table.update_scores ()
                        page_stack.push (scores_page)
                    }
                },
                Action {
                    // TRANSLATORS: Action on main page that starts a new game
                    text: i18n.tr ("New Game")
                    iconName: "reload"
                    onTriggered: {
                        if (table.n_cleared > 0 && table.n_moves > 0)
                            PopupUtils.open (confirm_new_game_dialog)
                        else
                            table.start_game ()
                    }
                }
            ]

            Item {
                anchors.fill: parent

                property var circle_radius: units.gu (5)
                property var circle_spacing: (isHorizontal ? height - moves_circle.height - score_circle.height : width - moves_circle.width - score_circle.width) / 3

                CountCircle {
                    id: moves_circle
                    anchors.top: isHorizontal ? undefined : parent.top
                    anchors.left: isHorizontal ? parent.left : undefined
                    anchors.margins: units.gu (2)
                    x: isHorizontal ? 0 : parent.circle_spacing
                    y: isHorizontal ? parent.circle_spacing : 0
                    radius: parent.circle_radius
                    color: table.colors[3]
                    textColor: "white"
                    // TRANSLATORS: Label underneath dot that contains the number of moves left in this game
                    text: i18n.tr ("Moves Left")
                }

                CountCircle {
                    id: score_circle
                    anchors.top: isHorizontal ? undefined : parent.top
                    anchors.left: isHorizontal ? parent.left : undefined
                    anchors.margins: units.gu (2)
                    x: isHorizontal ? 0 : parent.width - parent.circle_spacing - width
                    y: isHorizontal ? parent.height - parent.circle_spacing - height : 0
                    radius: parent.circle_radius
                    color: table.colors[3]
                    textColor: "white"
                    // TRANSLATORS: Label underneath dot that contains the number of dots cleared in the current game
                    text: i18n.tr ("Dots Cleared")
                }

                Item {
                    id: table
                    anchors.top: isHorizontal ? parent.top : moves_circle.bottom
                    anchors.bottom: parent.bottom
                    anchors.left: isHorizontal ? moves_circle.right : parent.left
                    anchors.right: parent.right
                    anchors.margins: units.gu (2)
                    opacity: n_moves == 0 ? 0.25 : 1.0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.InOutCubic
                        }
                    }

                    property var colors: ["#ef2929", "#729fcf", "#8ae234", "#ad7fa8", "#fcaf3e"]
                    property var dots
                    property var selected_dots: []
                    property var lines: []
                    property var line_component
                    property var dot_component
                    property var n_moves
                    property var n_cleared: 0
                    property var spacing: 120
                    property var dot_radius: 30
                    property var line_width: 15

                    function select (x, y) {
                        if (n_moves == 0)
                            return

                        var line = line_component.createObject (table)
                        var dot = get_nearest (x, y)
                        line.x1 = dot.cx
                        line.y1 = dot.cy
                        line.x2 = line.x1
                        line.y2 = line.y1
                        line.color = dot.color
                        line.height = line_width
                        selected_dots.push (dot)
                        lines.push (line)
                    }

                    function move_to (x, y) {
                        if (selected_dots.length == 0)
                            return

                        var last_dot = selected_dots[selected_dots.length - 1]
                        var line = lines[lines.length - 1]

                        // Get the dot we are nearest to
                        var nearest = get_nearest (x, y)
                        var d = Math.pow (last_dot.x_coord - nearest.x_coord, 2) + Math.pow (last_dot.y_coord - nearest.y_coord, 2)

                        // If go back to previous dot then unselect
                        if (selected_dots.length > 1 && nearest == selected_dots[selected_dots.length - 2]) {
                            selected_dots.pop ()
                            line.destroy ()
                            lines.pop ()
                            line = lines[lines.length - 1]
                        }
                        // If go to new dot beside this one then extend line
                        else if (nearest != last_dot && nearest.color == last_dot.color && d == 1) {
                            // If already had this dot selected, then made a loop!
                            for (var i = 0; i < selected_dots.length; i++) {
                                if (selected_dots[i] == nearest) {
                                    complete_loop ()
                                    return
                                }
                            }

                            // End line on this dot
                            line.x2 = nearest.cx
                            line.y2 = nearest.cy

                            // Create a new line
                            line = line_component.createObject (table)
                            line.x1 = nearest.cx
                            line.y1 = nearest.cy
                            line.color = last_dot.color
                            line.height = line_width

                            selected_dots.push (nearest)
                            lines.push (line)
                        }

                        line.x2 = x
                        line.y2 = y
                    }

                    function complete () {
                        if (selected_dots.length < 2) {
                            clear_selection ()
                            return
                        }

                        n_moves--

                        // Clear all the selected dots
                        for (var i = 0; i < selected_dots.length; i++) {
                             var dot = selected_dots[i]
                             dots[dot.x_coord][dot.y_coord] = undefined
                             dot.destroy ()
                             n_cleared++
                        }
                        clear_selection ()

                        fill ()
                        update_labels ()

                        move_complete ()
                    }

                    function complete_loop () {
                        if (selected_dots.length < 2)
                            return

                        n_moves--

                        // Clear all of that color
                        var dot = selected_dots[0]
                        for (var x = 0; x < dots.length; x++) {
                            for (var y = 0; y < dots[0].length; y++) {
                                if (dots[x][y].color == dot.color) {
                                    dots[x][y].destroy ()
                                    dots[x][y] = undefined
                                    n_cleared++
                                }
                            }
                        }
                        clear_selection ()

                        fill (dot.color)
                        update_labels ()

                        move_complete ()
                    }

                    function move_complete () {
                        if (n_moves == 0)
                            end_game ()
                    }

                    function end_game () {
                        // Save score
                        var now = new Date ()
                        get_database ().transaction (function (t) {
                            t.executeSql ("CREATE TABLE IF NOT EXISTS Scores(date TEXT, mode TEXT, score NUMBER)")
                            t.executeSql ("INSERT INTO Scores VALUES(?, ?, ?)", [now.toISOString (), "default", n_cleared])
                        })
                    }

                    function get_database () {
                        return LocalStorage.openDatabaseSync ("scores", "1", "Dotty Scores", 0)
                    }

                    function update_scores () {
                        var scores
                        get_database ().transaction (function (t) {
                            try {
                                scores = t.executeSql ("SELECT * FROM Scores ORDER BY score DESC LIMIT 5")
                            }
                            catch (e) {
                            }
                        })
                        var n_scores = 0
                        if (scores != undefined)
                            n_scores = scores.rows.length

                        var score_entries = [ score_entry0, score_entry1, score_entry2, score_entry3, score_entry4 ]
                        var i
                        for (i = 0; i < n_scores; i++) {
                            var item = scores.rows.item (i)
                            score_entries[i].visible = true
                            score_entries[i].score = item.score
                            score_entries[i].date = format_date (new Date (item.date))
                        }
                        for (; i < 5; i++) {
                            score_entries[i].score = ""
                            score_entries[i].date = ""
                        }
                    }

                    function clear_scores () {
                        get_database ().transaction (function (t) {
                            try {
                                t.executeSql ("DELETE FROM Scores")
                            }
                            catch (e) {
                            }
                        })
                        update_scores ()
                    }

                    function format_date (date) {
                        var now = new Date ()
                        var seconds = (now.getTime () - date.getTime ()) / 1000
                        if (seconds < 1) {
                            // TRANSLATORS: Label shown below high score for a score just achieved
                            return i18n.tr ("Now")
                        }
                        if (seconds < 120) {
                            var n_seconds = Math.floor (seconds)
                            // TRANSLATORS: Label shown below high score for a score achieved seconds ago
                            return i18n.tr ("%n second ago", "%n seconds ago", n_seconds).replace ("%n", n_seconds)
                        }
                        var minutes = seconds / 60
                        if (minutes < 120) {
                            var n_minutes = Math.floor (minutes)
                            // TRANSLATORS: Label shown below high score for a score achieved minutes ago                            
                            return i18n.tr ("%n minute ago", "%n minutes ago", n_minutes).replace ("%n", n_minutes)
                        }
                        var hours = minutes / 60
                        if (hours < 48) {
                            var n_hours = Math.floor (hours)
                            // TRANSLATORS: Label shown below high score for a score achieved hours ago                            
                            return i18n.tr ("%n hour ago", "%n hours ago", n_hours).replace ("%n", n_hours)
                        }
                        var days = hours / 24
                        if (days < 30) {
                            var n_days = Math.floor (days)
                            // TRANSLATORS: Label shown below high score for a score achieved days ago                            
                            return i18n.tr ("%n day ago", "%n days ago", n_days).replace ("%n", n_days)
                        }
                        if (date.getFullYear () != now.getFullYear ())
                            return Qt.formatDate (date, "MMM yyyy")
                        return Qt.formatDate (date, "d MMM")
                    }

                    function update_labels () {
                        moves_circle.count = n_moves
                        score_circle.count = n_cleared
                    }

                    function start_game () {
                        // Clear existing dots
                        clear_selection ()
                        for (var x = 0; x < dots.length; x++) {
                            for (var y = 0; y < dots[0].length; y++) {
                                if (dots[x][y] != undefined) {
                                    dots[x][y].destroy ()
                                    dots[x][y] = undefined
                                }
                            }
                        }

                        // Start new game
                        fill ()
                        n_moves = 30
                        n_cleared = 0
                        update_labels ()
                    }

                    function fill (exclude_color) {
                        var new_colors = []
                        for (var i = 0; i < colors.length; i++)
                                if (colors[i] != exclude_color)
                                        new_colors[new_colors.length] = colors[i]

                        // Add in new dots
                        var new_dots = []
                        for (var y = dots[1].length - 1; y >= 0; y--) {
                            for (var x = 0; x < dots.length; x++) {
                                if (dots[x][y] != undefined)
                                    continue

                                // Drop down dot from above
                                var above_dot = undefined
                                for (var yy = y - 1; yy >= 0; yy--) {
                                    if (dots[x][yy] != undefined) {
                                        above_dot = dots[x][yy]
                                        dots[x][yy] = undefined
                                        break
                                    }
                                }

                                // If nothing above, create a new one
                                if (above_dot == undefined) {
                                    above_dot = dot_component.createObject (table)
                                    new_dots[new_dots.length] = above_dot
                                    above_dot.color = new_colors[Math.floor (Math.random () * new_colors.length)]
                                }

                                // Move dot down into empty space
                                above_dot.x_coord = x
                                above_dot.y_coord = y
                                place_dot (above_dot)
                                dots[x][y] = above_dot
                            }
                        }

                        // If no there are no possible dots to link then make one of the new
                        // dots match an adjacent one
                        if (!can_link ()) {
                             var new_dot = new_dots[Math.floor (Math.random () * new_dots.length)]
                             if (new_dot.y_coord == 0)
                                 new_dot.color = dots[new_dot.x_coord][new_dot.y_coord + 1].color
                             else
                                 new_dot.color = dots[new_dot.x_coord][new_dot.y_coord - 1].color
                        }
                    }

                    function can_link () {
                        for (var x = 0; x < dots.length; x++)
                            for (var y = 0; y < dots[0].length; y++) {
                                var c = dots[x][y].color
                                if (x > 0 && dots[x-1][y].color == c)
                                    return true
                                if (x + 1 < dots.length && dots[x+1][y].color == c)
                                    return true
                                if (y > 0 && dots[x][y-1].color == c)
                                    return true
                                if (y + 1 < dots[0].length && dots[x][y+1].color == c)
                                    return true
                            }

                        return false
                    }

                    function clear_selection () {
                        for (var i = 0; i < lines.length; i++)
                             lines[i].destroy ()
                        lines = []
                        selected_dots = []
                    }

                    function get_nearest (x, y) {
                        var nearest
                        var d = -1
                        for (var dx = 0; dx < dots.length; dx++) {
                            for (var dy = 0; dy < dots[dx].length; dy++) {
                                var dot = dots[dx][dy]
                                var dd = Math.pow (x - dot.cx, 2) + Math.pow (y - dot.cy, 2)
                                if (dd < d || d < 0) {
                                    d = dd
                                    nearest = dot
                                }
                            }
                        }
                        return nearest
                    }

                    onWidthChanged: layout ()
                    onHeightChanged: layout ()

                    function layout () {
                        if (dots == undefined)
                            return

                        var size = Math.min (width, height)
                        spacing = size / dots.length
                        dot_radius = spacing / 4
                        line_width = Math.round (dot_radius / 2)

                        for (var x = 0; x < dots.length; x++)
                            for (var y = 0; y < dots[0].length; y++)
                                place_dot (dots[x][y])
                        for (var i = 0; i < lines.length; line++)
                            lines[i].width = line_width
                    }

                    function place_dot (dot) {
                        var x_offset = (width - (dots.length - 1) * spacing) / 2
                        var y_offset = (height - (dots[0].length - 1) * spacing) / 2
                        dot.cx = x_offset + dot.x_coord * spacing
                        dot.cy = y_offset + dot.y_coord * spacing
                        dot.width = dot_radius * 2
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: table.select (mouse.x, mouse.y)
                        onPositionChanged: table.move_to (mouse.x, mouse.y)
                        onReleased: table.complete ()
                    }

                    Component.onCompleted: {
                        table.dot_component = Qt.createComponent ("Dot.qml")
                        //if (dot_component.status == Component.Ready)
                        table.line_component = Qt.createComponent ("Line.qml")
                        //if (line_component.status == Component.Ready)

                        dots = new Array (6)
                        for (var x = 0; x < 6; x++)
                            dots[x] = new Array (6)
                        table.start_game ()
                        layout ()
                    }
                }
            }
        }

        Page {
            id: how_to_play_page
            visible: false
            // TRANSLATORS: Title of page with game instructions
            title: i18n.tr ("How to Play")

            Label {
                anchors.fill: parent
                anchors.margins: units.gu (2)

                wrapMode: Text.Wrap
                textFormat: Text.StyledText
                // TRANSLATORS: Game instructions
                text: i18n.tr ("<p><i>Dotty</i> is a game where the goal is to clear as many dots in 30 turns.</p>\
<br/>\
<p>To link dots drag your finger / cursor between adjacent dots of the same color (horizontally or vertically). \
The dots you link will be removed and new dots will drop in from the top. \
The number of dots cleared is added to your total - clear as many as possible!</p>\
<br/>\
<p>If you can link the dots in a loop all the dots of that color will be cleared! \
In addition, the replacement dots will not be of the color you cleared which will make it more likely to get another loop. \
Loops are the best way to get high scores.</p>\
<br/>\
<p>Have fun!</p>")
            }
        }

        Page {
            id: scores_page
            visible: false
            // TRANSLATORS: Title of page showing high scores
            title: i18n.tr ("High Scores")

            head.actions:
            [
                Action {
                    // TRANSLATORS: Action in high scores page that clears scores
                    text: i18n.tr ("Clear scores")
                    iconName: "reset"
                    onTriggered: PopupUtils.open (confirm_clear_scores_dialog)
                }
            ]

            ScoreEntry {
                id: score_entry0
                x: parent.width * 0.3 - width * 0.5
                y: parent.height * 0.2 - height * 0.5
                color: table.colors[0]
                size: units.gu (10)
            }
            ScoreEntry {
                id: score_entry1
                x: parent.width * 0.7 - width * 0.5
                y: parent.height * 0.35 - height * 0.5
                color: table.colors[1]
                size: units.gu (9)
            }
            ScoreEntry {
                id: score_entry2
                x: parent.width * 0.3 - width * 0.5
                y: parent.height * 0.5 - height * 0.5
                color: table.colors[2]
                size: units.gu (8)
            }
            ScoreEntry {
                id: score_entry3
                x: parent.width * 0.7 - width * 0.5
                y: parent.height * 0.65 - height * 0.5
                color: table.colors[3]
                size: units.gu (7)
            }
            ScoreEntry {
                id: score_entry4
                x: parent.width * 0.3 - width * 0.5
                y: parent.height * 0.8 - height * 0.5
                color: table.colors[4]
                size: units.gu (6)
            }
        }
    }
}
