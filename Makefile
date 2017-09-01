all: dotty.desktop \
     po/com.ubuntu.developer.robert-ancell.dotty.pot \
     share/locale/cs/LC_MESSAGES/com.ubuntu.developer.robert-ancell.dotty.mo \
     share/locale/de/LC_MESSAGES/com.ubuntu.developer.robert-ancell.dotty.mo \
     share/locale/el/LC_MESSAGES/com.ubuntu.developer.robert-ancell.dotty.mo \
     share/locale/fi/LC_MESSAGES/com.ubuntu.developer.robert-ancell.dotty.mo \
     share/locale/fr/LC_MESSAGES/com.ubuntu.developer.robert-ancell.dotty.mo \
     share/locale/hu/LC_MESSAGES/com.ubuntu.developer.robert-ancell.dotty.mo \
     share/locale/it/LC_MESSAGES/com.ubuntu.developer.robert-ancell.dotty.mo \
     share/locale/nl/LC_MESSAGES/com.ubuntu.developer.robert-ancell.dotty.mo \
     share/locale/pl/LC_MESSAGES/com.ubuntu.developer.robert-ancell.dotty.mo \
     share/locale/pt/LC_MESSAGES/com.ubuntu.developer.robert-ancell.dotty.mo \
     share/locale/ru/LC_MESSAGES/com.ubuntu.developer.robert-ancell.dotty.mo \
     share/locale/tr/LC_MESSAGES/com.ubuntu.developer.robert-ancell.dotty.mo \
     share/locale/zh_CN/LC_MESSAGES/com.ubuntu.developer.robert-ancell.dotty.mo

click:
	click build --ignore=Makefile --ignore=*.pot --ignore=*.po --ignore=*.qmlproject --ignore=*.qmlproject.user --ignore=*.in --ignore=po --ignore=*.sh .

dotty.desktop: dotty.desktop.in po/*.po
	msgfmt --desktop --template=dotty.desktop.in -d po/ -o $@

po/com.ubuntu.developer.robert-ancell.dotty.pot: main.qml dotty.desktop.in
	xgettext --from-code=UTF-8 --language=JavaScript --keyword=tr --keyword=tr:1,2 --add-comments=TRANSLATORS --force-po main.qml -o po/com.ubuntu.developer.robert-ancell.dotty.pot
	xgettext --language=Desktop -k -kName -kComment -kKeywords --add-comments=TRANSLATORS dotty.desktop.in -j -o $@

share/locale/%/LC_MESSAGES/com.ubuntu.developer.robert-ancell.dotty.mo: po/%.po
	msgfmt -o $@ $<

clean:
	rm -f share/locale/*/*/*.mo share/locale/*/*/.gitkeep dotty.desktop

run:
	/usr/bin/qmlscene $@ main.qml
