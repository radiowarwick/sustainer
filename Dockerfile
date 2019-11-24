FROM debian:stretch

WORKDIR /sustainer

RUN apt update && \
    apt install -y liquidsoap \
    liquidsoap-plugin-alsa \
    liquidsoap-plugin-jack \
    liquidsoap-plugin-pulseaudio

RUN touch /var/log/liquidsoap/sustainer.log && \
    chmod 777 /var/log/liquidsoap/sustainer.log

RUN useradd user && \
    usermod -aG audio user

EXPOSE 8080

COPY . .

USER user

CMD ["liquidsoap", "sustainer.liq"]