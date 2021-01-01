from espressif/idf:release-v4.0

RUN wget https://nim-lang.org/download/nim-1.4.2-linux_x64.tar.xz 
RUN tar xvf nim-1.4.2-linux_x64.tar.xz
ENV PATH="/nim-1.4.2/bin:${PATH}"

# Install utilities
RUN apt-get update
RUN apt-get install -y fish joe

# Configure fish shell
RUN chsh root -s /usr/bin/fish
COPY config.fish /root/.config/fish/

ENV EDITOR joe
