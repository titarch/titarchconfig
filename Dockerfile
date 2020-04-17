FROM archlinux

RUN pacman -Sy --noconfirm base base-devel
RUN useradd -ms /bin/bash tu
WORKDIR /home/tu
COPY . .
