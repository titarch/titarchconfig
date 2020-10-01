FROM archlinux

RUN pacman -Syu --noconfirm base base-devel

RUN useradd -ms /bin/bash tu && chpasswd "tu:tu" && groupadd sudo && usermod -aG sudo tu
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
WORKDIR /home/tu
COPY . titarchconfig
USER tu
