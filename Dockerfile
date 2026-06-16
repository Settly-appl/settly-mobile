FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

RUN git config --global --add safe.directory /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

ARG SETTLY_HOST=https://settly.duckdns.org
RUN flutter build web --release --dart-define=SETTLY_HOST=$SETTLY_HOST

FROM nginx:alpine

COPY nginx/web.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
