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

RUN flutter build web --release --dart-define=SETTLY_HOST=$SETTLY_HOST

RUN printf '{"buildId":"%s"}\n' "${SETTLY_BUILD}" > build/web/build-id.json

FROM nginx:alpine

COPY nginx/web.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
