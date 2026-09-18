FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

RUN git config --global --add safe.directory /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

ARG SETTLY_HOST=https://settly.duckdns.org

# Stempel builda, po którym działająca strona poznaje, że serwer ma nowszą
# wersję. Wstrzykiwany PRZED `flutter build web`, żeby trafił do index.html
# objętego mapą zasobów service workera; build-id.json powstaje PO buildzie,
# więc celowo zostaje poza tą mapą i jest zawsze pobierany z sieci.
ARG SETTLY_BUILD=dev
RUN sed -i "s|__SETTLY_BUILD__|${SETTLY_BUILD}|g" web/index.html

# --no-tree-shake-icons: font ikon jest w KAŻDYM buildzie taki sam.
#
# Domyślnie build przycina MaterialIcons do glifów użytych w danym buildzie i
# zapisuje wynik pod niezmienną nazwą assets/fonts/MaterialIcons-Regular.otf.
# Każdy klient, który ma w cache font ze starszego builda, rysuje więc jako nic
# każdą ikonę dodaną od tamtej pory — a stare ikony działają, więc wygląda to
# na błąd koloru albo układu (tak to wyglądało trzy razy: kosz w sugestiach,
# potem plakietka „Nie uczestniczysz", potem strzałki w Rozliczeniach).
# Pełny font waży ~1,6 MB, jest pobierany raz i od tej pory żadna nowa ikona
# nie zależy od tego, czy klientowi odświeżył się cache.
RUN flutter build web --release --no-tree-shake-icons --dart-define=SETTLY_HOST=$SETTLY_HOST

RUN printf '{"buildId":"%s"}\n' "${SETTLY_BUILD}" > build/web/build-id.json

FROM nginx:alpine

COPY nginx/web.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
